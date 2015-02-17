#include <amxmodx>
#include <amxmisc>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugNatives>
#include <PugMenus>
#include <PugCS>

#include <PugCaptains>

#pragma semicolon 1

#define PUG_TASK_HUDLIST 1339

public bool:g_bVoting;

new g_pVoteDelay;
new g_pVotePercent;
new g_pMapVoteEnabled;
new g_pMapVote;
new g_pShowScores;
new g_pShowVotes;
new g_pHLDSVotes;
new g_pVoteKickPercent;
new g_pVoteKickTeams;

new g_pMapCycle;

new g_iMenuMap;
new g_iMenuTeams;

#define PUG_MAXMAPS 16

new g_iMapCount;
new g_sMapNames[PUG_MAXMAPS][32];
new g_iMapVotes[PUG_MAXMAPS];

enum _:TEAMS
{
	CAPTAINS,
	AUTO,
	NONE,
	SKILL
};

new g_sTeamTypes[TEAMS][] =
{
	"Capitaes",
	"Automatico",
	"Sem sorteio",
	"Balancear Skill"
};

new g_iTeamVotes[TEAMS];

new g_iNum;
new g_iPlayers[MAX_PLAYERS];

new g_iVotes[MAX_PLAYERS];
new g_iVoted[MAX_PLAYERS];

public plugin_init()
{
	register_plugin("Pug MOD (Vote System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("PugMenus.txt");
	
#if defined _PugCaptains_included
	register_dictionary("PugCaptains.txt");
#endif
	
	g_pVoteDelay 		= create_cvar("pug_vote_delay","15.0",FCVAR_NONE,"Tempo para as sessoes de votacao",true,5.0,true,30.0);
	g_pVotePercent 		= create_cvar("pug_vote_percent","0.4",FCVAR_NONE,"Diferenca minima para a votacao ter sucesso",true,0.1,true,31.0);
	g_pMapVoteEnabled 	= create_cvar("pug_vote_map_enabled","1",FCVAR_NONE,"Ativa a escolha do mapa entre as partidas",true,0.0,true,1.0);
	g_pMapVote 		= create_cvar("pug_vote_map","1",FCVAR_NONE,"Define se havera escolha do mapa na partida atual",true,0.0,true,1.0);
	g_pShowScores 		= create_cvar("pug_show_scores","0",FCVAR_NONE,"Ativa a mostra do placar entre cada changelevel",true,0.0,true,1.0);
	g_pShowVotes 		= create_cvar("pug_show_votes","2",FCVAR_NONE,"Mostra quem votou ou somente a lista de votos",true,1.0,true,2.0);
	g_pHLDSVotes 		= create_cvar("pug_hlds_votes","0",FCVAR_NONE,"Permite os comandos de voto nativo do HLDS",true,0.0,true,1.0);
	g_pVoteKickPercent 	= create_cvar("pug_vote_kick_percent","60.0",FCVAR_NONE,"Porcentagem dos votos para Kickar um player",true,1.0,true,100.0);
	g_pVoteKickTeams 	= create_cvar("pug_vote_kick_teams","1",FCVAR_NONE,"Ativa o Vote Kick somente entre as equipes",true,0.0,true,1.0);
	
	g_pMapCycle = get_cvar_pointer("mapcyclefile");
	
	g_iMenuMap = menu_create("Mapa:","PugVoteMapHandle");
	
	menu_setprop(g_iMenuMap,MPROP_EXIT,MEXIT_NEVER);
	
	g_iMenuTeams = menu_create("Modo de jogo:","PugVoteTeamHandle");
	
	menu_additem(g_iMenuTeams,"Capitaes","0");
	menu_additem(g_iMenuTeams,"Automatico","1");
	menu_additem(g_iMenuTeams,"Sem sorteio","2");
	menu_additem(g_iMenuTeams,"Balancear Skill","3");
	
	menu_setprop(g_iMenuTeams,MPROP_EXIT,MEXIT_NEVER);
	
	register_clcmd("vote","PugHLDSVote");
	register_clcmd("votemap","PugHLDSVote");
	
	PugRegisterCommand("votekick","PugVoteKick",ADMIN_ALL,"Kickar um Player");
	
	PugRegisterAdminCommand("votemap","PugCommandVoteMap",PUG_CMD_LVL,"Vote Map");
	PugRegisterAdminCommand("voteteams","PugCommandVoteTeam",PUG_CMD_LVL,"Modo de jogo");
}

public plugin_cfg()
{
	new sPatch[40];
	PugGetConfigsDir(sPatch,charsmax(sPatch));

	format(sPatch,charsmax(sPatch),"%s/maps.ini",sPatch);

	if(!PugLoadMaps(sPatch))
	{
		get_pcvar_string(g_pMapCycle,sPatch,charsmax(sPatch));
		
		PugLoadMaps(sPatch);
	}
}

public client_disconnect(id)
{
	if(g_iVoted[id])
	{
		if(get_pcvar_num(g_pVoteKickTeams))
		{
			new sTeam[13];
			get_user_team(id,sTeam,charsmax(sTeam));
			
			get_players(g_iPlayers,g_iNum,"he",sTeam);
		}
		else
		{
			get_players(g_iPlayers,g_iNum,"h");
		}
		
		for(new i;i < g_iNum;i++)
		{
			if(g_iVoted[id] & (1 << g_iPlayers[i]))
			{
				g_iVotes[g_iPlayers[i]]--;
			}
		}
		
		g_iVoted[id] = 0;
	}
}

PugLoadMaps(const sPatch[])
{
	if(file_exists(sPatch))
	{
		new iFile = fopen(sPatch,"rb");
		
		new sMap[32],iNum[10];
	
		new sCurrent[32];
		get_mapname(sCurrent,charsmax(sCurrent));
		
		while(!feof(iFile) && (g_iMapCount < PUG_MAXMAPS))
		{
			fgets(iFile,sMap,charsmax(sMap));
			trim(sMap);
			
			if(sMap[0] != ';' && is_map_valid(sMap) && !equali(sMap,sCurrent))
			{
				copy(g_sMapNames[g_iMapCount],charsmax(g_sMapNames[]),sMap);
					
				num_to_str(g_iMapCount,iNum,charsmax(iNum));
				menu_additem(g_iMenuMap,g_sMapNames[g_iMapCount],iNum);
			
				g_iMapCount++;
			}
		}
		
		fclose(iFile);
		
		return g_iMapCount;
	}
	
	return 0;
}

public PugEventStart()
{
	if(get_pcvar_num(g_pMapVoteEnabled) && get_pcvar_num(g_pMapVote))
	{
		PugStartMapVote();
	}
	else
	{
		PugStartTeamVote();
	}
}

public PugEventEnd()
{
	if(!get_pcvar_num(g_pMapVote))
	{
		set_pcvar_num(g_pMapVote,1);
	}
}

public PugStartMapVote()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"PugStartMapVote",1990 + g_iMenuMap);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iMapVotes,0,sizeof(g_iMapVotes));
	
	PugDisplayMenuAll(g_iMenuMap);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_START");
	
	set_task(fDelay,"PugVoteMapEnd",1990 + g_iMenuMap);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		set_task(0.5,"PugVotesListMap",PUG_TASK_HUDLIST, .flags="b");
	}
	
	return PLUGIN_HANDLED;
}

