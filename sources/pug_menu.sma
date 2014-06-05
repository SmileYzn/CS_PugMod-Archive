#include <amxmodx>
#include <amxmisc>

#include <pug_menu>
#include <pug_const>
#include <pug_stocks>
#include <pug_natives>
#include <pug_forwards>
#include <pug_modspecific>

#pragma semicolon 1

CREATE_GEN_FORW_ID(Fw_PugFirstHalf);

#include <pug_captains>

public bool:g_bVoting;

public g_iMenuMap;
public g_iMenuTeam;

new g_bMapNoSwitch;

public g_pVoteDelay;
public g_pVotePercent;
public g_pMapVoteEnabled;
public g_pMapVote;
public g_pShowScores;

#define PUG_MAX_MAPS 16

new g_iMapVotes[PUG_MAX_MAPS];
new g_sMapNames[PUG_MAX_MAPS][32];
new g_iMapCount;

new g_iTeamVotes[5];

new g_pMapCycleFile;

public plugin_init()
{
	register_plugin("Pug Mod Menu",AMXX_VERSION_STR,"SmileY");
	
	register_dictionary("pug.txt");
	register_dictionary("pug_vote.txt");
	
	g_pVoteDelay = register_cvar("pug_vote_delay","15.0");
	g_pVotePercent = register_cvar("pug_vote_percent","0.7");
	g_pMapVoteEnabled = register_cvar("pug_vote_map_enabled","1");
	g_pMapVote = register_cvar("pug_vote_map","1");
	g_pShowScores = register_cvar("pug_show_scores","1");
	
	PugRegisterAdminCommand("votemap","PugCommandVoteMap",PUG_CMD_LVL,"Vote Map");
	PugRegisterAdminCommand("voteteams","PugCommandVoteTeam",PUG_CMD_LVL,"Modo de jogo");
	
	g_pMapCycleFile = get_cvar_pointer("mapcyclefile");
	
	g_iMenuMap = menu_create("Vote Map:","PugVoteMapHandle",1);
	menu_setprop(g_iMenuMap,MPROP_EXIT,MEXIT_NEVER);
	
	g_iMenuTeam = menu_create("Modo de jogo:","PugVoteTeamHandle",1);
	
	menu_additem(g_iMenuTeam,"Sem sorteio","1");
	menu_additem(g_iMenuTeam,"Skill","2");
	menu_additem(g_iMenuTeam,"Capitaes","3");
	menu_additem(g_iMenuTeam,"Automatico","4");
	
	menu_setprop(g_iMenuTeam,MPROP_EXIT,MEXIT_NEVER);
}

public plugin_cfg()
{
	new sPatch[64];
	PugGetConfigsDir(sPatch,charsmax(sPatch));

	format(sPatch,charsmax(sPatch),"%s/maps.ini",sPatch);

	if(!PugLoadMaps(sPatch))
	{
		get_pcvar_string(g_pMapCycleFile,sPatch,charsmax(sPatch));
		
		PugLoadMaps(sPatch);
	}
}

public PugFirstHalf(GEN_FORW_ID(iForward))
{
	Fw_PugFirstHalf = iForward;

	if(get_pcvar_num(g_pMapVoteEnabled) && get_pcvar_num(g_pMapVote))
	{
		PugStartVoteMap();
	}
	else
	{
		PugStartVoteTeam();
	}

	return PLUGIN_HANDLED;
}

public PugFinished()
{
	if(!g_bMapNoSwitch) set_pcvar_num(g_pMapVoteEnabled,1);
}

public PugLoadMaps(const sPatch[])
{
	if(file_exists(sPatch))
	{
		new iFile = fopen(sPatch,"rb");
		
		new sMap[32],iNum[10];
	
		new sCurrent[32];
		get_mapname(sCurrent,charsmax(sCurrent));
		
		while(!feof(iFile) && (g_iMapCount < PUG_MAX_MAPS))
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

public PugStartVoteMap()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"PugStartVoteMap",1990 + g_iMenuMap);
		
		return PLUGIN_CONTINUE;
	}

	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iMapVotes,0,sizeof(g_iMapVotes));
	
	PugDisplayMenuAll(g_iMenuMap);

	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTE_START","do mapa");
	
	set_task(fDelay,"PugVoteMapEnd",1990 + g_iMenuMap);
	
	return PLUGIN_HANDLED;
}

public PugVoteMapHandle(id,iMenu,iKey)
{
	if(iKey < 0)
	{
		return PLUGIN_HANDLED;
	}
 
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey, iAccess, sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
	g_iMapVotes[str_to_num(sCommand)]++;

	new sName[32];
	get_user_name(id,sName,charsmax(sName));
		
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTED_FOR",sName,sOption);

	g_bVoted[id] = true;
	
	if(PugShoudStopVote()) PugVoteMapEnd();
 
	return PLUGIN_HANDLED;
}

