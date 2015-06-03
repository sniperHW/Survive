<?php

ini_set('max_execution_time', 120);
$size = 256*256;
$destination = realpath('./files');

	if (isset($_FILES['upload'])){
		$file = $_FILES['upload'];
		
		$filename = $destination."/".preg_replace("|[\\\/]|", "", $file["name"]);
		$sname = md5($file["name"]);
		//check that file name is valid
		if ($filename != "" && !file_exists($filename)){
			move_uploaded_file($file["tmp_name"], $filename);
			echo "{ status: 'server', sname:'$sname'}";
		} else {
			echo "{ status:'error' }";
		}
	}
	

?>