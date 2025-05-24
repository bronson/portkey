<?php
// Configuration
$ports = getenv('PORTS') ?: '25565';
$passwd_file = '/var/www/html/passwd';
$message = "";
$authenticated = false;
$username = "";

// Process login
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $input_username = trim($_POST['username']);
    $input_password = trim($_POST['password']);

    // Check credentials against the password file
    if (file_exists($passwd_file)) {
        $lines = file($passwd_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            list($username, $password) = explode(':', $line, 2);
            if (trim($username) === $input_username && trim($password) === $input_password) {
                $authenticated = true;
                $username = $input_username;
                break;
            }
        }
    }

    if ($authenticated) {
        // Get user's IP
        $ip = $_SERVER['REMOTE_ADDR'];
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ip = $_SERVER['HTTP_X_FORWARDED_FOR']; // Use forwarded IP if behind proxy
        }

        // Log the access request for the iptables_manager container
        $log_entry = json_encode([
            'action' => 'allow',
            'ip' => $ip,
            'username' => $username
        ]) . "\n";

        file_put_contents('/var/www/html/access_log', $log_entry, FILE_APPEND);

        $message = "Access granted! You can now connect to the server.";
    } else {
        $message = "Invalid credentials!";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Server Access Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; }
        .container { background: #f5f5f5; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        input[type="text"], input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        input[type="submit"] { background: #4CAF50; color: white; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; }
        input[type="submit"]:hover { background: #45a049; }
        .message { margin: 10px 0; padding: 10px; background: #e7f3fe; border-left: 6px solid #2196F3; }
        .error { background: #ffebee; border-left: 6px solid #f44336; }
        strong { color: #2196F3; }
        em { color: #666; font-style: italic; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Server Access Portal</h2>
        <?php if (!empty($message)): ?>
            <div class="message <?php echo (strpos($message, 'Invalid') !== false) ? 'error' : ''; ?>"><?php echo htmlspecialchars($message); ?></div>
        <?php endif; ?>

        <?php if ($authenticated): ?>
            <p>You're authenticated as <strong><?php echo htmlspecialchars($username); ?></strong>!</p>
            <p>You can now connect to all protected services.</p>
            <p>Server address: <?php echo getenv('SERVER_ADDRESS') ?: 'your-server-address'; ?></p>
            <p>Your access will remain valid permanently until manually revoked by an administrator.</p>
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
