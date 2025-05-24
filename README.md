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
| `AUTH_USERNAME` | Username for authentication | your_friend_username |
| `AUTH_PASSWORD` | Password for authentication | secure_password |
| `MINECRAFT_PORT` | Port your Minecraft server runs on | 25565 |
| `SERVER_ADDRESS` | Minecraft server address shown to users | your-server-address |
| `ACCESS_DURATION` | Time in hours that access is granted | 12 |

## Security Considerations

- The default configuration uses HTTP. For production, enable HTTPS by setting `DOMAIN` in your `.env` file.
- Credentials are stored in environment variables rather than in code.
- The iptables manager container runs with NET_ADMIN capability, allowing it to modify firewall rules.
- Only authenticated users can access your Minecraft server.

## Customization

### Custom Styling

To modify the appearance of the login page, edit `app/index.php` and update the CSS in the style section.

### Adjusting Access Duration

Change the `ACCESS_DURATION` environment variable to modify how long users can access the Minecraft server after authentication.

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

## License

This project is open source and available under the MIT License.
