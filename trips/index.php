<?php
declare(strict_types=1);
require __DIR__ . '/lib.php';

$trips = all_trips();

$body = "    <h1>Trips</h1>\n";
if ($trips === []) {
    $body .= "    <p>No trips yet.</p>\n";
} else {
    foreach ($trips as $t) {
        $href     = 'trip.php?trip=' . rawurlencode($t['slug']);
        $location = htmlspecialchars($t['location'], ENT_QUOTES);
        $dates    = htmlspecialchars(format_range($t['start'], $t['end']), ENT_QUOTES);
        $label    = $location . ' <span class="dates">' . $dates . '</span>';
        $body .= '    <a class="button" href="' . $href . '">' . $label . "</a>\n";
    }
}

render_page('Trips', $body);
