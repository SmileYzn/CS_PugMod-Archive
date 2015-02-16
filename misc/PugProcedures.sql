DELIMITER $$

DROP PROCEDURE IF EXISTS `PugSavePlayer` $$

CREATE PROCEDURE PugSavePlayer(IN sSteam VARCHAR(35), IN sName VARCHAR(32))
BEGIN
	INSERT INTO pug_players (`steam`, `name`)
	VALUES (sSteam, sName)
	ON DUPLICATE KEY UPDATE `name` = sName;
END $$

DROP PROCEDURE IF EXISTS `PugSaveStats` $$

CREATE PROCEDURE PugSaveStats
(
	IN sSteam VARCHAR(35),
	IN iKills INT,
	IN iAssists INT,
	IN iDeaths INT,
	IN iHeadshots INT,
	IN iShots INT,
	IN iHits INT,
	IN iDamage INT,
	IN fRWS FLOAT,
	IN iRounds INT,
	IN iRoundsLose INT,
	IN iRoundsWin INT,
	IN iMatchs INT,
	IN iMatchsLose INT,
	IN iMatchsWin INT
)
BEGIN
	INSERT INTO pug_stats
	(
		`steam`,
		`kills`,
		`assists`,
		`deaths`,
		`headshots`,
		`shots`,
		`hits`,
		`damage`,
		`rws`,
		`rounds`,
		`rounds_lose`,
		`rounds_win`,
		`matchs`,
		`matchs_lose`,
		`matchs_win`
	)
	VALUES
	(
		sSteam,
		iKills,
		iAssists,
		iDeaths,
		iHeadshots,
		iShots,
		iHits,
		iDamage,
		fRWS,
		iRounds,
		iRoundsLose,
		iRoundsWin,
		iMatchs,
		iMatchsLose,
		iMatchsWin
	)
	ON DUPLICATE KEY UPDATE
	`steam` = sSteam,
	`kills` = `kills` + iKills,
	`assists` = `assists` + iAssists,
	`deaths` = `deaths` + iDeaths,
	`headshots` = `headshots` + iHeadshots,
	`shots` = `shots` + iShots,
	`hits` = `hits` + iHits,
	`damage` = `damage` + iDamage,
	`rounds` = `rounds` + iRounds,
	`rounds_lose` = `rounds_lose` + iRoundsLose,
	`rounds_win` = `rounds_win` + iRoundsWin,
	`matchs` = `matchs` + iMatchs,
	`matchs_lose` = `matchs_lose` + iMatchsLose,
	`matchs_win` = `matchs_win` + iMatchsWin;
END $$

DROP PROCEDURE IF EXISTS `PugSaveBomb` $$

CREATE PROCEDURE PugSaveBomb(IN sSteam VARCHAR(35), IN iDefuses INT, IN iDefused INT, IN iPlants INT, IN iExplosions INT)
BEGIN
	INSERT INTO pug_bomb (`steam`, `defuses`, `defused`, `plants`, `explosions`)
	VALUES (sSteam, iDefuses, iDefused, iPlants, iExplosions)
	ON DUPLICATE KEY UPDATE
	`steam` = sSteam,
	`defuses` = `defuses` + iDefuses,
	`defused` = `defused` + iDefused,
	`plants` = `plants` + iPlants,
	`explosions` = `explosions` + iExplosions;
END $$

DROP PROCEDURE IF EXISTS `PugSaveStreak` $$

CREATE PROCEDURE PugSaveStreak(IN sSteam VARCHAR(35), IN iK1 INT, IN iK2 INT, IN iK3 INT, IN iK4 INT, IN iK5 INT)
BEGIN
	INSERT INTO pug_streak (`steam`, `1k`, `2k`, `3k`, `4k`, `5k`)
	VALUES (sSteam, iK1, iK2, iK3, iK4, iK5)
	ON DUPLICATE KEY UPDATE
	`steam` = sSteam,
	`1k` = `1k` + iK1,
	`2k` = `2k` + iK2,
	`3k` = `3k` + iK3,
	`4k` = `4k` + iK4,
	`5k` = `5k` + iK5;
END $$

DROP PROCEDURE IF EXISTS `PugSaveVersus` $$

