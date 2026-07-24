<?php
declare(strict_types=1);

/**
 * Shared helpers for the JSON-driven trip pages.
 *
 * Each trip is one JSON file in this directory named
 *   <location>_<startYYYYMMDD>_<endYYYYMMDD>.json
 * whose contents are a flat object of  label_key => URL.
 */

/** Parse a trip JSON filename, or return null if it doesn't match. */
function parse_trip_filename(string $filename): ?array
{
    if (!preg_match('/^(.+)_(\d{8})_(\d{8})\.json$/', $filename, $m)) {
        return null;
    }
    $start = DateTimeImmutable::createFromFormat('Ymd', $m[2]);
    $end   = DateTimeImmutable::createFromFormat('Ymd', $m[3]);
    if (!$start || !$end) {
        return null;
    }
    return [
        'slug'     => $m[1] . '_' . $m[2] . '_' . $m[3],
        'location' => humanize($m[1]),
        'start'    => $start,
        'end'      => $end,
    ];
}

/** "pointe_west_info" -> "Pointe West Info" */
function humanize(string $s): string
{
    return ucwords(str_replace('_', ' ', $s));
}

/**
 * Human date range:
 *   same month  -> "Jun 21–26, 2026"
 *   same year   -> "Jun 28 – Jul 3, 2026"
 *   cross-year  -> "Dec 30, 2026 – Jan 2, 2027"
 */
function format_range(DateTimeImmutable $a, DateTimeImmutable $b): string
{
    if ($a->format('Y') !== $b->format('Y')) {
        return $a->format('M j, Y') . ' - ' . $b->format('M j, Y');
    }
    if ($a->format('m') !== $b->format('m')) {
        return $a->format('M j') . ' - ' . $b->format('M j, Y');
    }
    return $a->format('M j') . '-' . $b->format('j, Y');
}

/** True when $v starts with a URL scheme (http:, tel:, geo:, mailto:, ...). */
function is_url_like(string $v): bool
{
    return (bool) preg_match('~^[a-z][a-z0-9+.\-]*:~i', $v);
}

/** Build a Google Maps search link for a free-text address. */
function maps_url(string $address): string
{
    return 'https://maps.google.com/?q=' . rawurlencode($address);
}

/** "Galveston — Jun 21–26, 2026" */
function trip_title(array $t): string
{
    return $t['location'] . ' - ' . format_range($t['start'], $t['end']);
}

/**
 * Current/upcoming trips in this folder, soonest first. Trips that ended
 * yesterday or earlier (end < today) are filtered out.
 */
function all_trips(): array
{
    $today = new DateTimeImmutable('today');
    $trips = [];
    foreach (glob(__DIR__ . '/*.json') ?: [] as $path) {
        $t = parse_trip_filename(basename($path));
        if ($t !== null && $t['end'] >= $today) {
            $t['path'] = $path;
            $trips[] = $t;
        }
    }
    usort($trips, fn($x, $y) => $x['start'] <=> $y['start']);   // soonest first
    return $trips;
}

/** Emit the shared HTML shell (matches the existing bball.html styling). */
function render_page(string $title, string $body): void
{
    if (!headers_sent()) {
        header('Cache-Control: no-cache, no-store, must-revalidate');
        header('Pragma: no-cache');
        header('Expires: 0');
    }
    $t = htmlspecialchars($title, ENT_QUOTES);
    echo <<<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$t</title>
  <style>
    :root { color-scheme: light dark; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      font-size: clamp(18px, 4vw, 22px);
      line-height: 1.5;
      padding: 24px 16px;
    }
    .wrap { max-width: 680px; margin: 0 auto; }
    h1 { font-size: 1.4em; }
    a, a:link, a:visited, a:hover, a:active {
     display: block; margin: 12px 0; text-decoration: none; color: inherit;
    }
    .button { border: 1px solid #888; border-radius: 10px; padding: 14px 16px; }
    .dates { font-size: 0.75em; font-weight: 400; opacity: 0.6; }
  </style>
</head>
<body>
  <div class="wrap">
$body
  </div>
</body>
</html>

HTML;
}
