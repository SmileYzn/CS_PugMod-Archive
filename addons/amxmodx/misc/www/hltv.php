<?php
	require('config.php');
	
	function format_size($Size, $Round = 0)
	{
		$Sizes = array('B','kB','MB','GB','TB','PB','EB','ZB','YB');

		for($i = 0; $Size > 1024 && isset($Sizes[$i + 1]);$i++)
		{
			$Size /= 1024;
		}

		return round($Size, $Round) . " " . $Sizes[$i];
	}

	function browse($Path)
	{
		global $Servers;
		$Data = Array();
		
		$Prefix = $Servers[$Path]['prefix'];
		$szPrefix = strlen($Prefix) + 1;
		
		$Offsets = array
		(
			'year' => $szPrefix,
			'month' => $szPrefix + 2,
			'day' => $szPrefix + 4,
			'hour' => $szPrefix + 6,
			'minute' => $szPrefix + 8,
			'map' => $szPrefix + 11
		);
		
		if(is_dir($Path))
		{
			if($Dir = opendir($Path))
			{
				while(($File = readdir($Dir)) !== FALSE)
				{
					if(!is_dir($File) && $File[0] !== '.')
					{
						$NameEnd = strrpos($File,".dem");
						$NameEnd = $NameEnd === FALSE ? strpos($File,".gz") : $NameEnd;
						
						if($NameEnd === FALSE)
						{
							continue;
						}
						
						$TmpFileSize = @FileSize($Path == '.' ? $File : $Path . '/' . $File);
						
						$Tmp = Array();
						
						$Tmp['year']   = substr($File, $Offsets['year'],2);
						$Tmp['month']  = substr($File, $Offsets['month'],2);
						$Tmp['day']    = substr($File, $Offsets['day'],2);
						$Tmp['hour']   = substr($File, $Offsets['hour'],2);
						$Tmp['minute'] = substr($File, $Offsets['minute'],2);
						$Tmp['map']    = substr($File, $Offsets['map'],$NameEnd - $Offsets['map']);
						$Tmp['file']   = $File;
						$Tmp['size']   = format_size($TmpFileSize);
						$Tmp['path']   = $Path == '.' ? $File : $Path . '/' . $File;
						
						$Data[] = $Tmp;
					}
				}
				
				closedir($Dir);
			}
		}
		
		echo
		"
			<table width='100%' border='0' cellpadding='1' cellspacing='1'>
			<tr>
				<th>Date</th>
				<th>Time</th>
				<th>Map</th>
				<th>Size</th>
				<th>Download</th>
			</tr>
		";
		
		if(count($Data) > 0)
		{
			sort($Data);
			$Data = array_reverse($Data);
			$i = 1;
			
			foreach($Data as $Field)
			{
				echo (!($i % 2)) ? "<tr>" : "<tr id='c'>";
				echo "<td style='text-align: center;' width='11%'>" . $Field['day'] . "." . $Field['month'] . "." . $Field['year'] . "</td>";
				echo "<td style='text-align: center;' width='10%'>" . $Field['hour'] . ":" . $Field['minute'] . "</td>";
				echo "<td style='text-align: center;' width='15%'>" . $Field['map'] . "</td>";
				echo "<td style='text-align: center;' width='10%'>" . $Field['size'] . "</td>";
				echo "<td style='text-align: center;'><a href='" . $Field['path'] . "'>" . $Field['file'] . "</a></td>";
				echo "</tr>";
				
				$i = !$i;
			} 
		}
		else
		{
			echo "<tr><td colspan='5' align='center'>No demos available.</td></tr>";
		}
	}
?>

<html>
	<head>
		<title>Pug HLTV's</title>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<?php
			if(is_array($Servers))
			{
				$Count = count($Servers);
				
				if($Count == 1)
				{
					end($Servers);
					browse(key($Servers));
				}
				else if($Count == 0)
				{
					echo "No demos available!";
				}
				else if(isset($_GET['server']))
				{
					browse($_GET['server']);
				}
			}
		?>
		<?php if(!isset($_GET['server'])): ?>
		<form action="hltv.php" method="GET">
			<h3>Select an server:</h3>
			<select name="server">
				<?php
					foreach($Servers as $Key => $Value)
					{
						echo "<option value='$Key'>{$Value['title']}</option>";
					}
				?>
			</select>
			<button type="submit">Go</button>
		</form>
		<?php endif; ?>
	</body>
</html>
