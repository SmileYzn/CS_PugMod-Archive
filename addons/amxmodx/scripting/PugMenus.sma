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

#define MAX_MAPS	32
#define PUG_TASK_VOTE	1440

new bool:g_bMenuusLoaded;
public bool:g_bVoting;

new g_pVoteDelay;
new g_pVotePercent;
new g_pMapVoteEnabled;
new g_pMapVote;
new g_pSameMap;
new g_pShowScores;
new g_pTeamEnforcement;
new g_pShowVotes;
new g_pHLDSVotes;
new g_pVoteKickPercent;
new g_pVoteKickTeams;
new g_pVoteKickPlayers;

new g_pMapCycle;

new g_iMenuMap;
new g_iMenuTeams;

new g_iMapCount;
new g_sMapNames[MAX_MAPS][32];
new g_iMapVotes[MAX_MAPS];

enum _:TEAMS
{
	BY_VOTE		= 0,
	BY_CAPTAINS	= 1,
	BY_AUTO		= 2,
	BY_NONE		= 3,
	BY_SKILL	= 4
};

new g_sTeamTypes[TEAMS][32];
new g_iTeamVotes[TEAMS];

new g_iNum;
new g_iPlayers[MAX_PLAYERS];

new g_iVotes[MAX_PLAYERS];
new g_iVoted[MAX_PLAYERS];