public PugVoteMapEnd()
{
	PugCancelMenu();

	g_bVoting = false;
	remove_task(1990 + g_iMenuMap);

	if(PugVoteMapCount())
	{
		PugStartVoteTeam();
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
		return PugMessage(0,"PUG_VOTE_FAILED_NOVOTES");
	}

	new Float:fTemp = float(PugGetPlayers()) * get_pcvar_float(g_pVotePercent);
	
	if(g_iMapVotes[iWinner] < floatround(fTemp,floatround_floor))
	{
		return PugMessage(0,"PUG_VOTE_FAILED_INSUF_VOTES");
	}

	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTE_WON",g_sMapNames[iWinner]);

	g_bVoting = false;
	g_bMapNoSwitch = true;
	
	set_pcvar_num(g_pMapVoteEnabled,0);

	if(get_pcvar_num(g_pShowScores))
	{
		message_begin(MSG_ALL,SVC_INTERMISSION);
		message_end();
	}

	set_task(5.0,"PugChangeMap",iWinner);
	
	return PLUGIN_CONTINUE;
}

public PugChangeMap(iMap)
{
	server_cmd("changelevel ^"%s^"",g_sMapNames[iMap]);
}

public PugStartVoteTeam()
{
	new Float:fDelay = get_pcvar_float(g_pVoteDelay);
	
	if(g_bVoting)
	{
		set_task(fDelay,"PugStartVoteTeam",1990 + g_iMenuTeam);
		
		return PLUGIN_CONTINUE;
	}

	g_bVoting = true;
	arrayset(g_bVoted,false,sizeof(g_bVoted));
	arrayset(g_iTeamVotes,0,sizeof(g_iTeamVotes));
	
	PugDisplayMenuAll(g_iMenuTeam);

	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTE_START","dos times");

	set_task(fDelay,"PugVoteTeamEnd",1990 + g_iMenuTeam);
	
	return PLUGIN_HANDLED;
}

public PugVoteTeamHandle(id,iMenu,iKey)
{
	if(iKey < 0)
	{
		return PLUGIN_HANDLED;
	}

	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey, iAccess, sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
	g_iTeamVotes[str_to_num(sCommand)]++;

	new sName[32];
	get_user_name(id,sName,charsmax(sName));
		
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTED_FOR",sName,sOption);

	g_bVoted[id] = true;

	if(PugShoudStopVote()) PugVoteTeamEnd();
 
	return PLUGIN_HANDLED;
}

public PugVoteTeamEnd()
{
	PugCancelMenu();
	PugVoteTeamCount();

	g_bVoting = false;
	remove_task(1990 + g_iMenuTeam);
}

public PugVoteTeamCount()
{
	new iWinner,iWinnerVotes,iVotes;
	
	for(new i;i < sizeof(g_iTeamVotes);i++)
	{
		iVotes = g_iTeamVotes[i];
		
		if(iVotes >= iWinnerVotes)
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
		ContinueGenForward(Fw_PugFirstHalf);
		
		return PugMessage(0,"PUG_VOTE_FAILED_NOVOTES");
	}

	new Float:fTemp = float(PugGetPlayers()) * get_pcvar_float(g_pVotePercent);
	
	if(g_iTeamVotes[iWinner] < floatround(fTemp,floatround_floor))
	{
		ContinueGenForward(Fw_PugFirstHalf);
		
		return PugMessage(0,"PUG_VOTE_FAILED_INSUF_VOTES");
	}
	
	switch(iWinner)
	{
		case 1:
		{
			PugMessage(0,"PUG_VOTETEAM_UNSORT");
			
			ContinueGenForward(Fw_PugFirstHalf);
		}
		case 2:
		{
			PugMessage(0,"PUG_VOTETEAM_SKILLSORT");
			PugTeamsOptmize();
			
			ContinueGenForward(Fw_PugFirstHalf);
		}
		case 3:
		{
			#if defined _pug_captains_included
			PugMessage(0,"PUG_VOTETEAM_CAPTAINSORT");
			PugTeamsCaptains();
			#else
			PugMessage(0,"PUG_VOTETEAM_CAPTAINSORT_1");
			PugTeamsRandomize();
			
			ContinueGenForward(Fw_PugFirstHalf);
			#endif
		}
		case 4:
		{
			PugMessage(0,"PUG_VOTETEAM_RANDOM");
			PugTeamsRandomize();
			
			ContinueGenForward(Fw_PugFirstHalf);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PugCommandVoteMap(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else PugAdminCommand(id,"o Vote Map","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartVoteMap());

	return PLUGIN_HANDLED;
}

public PugCommandVoteTeam(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else PugAdminCommand(id,"a escolha dos times","PUG_FORCE_VOTE",(g_bVoting) ? 0 : PugStartVoteTeam());

	return PLUGIN_HANDLED;
}
