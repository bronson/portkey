#!/bin/bash
# Script to clear all server access rules

# Configuration
PORTS=${1:-${PORTS:-22,8080,8443}}
CHAIN_NAME="PORTKEY_AUTH"

# Convert comma-separated ports to array
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

echo "Clearing all access to protected ports: $PORTS"

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
        echo "No IP addresses currently have access to protected ports"
    else
        echo "The following IP addresses currently have access to protected ports:"
        for IP in $ALLOWED_IPS; do
            echo " - $IP"
        done
        
        echo ""
        echo "To clear ALL access at once, run this command:"
        echo "   iptables -F $CHAIN_NAME && iptables -A $CHAIN_NAME -j DROP"
        echo "   # Portkey Authentication - access rules cleared"
        
        echo ""
        echo "To remove access for a specific IP from all ports, run:"
        echo "   iptables -D $CHAIN_NAME -s IP_ADDRESS -j ACCEPT"
        echo ""
        echo "To remove access for a specific IP from a specific port, run:"
        echo "   iptables -D $CHAIN_NAME -p tcp -s IP_ADDRESS --dport PORT_NUMBER -j ACCEPT"
        echo ""
        echo "For example:"
        echo "   iptables -D $CHAIN_NAME -p tcp -s 192.168.1.100 --dport 8080 -j ACCEPT"
        
        echo ""
        echo "IMPORTANT: These commands must be run with root privileges (use sudo if needed)"
    fi
fi

echo ""
echo "IMPORTANT: Restarting the container will NOT clear access rules."
echo "Access rules are now persistent by design and must be manually cleared."