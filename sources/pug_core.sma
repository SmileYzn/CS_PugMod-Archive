#include <amxmodx>
#include <amxmisc>

#include <pug_const>
#include <pug_ready>
#include <pug_stocks>
#include <pug_forwards>
#include <pug_modspecific>

#pragma semicolon 1

public g_iStage;
public g_iStatus;
public g_iRounds;

CREATE_GEN_FORW_ID(Fw_PugStart);
CREATE_GEN_FORW_ID(Fw_PugFirstHalf);
CREATE_GEN_FORW_ID(Fw_PugIntermission);
CREATE_GEN_FORW_ID(Fw_PugSecondHalf);
CREATE_GEN_FORW_ID(Fw_PugIntermissionOT);
CREATE_GEN_FORW_ID(Fw_PugOvertime);

public PugForwardEnd;
public PugForwardFinish;

public PugForwardRoundStart;
public PugForwardRoundStartFailed;
public PugForwardRoundEnd;
public PugForwardRoundEndFailed;

new g_iRet;
new g_iTempEndHolder;

new g_iTeams;
new g_iScore[PUG_MAX_TEAMS];
new g_sTeams[PUG_MAX_TEAMS][32];

public g_pMaxRounds;
public g_pMaxOTRounds;
public g_pIntermissionTime;

public g_pMaxPlayers;
public g_pMinPlayers;

public g_pDefaultMaxPlayers;
public g_pDefaultMinPlayers;

public g_pAllowSpec;
public g_pAllowHLTV;

new g_pSvVisibleMaxPlayers;

public plugin_init()
{
	new hPlugin = register_plugin("Pug Mod Core",AMXX_VERSION_STR,"SmileY");
	
	register_dictionary("pug.txt");
	
	g_pMaxRounds = register_cvar("pug_rounds_max","30");
	g_pMaxOTRounds = register_cvar("pug_rounds_ot","6");
	g_pIntermissionTime = register_cvar("pug_intermission_time","10.0");
	
	g_pMaxPlayers = register_cvar("pug_players_max","10");
	g_pMinPlayers = register_cvar("pug_players_min","10");
	
	g_pDefaultMaxPlayers = register_cvar("pug_players_default_max","10");
	g_pDefaultMinPlayers = register_cvar("pug_players_default_min","10");
	
	g_pAllowSpec = register_cvar("pug_allow_spectators","1");
	g_pAllowHLTV = register_cvar("pug_allow_hltv","1");
	
	g_pSvVisibleMaxPlayers = get_cvar_pointer("sv_visiblemaxplayers");
	
	register_clcmd("say","PugHandleSay");
	register_clcmd("say_team","PugHandleSay");
	
	PugRegisterCommand("status","PugCommandStatus", .sInfo="Mostra o status do PUG");
	PugRegisterCommand("score","PugCommandCheckScore", .sInfo="Mostra o placar do PUG");
	PugRegisterCommand("round","PugCommandCheckRound", .sInfo="Mostra o round atual");
	
	PugRegisterAdminCommand("pause","PugCommandPause",PUG_CMD_LVL,"Pausa o PUG");
	PugRegisterAdminCommand("unpause","PugCommandUnPause",PUG_CMD_LVL,"Despausa o PUG");
	PugRegisterAdminCommand("togglepause","PugCommandTogglePause",PUG_CMD_LVL,"Altera a Pausa no PUG");
	
	PugRegisterAdminCommand("pugstart","PugCommandStart",PUG_CMD_LVL,"Forca o inicio do PUG");
	PugRegisterAdminCommand("pugstop","PugCommandStop",PUG_CMD_LVL,"Forca o fim do PUG");
	PugRegisterAdminCommand("pugreset","PugCommandReset",PUG_CMD_LVL,"Reinicia o PUG");
	
	Fw_PugStart = CreateGenForward("PugPreStart",hPlugin,get_func_id("PugStartHandler"));
	Fw_PugFirstHalf = CreateGenForward("PugFirstHalf",hPlugin,get_func_id("PugFirstHalfHandler"));
	Fw_PugIntermission = CreateGenForward("PugIntermission",hPlugin,get_func_id("PugIntermissionHandler"));
	Fw_PugSecondHalf = CreateGenForward("PugSecondHalf",hPlugin,get_func_id("PugSecondHalfHandler"));
	Fw_PugIntermissionOT = CreateGenForward("PugIntermissionOT",hPlugin,get_func_id("PugIntermissionOTHandler"));
	Fw_PugOvertime = CreateGenForward("PugOvertime",hPlugin,get_func_id("PugOvertimeHandler"));
	
	PugForwardEnd = CreateMultiForward("PugWinner",ET_CONTINUE,FP_CELL);
	PugForwardFinish = CreateMultiForward("PugFinished",ET_CONTINUE);
	
	PugForwardRoundStart = CreateMultiForward("PugRoundStart",ET_CONTINUE);
	PugForwardRoundEnd = CreateMultiForward("PugRoundEnd",ET_CONTINUE,FP_CELL);

	PugForwardRoundStartFailed = CreateMultiForward("PugRoundStartFailed",ET_CONTINUE);
	PugForwardRoundEndFailed = CreateMultiForward("PugRoundEndFailed",ET_CONTINUE);
}

