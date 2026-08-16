<?php
header('Content-Type: text/html');

$apt_id = isset($_POST['apt_id']) ? preg_replace('/\D/', '', $_POST['apt_id']) : '';
$confirm_date = isset($_POST['confirm_date']) ? preg_replace('/\D/', '', $_POST['confirm_date']) : '';

if ($apt_id === '' || $confirm_date === '') {
    echo '<p>Not allowed.</p>';
} else {
    $cmd = 'ruby /home/washingrving/ball_button.rb cancel '
        . escapeshellarg($apt_id) . ' ' . escapeshellarg($confirm_date) . ' 2>&1';
    echo '<pre>' . htmlspecialchars(shell_exec($cmd)) . '</pre>';
}

echo '<p><a href="jpickle.html">Back to schedule</a></p>';
