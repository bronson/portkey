# Homeportal

## A Network Authentication Portal

A Docker-based authentication system for controlling server access with a web portal and iptables.

## Overview

This project provides:

- **Web Server**: Serves the webpage to authenticate against
- **PHP-FPM**: handles authentication logic
- **IPTables Manager**: Manages firewall rules

## Requirements

- Docker and Docker Compose
- A server running Linux (for iptables support)
- Port 80/443 available for the web interface
- Root privileges for iptables management

## Setup Instructions

### 1. Configure Environment Variables

```bash
cp .env.example .env
nano .env  # Edit with your own credentials and settings
```

### 2. Build and Start the Services

```bash
docker-compose up -d
chmod +x clear_access.sh  # Make the cleanup script executable
```

### 3. Access the Web Portal

Open your browser and navigate to `http://your-server-ip`.

## Configuration Options

| Environment Variable | Description | Default |
|---------------------|-------------|---------|

| `MINECRAFT_PORT` | Port your Minecraft server runs on | 25565 |
| `SERVER_ADDRESS` | Minecraft server address shown to users | your-server-address |

## Security Considerations

- The default configuration uses HTTP. For production, enable HTTPS by setting `DOMAIN` in your `.env` file.
- User credentials are stored in a JSON file (`users.json`) that can be directly edited.
- The iptables manager container runs with NET_ADMIN capability, allowing it to modify firewall rules.
- Only authenticated users can access your Minecraft server.

## Customization

### Custom Styling

To modify the appearance of the login page, edit `app/index.php` and update the CSS in the style section.

### Managing Users

Edit the `app/users.json` file directly to manage users. The file structure is as follows:

```json
[
    {
        "username": "user1",
        "password": "password1",
        "note": "John's account"
    },
    {
        "username": "user2",
        "password": "password2",
        "note": "Jane's account"
    }
]
```

Each user entry consists of:
- `username`: Unique identifier for the user
- `password`: User's authentication password
- `note` (optional): A note about the user account

To add, edit, or remove users, simply modify this JSON file directly.

### Access Control

All authenticated users will have access to the Minecraft server until the container is restarted. There is no automatic expiration of access.

#### How IP Rules Are Removed

There are two ways to remove IP access rules:

1. **Automatic Cleanup on Container Restart**: When the iptables_manager container is restarted or stopped, it automatically removes all IP access rules.

2. **Manual Cleanup**: Use the included `clear_access.sh` script to manually clear all access:
   ```bash
   ./clear_access.sh
   ```
   This script will restart the iptables_manager container, which removes all current access rules.

## Troubleshooting

### Checking Logs

```bash
# View logs for all services
docker-compose logs

# View logs for a specific service
docker-compose logs web
docker-compose logs php
docker-compose logs iptables_manager
```

### Common Issues

- **Web page doesn't load**: Check if ports 80/443 are accessible and not blocked by firewall
- **Authentication works but can't connect to Minecraft**: Verify iptables_manager logs to ensure rules are being applied
- **Rules not being applied**: Check if the `access_log` file has correct permissions
- **Changes to users.json not taking effect**: Make sure the file is valid JSON and restart the container with `docker-compose restart php`
- **Need to clear all access**: Run `./clear_access.sh` to restart the iptables_manager and clear all access rules

## License

This project is open source and available under the MIT License.
