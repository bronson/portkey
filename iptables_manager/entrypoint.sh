#!/bin/bash
set -e

MINECRAFT_PORT=${MINECRAFT_PORT:-25565}
ACCESS_LOG="/app/access_log"

# Create access log file if it doesn't exist
touch $ACCESS_LOG
chmod 666 $ACCESS_LOG

# Function to handle cleanup on exit
cleanup() {
    echo "Cleaning up firewall rules..."
    # Remove our custom DROP rule
    iptables -D INPUT -p tcp --dport $MINECRAFT_PORT -j DROP 2>/dev/null || true
    echo "Cleanup complete"
    exit 0
}

# Set up trap for cleanup
trap cleanup SIGTERM SIGINT

# Block all external access to Minecraft port by default
echo "Setting up initial firewall rule to block external access to port $MINECRAFT_PORT"
iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -j DROP

# Keep track of allowed IPs for cleanup
declare -A allowed_ips

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
    duration=$(echo $line | jq -r '.duration')
    timestamp=$(echo $line | jq -r '.timestamp')
    
    # Validate inputs
    if [[ -z "$ip" || -z "$port" || ! "$port" =~ ^[0-9]+$ || ! "$duration" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid parameters in log entry: $line"
        continue
    fi
    
    if [ "$action" = "allow" ]; then
        echo "Allowing access from $ip to port $port for $duration hours"
        
        # Add firewall rule to allow access
        iptables -I INPUT -p tcp -s $ip --dport $port -j ACCEPT
        
        # Store IP in our tracking array
        allowed_ips["$ip"]="$port"
        
        # Set rule to expire after duration
        (
            sleep $(($duration * 3600))
            echo "Removing access for $ip to port $port"
            iptables -D INPUT -p tcp -s $ip --dport $port -j ACCEPT 2>/dev/null || echo "Rule for $ip already removed"
            # Remove from tracking array
            unset allowed_ips["$ip"]
        ) &
    fi
done