public plugin_cfg() 
{
	set_pcvar_num(g_pSvVisibleMaxPlayers,get_pcvar_num(g_pMaxPlayers));

	g_iStage = PUG_STAGE_WAITING;
	g_iStatus = PUG_STATUS_DEAD;
	g_iRounds = 0;
	
	g_iTeams = 1;
	g_iTempEndHolder = -1;
	copy(g_sTeams[0],charsmax(g_sTeams),"PugMod");
	
	set_task(5.0,"PugStart");
}

public plugin_end()
{
	if((g_iStage != PUG_STAGE_END) && (g_iStatus == PUG_STATUS_LIVE))
	{
		PugEnd(0);
	}
}

public client_authorized(id)
{
	PugCheckPlayer(id);
}

public client_disconnect(id)
{
	if(PUG_STAGE_FIRSTHALF <= g_iStage <= PUG_STAGE_OVERTIME)
	{
		if(PugGetPlayers() <= PUG_MIN_PLAYERS)
		{
			PugEnd(0);
		}
	}
}

public PugCheckPlayer(id)
{
	new iHLTV = is_user_hltv(id);
	new iSpec = get_pcvar_num(g_pAllowSpec);
	new iMaxP = get_pcvar_num(g_pMaxPlayers);
	
	if(get_playersnum() >= iMaxP)
	{
		if(!iHLTV || !iSpec)
		{
			PugDisconnect(id,"%L",LANG_SERVER,"PUG_KICK_FULL");
			
			return PLUGIN_HANDLED;
		}
	}
	
	new iAllowTV = get_pcvar_num(g_pAllowHLTV);
	
	if(PugGetPlayers() >= iMaxP)
	{
		if(iHLTV && !iAllowTV)
		{
			PugDisconnect(id,"%L",LANG_SERVER,"PUG_KICK_HLTV");
			
			return PLUGIN_HANDLED;
		}
		else if(!iSpec)
		{
			PugDisconnect(id,"%L",LANG_SERVER,"PUG_KICK_SPEC");
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

PugRestoreOrder()
{
	while(PugGetPlayers() > get_pcvar_num(g_pMaxPlayers))
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
		
		PugDisconnect(iWho,"%L",LANG_SERVER,"PUG_KICK_ORDER");
	}
}

public PugHandleSay(id)
{
	new sArgs[192];
	read_args(sArgs,charsmax(sArgs));
	remove_quotes(sArgs);

	if(sArgs[0] == '.' || sArgs[0] == '!')
	{
		client_cmd(id,sArgs);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public PugStart()
{
	if(g_iStage != PUG_STAGE_WAITING)
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_DEAD)
	{
		return SetPauseCall(get_func_id("PugStart"));
	}

	g_iStage = PUG_STAGE_START;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugStart);
	
	return PLUGIN_HANDLED;
}

public PugStartHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugStartHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;
	g_iRounds = 1;

	PugMessage(0,"PUG_START");
	PugNativeReadyPlayers(get_func_id("PugStartFirstHalf"));

	return PLUGIN_HANDLED;
}

public PugStartFirstHalf()
{
	if(g_iStage != PUG_STAGE_START)
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		return SetPauseCall(get_func_id("PugStartFirstHalf"));
	}

	g_iStage = PUG_STAGE_FIRSTHALF;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugFirstHalf);
	
	return PLUGIN_HANDLED;
}

public PugFirstHalfHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugFirstHalfHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;
	PugMessage(0,"PUG_FIRST_HALF");

	return PLUGIN_HANDLED;
}