CREATE PROCEDURE PugSaveVersus(IN sSteam VARCHAR(35), IN iV1 INT, IN iV2 INT, IN iV3 INT, IN iV4 INT, IN iV5 INT)
BEGIN
	INSERT INTO pug_versus (`steam`, `v1`, `v2`, `v3`, `v4`, `v5`)
	VALUES (sSteam, iV1, iV2, iV3, iV4, iV5)
	ON DUPLICATE KEY UPDATE
	`steam` = sSteam,
	`v1` = `v1` + iV1,
	`v2` = `v2` + iV2,
	`v3` = `v3` + iV3,
	`v4` = `v4` + iV4,
	`v5` = `v5` + iV5;
END $$

DROP PROCEDURE IF EXISTS `PugCalcStats` $$

CREATE PROCEDURE PugCalcStats(IN sSteam VARCHAR(35))
BEGIN
	DECLARE iKills SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iDeaths SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iHS SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iShots SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iHits SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iDamage SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iRounds SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iRoundsLose SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iDefused SMALLINT UNSIGNED DEFAULT 0;
	DECLARE iExplosions SMALLINT UNSIGNED DEFAULT 0;
	DECLARE fEFF FLOAT UNSIGNED DEFAULT 0;
	DECLARE fACC FLOAT UNSIGNED DEFAULT 0;
	DECLARE fRWS FLOAT UNSIGNED DEFAULT 0;
	
	SELECT shots INTO iShots FROM pug_stats WHERE steam = sSteam;
	
	IF iShots > 0 THEN
		SELECT hits INTO iHits FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `acc`)
		VALUES (sSteam, (100.0 * ROUND(iHits) / ROUND(iShots)))
		ON DUPLICATE KEY UPDATE `acc` = (100.0 * ROUND(iHits) / ROUND(iShots));
	END IF;
	
	SELECT kills INTO iKills FROM pug_stats WHERE steam = sSteam;
	
	IF iKills > 0 THEN
		SELECT deaths INTO iDeaths FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `eff`)
		VALUES (sSteam, (100.0 * ROUND(iKills) / ROUND(iKills + iDeaths)))
		ON DUPLICATE KEY UPDATE `eff` = (100.0 * ROUND(iKills) / ROUND(iKills + iDeaths));
	END IF;
	
	SELECT headshots INTO iHS FROM pug_stats WHERE steam = sSteam;
	
	IF iHS > 0 THEN
		SELECT hits INTO iHits FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `hsp`)
		VALUES (sSteam, (100.0 * ROUND(iHS) / ROUND(iHits)))
		ON DUPLICATE KEY UPDATE `hsp` = (100.0 * ROUND(iHS) / ROUND(iHits));
	END IF;
	
	SELECT rounds INTO iRounds FROM pug_stats WHERE steam = sSteam;
	
	IF iRounds > 0 THEN
		SELECT damage INTO iDamage FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `adr`)
		VALUES (sSteam, (ROUND(iDamage) / ROUND(iRounds)))
		ON DUPLICATE KEY UPDATE `adr` = (ROUND(iDamage) / ROUND(iRounds));
	END IF;
	
	IF iRounds > 0 THEN
		SELECT kills INTO iKills FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `fpr`)
		VALUES (sSteam, (ROUND(iKills) / ROUND(iRounds)))
		ON DUPLICATE KEY UPDATE `fpr` = (ROUND(iKills) / ROUND(iRounds));
	END IF;
	
	IF iKills > 0 THEN
		SELECT deaths INTO iDeaths FROM pug_stats WHERE steam = sSteam;
	
		INSERT INTO pug_misc (`steam`, `kdr`)
		VALUES (sSteam, (ROUND(iKills) / ROUND(iDeaths)))
		ON DUPLICATE KEY UPDATE `kdr` = (ROUND(iKills) / ROUND(iDeaths));
	END IF;
	
	SELECT eff INTO fEFF FROM pug_misc WHERE steam = sSteam;
	SELECT acc INTO fACC FROM pug_misc WHERE steam = sSteam;
	
	IF fEFF > 0.0 AND fACC > 0.0 THEN
		INSERT INTO pug_misc (`steam`, `skl`)
		VALUES (sSteam, ((fEFF + fACC) / 2))
		ON DUPLICATE KEY UPDATE `skl` = ((fEFF + fACC) / 2);
	END IF;

	SELECT rws INTO fRWS FROM pug_stats WHERE steam = sSteam;

	IF fRWS > 0.0 THEN
		SELECT defused INTO iDefused FROM pug_bomb WHERE steam = sSteam;
		SELECT explosions INTO iExplosions FROM pug_bomb WHERE steam = sSteam;
		SELECT rounds INTO iRounds FROM pug_stats WHERE steam = sSteam;
		SELECT rounds_lose INTO iRoundsLose FROM pug_stats WHERE steam = sSteam;

		if iDefused > 0 THEN
			SET fRWS = (fRWS + (iDefused * 30.0));
		END IF;

		if iExplosions > 0 THEN
			SET fRWS = (fRWS + (iExplosions * 30.0));
		END IF;
	
		INSERT INTO pug_misc (`steam`, `rws`)
		VALUES (sSteam, 100.0 * fRWS / ((ROUND(iRounds) + ROUND(iRoundsLose))))
		ON DUPLICATE KEY UPDATE `rws` = fRWS / ((ROUND(iRounds) + ROUND(iRoundsLose)));
	END IF;
