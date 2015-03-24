<?php
	$_HOST_ = "localhost";
	$_USER_ = "root";
	$_PASS_ = "";
	$_MYDB_ = "pug";

	function ClearString($Data)
	{
		$Data = trim($Data);
		$Data = stripslashes($Data);
		$Data = htmlspecialchars($Data);
	
		return $Data;
	}
?>