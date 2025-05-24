#!/bin/bash
set -e

ACCESS_LOG="/app/access_log"
CHAIN_NAME="${CHAIN_NAME:-PORTKEY_AUTH}"

if [ -z "$PORTS" ]; then
    echo "Error: PORTS environment variable is not set."
    exit 1
fi
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

# ensure access log exists even if services are started out of order
touch $ACCESS_LOG
chmod 666 $ACCESS_LOG

iptables -N $CHAIN_NAME 2>/dev/null || echo "Chain $CHAIN_NAME already exists"

if [ $(iptables -L $CHAIN_NAME -n | wc -l) -le 3 ]; then
    echo "Chain S$CHAIN_NAME is empty, setting default policy to DROP"
    iptables -A $CHAIN_NAME -j DROP
else
    echo "Chain $CHAIN_NAME exists, preserving configuration"
fi

# Send all traffic for configured ports to our chain if not already set up
echo "Directing traffic for multiple ports to $CHAIN_NAME chain (Portkey)"
for PORT in "${PORT_ARRAY[@]}"; do
    if ! iptables -L INPUT -n | grep -q "$CHAIN_NAME.*dpt:$PORT"; then
        echo "Adding rule for port $PORT to $CHAIN_NAME chain"
        iptables -A INPUT -p tcp --dport $PORT -j $CHAIN_NAME
    else
        echo "Traffic from port $PORT already directed to $CHAIN_NAME chain"
    fi
done


echo "Portkey Authentication firewall manager started"
echo "Monitoring for access requests on ports (${PORT_ARRAY[*]})"

# Monitor the access log file for new entries
tail -f $ACCESS_LOG | while read line; do
    # Parse the text format entry (TIMESTAMP|ACTION|IP|USERNAME)
        IFS='|' read -r timestamp action ip username <<< "$line"

        # Validate inputs
        if [[ -z "$ip" ]]; then
            echo "Error: Invalid parameters in log entry: $line"
            continue
        fi

    # If username is empty, set it to unknown
    if [[ -z "$username" ]]; then
        username="unknown"
    fi

    if [ "$action" = "allow" ]; then
        # Always add rules for all configured ports
        for PORT in "${PORT_ARRAY[@]}"; do
            if iptables -L $CHAIN_NAME -n | grep -q "ACCEPT.*$ip.*dpt:$PORT"; then
                echo "[$timestamp] IP $ip already has access to port $PORT (User: $username)"
                continue
            fi

            echo "[$timestamp] Allowing access from $ip to port $PORT (User: $username)"
            # Insert at the top of the chain (before the DROP rule)
            iptables -I $CHAIN_NAME 1 -p tcp -s $ip --dport $PORT -j ACCEPT
        done
    fi
done
