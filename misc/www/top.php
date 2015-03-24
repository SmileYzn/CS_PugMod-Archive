<html>
	<head>
		<title>Pug TOP 10</title>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<table width="100%" border="0" cellpadding="1" cellspacing="1">
			<tr>
				<th>#</th>
				<th>Player</th>
				<th>F</th>
				<th>A</th>
				<th>D</th>
				<th>HSP</th>
				<th>SKILL</th>
			</tr>

			<?php
				include 'config.php';

				$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_);
	
				if(mysqli_errno($iConnection))
				{
					return;
				}
			
				$iResult = mysqli_query($iConnection,"CALL PugGetTOP(10)");
				
				$i = 1;
				
				while($Row = mysqli_fetch_array($iResult))
				{
					echo (!($i % 2)) ? "<tr>" : "<tr id='c'>";
					
					switch($i)
					{
						case 1:
						{
							echo "<td style='text-align: center;'><img src='1.png'></td>";

							break;
						}
						case 2:
						{
							echo "<td style='text-align: center;'><img src='2.png'></td>";

							break;
						}
						case 3:
						{
							echo "<td style='text-align: center;'><img src='3.png'></td>";
						
							break;
						}
						default:
						{
							echo "<td style='text-align: center;'>" . $i . "</td>";

							break;
						}
					}
					
					echo "<td>" . $Row['name'] . "</td>";
					echo "<td style='text-align: center;'>" . $Row['kills'] . "</td>";
					echo "<td style='text-align: center;'>" . $Row['assists'] . "</td>";
					echo "<td style='text-align: center;'>" . $Row['deaths'] . "</td>";

					printf("<td style='text-align: center;'>%3.2f%%</td>",$Row['hsp']);
					
					if($Row['skl'] < 50.0)
					{
						printf("<td>%3.0f%% <img id='r' width='%3.0f%%'></td>",$Row['skl'],$Row['skl']);
					}
					else
					{
						printf("<td>%3.0f%% <img id='b' width='%3.0f%%'></td>",$Row['skl'],$Row['skl']);
					}
					
					echo "</tr>";
					
					$i++;
				}

				mysqli_close($iConnection);
			?>
		</table>
	</body>
</html>