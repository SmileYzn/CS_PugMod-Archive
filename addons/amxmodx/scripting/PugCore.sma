#include <amxmodx>
#include <amxmisc>
#include <time>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugNatives>
#include <PugCS>

#pragma semicolon 1

public g_iStage;
public g_iRound;

new g_iRoundWinner;

new g_iTeams;
new g_sTeams[PUG_MAX_TEAMS][32];
new g_iScores[PUG_MAX_TEAMS];

new g_iEventWarmup;
new g_iEventStart;
new g_iEventFirstHalf;
new g_iEventHalfTime;
new g_iEventSecondHalf;
new g_iEventOvertime;
new g_iEventEnd;

new g_iEventRoundStart;
new g_iEventRoundWinner;
new g_iEventRoundEnd;

new g_iEventReturn;

new g_pPlayersMin;
new g_pPlayersMax;
new g_pPlayersMinDefault;
new g_pPlayersMaxDefault;
new g_pRoundsMax;
new g_pRoundsOT;
new g_pAllowOT;
new g_pHandleTime;
new g_pAllowSpec;
new g_pAllowHLTV;
new g_pReconnect;

new Trie:g_tReconnect;

public plugin_init()
{
	register_plugin("Pug MOD (CORE)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("time.txt");
	register_dictionary("PugCore.txt");
	
	create_cvar("pug_version",PUG_MOD_VERSION,FCVAR_NONE,"Show the Pug Mod Version");

	g_pPlayersMin = create_cvar("pug_players_min","10",FCVAR_NONE,"Minimum of players to start a game (Not used at Pug config file)");
	g_pPlayersMax = create_cvar("pug_players_max","10",FCVAR_NONE,"Maximum of players allowed in the teams (Not used at Pug config file)");
	
	g_pPlayersMinDefault = create_cvar("pug_players_min_default","10",FCVAR_NONE,"Minimum of players to start a game (This will reset the minimum of players in every map change)");
	g_pPlayersMaxDefault = create_cvar("pug_players_max_default","10",FCVAR_NONE,"Maximum players to reset (This will reset the maximum of players in every map change)");
	
	g_pRoundsMax = create_cvar("pug_rounds_max","30",FCVAR_NONE,"Rounds to play before start Overtime");
	g_pRoundsOT = create_cvar("pug_rounds_overtime","6",FCVAR_NONE,"Rounds to play in overtime (In total)");
	g_pAllowOT = create_cvar("pug_allow_overtime","1",FCVAR_NONE,"Allow Overtime (If zero, the game can end tied)");
	
	g_pHandleTime = create_cvar("pug_intermission_time","10.0",FCVAR_NONE,"Time to reset pug after game ends");
	
	g_pAllowSpec = create_cvar("pug_allow_spectators","1",FCVAR_NONE,"Allow Spectators to join in server");
	g_pAllowHLTV = create_cvar("pug_allow_hltv","1",FCVAR_NONE,"Allow HLTV in pug");
	
	g_pReconnect = create_cvar("pug_retry_time","20.0",FCVAR_NONE,"Time to player wait before retry in server");
	
	g_tReconnect = TrieCreate();

	register_concmd("say","PugHookSay");
	register_concmd("say_team","PugHookSay");
	
	PugRegisterCommand("help","PugCommandHelp",ADMIN_ALL,"PUG_DESC_HELP");
	PugRegisterAdminCommand("help","PugCommandHelpAdmin",PUG_CMD_LVL,"PUG_DESC_HELP");
	
	PugRegisterCommand("status","PugCommandStatus",ADMIN_ALL,"PUG_DESC_STATUS");
	PugRegisterCommand("score","PugCommandScore",ADMIN_ALL,"PUG_DESC_SCORE");
	
	PugRegisterAdminCommand("pugstart","PugCommandStart",PUG_CMD_LVL,"PUG_DESC_START");
	PugRegisterAdminCommand("pugstop","PugCommandStop",PUG_CMD_LVL,"PUG_DESC_STOP");

	g_iEventWarmup = CreateMultiForward("PugEventWarmup",ET_IGNORE,FP_CELL);
	g_iEventStart = CreateMultiForward("PugEventStart",ET_IGNORE,FP_CELL);
	g_iEventFirstHalf = CreateMultiForward("PugEventFirstHalf",ET_IGNORE,FP_CELL);
	g_iEventHalfTime = CreateMultiForward("PugEventHalfTime",ET_IGNORE,FP_CELL);
	g_iEventSecondHalf = CreateMultiForward("PugEventSecondHalf",ET_IGNORE,FP_CELL);
	g_iEventOvertime = CreateMultiForward("PugEventOvertime",ET_IGNORE,FP_CELL);
	g_iEventEnd = CreateMultiForward("PugEventEnd",ET_IGNORE,FP_CELL);
	
	g_iEventRoundStart = CreateMultiForward("PugEventRoundStart",ET_IGNORE,FP_CELL);
	g_iEventRoundWinner = CreateMultiForward("PugEventRoundWinner",ET_IGNORE,FP_CELL);
	g_iEventRoundEnd = CreateMultiForward("PugEventRoundEnd",ET_IGNORE,FP_CELL);
}

public plugin_cfg()
{
	PugBuildHelpFile(ADMIN_ALL,"help.htm",".");
	PugBuildHelpFile(PUG_CMD_LVL,"admin.htm","!");
	
	PugBuildCvarsFile("cvars.htm");
	
	set_task(5.0,"CoreWarmup");
}

public plugin_end()
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		PugEnd(PugCalcWinner());
	}
	
	TrieDestroy(g_tReconnect);
}

