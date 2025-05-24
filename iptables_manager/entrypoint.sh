#!/bin/bash
set -e

# Allow comma-separated list of ports
PORTS=${PORTS:-22,8080,8443}
ACCESS_LOG="/app/access_log"
CHAIN_NAME="PORTAL_AUTH"

# Convert comma-separated ports to array
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

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

# Send all traffic for configured ports to our chain if not already set up
echo "Directing traffic for multiple ports to $CHAIN_NAME chain"
for PORT in "${PORT_ARRAY[@]}"; do
    if ! iptables -L INPUT -n | grep -q "$CHAIN_NAME.*dpt:$PORT"; then
        echo "Adding rule for port $PORT to $CHAIN_NAME chain"
        iptables -A INPUT -p tcp --dport $PORT -j $CHAIN_NAME
    else
        echo "Traffic from port $PORT already directed to $CHAIN_NAME chain"
    fi
done


echo "Port Access Authentication firewall manager started"
echo "Monitoring for access requests on ports: $PORTS"

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
        # Always add rules for all configured ports
        for PORT in "${PORT_ARRAY[@]}"; do
            if iptables -L $CHAIN_NAME -n | grep -q "ACCEPT.*$ip.*dpt:$PORT"; then
                echo "IP $ip already has access to port $PORT (User: $username)"
                continue
            fi
            
            echo "Allowing access from $ip to port $PORT (User: $username)"
            # Insert at the top of the chain (before the DROP rule)
            iptables -I $CHAIN_NAME 1 -p tcp -s $ip --dport $PORT -j ACCEPT
        done
    fi
done
