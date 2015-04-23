<?php
	date_default_timezone_set('GMT');
	
	$FileDate = date("ymd", mktime(0,0,0,date("m"),date("d") - 7,date("Y")));
	
	foreach(glob("/var/www/html/demos/*$FileDate*.zip") as $File)
	{
		unlink($File);
	}
?>