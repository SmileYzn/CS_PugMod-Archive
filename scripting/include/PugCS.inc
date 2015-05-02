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
	
native PugGetPlayers();
	
native bool:PugIsTeam(id);
native PugRespawn(id);
native PugSetGodMode(id,iGodMode);
native PugSetMoney(id,iMoney,iFlash);
native PugMapObjectives(iRemove);
	
native PugTeamsRandomize();
native PugTeamsBalance();
native PugTeamsOptmize();
native PugTeamsSwap();
