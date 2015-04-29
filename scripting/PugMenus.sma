#include <amxmodx>
#include <amxmisc>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugNatives>
#include <PugMenus>
#include <PugCS>
#include <PugCaptains>
#include <PugKnifeRound>

#pragma semicolon 1

#define PUG_TASK_VOTE 1440

public bool:g_bVoting;

new g_pVoteDelay;
new g_pVotePercent;
new g_pMapVoteEnabled;
new g_pMapVote;
new g_pSameMap;
new g_pShowScores;
new g_pTeamEnforcement;
new g_pKnifeRound;
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
	PUG_VOTE = 0,
	PUG_CAPTAINS,
	PUG_AUTO,
	PUG_NONE,
	PUG_SKILL
};

new g_sTeamTypes[TEAMS][32];
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

#if defined _PugKnifeRound_included
	register_dictionary("PugKnifeRound.txt");
#endif

	g_pVoteDelay = create_cvar("pug_vote_delay","15.0",FCVAR_NONE,"How long voting session goes on");
	g_pVotePercent = create_cvar("pug_vote_percent","0.4",FCVAR_NONE,"Difference between votes to determine a winner");
	g_pMapVoteEnabled = create_cvar("pug_vote_map_enabled","1",FCVAR_NONE,"Active vote map in pug");
	g_pMapVote = create_cvar("pug_vote_map","1",FCVAR_NONE,"Determine if current map will have the vote map (Not used at Pug config file)");
	g_pSameMap = create_cvar("pug_vote_map_same","0",FCVAR_NONE,"Add the current map at vote map menu");
	g_pShowScores = create_cvar("pug_show_scores","0",FCVAR_NONE,"Show scores after vote maps");
	g_pTeamEnforcement = create_cvar("pug_teams_enforcement","0",FCVAR_NONE,"The teams method for assign teams (0 = Vote, 1 = Captains, 2 = Automatic, 3 = None, 4 = Skill)");
	g_pKnifeRound = create_cvar("pug_teams_kniferound","1",FCVAR_NONE,"Force a Knife Round after choose teams");
	g_pShowVotes = create_cvar("pug_show_votes","2",FCVAR_NONE,"Method to show votes results (1 = Chat, 2 = Hudmessage)");
	g_pHLDSVotes = create_cvar("pug_hlds_votes","0",FCVAR_NONE,"Allow HLDS native votes commands as vote and votemap");
	g_pVoteKickPercent = create_cvar("pug_vote_kick_percent","60.0",FCVAR_NONE,"Percentage to kick an player using Vote Kick");
	g_pVoteKickTeams = create_cvar("pug_vote_kick_teams","1",FCVAR_NONE,"Vote Kick only for teammates");
	
	g_pMapCycle = get_cvar_pointer("mapcyclefile");
	
	g_iMenuMap = menu_create("Map:","PugVoteMapHandle");
	
	menu_setprop(g_iMenuMap,MPROP_EXIT,MEXIT_NEVER);
	
	register_clcmd("vote","PugHLDSVote");
	register_clcmd("votemap","PugHLDSVote");
	
	PugRegisterCommand("votekick","PugVoteKick",ADMIN_ALL,"PUG_DESC_VOTEKICK");

	PugRegisterAdminCommand("votemap","PugCommandVoteMap",PUG_CMD_LVL,"PUG_DESC_VOTEMAP");
	PugRegisterAdminCommand("voteteams","PugCommandVoteTeam",PUG_CMD_LVL,"PUG_DESC_VOTE_TEAMS");
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
		new sTeam[13];
		get_user_team(id,sTeam,charsmax(sTeam));
		
		get_players(g_iPlayers,g_iNum,get_pcvar_num(g_pVoteKickTeams) ? "he" : "h",sTeam);
		
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
		
		new iSameMap = get_pcvar_num(g_pSameMap);
		
		while(!feof(iFile) && (g_iMapCount < PUG_MAXMAPS))
		{
			fgets(iFile,sMap,charsmax(sMap));
			trim(sMap);
			
			if((sMap[0] != ';') && is_map_valid(sMap))
			{
				if(!iSameMap && equali(sMap,sCurrent)) continue;
				
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

public PugEventWarmup()
{
	g_iMenuTeams = menu_create("Teams:","PugVoteTeamHandle");
	
	format(g_sTeamTypes[PUG_VOTE],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_VOTE");
	format(g_sTeamTypes[PUG_CAPTAINS],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_CAPTAIN");
	format(g_sTeamTypes[PUG_AUTO],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_AUTO");
	format(g_sTeamTypes[PUG_NONE],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_NONE");
	format(g_sTeamTypes[PUG_SKILL],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_SKILL");
	
	menu_additem(g_iMenuTeams,g_sTeamTypes[PUG_CAPTAINS],"1");
	menu_additem(g_iMenuTeams,g_sTeamTypes[PUG_AUTO],"2");
	menu_additem(g_iMenuTeams,g_sTeamTypes[PUG_NONE],"3");
	menu_additem(g_iMenuTeams,g_sTeamTypes[PUG_SKILL],"4");
	
	menu_setprop(g_iMenuTeams,MPROP_EXIT,MEXIT_NEVER);
}

public PugEventStart()
{
	if(get_pcvar_num(g_pMapVoteEnabled) && get_pcvar_num(g_pMapVote))
	{
		PugStartMapVote();
	}
	else
	{
		new iTeamEnforcement = get_pcvar_num(g_pTeamEnforcement);
		
		if(iTeamEnforcement == PUG_VOTE)
		{
			PugStartTeamVote();
		}
		else
		{
			PugChangeTeams(iTeamEnforcement);
		}
	}
}

public PugEventEnd()
{
	set_pcvar_num(g_pTeamEnforcement,0);
	
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
		set_task(fDelay,"PugStartMapVote",PUG_TASK_VOTE + g_iMenuMap);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iMapVotes,0,sizeof(g_iMapVotes));
	
	PugDisplayMenuAll(g_iMenuMap);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_START");
	
	set_task(fDelay,"PugVoteMapEnd",PUG_TASK_VOTE + g_iMenuMap);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		PugVotesListMap(99.0);
	}
	
	return PLUGIN_HANDLED;
}

public PugVotesListMap(Float:fHoldTime)
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_MAP");
	
	new sResult[256];
	
	for(new x;x < g_iMapCount;++x)
	{
		if(g_iMapVotes[x])
		{
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
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,fHoldTime,0.0,0.0,4);
	
	if(sResult[0])
	{
		show_hudmessage(0,sResult);
	}
	else
	{
		show_hudmessage(0,"%L",LANG_SERVER,"PUG_NOVOTES");
	}
		
}

public PugVoteMapHandle(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey,iAccess,sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
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
			PugVotesListMap(99.0);
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
	remove_task(PUG_TASK_VOTE + g_iMenuMap);
	
	PugVotesListMap(99.0);
	
	if(!PugVoteMapCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"PugStartMapVote",PUG_TASK_VOTE + g_iMenuMap);
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

	g_bVoting = false;
	set_pcvar_num(g_pMapVote,0);
	
	new sMap[32];
	get_mapname(sMap,charsmax(sMap));
	
	if(!equali(sMap,g_sMapNames[iWinner]))
	{
		if(get_pcvar_num(g_pShowScores))
		{
			message_begin(MSG_ALL,SVC_INTERMISSION);
			message_end();
		}
	
		set_task(5.0,"PugChangeMap",iWinner);
	}
	else
	{
		set_task(3.0,"PugStartTeamVote");
	}
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_NEXTMAP",g_sMapNames[iWinner]);
	
	return PLUGIN_HANDLED;
}

public PugChangeMap(iMap)
{
	engine_changelevel(g_sMapNames[iMap]);
}

public PugStartTeamVote()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"PugStartTeamVote",PUG_TASK_VOTE + g_iMenuTeams);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iTeamVotes,0,sizeof(g_iTeamVotes));
	
	PugDisplayMenuAll(g_iMenuTeams);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMVOTE_START");
	
	set_task(fDelay,"PugVoteTeamEnd",PUG_TASK_VOTE + g_iMenuTeams);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		PugVotesListTeams(99.0);
	}
	
	return PLUGIN_HANDLED;
}

public PugVotesListTeams(Float:fHoldTime)
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_TEAM");
	
	new sResult[128];
	
	for(new x;x < TEAMS;++x)
	{
		if(g_iTeamVotes[x])
		{
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
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,fHoldTime,0.0,0.0,4);
	
	if(sResult[0])
	{
		show_hudmessage(0,sResult);
	}
	else
	{
		show_hudmessage(0,"%L",LANG_SERVER,"PUG_NOVOTES");
	}
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
			PugVotesListTeams(99.0);
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
	remove_task(PUG_TASK_VOTE + g_iMenuTeams);
	PugVotesListTeams(99.0);
	
	if(!PugVoteTeamCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"PugStartTeamVote",PUG_TASK_VOTE + g_iMenuTeams);
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

public PugChangeTeams(iWinner)
{
	switch(iWinner)
	{
		case PUG_CAPTAINS:
		{
#if defined _PugCaptains_included
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_START");
			PugTeamsCaptains();
#else
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_NONE");
			
			PugContinue();
#endif
		}
		case PUG_AUTO:
		{
			PugTeamsRandomize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_RANDOM");
			
			PugContinue();
		}
		case PUG_NONE:
		{
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SAME");
			
			PugContinue();
		}
		case PUG_SKILL:
		{
			PugTeamsOptmize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SKILL");
			
			PugContinue();
		}
	}
}

public PugContinue()
{
	if(get_pcvar_num(g_pKnifeRound))
	{
		PugKnifeRound();
	}
	else
	{
		PugFirstHalf();
	}
}

public PugEventFirstHalf(iStage)
{
	if(get_pcvar_num(g_pKnifeRound))
	{
		for(new i = 1;i < PugNumTeams();i++)
		{
			PugSetTeamScore(i,0);
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
		PugAdminCommand(id,"the Vote Map","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartMapVote());
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
		PugAdminCommand(id,"teams choose","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartTeamVote());
	}
	
	return PLUGIN_HANDLED;
}
