CS 1.6 Pickup Game Mod for Amx Mod X
====================================

.Description
============
This mod automates all a game, supporting advanced commands,<br>
rounds count, management teams, maps, HLTV, statistics and more!

.Requeriments
=============
- MetaMod v1.21.1+
- AmxModX 1.8.3-dev-git4671+
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
	.sum 		- Display the summary of eac round<br>
	.help 		- Pug Mod Help page<br>
	.eac		- Show EAC Shots in game (Need EAC plugin installed)<br>
	.stats 		- Show in game Stats (Need stats installed)<br>
	.rank 		- Show in game top15 (Need stats installed)<br>
	.match 		- Show in game matches played (Need stats installed)<br>
	.setup		- Control the setup menu for start pug<br>
	.start		- Start the pug after configure it.<br>
	.votekick 	- Vote to Kick a selected player<br><br>

- Adminstrator commands<br>
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

pug_access_mode		- Acess mode to server<br>
pug_password_field	- Password field for setinfo<br>
pug_default_access	- Default access for non-admin users<br>
pug_eac_url		- URL that uses for show EAC screenshots<br>
pug_eac_url_format	- URL order of main address from EAC<br>
pug_version		- Show the Pug Mod Version<br>
pug_players_min		- Minimum of players to start a game (Not used at Pug config file)<br>
pug_players_max		- Maximum of players allowed in the teams (Not used at Pug config file)<br>
pug_players_min_default	- Minimum of players to start a game (This will reset the minimum of players in every map change)<br>
pug_players_max_default	- Maximum players to reset (This will reset the maximum of players in every map change)<br>
pug_rounds_max		- Rounds to play before start Overtime<br>
pug_rounds_overtime	- Rounds to play in overtime (In total)<br>
pug_allow_overtime	- Allow Overtime (If zero, the game can end tied)<br>
pug_intermission_time	- Time to reset pug after game ends<br>
pug_allow_spectators	- Allow Spectators to join in server<br>
pug_allow_hltv		- Allow HLTV in pug<br>
pug_retry_time		- Time to player wait before retry in server<br>
pug_force_ready_time	- Force a player to be ready in that time (If zero, this function will be inactive)<br>
pug_force_ready_kick	- Kick Un-Ready players (If zero, the players will be put as ready automatically<br>
pug_force_auto_swap	- Auto Swap teams without Ready-System if the teams are complete<br>
pug_force_restart	- Force a restart when swap teams<br>
pug_switch_delay	- Delay to swap teams after Half-Time start<br>
pug_block_shield	- Block shield from game<br>
pug_block_grenades	- Block grenades at warmup rounds<br>
pug_show_money		- Display the money of team in every respawn<br>
pug_vote_delay		- How long voting session goes on<br>
pug_vote_percent	- Difference between votes to determine a winner<br>
pug_vote_map_enabled	- Active vote map in pug<br>
pug_vote_map		- Determine if current map will have the vote map (Not used at Pug config file)<br>
pug_vote_map_same	- Add the current map at vote map menu<br>
pug_show_scores		- Show scores after vote maps<br>
pug_teams_enforcement	- The teams method for assign teams (0 = Vote, 1 = Captains, 2 = Automatic, 3 = None, 4 = Skill)<br>
pug_teams_kniferound	- Force a Knife Round after choose teams<br>
pug_show_votes		- Method to show votes results (1 = Chat, 2 = Hudmessage)<br>
pug_hlds_votes		- Allow HLDS native votes commands as vote and votemap<br>
pug_vote_kick_percent	- Percentage to kick an player using Vote Kick<br>
pug_vote_kick_teams	- Vote Kick only for teammates<br>
pug_config_pugmod	- Config executed for pugmod cvars<br>
pug_config_warmup	- Used at warmup session in pug mod<br>
pug_config_start	- Executed when vote session starts<br>
pug_config_live		- Used when the match begin (Live config)<br>
pug_config_halftime	- Used at half-time session<br>
pug_config_overtime	- Used at Overtime session<br>
pug_config_end		- Executed when the match ends<br>
pug_sql_host		- SQL server address<br>
pug_sql_user		- Database user<br>
pug_sql_pass		- Database password<br>
pug_sql_db		- Database name<br>
pug_bans_url		- URL that will store bans page<br>
pug_require_register	- Kick players that is not registred at database<br>
pug_leaves_ban		- Ban a player that reaches a number of leaves<br>
pug_leaves_bantime	- Time to ban when reach leave infraction times (In minutes)<br>
pug_ranked_server	- Rank the server to database<br>
pug_web_url		- URL of stats pages for pug mod<br>
pug_hltv_host		- Remote HLTV IP address<br>
pug_hltv_port		- Remote HLTV Port<br>
pug_hltv_pass		- Remote HLTV (Rcon|adminpass) Password<br>
pug_hltv_demo_dir	- Demos sub-dir (Stored at cstrike folder)<br>
pug_hltv_demo_name	- Demo name prefix (Ie. pug will be saved as pug-1504070051-de_dust2.dem)