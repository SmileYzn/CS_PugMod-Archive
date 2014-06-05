#if defined _pug_modspecific_included
  #endinput
#endif
#define _pug_modspecific_included

native PugGetPlayers();
native PugGetPlayersTeam(iTeam);

native PugTeamsRandomize();
native PugTeamsBalance();
native PugTeamsOptmize();

native PugGetClientTeam(id);
native PugSetClientTeam(id,iTeam);

native PugRespawnClient(id);
native PugSetGodMode(id,iGodMode);
native PugSetClientMoney(id,iMoney,iFlash);

native PugRemoveC4(iRemove);
