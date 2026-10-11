<?php
header('Content-Type: text/html');

$apt_id = isset($_POST['apt_id']) ? preg_replace('/\D/', '', $_POST['apt_id']) : '';
$confirm_date = isset($_POST['confirm_date']) ? preg_replace('/\D/', '', $_POST['confirm_date']) : '';

if ($apt_id === '' || $confirm_date === '') {
    echo '<p>Not allowed.</p>';
} else {
    $cmd = escapeshellarg(__DIR__ . '/ball_button.sh') . ' cancel '
        . escapeshellarg($apt_id) . ' ' . escapeshellarg($confirm_date) . ' 2>&1';
    $output = shell_exec($cmd);

    $output = (string)$output;
    $cancelled = strpos($output, 'cancel response: ') !== false
        && strpos($output, 'cancel response: not allowed') === false;

    if ($cancelled) {
        header('Location: index.php');
        exit;
    }
    echo '<pre>' . htmlspecialchars($output) . '</pre>';
}

echo '<p><a href="index.php">Back to schedule</a></p>';
