<?php
declare(strict_types=1);
require __DIR__ . '/lib.php';

$slug = (string) ($_GET['trip'] ?? '');

$t    = null;
$path = null;
if (preg_match('/^[a-z0-9_]+$/i', $slug)) {
    $t = parse_trip_filename($slug . '.json');
    if ($t !== null) {
        $path = __DIR__ . '/' . $slug . '.json';
    }
}

if ($t === null || $path === null || !is_file($path)) {
    http_response_code(404);
    render_page(
        'Trip not found',
        "    <h1>Trip not found</h1>\n" .
        '    <a class="button" href="index.php">← All trips</a>' . "\n"
    );
    exit;
}

$data = json_decode((string) file_get_contents($path), true);

$body = '    <h1>' . htmlspecialchars(trip_title($t), ENT_QUOTES) . "</h1>\n";
foreach ((array) $data as $key => $value) {
    // A value can be:
    //   - a plain URL string (label derived from the key)
    //   - a plain string with no URL scheme, e.g. a bare address -> rendered as text
    //     (never turned into a link, to avoid a broken relative href)
    //   - {"label": "...", "url": "..."} for an explicit link
    //   - {"address": "..."} for a Google Maps link
    //   - {"text": "..."} for a plain, non-clickable note
    $url  = null;
    $text = null;
    if (is_string($value)) {
        $label = humanize((string) $key);
        if (is_url_like($value)) {
            $url = $value;
        } else {
            $text = $value;
        }
    } elseif (is_array($value) && isset($value['url']) && is_string($value['url'])) {
        $label = isset($value['label']) && is_string($value['label'])
            ? $value['label']
            : humanize((string) $key);
        $url = $value['url'];
    } elseif (is_array($value) && isset($value['address']) && is_string($value['address'])) {
        $label = isset($value['label']) && is_string($value['label'])
            ? $value['label']
            : $value['address'];
        $url = maps_url($value['address']);
    } elseif (is_array($value) && isset($value['text']) && is_string($value['text'])) {
        $label = isset($value['label']) && is_string($value['label'])
            ? $value['label']
            : humanize((string) $key);
        $text = $value['text'];
    } else {
        continue;
    }

    $label = htmlspecialchars($label, ENT_QUOTES);
    if ($url !== null) {
        $url = htmlspecialchars($url, ENT_QUOTES);
        $body .= '    <a class="button" href="' . $url . '" target="_blank" rel="noopener">' . $label . "</a>\n";
    } else {
        $text = htmlspecialchars((string) $text, ENT_QUOTES);
        $body .= '    <div class="button">' . $label . ' <span class="dates">' . $text . "</span></div>\n";
    }
}
$body .= '    <a href="index.php">← All trips</a>' . "\n";

render_page(trip_title($t), $body);
