<html>
	<head>
		<title>Stats</title>
	</head>
	<body>
		<form method="GET" action="stats.php">
			<input type="text" size="35" name="Alias">
			<input type="submit" value="Pesquisar">
		</form>
		<br>
		<br>
		<form method="GET" action="top.php">
			<input type="submit" value="TOP 10">
		</form>
		<br>
		<br>
		<form action="hltv.php" method="GET">
			<span style="font-weight: bold; font-size: 1.1em;">Select an server: </span>
			<select name="server">
				<?php
					include("config.php");

					foreach($Servers as $Key => $Value)
					{
							echo "<option " . ($Key == $_GET['server'] ? "selected" : "") . " value='" . $Key . "'>" . $Value['title'] . "</option>";
					}
				?>
			</select>
			<button type="submit">Go</button>
		</form>
	</body>
</html>