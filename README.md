# Portkey

## Lock down your services

Use Docker, Caddy, and iptables to let your users to grant themselves access to protected ports on your server.

## Setup

Ensure you're using Docker, Docker Compose, and Linux (for iptables support).

### 1. Configuration

```bash
cp .env.example .env
cp passwd.example passwd
```

Now configure the settings in `.env` and add your users to the `passwd` file.

Make sure you set PORTS to a comma-separated list of ports you want to protect.

The passwd file is re-read every time the web app performs an
authentication so any modifications go live immediately.

### 2. Start er Up

```bash
docker-compose up -d
```

You can glance over the log messages to make sure everything looks OK.

```
docker-compose logs
```

### 3. Use the Web Portal

Open your browser and navigate to your server. If you specify a
good user/pw, your IP address will receive access to the protected ports.

Users with IP addresses that already have access will see a notification and can revoke their own access if needed.

### 4. Manage Portkey

Use portkeyctl to manage the access rules.

   - **List Authorized IPs**: View all IP addresses with access:
     ```bash
     sudo ./portkeyctl list
     ```

   - **Clear All Access**: Remove all access rules:
     ```bash
     sudo ./portkeyctl clear
     ```

   - **Remove Specific IP**: Remove access for a specific IP address:
     ```bash
     sudo ./portkeyctl remove 192.168.1.100
     ```

## Customization

### Custom Styling

To modify the appearance of the login page, edit `web/index.php` and update the CSS in the style section.

### Potential Issues

- **Application fails to start**: Ensure the `PORTS` environment variable is set in your `.env` file
- **Web page doesn't load**: Check if the configured web ports (default: 80/443) are accessible and not blocked by firewall. Check your webserver logs to see if the request hit the server: `docker-compose logs portkey-web`
- **Authentication works but access wasn't granted**: Verify filter logs to ensure rules are being applied to the correct ports.
- **Rules not being applied**: Check if the `access_log` and `authorized_ips` files exist in the root directory and have permissions 666. The filter service maintains the authorized_ips file which lists all IPs with access to protected ports.
- **Changes to passwd file not taking effect**: Ensure your passwd file is in the root directory and restart the container with `docker-compose restart php`
- **Clear all access and start over**: Run `sudo ./portkeyctl clear` to manually flush the firewall chain
- **Access remains after container is stopped**: This is by design - access rules are persistent across restarts

## License

This project is open source and available under the MIT License.