public plugin_natives()
{
	register_library("PugNatives");
	
	register_native("PugWarmup","CoreWarmup");
	register_native("PugStart","CoreStart");
	register_native("PugFirstHalf","CoreFirstHalf");
	register_native("PugHalfTime","CoreHalfTime");
	register_native("PugSecondHalf","CoreSecondHalf");
	register_native("PugOvertime","CoreOvertime");
	register_native("PugEnd","CoreEnd");
	
	register_native("PugRegisterTeam","CoreRegisterTeam");
	register_native("PugNumTeams","CoreNumTeams");
	register_native("PugSwapTeams","CoreSwapTeams");
	
	register_native("PugGetTeamScore","CoreGetTeamScore");
	register_native("PugSetTeamScore","CoreSetTeamScore");
	
	register_native("PugGetTeamName","CoreGetTeamName");
	register_native("PugSetTeamName","CoreSetTeamName");
	
	register_native("PugRoundStart","CoreRoundStart");
	register_native("PugRoundEnd","CoreRoundEnd");
	
	register_native("PugRoundWinner","CoreRoundWinner");
}

public client_authorized(id)
{
	new iHLTV = is_user_hltv(id);
	new iAllowSpec = get_pcvar_num(g_pAllowSpec);
	
	new iPlayers[MAX_PLAYERS],iPlayersNum;
	get_players(iPlayers,iPlayersNum,"ch");
	
	if(iPlayersNum >= get_pcvar_num(g_pPlayersMax))
	{
		if(!iHLTV && !iAllowSpec)
		{
			server_cmd("kick #%i ^"%L^"",get_user_userid(id),LANG_SERVER,"PUG_KICK_FULL");
			
			return PLUGIN_CONTINUE;
		}
	}
	
	if(PugGetPlayers() >= get_pcvar_num(g_pPlayersMin))
	{
		if(!iHLTV && !iAllowSpec)
		{
			server_cmd("kick #%i ^"%L^"",get_user_userid(id),LANG_SERVER,"PUG_KICK_SPEC");
			
			return PLUGIN_CONTINUE;
		}
	}
	
	if(iHLTV && !get_pcvar_num(g_pAllowHLTV))
	{
		server_cmd("kick #%i ^"%L^"",get_user_userid(id),LANG_SERVER,"PUG_KICK_HLTV");
		
		return PLUGIN_CONTINUE;
	}
	
	new iReconnectTime = get_pcvar_num(g_pReconnect);
	
	if(iReconnectTime && !is_user_bot(id) && !iHLTV && !access(id,PUG_CMD_LVL))
	{
		new sSteam[35],iTime;
		get_user_authid(id,sSteam,charsmax(sSteam));       
	
		if(TrieGetCell(g_tReconnect,sSteam,iTime))
		{
			if(get_systime() - iTime < iReconnectTime)
			{
				new sTime[32];
				get_time_length
				(
					id,
					(iReconnectTime + iTime - get_systime()),
					timeunit_seconds,
					sTime,
					charsmax(sTime)
				);
				
				server_cmd("kick #%i ^"%L^"",get_user_userid(id),LANG_SERVER,"PUG_KICK_RETRY",sTime);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if(get_pcvar_num(g_pReconnect) && !access(id,PUG_CMD_LVL))
	{
		new sSteam[35];
		get_user_authid(id,sSteam,charsmax(sSteam));
		
		TrieSetCell(g_tReconnect,sSteam,get_systime());
	}
	
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		new iPlayersMin = get_pcvar_num(g_pPlayersMin);
		
		if(PugGetPlayers() <= (iPlayersMin / 2))
		{
			PugEnd(PugCalcWinner());
			
			return PLUGIN_CONTINUE;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PugHookSay(id)
{
	new sArgs[192];
	read_args(sArgs,charsmax(sArgs));
	remove_quotes(sArgs);
	
	if((sArgs[0] == '.') || (sArgs[0] == '!'))
	{
		client_cmd(id,sArgs,charsmax(sArgs));
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CoreWarmup()
{
	if(g_iStage == PUG_STAGE_DEAD)
	{
		g_iStage = PUG_STAGE_WARMUP;
	
		ExecuteForward(g_iEventWarmup,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventWarmup()
{
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_START");
}

public CoreStart()
{
	if(g_iStage == PUG_STAGE_WARMUP)
	{
		g_iStage = PUG_STAGE_START;
	
		ExecuteForward(g_iEventStart,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CoreFirstHalf()
{
	if(g_iStage == PUG_STAGE_START)
	{
		g_iStage = PUG_STAGE_FIRSTHALF;
	
		ExecuteForward(g_iEventFirstHalf,g_iEventReturn,g_iStage);
	
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PugEventFirstHalf()
{
	g_iRound = 1;
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_FIRSTHALF",g_sPugStage[g_iStage]);
}

public CoreHalfTime()
{
	if((g_iStage == PUG_STAGE_FIRSTHALF) || (g_iStage == PUG_STAGE_SECONDHALF) || (g_iStage == PUG_STAGE_OVERTIME))
	{
		g_iStage = PUG_STAGE_HALFTIME;
	
		ExecuteForward(g_iEventHalfTime,g_iEventReturn,g_iStage);
	
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventHalfTime()
{
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_HALFTIME",g_sPugStage[g_iStage]);
}

public CoreSecondHalf()
{
	if(g_iStage == PUG_STAGE_HALFTIME)
	{
		g_iStage = PUG_STAGE_SECONDHALF;
	
		ExecuteForward(g_iEventSecondHalf,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}

public PugEventSecondHalf()
{
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_SECONDHALF",g_sPugStage[g_iStage]);
}

public CoreOvertime()
{
	if(g_iStage == PUG_STAGE_HALFTIME)
	{
		g_iStage = PUG_STAGE_OVERTIME;
		
		ExecuteForward(g_iEventOvertime,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventOvertime()
{
	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_OVERTIME",g_sPugStage[g_iStage]);
}

public CoreEnd(id,iParms)
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		g_iStage = PUG_STAGE_FINISHED;
		
		ExecuteForward(g_iEventEnd,g_iEventReturn,get_param(1));
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventEnd(iWinner)
{
	PugDisplayScores(0,"PUG_END_WONALL");
	
	set_task(get_pcvar_float(g_pHandleTime),"PugReset",g_pHandleTime);
}

public PugReset()
{
	g_iStage = PUG_STAGE_DEAD;
	
	g_iRound = 0;
	arrayset(g_iScores,0,sizeof(g_iScores));
	
	new iDefaultPlayers = get_pcvar_num(g_pPlayersMaxDefault);
	
	if(iDefaultPlayers)
	{
		set_pcvar_num(g_pPlayersMax,iDefaultPlayers);
	}
	
	iDefaultPlayers = get_pcvar_num(g_pPlayersMinDefault);
	
	if(iDefaultPlayers)
	{
		set_pcvar_num(g_pPlayersMin,iDefaultPlayers);
	}
	
	PugRestoreOrder();
	
	return PugWarmup();
}

PugRestoreOrder()
{
	new iPlayers[MAX_PLAYERS],iPlayersNum;
	get_players(iPlayers,iPlayersNum,"ch");
	
	while(iPlayersNum > get_pcvar_num(g_pPlayersMax))
	{
		new iTest = 3600,iWho,iTime;

		new iPlayers[32],iNum,iPlayer;
		get_players(iPlayers,iNum,"ch");

		for(new i;i < iNum;i++)
		{
			iPlayer = iPlayers[i];

			if(is_user_connected(iPlayer))
			{
				iTime = get_user_time(iPlayer,1);

     				if(iTest >= iTime)
				{
					iTest = iTime;

					iWho = iPlayer;
				}
			}
		}
		
		server_cmd("kick #%i ^"%L^"",get_user_userid(iWho),LANG_SERVER,"PUG_KICK_ORDER");
	}
}

public CoreRegisterTeam(id,iParams)
{
	g_iTeams++;
	get_string(1,g_sTeams[g_iTeams],charsmax(g_sTeams[]));

	return g_iTeams;
}

public CoreNumTeams()
{
	return g_iTeams;
}

public CoreSwapTeams(id,iParams)
{
	new a = get_param(1);
	new b = get_param(2);
	
	new sTeamA[MAX_NAME_LENGTH];
	
	formatex(sTeamA,charsmax(sTeamA),"%s",g_sTeams[a]);
	formatex(g_sTeams[a],charsmax(g_sTeams[]),"%s",g_sTeams[b]);
	formatex(g_sTeams[b],charsmax(g_sTeams[]),"%s",sTeamA);
	
	new iScoreA = g_iScores[a];
	
	g_iScores[a] = g_iScores[b];
	g_iScores[b] = iScoreA;
}

public CoreGetTeamScore(id,iParams)
{
	return g_iScores[get_param(1)];
}

public CoreSetTeamScore(id,iParams)
{
	g_iScores[get_param(1)] = get_param(2);
}

public CoreGetTeamName(id,iParams)
{
	set_string(2,g_sTeams[get_param(1)],charsmax(g_sTeams[]));
}

public CoreSetTeamName(id,iParams)
{
	get_string(2,g_sTeams[get_param(1)],charsmax(g_sTeams[]));
}

public CoreRoundStart()
{
	if(PUG_STAGE_START <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		ExecuteForward(g_iEventRoundStart,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CoreRoundEnd()
{
	if(PUG_STAGE_START <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		ExecuteForward(g_iEventRoundEnd,g_iEventReturn,g_iStage);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventRoundStart()
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		PugDisplayScores(0,"PUG_SCORE_WINNING");
		
		console_print(0,"* %L",LANG_SERVER,"PUG_ROUND_START",g_iRound);
	}
}

public CoreRoundWinner(id,iParams)
{
	if(PUG_STAGE_START <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		ExecuteForward(g_iEventRoundWinner,g_iEventReturn,get_param(1));
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugEventRoundWinner(iWinner)
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		if(iWinner)
		{
			g_iRoundWinner = iWinner;
			
			console_print(0,"* %L",LANG_SERVER,"PUG_ROUND_END",g_iRound,g_sTeams[iWinner]);
		}
		else
		{
			g_iRoundWinner = 0;
			
			console_print(0,"* %L",LANG_SERVER,"PUG_ROUND_END_FAILED",g_iRound);
		}
	}
}

public PugEventRoundEnd(iStage) /* THIS IS A FIX FOR LAST ROUND PROBLEM */
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		if(g_iRoundWinner)
		{
			g_iScores[g_iRoundWinner]++;
			
			PugHandleRound();
			
			g_iRound++;
		}
	}
}

public PugHandleRound()
{
	new iRoundsTotal = get_pcvar_num(g_pRoundsMax);
	
	switch(g_iStage)
	{
		case PUG_STAGE_FIRSTHALF:
		{
			if(g_iRound == (iRoundsTotal / 2))
			{
				PugDisplayScores(0,"PUG_SCORE_WINNING");
				
				PugHalfTime();
			}
		}
		case PUG_STAGE_SECONDHALF:
		{
			if(PugCheckScore(iRoundsTotal / 2) || (g_iRound >= iRoundsTotal))
			{
				new iTotalWinner = PugCalcWinner();
				
				if(iTotalWinner)
				{
					PugEnd(iTotalWinner);
				}
				else
				{
					if(get_pcvar_num(g_pAllowOT))
					{
						PugDisplayScores(0,"PUG_SCORE_WINNING");
						PugHalfTime();
					}
					else
					{
						PugEnd(iTotalWinner);
					}
				}
			}
		}
		case PUG_STAGE_OVERTIME:
		{
			new iOTRounds = (g_iRound - iRoundsTotal);
			new iStoreOTRounds = (get_pcvar_num(g_pRoundsOT));

			iOTRounds %= iStoreOTRounds;
			new iTotalRounds = (iStoreOTRounds / 2);

			if(iOTRounds == iTotalRounds)
			{
				PugDisplayScores(0,"PUG_SCORE_WINNING");
				PugHalfTime();
			}
			else if(PugCheckOvertimeScore((iStoreOTRounds / 2),(iRoundsTotal / 2),iStoreOTRounds) || !iOTRounds)
			{
				new iTotalWinner = PugCalcWinner();
				
				if(iTotalWinner)
				{
					PugEnd(iTotalWinner);
				}
				else
				{
					PugDisplayScores(0,"PUG_SCORE_WINNING");
					PugHalfTime();
				}
			}
		}
	}
}

public PugDisplayScores(id,sMethod[])
{
	new sCurrentScore[PUG_MAX_TEAMS],iTopTeam = 0;
	new sTeam[64],sFinishedScores[PUG_MAX_TEAMS * 5];
	
	for(new i = 1;i <= g_iTeams;++i)
	{
		if(g_iScores[iTopTeam] < g_iScores[i])
		{
			iTopTeam = i;
		}
	
		sCurrentScore[i] = g_iScores[i];
	}
	
	if(PugCalcWinner())
	{
		formatex(sTeam,charsmax(sTeam),"%L",LANG_SERVER,sMethod,g_sTeams[iTopTeam]);
	}
	else
	{
		formatex(sTeam,charsmax(sTeam),"%L",LANG_SERVER,(g_iStage != PUG_STAGE_FINISHED) ? "PUG_SCORE_TIED" : "PUG_END_TIED");
	}
	
	SortIntegers(sCurrentScore,PUG_MAX_TEAMS,Sort_Descending);
	
	format(sFinishedScores,(PUG_MAX_TEAMS * 5),"%i",sCurrentScore[0]);
	
	for(new i = 1;i < g_iTeams;i++)
	{
		format(sFinishedScores,(PUG_MAX_TEAMS * 5),"%s-%i",sFinishedScores,sCurrentScore[i]);
	}
	
	client_print_color(id,print_team_red,"%s %s %s",g_sHead,sTeam,sFinishedScores);
	
	if(id == 0)
	{
		server_print("%s %s %s",g_sHead,sTeam,sFinishedScores);
	}
}

PugCalcWinner()
{
	new iWinner = 1,iTied;
	new iScoreA,iScoreB;

	for(new i = 2;i <= g_iTeams;++i)
	{
		iScoreA = g_iScores[iWinner];
		iScoreB = g_iScores[i];

		if(iScoreA == iScoreB)
		{
			iTied = 1;
		}
		else if(iScoreA < iScoreB)
		{
			iWinner = i;
			iTied = 0;
		}
	}

	if(iTied != 0)
	{
		return 0;
	}

	return iWinner;
}

PugCheckScore(iValue)
{
	for(new i = 1;i <= g_iTeams;i++)
	{
		if(g_iScores[i] > iValue)
		{
			return i;
		}
	}

	return 0;
}


PugCheckOvertimeScore(iCheck,iSub,iModulo)
{
	new iTempScore;
	
	for(new i = 1;i <= g_iTeams;i++)
	{
		iTempScore = g_iScores[i] - iSub;
		iTempScore %= iModulo;
		
		if(iTempScore > iCheck)
		{
			return i;
		}
	}

	return 0;
}

public PugCommandStatus(id)
{
	if(id)
	{
		client_print_color
		(
			id,
			print_team_red,
			"%s %L",
			g_sHead,
			LANG_SERVER,
			"PUG_CMD_STATUS",
			PugGetPlayers(),
			g_iTeams,
			get_pcvar_num(g_pPlayersMin),
			get_pcvar_num(g_pPlayersMax),
			g_sPugStage[g_iStage]
		);
	}
	else
	{
		server_print
		(
			"%s %L",
			g_sHead,
			LANG_SERVER,
			"PUG_CMD_STATUS",
			PugGetPlayers(),
			g_iTeams,
			get_pcvar_num(g_pPlayersMin),
			get_pcvar_num(g_pPlayersMax),
			g_sPugStage[g_iStage]
		);
	}

	return PLUGIN_HANDLED;
}

public PugCommandScore(id)
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		PugDisplayScores(id,"PUG_SCORE_WINNING");
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	}

	return PLUGIN_HANDLED;
}

public PugCommandHelp(id)
{
	new sDir[64];
	PugGetConfigsDir(sDir,charsmax(sDir));
	add(sDir,charsmax(sDir),"/help.htm");
	
	show_motd(id,sDir,"Comandos do PUG");
	
	return PLUGIN_HANDLED;
}

public PugCommandHelpAdmin(id,iLevel)
{
	if(access(id,PUG_CMD_LVL) && (id != 0))
	{
		new sDir[64];
		PugGetConfigsDir(sDir,charsmax(sDir));
		add(sDir,charsmax(sDir),"/admin.htm");
	
		show_motd(id,sDir,"Comandos de Administrador");
	}
	else
	{
		PugCommandHelp(id);
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandStart(id)
{
	if(access(id,PUG_CMD_LVL) && (id != 0))
	{
		new sCommand[16];
		read_argv(0,sCommand,charsmax(sCommand));
		
		PugAdminCommand(id,sCommand,"PUG_FORCE_START",PugStart());
	}
	else
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}

	return PLUGIN_HANDLED;
}

public PugCommandStop(id)
{
	if(access(id,PUG_CMD_LVL) && (id != 0))
	{	
		new sCommand[16];
		read_argv(0,sCommand,charsmax(sCommand));
		
		PugAdminCommand(id,sCommand,"PUG_FORCE_END",PugEnd(PugCalcWinner()));
	}
	else
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}

	return PLUGIN_HANDLED;
}
