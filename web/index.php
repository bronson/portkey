<?php

$ports = getenv('PORTS');
if (!$ports) {
    die("Error: PORTS environment variable is not set.");
}

$passwd_file = '/var/www/html/passwd';
$message = "";
$authenticated = false;
$username = "";
$already_authorized = false;

// Get user's IP
$ip = $_SERVER['REMOTE_ADDR'];
if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR']; // Use forwarded IP if behind proxy
}

// Check if the IP is already authorized by reading the authorized_ips file
if (file_exists('/var/www/html/authorized_ips')) {
    $authorized_ips = file('/var/www/html/authorized_ips', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($authorized_ips as $line) {
        // Skip comment lines
        if (substr($line, 0, 1) === '#') {
            continue;
        }
        if (trim($line) === $ip) {
            $already_authorized = true;
            break;
        }
    }
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $input_username = trim($_POST['username']);
    $input_password = trim($_POST['password']);
    if (empty($input_username) || empty($input_password)) {
        $message = "Username and password cannot be blank!";
    } elseif (file_exists($passwd_file)) {
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

    if ($already_authorized && ($_POST['action']) && $_POST['action'] === 'logout') {
        // Write a deny entry to the access_log
        $timestamp = date('Y-m-d H:i:s');
        $log_entry = "$timestamp|deny|$ip|$username\n";
        file_put_contents('/var/www/html/access_log', $log_entry, FILE_APPEND);
        $message = "Access removal request has been submitted. Your access should be revoked shortly.";
        $already_authorized = false; // Immediately update UI to show access is being revoked
    } elseif ($authenticated) {
        $timestamp = date('Y-m-d H:i:s');
        $log_entry = "$timestamp|allow|$ip|$username\n";
        file_put_contents('/var/www/html/access_log', $log_entry, FILE_APPEND);
        $message = "Access granted! You can now connect to protected services.";
        $already_authorized = true;
    } else {
        $message = "Invalid credentials!";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Portkey Access Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; }
        .container { background: #f5f5f5; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        input[type="text"], input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        input[type="submit"] { background: #4CAF50; color: white; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; }
        input[type="submit"]:hover { background: #45a049; }
        .message { margin: 10px 0; padding: 10px; background: #e7f3fe; border-left: 6px solid #2196F3; }
        .error { background: #ffebee; border-left: 6px solid #f44336; }
        .info { background: #e8f5e9; border-left: 6px solid #4CAF50; }
        .warning { background: #fff8e1; border-left: 6px solid #FFC107; }
        strong { color: #2196F3; }
        em { color: #666; font-style: italic; }
        .btn-danger { background: #f44336; color: white; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; }
        .btn-danger:hover { background: #d32f2f; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Portkey Access Portal</h2>
        <?php if ($already_authorized): ?>
            <div class="message info">Your IP address (<?php echo htmlspecialchars($ip); ?>) is already authorized to access protected services!</div>
        <?php endif; ?>

        <?php if (!empty($message)): ?>
            <div class="message <?php echo (strpos($message, 'Invalid') !== false) ? 'error' : ((strpos($message, 'removal') !== false) ? 'warning' : ''); ?>"><?php echo htmlspecialchars($message); ?></div>
        <?php endif; ?>

        <?php if ($authenticated || $already_authorized): ?>
            <p>You're authenticated as <strong><?php echo htmlspecialchars($username); ?></strong>!</p>
            <p>You can now connect to all protected services.</p>
            <p>Your access will remain valid permanently until manually revoked by an administrator.</p>

            <form method="post">
                <input type="hidden" name="action" value="logout">
                <div>
                    <input type="submit" class="btn-danger" value="Revoke My Access">
                </div>
            </form>
        <?php else: ?>
            <form method="post">
                <div>
                    <label for="username">Username:</label>
                    <input type="text" id="username" name="username" minlength="1" required>
                </div>
                <div>
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" minlength="1" required>
                </div>
                <div>
                    <input type="submit" value="Login">
                </div>
            </form>
        <?php endif; ?>
    </div>
</body>
</html>
