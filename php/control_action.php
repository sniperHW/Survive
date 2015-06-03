<?php
function SendMsg2Daemon($ip,$port,$msg,$timeout = 15){
  if(!$ip || !$port || !$msg){
    return array(false);
  }
  $errno;
  $errstr;
  $fp = @fsockopen($ip,$port,$errno,$errstr,$timeout);
  if(!$fp){
    return array(false);
  }
  stream_set_blocking($fp, true);
  stream_set_timeout($fp, $timeout);
  @fwrite($fp, $msg . "\n");   
  $status = stream_get_meta_data($fp);
  $ret;
  if(!$status['timed_out']) {
      $datas = 'data:';
      while(!feof($fp)){
        $data = fread($fp, 4096);
        if($data){
          $datas = $datas . $data;
        }
      }
      return array(true,$datas);
  }else{
    $ret = array(false);
  }
  @fclose($fp);
  return ret;  
}

$result = SendMsg2Daemon('127.0.0.1','8800',$_POST['op']);
if($result[0]){
  echo $result[1]; 
}else{
  echo 'SendMsg2Daemon error!';
}

//echo $_POST['op'];
?>