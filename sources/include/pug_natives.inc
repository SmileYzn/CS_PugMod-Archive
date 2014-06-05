#if defined _pug_natives_included
	#endinput
#endif
#define _pug_natives_included

#include <amxconst>

native PugPause();
native PugUnPause();
native PugSetPauseCall(iFunctionID,iPluginID = INVALID_PLUGIN_ID);

native PugCallRoundStart();
native PugCallRoundEnd(iWinner);

native PugCallReset();

native PugSwapTeams(iTeamA,iTeamB);
native PugRegisterTeam(sTeam[]);
native PugNumTeams();

native PugGetTeamName(iTeam,sName[32]);
native PugSetTeamName(iTeam,sName[32]);

native PugSetTeamScore(iTeam,iScore);
native PugGetTeamScore(iTeam);