public PugVotesListMap()
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,0.6,0.0,0.0,1);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_MAP");
	
	new sResult[256],iVotes;
	
	for(new x;x < g_iMapCount;++x)
	{
		if(g_iMapVotes[x])
		{
			iVotes++;
			
			format
			(
				sResult,
				charsmax(sResult),
				"%s%s - %i %L^n",
				sResult,
				g_sMapNames[x],
				g_iMapVotes[x],
				LANG_SERVER,
				(g_iMapVotes[x] > 1) ? "PUG_VOTES" : "PUG_VOTE"
			);
		}
	}
	
	if(!iVotes)
	{
		formatex(sResult,charsmax(sResult),"%L",LANG_SERVER,"PUG_NOVOTES");
	}
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,0.6,0.0,0.0,2);
	show_hudmessage(0,sResult);
}

public PugVoteMapHandle(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey, iAccess, sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
	g_bVoted[id] = true;
	g_iMapVotes[str_to_num(sCommand)]++;
	
	switch(get_pcvar_num(g_pShowVotes))
	{
		case 1:
		{
			new sName[MAX_NAME_LENGTH];
			get_user_name(id,sName,charsmax(sName));
	
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTE_CHOOSED",sName,sOption);
		}
		case 2:
		{
			PugVotesListMap();
		}
	}
	
	if(PugShoudStopVote())
	{
		PugVoteMapEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public PugVoteMapEnd()
{
	PugCancelMenu();

	g_bVoting = false;
	remove_task(1990 + g_iMenuMap);
	remove_task(PUG_TASK_HUDLIST);
	
	if(!PugVoteMapCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"PugStartMapVote",1990 + g_iMenuMap);
	}
}

public PugVoteMapCount()
{
	new iWinner,iWinnerVotes,iVotes;

	for(new i;i < g_iMapCount;++i)
	{
		iVotes = g_iMapVotes[i];
		
		if(iVotes > iWinnerVotes)
		{
			iWinner = i;
			iWinnerVotes = iVotes;
		}
		else if(iVotes == iWinnerVotes)
		{
			if(random_num(0,1))
			{
				iWinner = i;
				iWinnerVotes = iVotes;
			}
		}
	}

	if(!g_iMapVotes[iWinner])
	{
		client_print_color(0,print_team_red,"%s %L %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_FAIL",LANG_SERVER,"PUG_NOVOTES");
		
		return PLUGIN_CONTINUE;
	}

	new Float:fTemp = float(PugGetPlayers()) * get_pcvar_float(g_pVotePercent);
	
	if(g_iMapVotes[iWinner] < floatround(fTemp,floatround_floor))
	{
		client_print_color(0,print_team_red,"%s %L %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_FAIL",LANG_SERVER,"PUG_NOWINNER");
		
		return PLUGIN_CONTINUE;
	}
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_NEXTMAP",g_sMapNames[iWinner]);

	g_bVoting = false;
	
	set_pcvar_num(g_pMapVote,0);

	if(get_pcvar_num(g_pShowScores))
	{
		message_begin(MSG_ALL,SVC_INTERMISSION);
		message_end();
	}

	set_task(5.0,"PugChangeMap",iWinner);
	
	return PLUGIN_HANDLED;
}

public PugChangeMap(iMap)
{
	server_cmd("changelevel ^"%s^"",g_sMapNames[iMap]);
}

public PugStartTeamVote()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"PugStartTeamVote",1990 + g_iMenuTeams);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iTeamVotes,0,sizeof(g_iTeamVotes));
	
	PugDisplayMenuAll(g_iMenuTeams);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMVOTE_START");
	
	set_task(fDelay,"PugVoteTeamEnd",1990 + g_iMenuTeams);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		set_task(0.5,"PugVotesListTeams",PUG_TASK_HUDLIST, .flags="b");
	}
	
	return PLUGIN_HANDLED;
}

