#!/bin/bash
# Script to clear all Minecraft server access rules

# Configuration
MINECRAFT_PORT=${1:-25565}
CONTAINER_NAME="homeportal_iptables_manager_1"

echo "Clearing all access to Minecraft server port $MINECRAFT_PORT"

# Option 1: Simply restart the iptables_manager container (recommended)
echo "Method 1: Restarting iptables_manager container to clear all access"
docker restart $CONTAINER_NAME
echo "All access cleared by restarting the container"

# Option 2: For advanced users - manually clear iptables rules without container restart
echo ""
echo "Method 2: Manually clearing iptables rules (for advanced users)"
echo "This will list IP addresses with access and allow you to remove them manually"

# Get list of allowed IPs
ALLOWED_IPS=$(docker exec $CONTAINER_NAME iptables -L INPUT -n | grep ACCEPT | grep "dpt:$MINECRAFT_PORT" | awk '{print $4}')

if [ -z "$ALLOWED_IPS" ]; then
    echo "No IP addresses currently have access to port $MINECRAFT_PORT"
else
    echo "The following IP addresses currently have access to port $MINECRAFT_PORT:"
    for IP in $ALLOWED_IPS; do
        echo " - $IP"
    done
    
    echo ""
    echo "To manually remove access for a specific IP, run:"
    echo "docker exec $CONTAINER_NAME iptables -D INPUT -p tcp -s IP_ADDRESS --dport $MINECRAFT_PORT -j ACCEPT"
    echo ""
    echo "For example:"
    echo "docker exec $CONTAINER_NAME iptables -D INPUT -p tcp -s 192.168.1.100 --dport $MINECRAFT_PORT -j ACCEPT"
    
    echo ""
    echo "To remove ALL access rules at once, run:"
    echo "for IP in $ALLOWED_IPS; do docker exec $CONTAINER_NAME iptables -D INPUT -p tcp -s \$IP --dport $MINECRAFT_PORT -j ACCEPT; done"
fi

echo ""
echo "Note: Method 1 (restarting the container) is the recommended approach"
echo "as it ensures a clean state and proper rule initialization."