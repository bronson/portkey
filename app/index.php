<?php
// Configuration
$username = getenv('AUTH_USERNAME') ?: "your_friend_username";
$password = getenv('AUTH_PASSWORD') ?: "secure_password";
$minecraft_port = getenv('MINECRAFT_PORT') ?: 25565;
$access_duration = getenv('ACCESS_DURATION') ?: 12; // hours

// Basic authentication
session_start();
$message = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if ($_POST['username'] === $username && $_POST['password'] === $password) {
        $_SESSION['authenticated'] = true;
        
        // Get user's IP
        $ip = $_SERVER['REMOTE_ADDR'];
        
        // Log the access request for the iptables_manager container
        $log_entry = json_encode([
            'action' => 'allow',
            'ip' => $ip,
            'port' => $minecraft_port,
            'duration' => $access_duration,
            'timestamp' => time()
        ]) . "\n";
        
        file_put_contents('/var/www/html/access_log', $log_entry, FILE_APPEND);
        
        $message = "Access granted! You can now connect to the Minecraft server for {$access_duration} hours.";
    } else {
        $message = "Invalid credentials!";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Minecraft Server Access</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; }
        .container { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        input[type="text"], input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; }
        input[type="submit"] { background: #4CAF50; color: white; padding: 10px 15px; border: none; cursor: pointer; }
        .message { margin: 10px 0; padding: 10px; background: #e7f3fe; border-left: 6px solid #2196F3; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Minecraft Server Access</h2>
        <?php if (!empty($message)): ?>
            <div class="message"><?php echo $message; ?></div>
        <?php endif; ?>
        
        <?php if (isset($_SESSION['authenticated']) && $_SESSION['authenticated']): ?>
            <p>You're authenticated! You can now connect to the Minecraft server.</p>
            <p>Server address: <?php echo getenv('SERVER_ADDRESS') ?: 'your-server-address'; ?></p>
            <p>Your access will expire in <?php echo $access_duration; ?> hours.</p>
        <?php else: ?>
            <form method="post">
                <div>
                    <label for="username">Username:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div>
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div>
                    <input type="submit" value="Login">
                </div>
            </form>
        <?php endif; ?>
    </div>
</body>
</html>