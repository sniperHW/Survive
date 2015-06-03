<?php

ini_set('max_execution_time', 120);
$size = 256*256;
$destination = realpath('./photos');


	if (isset($_GET['file'])){
		$hash = md5($_GET['file'].time()).".jpg";
		$filename = $destination."/".$hash;

		//check that file name is valid
		$source = fopen("php://input", "rb");
		$dest = fopen($filename, "w");
		while ($part = fread($source, $size))
			fwrite($dest, $part);
		
		fclose($source);
		fclose($dest);

		echo "{ status: 'server', name:'$hash'}";

	} else {
		echo "{ status:'error' }";
	}

?>