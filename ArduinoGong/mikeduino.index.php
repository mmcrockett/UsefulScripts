<?php
  if ('GET' === $_SERVER['REQUEST_METHOD']) {
    if ($_GET['returnedStatus']) {
      $log_file = 'history.log';

      $data = "" . $_GET['returnedStatus'] . ",";
      $data .= substr($_GET['previousHash'], 0, 20) . ",";
      $data .= substr($_GET['nextHash'], 0, 20) . ",";
      $data .= ('0' == $_GET['different'] ? 'false' : 'true') . ",";
      $data .= $_GET['signal'] . ",";
      $data .= time() . "\n";

      file_put_contents($log_file, $data, FILE_APPEND);
    }

    echo hash_file('sha256', '/home/washingrving/mmcrockett.com/WeInfuseGong/data.json');
  } else {
    echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  }
?>