public plugin_init()
{
	register_plugin("Pug Mod (Vote System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("PugMenus.txt");
	
#if defined _PugCaptains_included
	register_dictionary("PugCaptains.txt");
#endif

	g_pVoteDelay		= create_cvar("pug_vote_delay","15.0",FCVAR_NONE,"How long voting session goes on");
	g_pVotePercent		= create_cvar("pug_vote_percent","0.4",FCVAR_NONE,"Difference between votes to determine a winner");
	g_pMapVoteEnabled	= create_cvar("pug_vote_map_enabled","1",FCVAR_NONE,"Active vote map in pug");
	g_pMapVote		= create_cvar("pug_vote_map","1",FCVAR_NONE,"Determine if current map will have the vote map (Not used at Pug config file)");
	g_pSameMap		= create_cvar("pug_vote_map_same","0",FCVAR_NONE,"Add the current map at vote map menu");
	g_pShowScores		= create_cvar("pug_show_scores","0",FCVAR_NONE,"Show scores after vote maps");
	g_pTeamEnforcement	= create_cvar("pug_teams_enforcement","0",FCVAR_NONE,"The teams method for assign teams (0 = Vote, 1 = Captains, 2 = Automatic, 3 = None, 4 = Skill)");
	g_pShowVotes		= create_cvar("pug_show_votes","2",FCVAR_NONE,"Method to show votes results (1 = Chat, 2 = Hudmessage)");
	g_pHLDSVotes		= create_cvar("pug_hlds_votes","0",FCVAR_NONE,"Allow HLDS native votes commands as vote and votemap");
	g_pVoteKickPercent	= create_cvar("pug_vote_kick_percent","60.0",FCVAR_NONE,"Percentage to kick an player using Vote Kick");
	g_pVoteKickTeams	= create_cvar("pug_vote_kick_teams","1",FCVAR_NONE,"Vote Kick only for teammates");
	g_pVoteKickPlayers	= create_cvar("pug_vote_kick_players","3",FCVAR_NONE,"Players needed to a Vote Kick");
	
	g_pMapCycle = get_cvar_pointer("mapcyclefile");
	
	register_clcmd("vote","HLDS_Vote");
	register_clcmd("votemap","HLDS_Vote");
	
	PugRegisterCommand("votekick","fnVoteKick",ADMIN_ALL,"PUG_DESC_VOTEKICK");

	PugRegisterAdminCommand("votemap","fnVoteMap",PUG_CMD_LVL,"PUG_DESC_VOTEMAP");
	PugRegisterAdminCommand("voteteams","fnVoteTeam",PUG_CMD_LVL,"PUG_DESC_VOTE_TEAMS");
}

public PugEventWarmup()
{
	if(g_bMenuusLoaded == false)
	{
		new sText[32];
		format(sText,charsmax(sText),"%L",LANG_SERVER,"PUG_HUD_MAP");
		
		g_iMenuMap = menu_create(sText,"fnMapMenuHandle");
		
		format(sText,charsmax(sText),"%L",LANG_SERVER,"BACK");
		menu_setprop(g_iMenuMap,MPROP_BACKNAME,sText);
		
		format(sText,charsmax(sText),"%L",LANG_SERVER,"MORE");
		menu_setprop(g_iMenuMap,MPROP_NEXTNAME,sText);
		
		format(sText,charsmax(sText),"%L",LANG_SERVER,"EXIT");
		menu_setprop(g_iMenuMap,MPROP_EXITNAME,sText);
		
		menu_setprop(g_iMenuMap,MPROP_EXIT,MEXIT_NEVER);
		
		format(sText,charsmax(sText),"%L",LANG_SERVER,"PUG_HUD_TEAM");
		
		g_iMenuTeams = menu_create(sText,"MenuVoteTeamHandle");
		
		format(g_sTeamTypes[BY_VOTE],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_VOTE");
		format(g_sTeamTypes[BY_CAPTAINS],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_CAPTAIN");
		format(g_sTeamTypes[BY_AUTO],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_AUTO");
		format(g_sTeamTypes[BY_NONE],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_NONE");
		format(g_sTeamTypes[BY_SKILL],charsmax(g_sTeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_SKILL");
		
		menu_additem(g_iMenuTeams,g_sTeamTypes[BY_CAPTAINS],"1");
		menu_additem(g_iMenuTeams,g_sTeamTypes[BY_AUTO],"2");
		menu_additem(g_iMenuTeams,g_sTeamTypes[BY_NONE],"3");
		menu_additem(g_iMenuTeams,g_sTeamTypes[BY_SKILL],"4");
		
		menu_setprop(g_iMenuTeams,MPROP_EXIT,MEXIT_NEVER);
		
		new sPatch[40];
		PugGetConfigsDir(sPatch,charsmax(sPatch));
	
		format(sPatch,charsmax(sPatch),"%s/maps.ini",sPatch);
	
		if(!fnLoadMaps(sPatch))
		{
			get_pcvar_string(g_pMapCycle,sPatch,charsmax(sPatch));
			
			fnLoadMaps(sPatch);
		}
		
		g_bMenuusLoaded = true;
	}
}

public client_disconnected(id,bool:bDrop,szMessage[],iLen)
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

fnLoadMaps(const sPatch[])
{	
	if(file_exists(sPatch))
	{
		new iFile = fopen(sPatch,"rb");
		
		new sMap[32],iNum[10];
	
		new sCurrent[32];
		get_mapname(sCurrent,charsmax(sCurrent));
		
		new iSameMap = get_pcvar_num(g_pSameMap);
		
		while(!feof(iFile) && (g_iMapCount < MAX_MAPS))
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

public PugEventStart()
{
	if(get_pcvar_num(g_pMapVoteEnabled) && get_pcvar_num(g_pMapVote))
	{
		fnStartMapVote();
	}
	else
	{
		new iEnforcement = get_pcvar_num(g_pTeamEnforcement);
		
		if(iEnforcement == BY_VOTE)
		{
			fnStartTeamVote();
		}
		else
		{
			PugChangeTeams(iEnforcement);
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

public fnStartMapVote()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"fnStartMapVote",PUG_TASK_VOTE + g_iMenuMap);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_iMapVotes,0,sizeof(g_iMapVotes));

	PugDisplayMenuAll(g_iMenuMap);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_START");
	
	set_task(fDelay,"fnVoteMapEnd",PUG_TASK_VOTE + g_iMenuMap);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		fnVoteListMap(99.0);
	}
	
	return PLUGIN_HANDLED;
}

fnVoteListMap(Float:fHoldTime)
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_MAP");
	
	new sResult[256];
	
	for(new x;x < g_iMapCount;++x)
	{
		if(g_iMapVotes[x])
		{
			format(sResult,charsmax(sResult),"%s[%i] %s^n",sResult,g_iMapVotes[x],g_sMapNames[x]);
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

public fnMapMenuHandle(id,iMenu,iKey)
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
			fnVoteListMap(99.0);
		}
	}
	
	if(PugShoudStopVote())
	{
		fnVoteMapEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public fnVoteMapEnd()
{
	PugCancelMenu();

	g_bVoting = false;
	remove_task(PUG_TASK_VOTE + g_iMenuMap);
	
	fnVoteListMap(99.0);
	
	if(!fnVoteMapCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"fnStartMapVote",PUG_TASK_VOTE + g_iMenuMap);
	}
}

fnVoteMapCount()
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

	new Float:fTemp = float(PugGetPlayers(0)) * get_pcvar_float(g_pVotePercent);
	
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
	
		set_task(5.0,"fnChangeMap",iWinner);
	}
	else
	{
		set_task(3.0,"fnStartTeamVote");
	}
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEMAP_NEXTMAP",g_sMapNames[iWinner]);
	
	return PLUGIN_HANDLED;
}

public fnChangeMap(iMap)
{
	engine_changelevel(g_sMapNames[iMap]);
}

public fnStartTeamVote()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"fnStartTeamVote",PUG_TASK_VOTE + g_iMenuTeams);
	
		return PLUGIN_CONTINUE;
	}
	
	g_bVoting = true;
	arrayset(g_iTeamVotes,0,sizeof(g_iTeamVotes));

	PugDisplayMenuAll(g_iMenuTeams);
	
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMVOTE_START");
	
	set_task(fDelay,"fnVoteTeamEnd",PUG_TASK_VOTE + g_iMenuTeams);
	
	if(get_pcvar_num(g_pShowVotes) == 2)
	{
		fnVotesListTeams(99.0);
	}
	
	return PLUGIN_HANDLED;
}

public fnVotesListTeams(Float:fHoldTime)
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_TEAM");
	
	new sResult[128];
	
	for(new x;x < TEAMS;++x)
	{
		if(g_iTeamVotes[x])
		{
			format(sResult,charsmax(sResult),"%s[%i] %s^n",sResult,g_iTeamVotes[x],g_sTeamTypes[x]);
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

public MenuVoteTeamHandle(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey,iAccess,sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
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
			fnVotesListTeams(99.0);
		}
	}
	
	if(PugShoudStopVote())
	{
		fnVoteTeamEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public fnVoteTeamEnd()
{
	PugCancelMenu();

	g_bVoting = false;
	remove_task(PUG_TASK_VOTE + g_iMenuTeams);
	fnVotesListTeams(99.0);
	
	if(!fnTeamVoteCount())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"fnStartTeamVote",PUG_TASK_VOTE + g_iMenuTeams);
	}
}

public fnTeamVoteCount()
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

	new Float:fTemp = float(PugGetPlayers(0)) * get_pcvar_float(g_pVotePercent);
	
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
		case BY_CAPTAINS:
		{
#if defined _PugCaptains_included
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_START");
			PugTeamsCaptains();
#else
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS");
			
			PugFirstHalf();
#endif
		}
		case BY_AUTO:
		{
			PugTeamsRandomize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_RANDOM");
			
			PugFirstHalf();
		}
		case BY_NONE:
		{
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SAME");
			
			PugFirstHalf();
		}
		case BY_SKILL:
		{
			PugTeamsOptmize();
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAMS_SKILL");
			
			PugFirstHalf();
		}
	}
}

public HLDS_Vote(id)
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

public fnVoteKick(id)
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
		
		if(g_iNum < get_pcvar_num(g_pVoteKickPlayers))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTEKICK_PLAYERS");
		}
		else
		{
			new iPlayer,sName[MAX_NAME_LENGTH + 8],sTemp[4];
			new iMenuKick = menu_create("Players:","fnvoteKickHandle");
			
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

public fnvoteKickHandle(id,iMenu,iKey)
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

public fnVoteMap(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"the Vote Map","PUG_FORCE_VOTE",(g_bVoting) ? 0 : fnStartMapVote());
	}
	
	return PLUGIN_HANDLED;
}

public fnVoteTeam(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"teams choose","PUG_FORCE_VOTE",(g_bVoting) ? 0 : fnStartTeamVote());
	}
	
	return PLUGIN_HANDLED;
}