public PugStartIntermission()
{
	if(g_iStage != PUG_STAGE_FIRSTHALF)
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		return SetPauseCall(get_func_id("PugStartIntermission"));
	}

	g_iStage = PUG_STAGE_INTERMISSION;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugIntermission);
	
	return PLUGIN_HANDLED;
}

public PugIntermissionHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugIntermissionHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;

	PugMessage(0,"PUG_INTERMISSION");
	PugNativeReadyPlayers(get_func_id("PugStartSecondHalf"));

	return PLUGIN_CONTINUE;
}

public PugStartSecondHalf()
{
	if(g_iStage != PUG_STAGE_INTERMISSION)
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		return SetPauseCall(get_func_id("PugStartSecondHalf"));
	}

	g_iStage = PUG_STAGE_SECONDHALF;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugSecondHalf);
	
	return PLUGIN_HANDLED;
}

public PugSecondHalfHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugSecondHalfHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;
	
	PugMessage(0,"PUG_SECOND_HALF");

	return PLUGIN_HANDLED;
}

public PugStartIntermissionOT()
{
	if((g_iStage != PUG_STAGE_SECONDHALF) && (g_iStage != PUG_STAGE_OVERTIME))
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		return SetPauseCall(get_func_id("PugStartIntermissionOT"));
	}

	g_iStage = PUG_STAGE_INTERMISSION;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugIntermissionOT);
	
	return PLUGIN_HANDLED;
}

public PugIntermissionOTHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugIntermissionOTHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;

	PugMessage(0,"PUG_OT_INTERMISSION");
	
	PugNativeReadyPlayers(get_func_id("PugStartOvertime"));

	return PLUGIN_HANDLED;
}

public PugStartOvertime()
{
	if(g_iStage != PUG_STAGE_INTERMISSION)
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		return SetPauseCall(get_func_id("PugStartOvertime"));
	}

	g_iStage = PUG_STAGE_OVERTIME;
	g_iStatus = PUG_STATUS_WAITING;

	ExecuteGenForward(Fw_PugOvertime);
	
	return PLUGIN_HANDLED;
}

public PugOvertimeHandler()
{
	if(g_iStatus != PUG_STATUS_WAITING)
	{
		return SetPauseCall(get_func_id("PugOvertimeHandler"));
	}

	g_iStatus = PUG_STATUS_LIVE;
	
	PugMessage(0,"PUG_OVERTIME");

	return PLUGIN_HANDLED;
}

public PugStartEnd(id,iParams)
{
	PugEnd(get_param(1));
}

public PugEnd(iWinner)
{
	if((g_iStage != PUG_STAGE_FIRSTHALF) && (g_iStage != PUG_STAGE_INTERMISSION) && (g_iStage != PUG_STAGE_SECONDHALF)&& (g_iStage != PUG_STAGE_OVERTIME))
	{
		return PLUGIN_CONTINUE;
	}
	else if(g_iStatus != PUG_STATUS_LIVE)
	{
		g_iTempEndHolder = iWinner;
		
		return SetPauseCall(get_func_id("PugEnd"));
	}

	if(g_iTempEndHolder != -1)
	{
		iWinner = g_iTempEndHolder;
	}
	
	g_iTempEndHolder = -1;

	ExecuteForward(PugForwardEnd,g_iRet,iWinner);

	DisplayScores(0,"PUG_TEAM_WONALL");

	g_iStatus = PUG_STATUS_DEAD;
	g_iStage = PUG_STAGE_END;
	g_iRounds = 0;

	ExecuteForward(PugForwardFinish,g_iRet);

	set_task(get_pcvar_float(g_pIntermissionTime),"PugReset",1990 + g_pIntermissionTime);
	
	return PLUGIN_HANDLED;
}

public PugReset()
{
	g_iStage = PUG_STAGE_WAITING;
	g_iStatus = PUG_STATUS_DEAD;
	g_iRounds = 0;
	
	arrayset(g_iScore,0,sizeof(g_iScore));

	new iDefaultPlayers = get_pcvar_num(g_pDefaultMaxPlayers);
	
	if(iDefaultPlayers)
	{
		set_pcvar_num(g_pMaxPlayers,iDefaultPlayers);
		set_pcvar_num(g_pSvVisibleMaxPlayers,iDefaultPlayers);
		
		iDefaultPlayers = get_pcvar_num(g_pDefaultMinPlayers);
		
		if(iDefaultPlayers)
		{
			set_pcvar_num(g_pMinPlayers,iDefaultPlayers);
		}
	}

	PugRestoreOrder();
	
	return PugStart();
}