public PugVotesListTeams()
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,0.6,0.0,0.0,1);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_TEAM");
	
	new sResult[128],iVotes;
	
	for(new x;x < TEAMS;++x)
	{
		if(g_iTeamVotes[x])
		{
			iVotes++;
			
			format
			(
				sResult,
				charsmax(sResult),
				"%s%s - %i %L^n",
				sResult,
				g_sTeamTypes[x],
				g_iTeamVotes[x],
				LANG_SERVER,
				(g_iTeamVotes[x] > 1) ? "PUG_VOTES" : "PUG_VOTE"
			);
		}
	}
	
	if(!iVotes)
	{
		formatex(sResult,charsmax(sResult),"%L",LANG_SERVER,"PUG_NOVOTES");
	}
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,0.6,0.0,0.0,2);
	show_hudmessage(0,sResult);
}

public PugVoteTeamHandle(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey, iAccess, sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
	g_bVoted[id] = true;
	g_iTeamVotes[str_to_num(sCommand)]++;
	
	switch(get_pcvar_num(g_pShowVotes))
	{
		case 1:
		{
			new sName[MAX_NAME_LENGTH];
			get_user_name(id,sName,charsmax(sName));
	
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTE_CHOOSED",sName,sOption);
		}
		case 2:
		{
			PugVotesListTeams();
		}
	}
	
	if(PugShoudStopVote())
	{
		PugVoteTeamEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public PugVoteTeamEnd()
{
	PugCancelMenu();

	g_bVoting = false;
	remove_task(1990 + g_iMenuTeams);
	remove_task(PUG_TASK_HUDLIST);
	
	if(!PugVoteTeamCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"PugStartTeamVote",1990 + g_iMenuTeams);
	}
}

public PugVoteTeamCount()
{
	new iWinner,iWinnerVotes,iVotes;

	for(new i;i < sizeof(g_iTeamVotes);++i)
	{
		iVotes = g_iTeamVotes[i];
		
		if(iVotes > iWinnerVotes)
		{
			iWinner = i;
			iWinnerVotes = iVotes;
		}
		else if(iVotes == iWinnerVotes)
		{
			if(random_num(0,1))
			{
				iWinner = i;
				iWinnerVotes = iVotes;
			}
		}
	}

	if(!g_iTeamVotes[iWinner])
	{
		client_print_color(0,print_team_red,"%s %L %L",g_sHead,LANG_SERVER,"PUG_TEAMVOTE_FAIL",LANG_SERVER,"PUG_NOVOTES");
		
		return PLUGIN_CONTINUE;
	}

	new Float:fTemp = float(PugGetPlayers()) * get_pcvar_float(g_pVotePercent);
	
	if(g_iTeamVotes[iWinner] < floatround(fTemp,floatround_floor))
	{
		client_print_color(0,print_team_red,"%s %L %L",g_sHead,LANG_SERVER,"PUG_TEAMVOTE_FAIL",LANG_SERVER,"PUG_NOWINNER");
		
		return PLUGIN_CONTINUE;
	}
	
	PugChangeTeams(iWinner);
	
	return PLUGIN_HANDLED;
}

PugChangeTeams(iWinner)
{
	switch(iWinner)
	{
		case 0:
		{
#if defined _PugCaptains_included
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_START");
			PugTeamsCaptains();
#else
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS");
			
			PugFirstHalf();
#endif
		}
		case 1:
		{
			PugTeamsRandomize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_RANDOM");
			
			PugFirstHalf();
		}
		case 2:
		{
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SAME");
			
			PugFirstHalf();
		}
		case 3:
		{
			PugTeamsOptmize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SKILL");
			
			PugFirstHalf();
		}
	}
}

public PugHLDSVote(id)
{
	if(!get_pcvar_num(g_pHLDSVotes))
	{
		new sCommand[10];
		read_argv(0,sCommand,charsmax(sCommand));
		
		console_print(id,"* %L",LANG_SERVER,"PUG_HLDS_VOTE",sCommand);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugVoteKick(id)
{
	if(PugIsTeam(id))
	{
		if(get_pcvar_num(g_pVoteKickTeams))
		{
			new sTeam[13];
			get_user_team(id,sTeam,charsmax(sTeam));
			
			get_players(g_iPlayers,g_iNum,"he",sTeam);
		}
		else
		{
			get_players(g_iPlayers,g_iNum,"h");
		}
		
		if(g_iNum < 3)
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEKICK_PLAYERS");
		}
		else
		{
			new iPlayer,sName[MAX_NAME_LENGTH + 8],sTemp[4];
			new iMenuKick = menu_create("Players:","PugVoteKickHandle");
			
			for(new i;i < g_iNum;i++)
			{
				iPlayer = g_iPlayers[i];
				
				if((iPlayer != id) && !access(iPlayer,PUG_CMD_LVL))
				{
					get_user_name(iPlayer,sName,charsmax(sName));
					
					format(sName,charsmax(sName),"%s (\y%i%%\w)",sName,PugGetPercent(g_iVotes[iPlayer],g_iNum));
					
					num_to_str(iPlayer,sTemp,charsmax(sTemp));
					menu_additem(iMenuKick,sName,sTemp);
				}
			}
			
			PugDisplayMenuSingle(id,iMenuKick);
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugVoteKickHandle(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		menu_destroy(iMenu);
		
		return PLUGIN_HANDLED;
	}
	
	new iAccess,sInfo[4],sOption[32],iBack;
	menu_item_getinfo(iMenu,iKey,iAccess,sInfo,charsmax(sInfo),sOption,charsmax(sOption),iBack);
	
	new iPlayer = str_to_num(sInfo);
	
	if(is_user_connected(iPlayer))
	{
		if(g_iVoted[id] & (1 << iPlayer))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEKICK_VOTED");
		}
		else
		{
			g_iVotes[iPlayer]++;
			g_iVoted[id] |= (1 << iPlayer);
			
			if(get_pcvar_num(g_pVoteKickTeams))
			{
				new sTeam[13];
				get_user_team(id,sTeam,charsmax(sTeam));
				
				get_players(g_iPlayers,g_iNum,"he",sTeam);
			}
			else
			{
				get_players(g_iPlayers,g_iNum,"h");
			}
			
			new sName[2][MAX_NAME_LENGTH];
			get_user_name(id,sName[0],charsmax(sName[]));
			get_user_name(iPlayer,sName[1],charsmax(sName[]));
			
			new iPercent = get_pcvar_num(g_pVoteKickPercent);
			
			client_print_color
			(
				0,
				print_team_red,
				"%s %L",
				g_sHead,
				LANG_SERVER,
				"PUG_VOTEKICK_MSG",
				sName[0],
				sName[1],
				PugGetPercent(g_iVotes[iPlayer],g_iNum),
				iPercent
			);
			
			if(PugGetPercent(g_iVotes[iPlayer],g_iNum) >= iPercent)
			{
				g_iVotes[iPlayer] = 0;
				
				client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEKICK_KICKED",sName[1]);
				
				server_cmd("kick #%i ^"%L^"",get_user_userid(iPlayer),LANG_SERVER,"PUG_VOTEKICK_DISCONNECTED");
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEKICK_NOTFOUND");
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandVoteMap(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"o Vote Map","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartMapVote());
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandVoteTeam(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"a escolha dos times","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartTeamVote());
	}
	
	return PLUGIN_HANDLED;
}
