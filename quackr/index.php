<?php
const TIME_FIELDS = ['date', 'receivedAt', 'received_at', 'time', 'timestamp', 'created_at'];

function h($value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function load_config(): array
{
    $path = getenv('SMS_VIEWER_CONFIG') ?: __DIR__ . '/index.config.json';
    $config = is_readable($path) ? json_decode(file_get_contents($path), true) : null;
    foreach (['phone_number', 'quackr_api_key'] as $key) {
        if (!is_array($config) || empty($config[$key])) {
            http_response_code(500);
            exit("Config missing or invalid: $key");
        }
    }
    return $config;
}

function http_get_json(string $url, array $headers = []): ?array
{
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    $body = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($body === false || $status >= 400) {
        return null;
    }
    $decoded = json_decode($body, true);
    return is_array($decoded) ? $decoded : null;
}

function page_start(string $title): void
{
    echo '<!doctype html><html lang="en"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
        '<title>', h($title), '</title><style>',
        ':root{color-scheme:light dark;--bg:#f2f2f7;--card:#fff;--fg:#111;--muted:#6b6b76;--accent:#0a64d6}',
        '@media(prefers-color-scheme:dark){:root{--bg:#000;--card:#1c1c1e;--fg:#f2f2f7;--muted:#98989f;--accent:#4c9dff}}',
        '*{box-sizing:border-box}',
        'body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.4 -apple-system,system-ui,sans-serif}',
        'header{position:sticky;top:0;display:flex;align-items:center;justify-content:space-between;gap:12px;',
        'padding:12px 16px;background:var(--card);border-bottom:1px solid rgba(128,128,128,.25)}',
        'header h1{margin:0;font-size:18px}',
        'nav{font-size:15px}',
        'a,button{color:var(--accent)}',
        'main{padding:12px;max-width:640px;margin:0 auto}',
        '.card{background:var(--card);border-radius:12px;padding:12px 14px;margin-bottom:10px}',
        '.meta{display:flex;justify-content:space-between;gap:8px;font-size:13px;color:var(--muted);margin-bottom:4px}',
        '.body{overflow-wrap:anywhere;white-space:pre-wrap}',
        'button{font:inherit;border:0;background:none;padding:0}',
        '.code{display:block;width:100%;margin-top:10px;padding:12px;border-radius:10px;background:var(--accent);',
        'color:#fff;font-size:26px;font-weight:600;letter-spacing:2px;text-align:center}',
        '</style></head><body>';
}

function page_end(): void
{
    echo '</body></html>';
}

function format_phone(string $number): string
{
    if (preg_match('/^1?(\d{3})(\d{3})(\d{4})$/', $number, $m)) {
        return "($m[1]) $m[2]-$m[3]";
    }
    return $number;
}

function extract_code(string $text): ?string
{
    if (preg_match('/\b\d{3}[- ]\d{3}\b|\b\d{4,8}\b/', $text, $m)) {
        return $m[0];
    }
    return null;
}

function message_time(array $message): string
{
    foreach (TIME_FIELDS as $field) {
        if (!empty($message[$field])) {
            return (string)$message[$field];
        }
    }
    return '';
}

function render_messages(array $config): void
{
    $response = http_get_json(
        'https://api.quackr.io/receive-sms?phoneNumber=' . urlencode($config['phone_number']),
        ['x-api-key: ' . $config['quackr_api_key']]
    );
    $messages = $response['data']['messages'] ?? null;
    $phone = format_phone($config['phone_number']);

    page_start($phone);
    echo '<header><h1><button type="button" data-copy="', h($config['phone_number']), '">', h($phone), '</button></h1>',
        '<nav><a href="?">Refresh</a></nav></header><main>';

    if (!is_array($messages)) {
        echo '<div class="card">Could not load messages.</div>';
    } elseif ($messages === []) {
        echo '<div class="card">No messages.</div>';
    }
    foreach (is_array($messages) ? $messages : [] as $message) {
        $text = (string)($message['message'] ?? '');
        $code = extract_code($text);
        echo '<div class="card"><div class="meta"><span>', h($message['sender'] ?? ''), '</span><span>',
            h(message_time($message)), '</span></div><div class="body">', h($text), '</div>';
        if ($code !== null) {
            echo '<button type="button" class="code" data-copy="', h(preg_replace('/\D/', '', $code)), '">', h($code), '</button>';
        }
        echo '</div>';
    }

    echo '</main><script>',
        'document.addEventListener("click",function(e){var b=e.target.closest("[data-copy]");if(!b)return;',
        'navigator.clipboard.writeText(b.dataset.copy);var t=b.textContent;b.textContent="Copied";',
        'setTimeout(function(){b.textContent=t},900)})',
        '</script>';
    page_end();
}

render_messages(load_config());
