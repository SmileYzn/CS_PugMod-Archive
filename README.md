CS 1.6 Pickup Game Mod for Amx Mod X
====================================

.Description
============
This mod automates all game, supporting advanced commands,<br>
rounds count, management teams, maps, HLTV, statistics and more!

.Requeriments
=============
- MetaMod 1.21p38+
- AmxMod X 1.8.3-dev+5162+
- HLDS CS Dedicated server build 6153+

.Features
=========
- Vote Map<br>
- Team Picker<br>
- Config manager<br>
- Admin Commands<br>
- Client Commands<br>
- Automatic Overtime<br>
- Round Stats commands<br>
- Ready System<br>
- Teams balancer + Spectators management<br>
- Automatic LO3 on start<br>
- Automatic Swap teams<br>
- Warmup Rounds<br>
- Weapon restrictions<br>
- Multi language support in execution time<br>
- Overtime chooser<br>
- Auto setup and configuration<br>
- Automatic Help system<br>
- Automatic Stats system with SQL Support<br>
- Easy Anti Cheat support<br>
- Anti-Flood system<br>
- In Game stats commands<br>
- SQL Ban System and register system<br>
- Auto messages in game<br>
- Custom admin system.<br>
- HLTV system<br>
- Team Dead Talk support<br>
- Teammates money display<br>
- ScoreBoard fix after change teams<br>
- Dead talk<br><br>

.Installing
===========
- Download ZIP from GitHub
- Download Last AMXX dev at amxmodx.org/snapshots.php<br>
- Download AMXX Base + AMXX CSTRIKE addons<br>
- Copy amxmodx_mm.dll or amxmodx_i386.so to addons/amxmodx/dlls folder<br>
- Copy cstrike, csx, fakemeta, hamsandwich, mysql and sockets to modules folder<br>
- Now you can compile the Pug Plugins with scripting (Base) package downloaded from amxmodx<br>
- Copy all .amxx plugins to addons/amxmodx/plugins folder<br>
- Download Metamod 1.21-am from here (amxmodx.org/downloads.php) and place into addons/metamod/dlls folder<br>
- Setup your plugins.ini at addons/metamod folder according to your system (Linux or windows)<br>
- After all, configure pugmod.rc at addons/amxmodx/configs/pug as you wish<br>
- Upload addons folder with liblist.gam and server.cfg to HLDS<br>
- Just start server (Or configure server.cfg first)<br><br>

.Commands (Console and chat)
=========
- User commands<br>
	.status		- Pug Status command<br>
	.score 		- Show the scores<br>
	.round 		- Display the current round<br>
	.ready 		- Player is ready to play<br>
	.notready 	- Player is not ready<br>
	.hp 		- Display the HP of enemy team<br>
	.dmg 		- Display the damage in done in each round<br>
	.rdmg 		- Display the damage recived in each round<br>
	.sum 		- Display the summary of round<br>
	.help 		- Pug Mod Help page<br>
	.eac		- Show EAC Shots in game (Need EAC plugin installed)<br>
	.stats 		- Show in game Stats (Need stats installed)<br>
	.rank 		- Show in game top15 (Need stats installed)<br>
	.match 		- Show in game matches played (Need stats installed)<br>
	.setup		- Control the setup menu for start pug<br>
	.start		- Start the pug after configure it.<br>
	.votekick 	- Vote to Kick a selected player<br><br>

- Administrator commands<br>
	!pause 					- Pause the Pug<br>
	!unpause 				- Unpause the pug<br>
	!togglepause 				- Pause / Unpause the Pug<br>
	!pugstart 				- Force the PUG to start<br>
	!pugstop 				- Stop the Pug<br>
	!pugreset 				- Reset the pug settings<br>
	!forceready <Player | All> 		- Force the Player to ready state<br>
	!forceunready <Player | All> 		- Force the Player to unready state<br>
	!votemap 				- Start a vote for the next map<br>
	!voteconfig 				- Start a vote for config type<br>
	!kill <Player>				- Kill the selected player<br>
	!map <Map>				- Change the map<br>
	!kick <Player> 				- Kick the given player<br>
	!rcon <Command> 			- Sends a rcon command to server<br>
	!ban <Steam|Player> [Minutes] [Reason] 	- Ban the given player (Need PugDB installed)<br>
	!unban <Steam> 				- Ban the given player (Need PugDB installed)<br>
	!help 					- Pug Mod Help Admin page<br><br>

.Pug Mod Variables
======

pug_players_min		"10"		// Minimum of players to start a game<br>
pug_players_max		"10"		// Maximum of players allowed in the teams<br>
pug_rounds_max		"30"		// Rounds to play before start overtime<br>
pug_rounds_ot		"3"		// Win difference to determine a winner in overtime<br>
pug_force_ot		"1"		// Force Overtime (0 End game tied, 1 Force Overtime)<br>
pug_handle_time		"10.0"		// Time to PUG change states<br>
pug_allow_spec		"0"		// Allow Spectators in game<br>
pug_drop_ban_time	"15"		// Minutes of ban players that leave from game in live<br>
pug_vote_delay		"15.0"		// How long voting session goes on<br>
pug_vote_map_enabled	"1"		// Active vote map in pug (0 Disable, 1 Enable, 2 Random map)<br>
pug_teams_enforcement	"0"		// The teams method for assign teams (0 By vote, 1 Captains, 2 Automatic, 3 None, 4 Skill)<br>
pug_dead_talk				// Allow Dead talk when match is live<br>
pug_team_money				// Display Teammates money at round start<br>
pug_fix_scores				// Keep scoreboard after change teams<br><br>

pug_cfg_pugmod		"pugmod.rc"	// Config executed for pugmod cvars<br>
pug_cfg_warmup		"warmup.rc"	// Used at warmup session in pug mod<br>
pug_cfg_start		"start.rc"	// Executed when vote session starts<br>
pug_cfg_1st		"esl.rc"	// Used when the match begin (Live config)<br>
pug_cfg_halftime	"halftime.rc"	// Used at half-time session<br>
pug_cfg_2nd		"esl.rc"	// Used when the match begin (Live config)<br>
pug_cfg_overtime	"esl-ot.rc"	// Used at Overtime session<br>
pug_cfg_end		"end.rc"	// Executed when the match ends<br><br>

