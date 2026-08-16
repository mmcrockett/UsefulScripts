<?php
header('Content-Type: text/html');

$apt_id = isset($_POST['apt_id']) ? preg_replace('/\D/', '', $_POST['apt_id']) : '';
$confirm_date = isset($_POST['confirm_date']) ? trim($_POST['confirm_date']) : '';
$expected_date = isset($_POST['expected_date']) ? trim($_POST['expected_date']) : '';

if ($apt_id === '' || $confirm_date === '' || $confirm_date !== $expected_date) {
    echo '<p>Not allowed.</p>';
} else {
    $cmd = 'ruby /home/washingrving/ball_button.rb cancel ' . escapeshellarg($apt_id) . ' 2>&1';
    echo '<pre>' . htmlspecialchars(shell_exec($cmd)) . '</pre>';
}

echo '<p><a href="jpickle.html">Back to schedule</a></p>';