public PugCallRoundStart()
{
	if((g_iStage == PUG_STAGE_READY) || ((g_iStage != PUG_STAGE_FIRSTHALF) && (g_iStage != PUG_STAGE_SECONDHALF) && (g_iStage != PUG_STAGE_OVERTIME))) 
	{
		ExecuteForward(PugForwardRoundStartFailed,g_iRet);
		
		return PLUGIN_CONTINUE;
	}

	if(g_iStatus & (PUG_STATUS_UNPAUSED))
	{
		g_iStatus &= ~(PUG_STATUS_UNPAUSED);
	}

	if(g_iStatus != PUG_STATUS_LIVE)
	{
		ExecuteForward(PugForwardRoundStartFailed,g_iRet);
		
		return PLUGIN_CONTINUE;
	}

	console_print(0,"%s %L",g_sHead,LANG_SERVER,"PUG_ROUND_START",g_iRounds);
	
	PugCommandCheckScore(0);

	ExecuteForward(PugForwardRoundStart,g_iRet);
	
	return PLUGIN_HANDLED;
}

public PugCallRoundEnd(id,iParams)
{
	PugRoundend(get_param(1));
}

public PugRoundend(iWinner)
{
	if((g_iStage != PUG_STAGE_FIRSTHALF) && (g_iStage != PUG_STAGE_SECONDHALF) && (g_iStage != PUG_STAGE_OVERTIME)) 
	{
		ExecuteForward(PugForwardRoundEndFailed,g_iRet);
		
		return PLUGIN_CONTINUE;
	}
	
	if(g_iStatus != PUG_STATUS_LIVE)
	{
		if(g_iStatus & (PUG_STATUS_UNPAUSED))
		{
			g_iStatus &= ~(PUG_STATUS_UNPAUSED);
			
			PugMessage(0,"PUG_ROUND_FAIL_PAUSE");
			
			ExecuteForward(PugForwardRoundEndFailed,g_iRet);
			
			return PLUGIN_CONTINUE;
		}
	}

	g_iScore[iWinner]++;
	
	PugHandleRound();

	if(iWinner == 0)
	{
		PugMessage(0,"PUG_ROUND_FAIL_SERVER");
	}
	else 
	{
		console_print(0,"%s %L",g_sHead,LANG_SERVER,"PUG_TEAM_WON",g_iRounds,g_sTeams[iWinner]);
		
		g_iRounds++;
	}

	ExecuteForward(PugForwardRoundEnd,g_iRet,iWinner);

	return PUG_STATUS_LIVE;
}

PugHandleRound()
{
	new iTotalRounds = get_pcvar_num(g_pMaxRounds);

	switch(g_iStage)
	{
		case PUG_STAGE_FIRSTHALF:
		{
			if(g_iRounds == (iTotalRounds / 2))
			{
				PugCommandCheckScore(0);
				
				PugStartIntermission();
			}
		}
		case PUG_STAGE_SECONDHALF:
		{
			if(CheckScore(iTotalRounds / 2) || (g_iRounds >= iTotalRounds))
			{
				new iTotalWinner = PugCalcWinner();
				
				if(iTotalWinner == 0)
				{
					PugCommandCheckScore(0);
					
					PugStartIntermissionOT();
				}
				else PugEnd(iTotalWinner);
			}
		}
		case PUG_STAGE_OVERTIME:
		{
			new iOTRounds = (g_iRounds - iTotalRounds);
			new iStoreOTRounds = (get_pcvar_num(g_pMaxOTRounds));

			iOTRounds %= iStoreOTRounds;
			new iTotalRounds = (iStoreOTRounds / 2);

			if(iOTRounds == iTotalRounds )
			{
				PugCommandCheckScore(0);
				
				PugStartIntermissionOT();
			}
			else if(CheckOvertimeScore((iStoreOTRounds / 2),(iTotalRounds / 2),iStoreOTRounds) || !iOTRounds)
			{
				new iTotalWinner = PugCalcWinner();
				
				if(iTotalWinner == 0)
				{
					PugCommandCheckScore(0);
					
					PugStartIntermissionOT();
				}
				else PugEnd(iTotalWinner);
			}
		}
	}
}

