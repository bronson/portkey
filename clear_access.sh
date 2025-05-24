#!/bin/bash
# Script to clear all Minecraft server access rules

# Configuration
MINECRAFT_PORT=${1:-25565}
CHAIN_NAME="MINECRAFT_AUTH"

echo "Clearing all access to Minecraft server port $MINECRAFT_PORT"

# Note: The container no longer removes rules on restart
echo "NOTE: Restarting the container will NOT clear access rules anymore."
echo "Access rules are now persistent across container restarts."

# Manual method to clear the rules
echo ""
echo "To clear all access rules, you must manually flush the chain:"
echo "This is the ONLY way to clear access since rules now persist"

# Check if our chain exists
CHAIN_EXISTS=$(iptables -L $CHAIN_NAME -n 2>/dev/null || echo "")

if [ -z "$CHAIN_EXISTS" ]; then
    echo "The $CHAIN_NAME chain does not exist. No rules to clear."
else
    # Get list of allowed IPs
    ALLOWED_IPS=$(iptables -L $CHAIN_NAME -n | grep ACCEPT | awk '{print $4}')
    
    if [ -z "$ALLOWED_IPS" ]; then
        echo "No IP addresses currently have access to port $MINECRAFT_PORT"
    else
        echo "The following IP addresses currently have access to port $MINECRAFT_PORT:"
        for IP in $ALLOWED_IPS; do
            echo " - $IP"
        done
        
        echo ""
        echo "To clear ALL access at once, run this command:"
        echo "   iptables -F $CHAIN_NAME && iptables -A $CHAIN_NAME -j DROP"
        
        echo ""
        echo "To remove access for a specific IP, run:"
        echo "   iptables -D $CHAIN_NAME -p tcp -s IP_ADDRESS --dport $MINECRAFT_PORT -j ACCEPT"
        echo ""
        echo "For example:"
        echo "   iptables -D $CHAIN_NAME -p tcp -s 192.168.1.100 --dport $MINECRAFT_PORT -j ACCEPT"
        
        echo ""
        echo "IMPORTANT: These commands must be run with root privileges (use sudo if needed)"
    fi
fi

echo ""
echo "IMPORTANT: Restarting the container will NOT clear access rules."
echo "Access rules are now persistent by design and must be manually cleared."