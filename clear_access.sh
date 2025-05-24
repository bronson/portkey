#!/bin/bash
# Script to clear all Minecraft server access rules

# Configuration
MINECRAFT_PORT=${1:-25565}
CONTAINER_NAME="homeportal_iptables_manager_1"
CHAIN_NAME="MINECRAFT_AUTH"

echo "Clearing all access to Minecraft server port $MINECRAFT_PORT"

# Option 1: Simply restart the iptables_manager container (recommended)
echo "Method 1: Restarting iptables_manager container to clear all access"
docker restart $CONTAINER_NAME
echo "All access cleared by restarting the container"

# Option 2: For advanced users - flush the chain without container restart
echo ""
echo "Method 2: Flushing the iptables chain (for advanced users)"
echo "This will clear all access rules without restarting the container"

# Check if our chain exists
CHAIN_EXISTS=$(docker exec $CONTAINER_NAME iptables -L $CHAIN_NAME -n 2>/dev/null || echo "")

if [ -z "$CHAIN_EXISTS" ]; then
    echo "The $CHAIN_NAME chain does not exist. No rules to clear."
else
    # Get list of allowed IPs
    ALLOWED_IPS=$(docker exec $CONTAINER_NAME iptables -L $CHAIN_NAME -n | grep ACCEPT | awk '{print $4}')
    
    if [ -z "$ALLOWED_IPS" ]; then
        echo "No IP addresses currently have access to port $MINECRAFT_PORT"
    else
        echo "The following IP addresses currently have access to port $MINECRAFT_PORT:"
        for IP in $ALLOWED_IPS; do
            echo " - $IP"
        done
        
        echo ""
        echo "To flush all rules and reset the chain, run:"
        echo "docker exec $CONTAINER_NAME iptables -F $CHAIN_NAME"
        
        echo ""
        echo "To manually remove access for a specific IP, run:"
        echo "docker exec $CONTAINER_NAME iptables -D $CHAIN_NAME -p tcp -s IP_ADDRESS --dport $MINECRAFT_PORT -j ACCEPT"
        echo ""
        echo "For example:"
        echo "docker exec $CONTAINER_NAME iptables -D $CHAIN_NAME -p tcp -s 192.168.1.100 --dport $MINECRAFT_PORT -j ACCEPT"
    fi
fi

echo ""
echo "Note: Method 1 (restarting the container) is the recommended approach"
echo "as it ensures a clean state and proper rule initialization."