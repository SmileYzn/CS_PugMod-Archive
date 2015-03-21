			<?php
				function ClearString($Data)
				{
					$Data = trim($Data);
					$Data = stripslashes($Data);
					$Data = htmlspecialchars($Data);
	
					return $Data;
				}

				if($_SERVER["REQUEST_METHOD"] == "GET")
				{
					$Alias;
		
					if(isset($_GET['Alias']))
					{
						$Alias = ClearString($_GET['Alias']);
					}
					
					$iConnection = mysqli_connect("localhost","root","","db") or die(mysqli_error($iConnection));

					$Result = mysqli_query($iConnection,"CALL PugGetStats('$Alias')");
					$Stats = mysqli_fetch_array($Result);
					
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
		<table width="100%" border="0" cellpadding="1" cellspacing="1" align="center">
			<th colspan="2"><?php echo $Stats['name']; ?> - Stats</th>
			<th colspan="2">Round Stats</th>
			<th colspan="2">Streak</th>
			<tr id="c">
				<td width="13%">Kills</td>
				<td><?php echo $Stats['kills']; ?> (<?php echo $Stats['headshots']; ?> HS)</td>
				
				<td width="15%">Rounds</td>
				<td width="15%">
					<?php
						echo $Stats['rounds'];
					?>
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
				
				<td width="12%">1v2</td>
				<td><?php echo $Stats['v2']; ?></td>
			</tr>
			<tr>
				<td>Assists</td>
				<td><?php echo $Stats['assists']; ?></td>
				
				<td>Win</td>
				<td><?php echo $Stats['rounds_win']; ?></td>
				
				<td>v3</td>
				<td><?php echo $Stats['v3']; ?></td>
			</tr>
			<tr id="c">
				<td>Deaths</td>
				<td><?php echo $Stats['deaths']; ?></td>
				
				<td>Loses</td>
				<td><?php echo $Stats['rounds_lose']; ?></td>
				
				<td>v4</td>
				<td><?php echo $Stats['v4']; ?></td>
			</tr>
			<tr>
				<td>Shots</td>
				<td><?php echo $Stats['shots']; ?> (<?php echo $Stats['hits']; ?> hits)</td>
				
				<td>B. Plant</td>
				<td><?php echo $Stats['plants']; ?></td>
				
				<td>v5</td>
				<td><?php echo $Stats['v5']; ?></td>
			</tr>
			<tr id="c">
				<td>Dano (HP)</td>
				<td><?php echo $Stats['damage']; ?></td>
				
				<td>B. Defused</td>
				<td><?php echo $Stats['defused']; ?></td>
				
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
						$Skill = $Stats['skl'];
						
						if($Skill < 50.0)
						{
							printf("%3.0f%% <img id='r' width='%3.2f%%'>",$Skill,$Skill);
						}
						else
						{
							printf("%3.0f%% <img id='b' width='%3.2f%%'>",$Skill,$Skill);
						}
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
			
				$iCon = mysqli_connect("localhost","root","","db") or die(mysqli_error($iCon));
				
				$Res = mysqli_query($iCon,"CALL PugGetWeapons('" . $Stats['steam'] . "', 5)");
				
				$i = 1;

				while($Weapon = mysqli_fetch_array($Res))
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