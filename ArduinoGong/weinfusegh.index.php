<?php
$data_file = 'data.json';

if ('POST' === $_SERVER['REQUEST_METHOD']) {
  $request_data = json_decode( file_get_contents( 'php://input' ), true );

  $status = $request_data['action'];

  if ('closed' == $status && true == $request_data['pull_request']['merged']) {
    $data = json_decode( file_get_contents($data_file), true );
    $file = fopen($data_file, 'w') or die("Unable to open file!");

    $n = $request_data['number'];
    $name = $request_data['repository']['name'];

    if (false == array_key_exists($name, $data)) {
      $data[$name] = [];
    }

    if (false == in_array($n, $data[$name], true)) {
      array_push($data[$name], $n);
    }

    fwrite($file, json_encode($data));

    fclose($file);
  }
} else if ('GET' === $_SERVER['REQUEST_METHOD']) {
  echo `curl www.mikeduino.com`;
}
?>