END $$

DROP PROCEDURE IF EXISTS `PugSaveWeapon` $$

CREATE PROCEDURE PugSaveWeapon
(
	IN iWeapon INT,
	IN sString VARCHAR(32),
	IN iKills INT,
	IN iDeaths INT,
	IN iHeadshots INT,
	IN iShots INT,
	IN iHits INT,
	IN iDamage INT,
	IN sSteam VARCHAR(35)
)
BEGIN
	DECLARE sSteamID VARCHAR(35);
	SELECT `steam` INTO sSteamID FROM pug_weapon WHERE `steam` = sSteam AND `string` = sString AND `weapon` = iWeapon;

	IF sSteamID IS NULL THEN
		INSERT INTO pug_weapon
		(
			`weapon`,
			`string`,
			`kills`,
			`deaths`,
			`headshots`,
			`shots`,
			`hits`,
			`damage`,
			`steam`
		)
		VALUES
		(
			iWeapon,
			sString,
			iKills,
			iDeaths,
			iHeadshots,
			iShots,
			iHits,
			iDamage,
			sSteam
		);
	ELSE
		UPDATE pug_weapon SET
		`weapon` = iWeapon,
		`string` = sString,
		`kills` = `kills` + iKills,
		`deaths` = `deaths` + iDeaths,
		`headshots` = `headshots` + iHeadshots,
		`shots` = `shots` + iShots,
		`hits` = `hits` + iHits,
		`damage` = `damage` + iDamage,
		`steam` = sSteam WHERE `steam` = sSteam AND `string` = sString AND `weapon` = iWeapon;
	END IF;
END $$

DROP PROCEDURE IF EXISTS `PugSaveMatch` $$

CREATE PROCEDURE PugSaveMatch
(
	IN sServer VARCHAR(32),
	IN sIP VARCHAR(23),
	IN sMap VARCHAR(32),
	IN iWinTR INT,
	IN iWinCT INT,
	IN fDuration FLOAT
)
BEGIN
	INSERT INTO pug_match
	(
		`server`,
		`ip`,
		`map`,
		`score1`,
		`score2`,
		`rounds`,
		`seconds`,
		`duration`
	)
	VALUES
	(
		sServer,
		sIP,
		sMap,
		iWinTR,
		iWinCT,
		iWinTR + iWinCT,
		fDuration,
		SEC_TO_TIME(ROUND(fDuration))
	);
END $$

DROP PROCEDURE IF EXISTS `PugGetTOP` $$

CREATE PROCEDURE PugGetTOP(IN iMax INTEGER)
BEGIN
	SELECT pug_players.name, pug_stats.kills, pug_stats.assists, pug_stats.deaths, pug_misc.hsp, pug_misc.rws, pug_misc.skl
	FROM pug_players, pug_stats, pug_misc
	WHERE pug_players.steam = pug_stats.steam AND pug_players.steam = pug_misc.steam
	ORDER BY pug_misc.skl DESC LIMIT iMax;
