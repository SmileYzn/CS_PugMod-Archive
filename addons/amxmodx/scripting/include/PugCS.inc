#if defined _PugCS_included
	#endinput
#endif
#define _PugCS_included

#pragma reqlib "PugCS"
	#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib "PugCS"
#endif

native PugGetClientTeam(id);
native PugSetClientTeam(id,iTeam);
	
native PugGetPlayers(iGetBots);
	
native bool:PugIsTeam(id);
native PugRespawn(id);
native PugSetGodMode(id,iGodMode);
native PugSetMoney(id,iMoney,iFlash);
native PugMapObjectives(iRemove);
native PugSetScore(id,iFrags,iDeaths);

native PugTeamsRandomize();
native PugTeamsBalance();
native PugTeamsOptmize();

forward PugPlayerJoined(id,CsTeams:iTeam);
forward PugPlayerSpawned(id);
forward PugPlayerKilled(id);
