#if defined _PugNatives_included
	#endinput
#endif
#define _PugNatives_included

#pragma reqlib "PugNatives"
	#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib "PugNatives"
#endif

native PugWarmup();
native PugStart();
native PugFirstHalf();
native PugHalfTime();
native PugSecondHalf();
native PugOvertime();
native PugEnd(iWinner);

native PugRegisterTeam(sTeam[]);
native PugNumTeams();
native PugSwapTeams(iTeamA,iTeamB);
	
native PugGetTeamScore(iTeam);
native PugSetTeamScore(iTeam,iScore);

native PugGetTeamName(iTeam,sName[]);
native PugSetTeamName(iTeam,sName[]);

native PugRoundStart();
native PugRoundWinner(iWinner);
native PugRoundEnd();
