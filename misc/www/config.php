<?php
	// DB Config

	$_HOST_ = "localhost";
	$_USER_ = "root";
	$_PASS_ = "";
	$_MYDB_ = "pug";

	// Clear String Config

	function ClearString($Data)
	{
		$Data = trim($Data);
		$Data = stripslashes($Data);
		$Data = htmlspecialchars($Data);

		return $Data;
	}

	// HLTV demos list config:
	// 'Sub-folder name' -> 'Server Title' -> 'Prefix of demos in sub-folder'

	$Servers = array
	(
		'hltv' => array('title' => "Pug MOD Server #1", 'prefix' => "pug"),
		'hltv2' => array('title' => "Pug MOD Server #2", 'prefix' => "pug"),
		'hltv3' => array('title' => "Pug MOD Server #3", 'prefix' => "pug")
	);
?>