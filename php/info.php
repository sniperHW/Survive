<?php
header("cache-control:no-cache,must-revalidate");
header("Content-Type:text/html;charset=utf8");

function split_line($input,$separator){
	$ret = array();
	$line = strtok($input,$separator);
	while($line != ""){
		array_push($ret,$line);
		$line = strtok($separator);
	}
	return $ret;
}
$redis = new Redis();
$redis->connect('127.0.0.1', 6379);
$deployment = $redis->get('deployment');
$machine_status = $redis->hGetAll('MachineStatus');
$outputstr = "{\"deployment\":$deployment,\"machine_status\":[";
$first = true;
while(list($ip,$info) = each($machine_status)){
	if($first){
		$first = false;
	}else{
		$outputstr = $outputstr + ",";
	}
	$outputstr = $outputstr . "{\"ip\":\"$ip\",\"status\":" . base64_decode($info) . "}";
}
$outputstr = $outputstr . "]}";
echo $outputstr;
?>

