<?php
	require('config.php');

	$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_) or die("<link rel='stylesheet' type='text/css' href='style.css'><h4>Rank not found.</h4>");
?>

<html>
	<head>
		<title>Pug TOP 10</title>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<table width="100%" border="0" cellpadding="1" cellspacing="1">
			<tr>
				<th>#</abbr></th>
				<th>Player</th>
				<th>F</th>
				<th>A</th>
				<th>D</th>
				<th>ADR</th>
				<th>HSP</th>
				<th>SKILL</th>
			</tr>
			<?php
				$iResult = mysqli_query($iConnection,"CALL PugGetTOP(10)");
				
				$i = 1;
				
				while($Row = mysqli_fetch_array($iResult))
				{
					echo (!($i % 2)) ? "<tr>" : "<tr id='c'>";
					
					switch($i)
					{
						case 1:
						{
							echo "<td style='text-align: center;' width='5%'><img src='images/1.png'></td>";

							break;
						}
						case 2:
						{
							echo "<td style='text-align: center;' width='5%'><img src='images/2.png'></td>";

							break;
						}
						case 3:
						{
							echo "<td style='text-align: center;' width='5%'><img src='images/3.png'></td>";
						
							break;
						}
						default:
						{
							echo "<td style='text-align: center;' width='5%'>" . $i . "</td>";

							break;
						}
					}
					
					echo "<td style='text-align: center;' width='30%'><a href='stats.php?Alias=" . $Row['steam'] . "'>" . $Row['name'] . "</td>";
					echo "<td style='text-align: center;' width='9%'>" . $Row['kills'] . "</td>";
					echo "<td style='text-align: center;' width='9%'>" . $Row['assists'] . "</td>";
					echo "<td style='text-align: center;' width='9%'>" . $Row['deaths'] . "</td>";
					echo "<td style='text-align: center;' width='9%'>" . $Row['adr'] . "</td>";

					printf("<td style='text-align: center;' width='11%%'>%3.2f%%</td>",$Row['hsp']);
					printf("<td style='text-align: center;' width='11%%'>%3.3f</td>",$Row['skl']);
					
					echo "</tr>";
					
					$i++;
				}

				mysqli_close($iConnection);
			?>
		</table>
	</body>
</html>