END $$

DROP PROCEDURE IF EXISTS `PugGetStats` $$

CREATE PROCEDURE PugGetStats(IN sAlias VARCHAR(35))
BEGIN
	SELECT * FROM pug_players Player
	INNER JOIN pug_stats Stats ON Player.steam = Stats.steam
	INNER JOIN pug_bomb Bomb ON Player.steam = Bomb.steam
	INNER JOIN pug_misc Misc ON Player.steam = Misc.steam
	INNER JOIN pug_streak Streak ON Player.steam = Streak.steam
	INNER JOIN pug_versus Versus ON Player.steam = Versus.steam
	WHERE Player.steam = sAlias OR Player.name = sAlias;
END $$

DROP PROCEDURE IF EXISTS `PugGetPosition` $$

CREATE PROCEDURE PugGetPosition(IN sSteam VARCHAR(35))
BEGIN
	SELECT (COUNT(*) + 1) AS Pos FROM pug_misc WHERE skl > (SELECT skl FROM pug_misc WHERE steam = sSteam);
END $$

DROP PROCEDURE IF EXISTS `PugGetWeapons` $$

CREATE PROCEDURE PugGetWeapons(IN sSteam VARCHAR(35), IN iMax INT)
BEGIN
	SELECT * FROM pug_weapon WHERE steam = sSteam ORDER BY kills DESC LIMIT 5;
END $$

DROP PROCEDURE IF EXISTS `PugClearStats` $$

CREATE PROCEDURE PugClearStats(IN iConfirm INT)
BEGIN
	IF iConfirm > 0 THEN
		TRUNCATE TABLE pug_stats;
		TRUNCATE TABLE pug_bomb;
		TRUNCATE TABLE pug_streak;
		TRUNCATE TABLE pug_versus;
		TRUNCATE TABLE pug_misc;
	END IF;
END $$

DROP PROCEDURE IF EXISTS `PugGetPlayer` $$

CREATE PROCEDURE PugGetPlayer(IN sSteam VARCHAR(35))
BEGIN
	SELECT steam, name FROM pug_players WHERE steam = sSteam;
END $$

DROP PROCEDURE IF EXISTS `PugGetBans` $$

CREATE PROCEDURE PugGetBans(IN sSteam VARCHAR(35))
BEGIN
	SELECT * FROM pug_players WHERE steam = sSteam AND banned = 1;
END $$

DROP PROCEDURE IF EXISTS `PugBanSteam` $$

CREATE PROCEDURE PugBanSteam
(
	IN sSteam VARCHAR(35),
	IN iLen INT,
	IN sUnBan VARCHAR(32),
	IN sReason VARCHAR(64)
)
BEGIN
	UPDATE pug_players SET length = iLen, unban = sUnBan, reason = sReason, banned = 1 WHERE steam = sSteam AND banned = 0;
END $$

DROP PROCEDURE IF EXISTS `PugBanPlayer` $$

CREATE PROCEDURE PugBanPlayer
(
	IN sName VARCHAR(32),
	IN iLen INT,
	IN sUnBan VARCHAR(32),
	IN sReason VARCHAR(64)
)
BEGIN
	UPDATE pug_players SET length = iLen, unban = sUnBan, reason = sReason, banned = 1 WHERE name = sName AND banned = 0;
END $$

DROP PROCEDURE IF EXISTS `PugRemoveBan` $$

CREATE PROCEDURE PugRemoveBan(IN sSteam VARCHAR(35))
BEGIN
	UPDATE pug_players SET banned = 0 WHERE steam = sSteam AND banned = 1;
END $$

DROP PROCEDURE IF EXISTS `PugUpdateBans` $$

CREATE PROCEDURE PugUpdateBans(IN iTime INT)
BEGIN
	UPDATE pug_players SET banned = 0 WHERE (length < iTime AND length > 0);
END $$

DROP PROCEDURE IF EXISTS `PugAddLeave` $$

CREATE PROCEDURE PugAddLeave(IN sSteam VARCHAR(35))
BEGIN
	UPDATE pug_players SET leaves = leaves + 1 WHERE steam = sSteam;
END $$

DELIMITER ;