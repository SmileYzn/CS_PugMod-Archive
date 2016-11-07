CS 1.6 Pickup Game Mod for Amx Mod X
====================================

.Description
============
This mod automates all game, supporting advanced commands,<br>
rounds count, management teams, maps, HLTV, statistics and more!

.Requeriments
=============
- MetaMod v1.21.1+
- AmxModX 1.8.3-dev-git5073+
- HLDS CS Dedicated server build 6153+

.Features
=========
- Vote Map<br>
- Team Picker<br>
- Knife Round<br>
- Config chooser<br>
- Admin Commands<br>
- Client Commands<br>
- Automatic Overtime<br>
- Round Stats commands<br>
- Ready System<br>
- Auto Swap Teams<br>
- Teams balancer + Spectators management<br>
- AFK Kicker<br>
- Automatic LO3 config<br>
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
- And more is incoming<br><br>

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

.Console variables
======
pug_access_mode		"1"			// Acess mode to server
pug_password_field	"_pw"			// Password field for setinfo
pug_default_access	"z"			// Default access for non-admin users

pug_players_min_default	"10"			// Minimum of players to start a game (This will reset the minimum of players in every map change)
pug_players_max_default	"10"			// Maximum players to reset (This will reset the maximum of players in every map change)
pug_rounds_max		"30"			// Rounds to play before start Overtime
pug_rounds_overtime	"6"			// Rounds to play in overtime (In total)
pug_allow_overtime	"1"			// Allow Overtime (If zero, the game can end tied)
pug_intermission_time	"10.0"			// Time to reset pug after game ends
pug_allow_spectators	"1"			// Allow Spectators to join in server
pug_allow_hltv		"1"			// Allow HLTV in pug
pug_retry_time		"20.0"			// Time to player wait before retry in server (0.0 disabled)
pug_ban_leaver_time	"0"			// Time to ban player if he leaves on a live match (0 disabled)

pug_force_ready_time	"0.0"			// Force a player to be ready in that time (If zero, this function will be inactive)
pug_force_ready_kick	"0"			// Kick Un-Ready players (If zero, the players will be put as ready automatically)
pug_force_auto_swap	"1"			// Auto Swap teams without Ready-System if the teams are complete

pug_force_restart	"1"			// Force a restart when swap teams
pug_switch_delay	"5.0"			// Delay to swap teams after Half-Time start
pug_block_shield	"1"			// Block shield from game
pug_block_grenades	"1"			// Block grenades at warmup rounds
pug_show_money		"1"			// Display the money of team in every respawn

pug_vote_delay		"15.0"			// How long voting session goes on
pug_vote_percent	"0.4"			// Difference between votes to determine a winner
pug_vote_map_enabled	"1"			// Active vote map in pug
pug_vote_map_same	"0"			// Add the current map at vote map menu
pug_show_scores		"0"			// Show scores after vote maps
pug_teams_enforcement	"0"			// The teams method for assign teams (0 = Vote, 1 = Captains, 2 = Automatic, 3 = None, 4 = Skill)
pug_show_votes		"2"			// Method to show votes results (1 = Chat, 2 = Hudmessage)
pug_hlds_votes		"0"			// Allow HLDS native votes commands as vote and votemap
pug_vote_kick_percent	"60.0"			// Percentage to kick an player using Vote Kick
pug_vote_kick_teams	"1"			// Vote Kick only for teammates
pug_vote_kick_players	"3"			// Players needed to a Vote Kick

pug_config_pugmod	"pugmod.rc"		// Config executed for pugmod cvars
pug_config_warmup	"warmup.rc"		// Used at warmup session in pug mod
pug_config_start	"start.rc"		// Executed when vote session starts
pug_config_live		"esl.rc"		// Used when the match begin (Live config)
pug_config_halftime	"halftime.rc"		// Used at half-time session
pug_config_overtime	"esl-ot.rc"		// Used at Overtime session
pug_config_end		"end.rc"		// Executed when the match ends

