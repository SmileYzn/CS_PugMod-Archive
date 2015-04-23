			<?php
				require('config.php');

				if($_SERVER["REQUEST_METHOD"] == "GET")
				{
					$Alias = "";
		
					if(isset($_GET['Alias']))
					{
						$Alias = ClearString($_GET['Alias']);
					}
					
					$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_) or die(mysqli_connect_errno($iConnection));

					$Result = mysqli_query($iConnection,"CALL PugGetStats('$Alias')");
					$Stats = mysqli_fetch_array($Result);

					mysqli_close($iConnection);
					
					if(!mysqli_num_rows($Result))
					{
						die("<link rel='stylesheet' type='text/css' href='style.css'> <h3>Player nao encontrado.</h3>");
					}
				}
			?>

<html>
	<head>
		<title>Pug Stats</title>
		<link rel="icon" href="favicon.ico" type="image/x-icon"/>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
	<?php
		$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_) or die(mysqli_connect_errno($iConnection));
		$Result = mysqli_query($iConnection,"CALL PugGetRank('" . $Stats['steam'] . "')");
		$Rank = mysqli_fetch_array($Result);

		mysqli_close($iConnection);
	?>
		<table width="100%" border="0" cellpadding="1" cellspacing="1" align="center">
			<th colspan="2">#<?php echo $Rank['Rank']; ?> - <?php echo $Stats['name']; ?></th>
			<th colspan="2">Round Stats</th>
			<th colspan="2">Streak</th>
			<tr id="c">
				<td width="13%">Kills</td>
				<td width="15%"><?php echo $Stats['kills']; ?> (<?php echo $Stats['headshots']; ?> HS)</td>
				
				<td width="11%">Played</td>
				<td width="13%"><?php echo $Stats['rounds']; ?></td>
				
				<td width="10%">1v2</td>
				<td width="5%"><?php echo $Stats['v2']; ?></td>
			</tr>
			<tr>
				<td>Assists</td>
				<td><?php echo $Stats['assists']; ?></td>
				
				<td>Wins - Loses</td>
				<td>
					<?php echo $Stats['rounds_win'] . " - " . $Stats['rounds_lose']; ?>
					(<?php
						printf("%3.1f%%",WinPCT($Stats['rounds_win'],$Stats['rounds']));
						
						function WinPCT($iWin,$iPlayed)
						{
							if(!$iWin)
							{
								return 0.0;
							}
							
							return (100.0 * round($iWin) / round($iPlayed));
						}
					?>)
				</td>
				
				<td>v3</td>
				<td><?php echo $Stats['v3']; ?></td>
			</tr>
			<tr id="c">
				<td>Deaths</td>
				<td><?php echo $Stats['deaths']; ?></td>
				
				<td>B. Plant</td>
				<td><?php echo $Stats['plants']; ?></td>
				
				<td>v4</td>
				<td><?php echo $Stats['v4']; ?></td>
			</tr>
			<tr>
				<td>Shots</td>
				<td><?php echo $Stats['shots']; ?> (<?php echo $Stats['hits']; ?> hits)</td>
				
				<td>B. Defused</td>
				<td><?php echo $Stats['defused']; ?></td>
				
				<td>v5</td>
				<td><?php echo $Stats['v5']; ?></td>
			</tr>
			<tr id="c">
				<td>Damage</td>
				<td><?php echo $Stats['damage']; ?> HP</td>
				
				<td>RWS</td>
				<td><?php printf("%3.2f",$Stats['rws']); ?></td>
				
				<td>2K</td>
				<td><?php echo $Stats['2k']; ?></td>
			</tr>
			<tr>
				<td>Efficiency</td>
				<td><?php printf("%3.2f",$Stats['eff']); ?></td>
				
				<td>ADR</td>
				<td><?php printf("%3.1f",$Stats['adr']); ?></td>
				
				<td>3K</td>
				<td><?php echo $Stats['3k']; ?></td>
			</tr>
			<tr id="c">
				<td>Acuracy</td>
				<td><?php printf("%3.2f",$Stats['acc']); ?></td>
				
				<td>FPR</td>
				<td><?php printf("%3.1f",$Stats['fpr']); ?></td>
				
				<td>4K</td>
				<td><?php echo $Stats['4k']; ?></td>
			</tr>
			<tr>
				<td>Skill Level</td>
				<td>
					<?php
						printf("%3.3f",$Stats['skl']);
					?>
				</td>
				
				<td>KDR</td>
				<td><?php printf("%3.1f",$Stats['kdr']); ?></td>
				
				<td>5K (Aces)</td>
				<td><?php echo $Stats['5k']; ?></td>
			</tr>
		</table>
		<br>
		<table width="100%" border="0" cellpadding="1" cellspacing="1" align="center" style="text-align: center;">
			<tr>
				<th>Weapon</th>
				<th>K</th>
				<th>D</th>
				<th>HS</th>
				<th>ACC</th>
				<th>HSP</th>
			</tr>
			<?php
			
				$iConnection = mysqli_connect($_HOST_,$_USER_,$_PASS_,$_MYDB_) or die(mysqli_connect_errno($iConnection));
				
				$Result = mysqli_query($iConnection,"CALL PugGetWeapons('" . $Stats['steam'] . "', 5)");
				
				$i = 1;

				while($Weapon = mysqli_fetch_array($Result))
				{
					echo (!($i % 2)) ? "<tr>" : "<tr id=c>";
					
					echo "<td>" . str_replace("weapon_","",$Weapon['string']) . "</td>";
					echo "<td>" . $Weapon['kills'] . "</td>";
					echo "<td>" . $Weapon['deaths'] . "</td>";
					echo "<td>" . $Weapon['headshots'] . "</td>";
					
					Printf("<td>%3.2f</td>",GetAccuracy($Weapon['shots'],$Weapon['hits']));
					Printf("<td>%3.2f</td>",GetHSP($Weapon['headshots'],$Weapon['hits']));
					
					echo "</tr>";
					
					$i++;
				}
				
				function GetAccuracy($iShots,$iHits)
				{
					if(!$iShots)
					{
						return 0.0;
					}
					
					return (100.0 * round($iHits) / round($iShots));
				}
				
				function GetHSP($iHeadshots,$iHits)
				{
					if(!$iHeadshots)
					{
						return 0.0;
					}
					
					return (100.0 * round($iHeadshots) / round($iHits));
				}
			?>
	</table>
	</body>
</html>