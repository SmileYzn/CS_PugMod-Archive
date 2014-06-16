CS Pickup Game
==============
CS 1.6 Pickup Game Mod for Amx Mod X

.requeriments
=============
- MetaMod v1.21.1+
- AmxModX 1.8.3-dev-git3898+
- CS Dedicated server build 6153+

.features
=========
Web Stats (LOL NOPE)

.installing
===========
Shortly

.commands
=========
- User commands (Acessible by console and chat commands)<br>
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

- Adminstrator commands (Acessible by console and chat commands)
	!pause 				- Pause the Pug<br>
	!unpause 			- Unpause the pug<br>
	!togglepause 			- Pause / Unpause the Pug<br>
	!pugstart 			- Force the PUG to start<br>
	!pugstop 			- Stop the Pug<br>
	!pugreset 			- Reset the pug settings<br>
	!forceready <Player | All> 	- Force the Player to ready state<br>
	!forceunready <Player | All> 	- Force the Player to unready state<br>
	!votemap 			- Start a vote for the next map<br>
	!voteteams 			- Start a vote for team enforcement<br>
	!voteconfig 			- Start a vote for config type<br>
	!help 				- Pug Mod Help Admin page<br>

.convars
======
- CORE Convars<br>
pug_rounds_max 		"30" 	- Maximum of rounds to start Overtime<br>
pug_rounds_ot 		"6" 	- Overtime Rounds<br><br>
pug_players_max 	"10" 	- Maximum of players in game<br>
pug_players_min 	"10" 	- Minimum of players in game to start<br>
pug_players_default_max "10" 	- Default Maximum players<br>
pug_players_default_min "10" 	- Default Minimum players<br><br>
pug_allow_spectators 	"1" 	- Allow Spectators in game<br>
pug_allow_hltv 		"1" 	- Alow HLTV proxy in game<br><br>

- CS Specific Convars<br>
pug_force_restart 	"1" 	- Force the game to restart in some stages<br>
pug_switch_delay 	"5.0" 	- Delay to swap teams in Half Time<br>
pug_allow_shield 	"0" 	- Allow ShieldGun into the game<br>
pug_allow_grenades 	"0" 	- Allow Grenades in Warmup period<br>
pug_allow_kill 		"1" 	- Allow Kill command<br><br>

- Menu Convars<br>
pug_vote_delay 		"15.0" 	- Delay Between Pug votes<br>
pug_vote_percent 	"0.7" 	- Minimum percentage to accept the vote results<br>
pug_vote_map 		"1" 	- Enable Vote Map between games<br>
pug_show_scores 	"1" 	- Show Scoreboard on each Pug changelevel<br>
pug_hlds_vote 		"0"	- Allow HLDS Vote And VoteMap command<br><br>

// Sorry for poor english<br>
// If you not found a convar here, submit a bug :P