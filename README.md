# Portkey

## Lock down your services

Use Docker, Caddy, and iptables to show a login page and allow users to access protected services.

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
```

### 3. Access the Web Portal

Open your browser and navigate to `http://your-server-ip`.

## Configuration Options

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `PORTS` | Comma-separated list of ports to protect | 22,8080,8443,3306 |
| `SERVER_ADDRESS` | Server address shown to users | your-server-address |

## Security Considerations

- The default configuration uses HTTP. For production, enable HTTPS by setting `DOMAIN` in your `.env` file.
- User credentials are stored in a flat username:password file format
- The iptables manager container runs with NET_ADMIN capability to modify firewall rules
- Only authenticated users can access the protected ports (except 80/443 for the portal itself)
- All protected ports share the same access rules - once authenticated, a user has access to all ports

## Customization

### Custom Styling

To modify the appearance of the login page, edit `app/index.php` and update the CSS in the style section.

### Managing Users

Edit the `app/passwd` file directly to manage users. The file format is simple:
```
username:password
```

Each line contains a username and password pair separated by a colon.

### Removing Access Rules

Since access rules persist by design, you must manually clear them:

   - **Manual Cleanup**: Use the included `clear_access.sh` script:
     ```bash
     sudo ./clear_access.sh
     ```

   - **For Advanced Users**: Flush the chain manually:
     ```bash
     sudo iptables -F PORTKEY_AUTH && sudo iptables -A PORTKEY_AUTH -j DROP
     ```

   The script also supports removing specific IP addresses and viewing currently authorized IPs.

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
- **Authentication works but can't connect to the server**: Verify iptables_manager logs to ensure rules are being applied to the correct ports
- **Rules not being applied**: Check if the `access_log` file has correct permissions
- **Changes to passwd file not taking effect**: Restart the container with `docker-compose restart php`
- **Need to clear all access**: Run `sudo ./clear_access.sh` to manually flush the PORTKEY_AUTH chain
- **Access remains after container restart**: This is by design - access rules are persistent across restarts

## License

This project is open source and available under the MIT License.
