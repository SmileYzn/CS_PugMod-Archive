<?php
	include 'config.php';

	if($_SERVER["REQUEST_METHOD"] == "GET")
	{
		$Alias = "";
		
		if(isset($_GET['Alias']))
		{
			$Alias = ClearString($_GET['Alias']);
		}

		$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_) or die(mysqli_error($iConnection));

		$Result = mysqli_query($iConnection,"CALL PugGetBans('$Alias')");
					
		if(!mysqli_num_rows($Result))
		{
			die("<link rel='stylesheet' type='text/css' href='style.css'> <h4>Nenhum banimento ativo.</h4>");
		}
	}
?>

<html>
	<head>
		<title>Ban List</title>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<table width="100%" border="0" cellpadding="1" cellspacing="1">
			<tr>
				<th>Auth ID</th>
				<th>Alias</th>
				<th>Expire</th>
				<th>Reason</th>
			</tr>

			<?php
				$i = 1;
				while($Row = mysqli_fetch_array($Result))
				{
					echo (!($i % 2)) ? "<tr>" : "<tr id='c'>";
					
					echo "<td style='text-align: center;' width='12%'>" . $Row['steam'] . "</td>";
					echo "<td style='text-align: center;' width='10%'>" . $Row['name'] . "</td>";
					echo "<td style='text-align: center;' width='11%'>" . $Row['unban'] . "</td>";
					echo "<td style='text-align: center;' width='18%'>" . $Row['reason'] . "</td>";
					
					echo "</tr>";
					
					$i++;
				}

				mysqli_close($iConnection);
			?>
		</table>
	</body>
</html>