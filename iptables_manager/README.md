# IPTables Manager for Minecraft Authentication

This component manages firewall rules to control access to your Minecraft server using a dedicated iptables chain.

## How It Works

1. **Chain Creation**: When the container starts, it:
   - Creates a dedicated `MINECRAFT_AUTH` chain if it doesn't exist
   - Sets the default policy for this chain to DROP if the chain is empty
   - Directs all Minecraft port traffic to this chain if not already set up

2. **Authentication Process**: When a user successfully authenticates through the web portal:
   - Their IP address is added to the `MINECRAFT_AUTH` chain with an ACCEPT rule
   - This rule allows their IP to connect to the Minecraft server port

3. **Persistent Access**: The key feature of this system:
   - Access rules persist even when the container stops or restarts
   - Rules remain in place until manually cleared
   - This ensures continuous access to your Minecraft server

## Chain Structure

The iptables structure looks like this:

```
INPUT chain
└── MINECRAFT_AUTH chain (for port 25565)
    ├── ACCEPT rules for authenticated IPs
    └── Default DROP rule (for all other traffic)
```

## Container Requirements

- `NET_ADMIN` capability: Required to modify iptables rules
- Host network mode: Required to modify the host's firewall rules

## Configuration

The container accepts the following environment variables:

- `MINECRAFT_PORT`: The port your Minecraft server runs on (default: 25565)

## Logs

The container logs all allowed IPs with usernames for auditing purposes. The logs can be viewed with:

```bash
docker-compose logs iptables_manager
```

## Manually Managing Rules

### Viewing Current Rules

To see current firewall rules in the Minecraft chain:

```bash
sudo iptables -L MINECRAFT_AUTH -n
```

### Clearing All Access

Since access rules persist by design, you must manually clear them:

```bash
sudo iptables -F MINECRAFT_AUTH && sudo iptables -A MINECRAFT_AUTH -j DROP
```

This command:
1. Flushes all rules from the chain
2. Adds back the default DROP rule

Alternatively, use the provided script:

```bash
./clear_access.sh
```

### Removing Specific IPs

To remove access for a specific IP:

```bash
sudo iptables -D MINECRAFT_AUTH -p tcp -s IP_ADDRESS --dport 25565 -j ACCEPT
```

## Important Notes

- Restarting or stopping the container will NOT remove access rules
- This is intentional to maintain continuous access to your Minecraft server
- You must manually clear rules if you want to revoke all access

## Troubleshooting

If you encounter issues with firewall rules:

1. Check the iptables_manager logs:
   ```bash
   docker-compose logs iptables_manager
   ```

2. Verify the chain exists:
   ```bash
   sudo iptables -L MINECRAFT_AUTH -n
   ```

3. Ensure traffic is being directed to the chain:
   ```bash
   sudo iptables -L INPUT -n | grep MINECRAFT_AUTH
   ```