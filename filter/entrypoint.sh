#!/bin/bash
set -e

ACCESS_LOG=${ACCESS_LOG:-"/app/access_log"}
AUTHORIZED_IPS=${AUTHORIZED_IPS:-"/app/authorized_ips"}
CHAIN_NAME="${CHAIN_NAME:-PORTKEY_AUTH}"

if [ -z "$PORTS" ]; then
    echo "Error: PORTS environment variable is not set." >&2
    exit 1
fi
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

# ensure files exist even if services are started out of order
touch $ACCESS_LOG $AUTHORIZED_IPS
chmod 666 $ACCESS_LOG $AUTHORIZED_IPS

iptables -N $CHAIN_NAME 2>/dev/null || echo "Chain $CHAIN_NAME already exists"

if [ $(iptables -L $CHAIN_NAME -n | wc -l) -le 3 ]; then
    echo "Chain S$CHAIN_NAME is empty, setting default policy to DROP"
    iptables -A $CHAIN_NAME -j DROP
else
    echo "Chain $CHAIN_NAME exists, preserving configuration"
fi

# Send all traffic for configured ports to our chain if not already set up
echo "Directing traffic for ports (${PORT_ARRAY[*]}) to $CHAIN_NAME"
for PORT in "${PORT_ARRAY[@]}"; do
    if ! iptables -L INPUT -n | grep -q "$CHAIN_NAME.*dpt:$PORT"; then
        echo "Adding rule for port $PORT to $CHAIN_NAME chain"
        iptables -A INPUT -p tcp --dport $PORT -j $CHAIN_NAME
    else
        echo "Traffic from port $PORT already directed to $CHAIN_NAME chain"
    fi
done

function update_authorized_ips() {
    echo "# Authorized IPs - Last updated: $(date)" > $AUTHORIZED_IPS
    echo "# Managed by Portkey DO NOT EDIT" >> $AUTHORIZED_IPS
    iptables -L $CHAIN_NAME -n | grep ACCEPT | awk '{print $4}' >> $AUTHORIZED_IPS
    echo "# done." >> $AUTHORIZED_IPS
}

# Monitor the access log file for new entries
tail -f $ACCESS_LOG | while read line; do
    # Parse the text format entry (TIMESTAMP|ACTION|IP|USERNAME)
    IFS='|' read -r timestamp action ip username <<< "$line"

    # Validate inputs
    if [[ -z "$username" ]]; then
        echo "Error: Invalid parameters in log entry: $line"
        continue
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
        # Update the authorized IPs file
        update_authorized_ips
    elif [ "$action" = "deny" ]; then
        # Remove access for all configured ports
        echo "[$timestamp] Revoking access for IP $ip (User: $username)"
        for PORT in "${PORT_ARRAY[@]}"; do
            if iptables -L $CHAIN_NAME -n | grep -q "ACCEPT.*$ip.*dpt:$PORT"; then
                echo "[$timestamp] Removing access for IP $ip to port $PORT (User: $username)"
                iptables -D $CHAIN_NAME -p tcp -s $ip --dport $PORT -j ACCEPT
            fi
        done
        echo "[$timestamp] Access revoked for IP $ip (User: $username)"
        # Update the authorized IPs file
        update_authorized_ips
    else
        echo "[$timestamp] Invalid action '$action' for IP $ip (User: $username)"
    fi
done
