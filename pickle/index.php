<?php
const HISTORY_DAYS = 7;
const TZ = 'America/Chicago';

function h($value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function local_time(?string $iso, string $format): string
{
    if (!$iso) {
        return '';
    }
    return (new DateTimeImmutable($iso))->setTimezone(new DateTimeZone(TZ))->format($format);
}

function pretty_body(?string $body): string
{
    if ($body === null || $body === '') {
        return '';
    }
    $decoded = json_decode($body, true);
    return is_array($decoded) ? json_encode($decoded, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) : $body;
}

function open_db(): ?PDO
{
    $path = getenv('PICKLE_DB') ?: __DIR__ . '/pickle.sqlite3';
    if (!is_readable($path)) {
        return null;
    }
    $options = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5];
    if (defined('PDO::SQLITE_ATTR_OPEN_FLAGS')) {
        $options[PDO::SQLITE_ATTR_OPEN_FLAGS] = PDO::SQLITE_OPEN_READONLY;
    }
    return new PDO('sqlite:' . $path, null, null, $options);
}

$now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
$db = open_db();
$bookings = [];
$runs = [];
$requestsByRun = [];

if ($db) {
    $bookings = $db->query('SELECT * FROM bookings ORDER BY start_time')->fetchAll(PDO::FETCH_ASSOC);

    $cutoff = $now->modify('-' . HISTORY_DAYS . ' days')->format('Y-m-d\TH:i:s\Z');
    $stmt = $db->prepare('SELECT * FROM runs WHERE started_at >= ? ORDER BY started_at DESC, id DESC');
    $stmt->execute([$cutoff]);
    $runs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $db->prepare(
        'SELECT r.* FROM requests r JOIN runs ON runs.id = r.run_id WHERE runs.started_at >= ? ORDER BY r.id'
    );
    $stmt->execute([$cutoff]);
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $request) {
        $requestsByRun[$request['run_id']][] = $request;
    }
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
<link rel="icon" type="image/x-icon" href="/images/paddle.ico">
<link rel="icon" type="image/svg+xml" href="/images/paddle.svg">
<link rel="apple-touch-icon" href="/images/paddle-180.png">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>
<title>🏓 JCC Pickleball</title>
</head>
<body class="p-3">
<?php if (!$db): ?>
<p class="text-muted">No data yet - the cron job hasn't written the database.</p>
<?php else: ?>
<table class="table table-striped">
  <thead>
    <tr>
      <th scope="col">Date</th>
      <th scope="col">Time</th>
      <th scope="col">Court</th>
      <th scope="col">Checked In?</th>
      <th scope="col">Cancel</th>
    </tr>
  </thead>
  <tbody>
  <?php foreach ($bookings as $b): ?>
    <tr>
      <td><?= h(local_time($b['start_time'], 'l - M d')) ?></td>
      <td><?= h(local_time($b['start_time'], 'g:ia') . ' - ' . local_time($b['end_time'], 'g:ia')) ?></td>
      <td><?= h($b['court']) ?></td>
      <td><?= $b['checked_in'] ? '✅' : '➖' ?></td>
      <td>
        <?php if (new DateTimeImmutable($b['start_time']) > $now): ?>
        <span role="button" data-apt-id="<?= h($b['id']) ?>" onclick="openCancelModal(this)">❌</span>
        <?php endif; ?>
      </td>
    </tr>
  <?php endforeach; ?>
  </tbody>
</table>
<figcaption class="blockquote-footer pt-3">
  <?= $bookings ? 'Refreshed ' . h(local_time($bookings[0]['refreshed_at'], 'l F d Y g:ia')) : 'No upcoming bookings.' ?>
</figcaption>

<h5 class="pt-4">History (last <?= HISTORY_DAYS ?> days)</h5>
<?php if (!$runs): ?>
<p class="text-muted small">Nothing recorded.</p>
<?php endif; ?>
<?php foreach ($runs as $run): $requests = $requestsByRun[$run['id']] ?? []; $detail = $run['detail'] ?? null; ?>
<details class="mb-2">
  <summary class="h6"<?= $detail ? ' title="' . h($detail) . '"' : '' ?>>
    <?= h(local_time($run['started_at'], 'D g:i:sa')) ?>
    <span class="badge <?= $run['status'] === 'ok' ? 'text-bg-success' : ($run['status'] === 'error' ? 'text-bg-danger' : 'text-bg-secondary') ?>"><?= h($run['status']) ?></span>
    <?= h($run['summary'] ?: $run['command']) ?>
    <span class="text-muted small"><?= h($run['command']) ?>, <?= count($requests) ?> request<?= count($requests) === 1 ? '' : 's' ?></span>
  </summary>
  <?php if ($detail): ?><pre class="ms-3 small text-muted"><?= h($detail) ?></pre><?php endif; ?>
  <?php foreach ($requests as $r): ?>
  <div class="ms-3 mb-3 small">
    <div>
      <?= h(local_time($r['created_at'], 'g:i:sa')) ?>
      <strong><?= h($r['method']) ?></strong> <?= h($r['url'] === '' ? '/' : $r['url']) ?>
      <span class="badge <?= ($r['status'] !== null && (int)$r['status'] < 400) ? 'text-bg-success' : 'text-bg-danger' ?>"><?= h($r['status'] ?? 'no response') ?></span>
      <span class="text-muted"><?= h($r['context']) ?><?= (int)$r['attempt'] > 1 ? ', attempt ' . (int)$r['attempt'] : '' ?><?= $r['duration_ms'] !== null ? ', ' . (int)$r['duration_ms'] . 'ms' : '' ?></span>
    </div>
    <?php if ($r['error']): ?><pre class="text-danger mb-1"><?= h($r['error']) ?></pre><?php endif; ?>
    <?php if ($r['request_body']): ?>
    <div class="text-muted">Request</div>
    <pre class="border rounded p-2 mb-1" style="max-height: 14rem; overflow: auto;"><?= h(pretty_body($r['request_body'])) ?></pre>
    <?php endif; ?>
    <?php if ($r['response_body']): ?>
    <div class="text-muted">Response</div>
    <pre class="border rounded p-2 mb-1" style="max-height: 14rem; overflow: auto;"><?= h(pretty_body($r['response_body'])) ?></pre>
    <?php endif; ?>
  </div>
  <?php endforeach; ?>
</details>
<?php endforeach; ?>
<?php endif; ?>

<div class="modal fade" id="cancelModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post" action="cancel.php">
        <div class="modal-header">
          <h5 class="modal-title">Cancel booking</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" name="apt_id" id="cancelAptId">
          <input type="text" name="confirm_date" class="form-control" placeholder="secret 8 digits" required>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-danger">Cancel booking</button>
        </div>
      </form>
    </div>
  </div>
</div>
<script>
  function openCancelModal(btn) {
    document.getElementById('cancelAptId').value = btn.getAttribute('data-apt-id');
    new bootstrap.Modal(document.getElementById('cancelModal')).show();
  }
</script>
</body>
</html>
