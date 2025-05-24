#!/bin/bash
set -e

MINECRAFT_PORT=${MINECRAFT_PORT:-25565}
ACCESS_LOG="/app/access_log"
CHAIN_NAME="MINECRAFT_AUTH"

# Create access log file if it doesn't exist
touch $ACCESS_LOG
chmod 666 $ACCESS_LOG

iptables -N $CHAIN_NAME 2>/dev/null || echo "Chain $CHAIN_NAME already exists"

if [ $(iptables -L $CHAIN_NAME -n | wc -l) -le 3 ]; then
    echo "Chain is empty, setting default policy for $CHAIN_NAME chain to DROP"
    iptables -A $CHAIN_NAME -j DROP
else
    echo "Chain $CHAIN_NAME already has rules, preserving existing configuration"
fi

# Send Minecraft traffic to our chain if not already set up
if ! iptables -L INPUT -n | grep -q "$CHAIN_NAME"; then
    echo "Directing Minecraft traffic to $CHAIN_NAME chain"
    iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -j $CHAIN_NAME
else
    echo "Traffic from port $MINECRAFT_PORT already directed to $CHAIN_NAME chain"
fi


echo "Minecraft authentication firewall manager started"
echo "Monitoring for access requests on port $MINECRAFT_PORT"

# Monitor the access log file for new entries
tail -f $ACCESS_LOG | while read line; do
    # Parse the JSON log entry
    if ! jq -e . >/dev/null 2>&1 <<< "$line"; then
        echo "Error: Invalid JSON entry: $line"
        continue
    fi

    action=$(echo $line | jq -r '.action')
    ip=$(echo $line | jq -r '.ip')
    port=$(echo $line | jq -r '.port')
    username=$(echo $line | jq -r '.username // "unknown"')

    # Validate inputs
    if [[ -z "$ip" || -z "$port" || ! "$port" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid parameters in log entry: $line"
        continue
    fi

    if [ "$action" = "allow" ]; then
        if iptables -L $CHAIN_NAME -n | grep -q "ACCEPT.*$ip.*dpt:$port"; then
            echo "IP $ip already has access to port $port (User: $username)"
            continue
        fi

        echo "Allowing access from $ip to port $port (User: $username)"

        # Add firewall rule to allow access to our chain
        # Insert at the top of the chain (before the DROP rule)
        iptables -I $CHAIN_NAME 1 -p tcp -s $ip --dport $port -j ACCEPT
    fi
done
