<html>
	<head>
		<title>Last Matches</title>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<table width="100%" border="0" cellpadding="1" cellspacing="1">
			<tr>
				<th>#</th>
				<th>Server</th>
				<th>Date</th>
				<th>Team A</th>
				<th>Team B</th>
				<th>Rounds</th>
				<th>Map</th>
			</tr>

			<?php
				include 'config.php';

				$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_);
	
				if(mysqli_errno($iConnection))
				{
					die("<link rel='stylesheet' type='text/css' href='style.css'> <h4>System out of service.</h4>");
				}
			
				$iResult = mysqli_query($iConnection,"SELECT id, server, date, score1, score2, rounds, map FROM pug_match ORDER BY id");
				
				$i = 1;
				
				while($Row = mysqli_fetch_array($iResult))
				{
					echo (!($i % 2)) ? "<tr>" : "<tr id='c'>";
					echo "<td style='text-align: center;' width='5%'>" . $Row['id'] . "</td>";
					
					echo "<td style='text-align: center;' width='25%'>" . $Row['server'] . "</td>";
					echo "<td style='text-align: center;' width='23%'>" . $Row['date'] . "</td>";
					echo "<td style='text-align: center;' width='10%'>" . $Row['score1'] . "</td>";
					echo "<td style='text-align: center;' width='10%'>" . $Row['score2'] . "</td>";
					echo "<td style='text-align: center;' width='5%'>" . $Row['rounds'] . "</td>";
					echo "<td style='text-align: center;' width='15%'>" . $Row['map'] . "</td>";
					
					echo "</tr>";
					
					$i++;
				}

				mysqli_close($iConnection);
			?>
		</table>
	</body>
</html>