PugCalcWinner()
{
	new iScoreA,iScoreB;
	new iWinner = 1,iTied = 0;
	
	for(new i = 2;i < g_iTeams;i++)
	{
		iScoreA = g_iScore[iWinner];
		iScoreB = g_iScore[i];

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

	if(iTied != 0) return PLUGIN_CONTINUE;

	return iWinner;
}

public CheckScore(iValue)
{
	for(new i = 1;i < g_iTeams;i++)
	{
		if(g_iScore[i] > iValue) return i;
	}

	return PLUGIN_CONTINUE;
}

public CheckOvertimeScore(iCheck,iSub,iModulo)
{
	new iTempScore;
	
	for(new i = 1;i < g_iTeams;i++)
	{
		iTempScore = g_iScore[i] - iSub;
		iTempScore %= iModulo;
		
		if(iTempScore > iCheck)
		{
			return i;
		}
	}

	return PLUGIN_CONTINUE;
}

public PugPauseFuncID;
public PugPausePluginID;

public PugPause()
{
	if(g_iStatus & (PUG_STATUS_UNPAUSED))
	{
		g_iStatus &= ~(PUG_STATUS_UNPAUSED);
	}

	g_iStatus |= (PUG_STATUS_PAUSED);
	
	PugPausePluginID = INVALID_PLUGIN_ID;
	PugPausePluginID = INVALID_PLUGIN_ID;
}

public PugUnPause()
{
	if(g_iStatus ^ (PUG_STATUS_PAUSED)) return;

	g_iStatus &= ~(PUG_STATUS_PAUSED);
	g_iStatus |= (PUG_STATUS_UNPAUSED);

	if(PugPauseFuncID != INVALID_PLUGIN_ID)
	{
		if(callfunc_begin_i(PugPauseFuncID,PugPausePluginID) > 0)
		{
			callfunc_end();
		}
	}
}

public PugIsPaused()
{
	return g_iStatus & (PUG_STATUS_PAUSED);
}

stock SetPauseCall(iFunction,iPlugin = INVALID_PLUGIN_ID)
{
	PugPauseFuncID = iFunction;
	PugPausePluginID = iPlugin;
	
	return PLUGIN_CONTINUE;
}

public plugin_natives()
{
	register_native("PugPause","PugPause");
	register_native("PugUnPause","PugUnPause");
	register_native("PugSetPauseCall","PugSetPauseCall");

	register_native("PugCallRoundStart","PugCallRoundStart");
	register_native("PugCallRoundEnd","PugCallRoundEnd");

	register_native("PugCallReset","PugReset");

	register_native("PugSwapTeams","SwapTeams");
	register_native("PugRegisterTeam","RegisterTeam");
	register_native("PugNumTeams","NumTeams");

	register_native("PugGetTeamName","GetTeamName");
	register_native("PugSetTeamName","SetTeamName");
	
	register_native("PugSetTeamScore","SetTeamScore");
	register_native("PugGetTeamScore","GetTeamScore");
}

public GetTeamName(id,iParams)
{
	 set_string(2,g_sTeams[get_param(1)],charsmax(g_sTeams));
}

public SetTeamName(id,iParams)
{
	get_string(2,g_sTeams[get_param(1)],charsmax(g_sTeams));
}

public NumTeams(id,iParams)
{
	return g_iTeams - 1;
}

public SwapTeams(id,iParams)
{
	new a = get_param(1);
	new b = get_param(2);

	new sTeamA[32];
	
	formatex(sTeamA,charsmax(sTeamA),"%s",g_sTeams[a]);
	formatex(g_sTeams[a],charsmax(g_sTeams[]),"%s",g_sTeams[b]);
	formatex(g_sTeams[b],charsmax(g_sTeams[]),"%s",sTeamA);
	
	new iScoreA = g_iScore[a];
	
	g_iScore[a] = g_iScore[b];
	g_iScore[b] = iScoreA;
}

public RegisterTeam(id,iParams)
{
	get_string(1,g_sTeams[g_iTeams],charsmax(g_sTeams[]));
	++g_iTeams;

	return g_iTeams - 1;
}

public SetTeamScore(id,iParams)
{
	g_iScore[get_param(1)] = get_param(2);
}

public GetTeamScore(id,iParams)
{
	return g_iScore[get_param(1)];
}

public PugSetPauseCall(id,iParams)
{
	new iPlugin = get_param(2);
	
	return SetPauseCall(get_param(1),(iPlugin == INVALID_PLUGIN_ID) ? id : iPlugin);
}

public DisplayScores(id,sMethod[])
{
	new sCurrentScore[PUG_MAX_TEAMS],iTopTeam = 0;
	new sTeam[64],sFinishedScores[PUG_MAX_TEAMS * 5];
	
	for(new i = 1;i < g_iTeams;++i)
	{
		if(g_iScore[iTopTeam] < g_iScore[i])
		{
			iTopTeam = i;
		}
		
		sCurrentScore[i] = g_iScore[i];
	}
	
	if(PugCalcWinner() == 0)
	{
		formatex(sTeam,charsmax(sTeam),"%L",LANG_SERVER,"PUG_SCORE_TIED");
	}
	else
	{
		formatex(sTeam,charsmax(sTeam),"%L",LANG_SERVER,sMethod,g_sTeams[iTopTeam]);
	}

	SortIntegers(sCurrentScore,PUG_MAX_TEAMS,Sort_Descending);

	format(sFinishedScores,(PUG_MAX_TEAMS * 5),"%i",sCurrentScore[0]);
	
	for(new i = 2;i < g_iTeams;++i)
	{
		format(sFinishedScores,(PUG_MAX_TEAMS * 5),"%s-%i",sFinishedScores,sCurrentScore[i - 1]);
	}

	client_print_color(id,print_team_grey,"^4%s^1 %s %s",g_sHead,sTeam,sFinishedScores);
	
	if(id == 0)
	{
		server_print("%s %s %s",g_sHead,sTeam,sFinishedScores);
	}
}

public PugCommandStatus(id)
{
	client_print_color
	(
		id,
		print_team_grey,
		"^4%s^1 Players: %i (Min: %i - Max: %i) (Stage: %s)",
		g_sHead,
		PugGetPlayers(),
		get_pcvar_num(g_pMinPlayers),
		get_pcvar_num(g_pMaxPlayers),
		g_sStage[g_iStage]
	);
	
	if(g_iStatus == PUG_STATUS_LIVE)
	{
		for(new i = 1;i < g_iTeams;i++)
		{
			client_print_color
			(
				id,
				print_team_grey,
				"^4%s^1 %L",
				g_sHead,
				LANG_SERVER,
				"PUG_CHECK_SCORE",
				g_sTeams[i],
				g_iScore[i]
			);
		}
	}

	return PLUGIN_HANDLED;
}

public PugCommandCheckScore(id)
{
	if(g_iStatus == PUG_STATUS_LIVE)
	{
		DisplayScores(id,"PUG_SCORE_WINNING");
	}
	else PugMessage(id,"PUG_CMD_NOTALLOWED");

	return PLUGIN_HANDLED;
}

public PugCommandCheckRound(id)
{
	if(g_iStatus == PUG_STATUS_LIVE)
	{
		if(id)
		{
			client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_CHECK_ROUND",g_iRounds);
		}
		else server_print("%s %L",g_sHead,LANG_SERVER,"PUG_CHECK_ROUND",g_iRounds);
	}
	else PugMessage(id,"PUG_CMD_NOTALLOWED");
	
	return PLUGIN_HANDLED;
}

public PugCommandPause(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"Pause","PUG_FORCE_PAUSE",PugPause());
	}

	return PLUGIN_HANDLED;
}

public PugCommandUnPause(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else PugAdminCommand(id,"Un-Pause","PUG_FORCE_UNPAUSE",PugUnPause());

	return PLUGIN_HANDLED;
}

public PugCommandTogglePause(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else PugAdminCommand(id,"Toggle Pause","PUG_FORCE_TOGGLE_PAUSE",PugIsPaused() ? PugUnPause() : PugPause());

	return PLUGIN_HANDLED;
}

public PugCommandStart(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		if(g_iStage == PUG_STAGE_READY)
		{
			g_iStage = PUG_STAGE_START;
			g_iStatus = PUG_STATUS_LIVE;
		}
		
		PugAdminCommand(id,"Start PUG","PUG_FORCE_START",PugStartFirstHalf());
	}

	return PLUGIN_HANDLED;
}

public PugCommandStop(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"Stop PUG","PUG_FORCE_END",PugEnd(PugCalcWinner()));
	}

	return PLUGIN_HANDLED;
}

public PugCommandReset(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		PugAdminCommand(id,"Pug Reset","PUG_FORCE_RESTART",PugReset());
	}

	return PLUGIN_HANDLED;
}
