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
```

### 3. Access the Web Portal

Open your browser and navigate to `http://your-server-ip`.

## Configuration Options

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `PORTS` | Comma-separated list of ports to protect | 25565,25566,25567,7777 |
| `SERVER_ADDRESS` | Server address shown to users | your-server-address |

## Security Considerations

- The default configuration uses HTTP. For production, enable HTTPS by setting `DOMAIN` in your `.env` file.
- User credentials are stored in a JSON file (`users.json`) that can be directly edited
- The iptables manager container runs with NET_ADMIN capability to modify firewall rules
- Only authenticated users can access the protected ports
- All ports share the same access rules - once authenticated, a user has access to all ports

## Customization

### Custom Styling

To modify the appearance of the login page, edit `app/index.php` and update the CSS in the style section.


2. **Removing Access Rules**: Since access rules persist by design, you must manually clear them:
   
   - **Manual Cleanup**: Use the included `clear_access.sh` script:
     ```bash
     sudo ./clear_access.sh
     ```
   
   - **For Advanced Users**: Flush the chain manually:
     ```bash
     sudo iptables -F PORTAL_AUTH && sudo iptables -A PORTAL_AUTH -j DROP
     ```

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
- **Changes to users.json not taking effect**: Make sure the file is valid JSON and restart the container with `docker-compose restart php`
- **Need to clear all access**: Run `sudo ./clear_access.sh` to manually flush the PORTAL_AUTH chain
- **Access remains after container restart**: This is by design - access rules are persistent across restarts

## License

This project is open source and available under the MIT License.
