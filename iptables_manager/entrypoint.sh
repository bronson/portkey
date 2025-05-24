#!/bin/bash
set -e

MINECRAFT_PORT=${MINECRAFT_PORT:-25565}
ACCESS_LOG="/app/access_log"
CHAIN_NAME="MINECRAFT_AUTH"

# Create access log file if it doesn't exist
touch $ACCESS_LOG
chmod 666 $ACCESS_LOG

# Function to handle cleanup on exit
cleanup() {
    echo "Cleaning up firewall rules..."
    
    # Remove reference to our chain from INPUT
    echo "Removing reference to $CHAIN_NAME chain from INPUT chain"
    iptables -D INPUT -p tcp --dport $MINECRAFT_PORT -j $CHAIN_NAME 2>/dev/null || true
    
    # Remove all rules in our chain and delete the chain
    echo "Flushing and removing $CHAIN_NAME chain"
    iptables -F $CHAIN_NAME 2>/dev/null || true
    iptables -X $CHAIN_NAME 2>/dev/null || true
    
    echo "Cleanup complete"
    exit 0
}

# Set up trap for cleanup
trap cleanup SIGTERM SIGINT

# Create a new chain for Minecraft authentication
echo "Creating $CHAIN_NAME chain for Minecraft authentication"
iptables -N $CHAIN_NAME 2>/dev/null || iptables -F $CHAIN_NAME

# Set default policy for our chain to DROP
echo "Setting default policy for $CHAIN_NAME chain to DROP"
iptables -A $CHAIN_NAME -j DROP

# Send Minecraft traffic to our chain
echo "Directing Minecraft traffic to $CHAIN_NAME chain"
iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -j $CHAIN_NAME

# Keep track of allowed IPs for logging
declare -A allowed_ips

echo "Minecraft authentication firewall manager started"
echo "Monitoring for access requests on port $MINECRAFT_PORT"
echo "Note: IP access remains valid until container restart"
echo "All authorized IPs are managed in iptables chain: $CHAIN_NAME"

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
        # Check if this IP is already allowed
        if [[ -n "${allowed_ips[$ip]}" ]]; then
            echo "IP $ip already has access to port $port (User: $username)"
            continue
        fi
        
        echo "Allowing access from $ip to port $port (User: $username)"
        
        # Add firewall rule to allow access to our chain
        # Insert at the top of the chain (before the DROP rule)
        iptables -I $CHAIN_NAME 1 -p tcp -s $ip --dport $port -j ACCEPT
        
        # Store IP in our tracking array
        allowed_ips["$ip"]="$port:$username"
    fi
done