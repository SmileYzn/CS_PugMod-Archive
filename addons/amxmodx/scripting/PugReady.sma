#include <amxmodx>
#include <amxmisc>
#include <time>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugNatives>
#include <PugCS>

#pragma semicolon 1

#define TASK_AUTO 1901

new bool:g_bReadySystem;
new bool:g_bReady[MAX_PLAYERS+1];

new g_pAutoReadyTime;
new g_pAutoReadyKick;
new g_pAutoStartHalf;

new g_pPlayersMin;
new g_pRoundsMax;
new g_pHandleTime;

public plugin_init()
{
	register_plugin("Pug Mod (Ready System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);

	register_dictionary("PugCore.txt");
	register_dictionary("PugReady.txt");
	register_dictionary("time.txt");
	
	g_pAutoReadyTime = create_cvar("pug_force_ready_time","0.0",FCVAR_NONE,"Force a player to be ready in that time (If zero, this function will be inactive)");
	g_pAutoReadyKick = create_cvar("pug_force_ready_kick","0",FCVAR_NONE,"Kick Un-Ready players (If zero, the players will be put as ready automatically)");
	g_pAutoStartHalf = create_cvar("pug_force_auto_swap","1",FCVAR_NONE,"Auto Swap teams without Ready-System if the teams are complete");
	
	g_pPlayersMin	= get_cvar_pointer("pug_players_min");
	g_pRoundsMax	= get_cvar_pointer("pug_rounds_max");
	g_pHandleTime	= get_cvar_pointer("pug_intermission_time");
	
	PugRegisterCommand("ready","fnReadyUp",ADMIN_ALL,"PUG_DESC_READY");
	PugRegisterCommand("notready","fnReadyDown",ADMIN_ALL,"PUG_DESC_NOTREADY");
	
	PugRegisterAdminCommand("forceready","fnForceReady",PUG_CMD_LVL,"PUG_DESC_FORCEREADY");
	
	register_event("ResetHUD","fnKeepMenu","b");
	
	hook_cvar_change(g_pPlayersMin,"fnKeepMenu");
	hook_cvar_change(get_cvar_pointer("amx_language"),"fnKeepMenu");
}

public client_disconnected(id,bool:bDrop,szMessage[],iLen)
{
	if(task_exists(id + TASK_AUTO))
	{
		remove_task(id + TASK_AUTO);
	}
	
	if(g_bReadySystem)
	{
		set_task(0.1,"fnKeepMenu");
	}
}

public client_infochanged(id)
{
	if(g_bReadySystem)
	{
		set_task(0.1,"fnKeepMenu");
	}
}

public PugPlayerJoined(id,CsTeams:iTeam)
{
	if(g_bReadySystem)
	{
		g_bReady[id] = false;
		
		new Float:fReadyTime = get_pcvar_float(g_pAutoReadyTime);
		
		if(fReadyTime && !is_user_bot(id))
		{
			set_task(fReadyTime,"fnReadyTimeOut",id + TASK_AUTO);
			
			new sTime[32];
			get_time_length(id,floatround(fReadyTime),timeunit_seconds,sTime,charsmax(sTime));
	
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,get_pcvar_num(g_pAutoReadyKick) ? "PUG_SAY_READY_KICK" : "PUG_SAY_READY_AUTO",sTime);
		}
		
		fnKeepMenu();
	}
}

public PugEventWarmup()
{
	fnReadySystem(true);
}

public PugEventStart()
{
	if(g_bReadySystem)
	{
		fnReadySystem(false);
	}
}

public PugEventHalfTime()
{
	if(get_pcvar_num(g_pAutoStartHalf) && (PugGetPlayers(1) >= get_pcvar_num(g_pPlayersMin)))
	{
		arrayset(g_bReady,true,sizeof(g_bReady));
		set_task(get_pcvar_float(g_pHandleTime),"fnCheckReady",TASK_AUTO);
	}
	else
	{
		fnReadySystem(true);
	}
}

public PugEventSecondHalf()
{
	if(g_bReadySystem)
	{
		fnReadySystem(false);
	}
}

public PugEventOvertime()
{
	if(g_bReadySystem)
	{
		fnReadySystem(false);
	}
}

fnReadySystem(bool:bActive)
{
	g_bReadySystem = bActive;
	
	if(g_bReadySystem)
	{
		fnKeepMenu();
		arrayset(g_bReady,0,sizeof(g_bReady));
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_SAY_READY");
	}
	else
	{
		fnDisplay(0.0);
		arrayset(g_bReady,0,sizeof(g_bReady));
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_ALL_READY");
	}
}

public fnKeepMenu()
{
	if(g_bReadySystem)
	{
		fnDisplay(999.0);
	}
}

fnDisplay(Float:fHoldTime)
{
	new iPlayers[MAX_PLAYERS],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	new iPlayersNum,iReadys;
	new sList[2][512],sName[MAX_NAME_LENGTH];
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		if(!PugIsTeam(iPlayer))
		{
			continue;
		}
	
		iPlayersNum++;
		get_user_name(iPlayer,sName,charsmax(sName));

		if(g_bReady[iPlayer])
		{
			iReadys++;
			formatex(sList[0],charsmax(sList[]),"%s%s^n",sList[0],sName);
		}
		else
		{
			formatex(sList[1],charsmax(sList[]),"%s%s^n",sList[1],sName);
		}
	}
	
	new iMinPlayers = get_pcvar_num(g_pPlayersMin);

	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,1);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_UNREADY",(iPlayersNum - iReadys),iMinPlayers);

	set_hudmessage(0,255,0,0.58,0.02,0,0.0,fHoldTime,0.0,0.0,2);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_READY",iReadys,iMinPlayers);

	set_hudmessage(255,255,225,0.58,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"^n%s",sList[0]);

	set_hudmessage(255,255,225,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,4);
	show_hudmessage(0,"^n%s",sList[1]);
}

public fnReadyUp(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == STAGE_WARMUP) || (iStage == STAGE_HALFTIME))
	{
		if(PugIsTeam(id))
		{
			if(!g_bReady[id])
			{
				g_bReady[id] = true;
				
				if(task_exists(id + TASK_AUTO))
				{
					remove_task(id + TASK_AUTO);
				}
				
				new sName[MAX_NAME_LENGTH];
				get_user_name(id,sName,charsmax(sName));
				
				client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_READY",sName);
				
				fnCheckReady();
			}
			else
			{
				client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_READYED");
			}
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_TEAM");
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NEEDED");
	}
	
	return PLUGIN_HANDLED;
}

public fnReadyDown(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == STAGE_WARMUP) || (iStage == STAGE_HALFTIME))
	{
		if(PugIsTeam(id))
		{
			if(g_bReady[id])
			{
				g_bReady[id] = false;
				
				new Float:fReadyTime = get_pcvar_float(g_pAutoReadyTime);
				
				if(fReadyTime && get_pcvar_num(g_pAutoReadyKick))
				{
					set_task(fReadyTime,"fnReadyTimeOut",id + TASK_AUTO);
				}
				
				new sName[MAX_NAME_LENGTH];
				get_user_name(id,sName,charsmax(sName));
				
				client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_UNREADY",sName);
				
				fnCheckReady();
			}
			else
			{
				client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NOTREADY");
			}
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_TEAM");
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NEEDED");
	}
	
	return PLUGIN_HANDLED;
}

public fnForceReady(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOTALLOWED");
	}
	else
	{
		new sArg[32];
		read_argv(1,sArg,charsmax(sArg));
		
		new iPlayer = cmd_target(id,sArg,CMDTARGET_NO_BOTS);
		
		if(!iPlayer)
		{
			return PLUGIN_HANDLED;
		}
		
		PugAdminCommandClient(id,"Force .ready","PUG_FORCE_READY",iPlayer,fnReadyUp(iPlayer));
	}
	
	return PLUGIN_HANDLED;
}

public fnCheckReady()
{
	fnKeepMenu();
	
	new iReady = 0;
	
	for(new i;i < sizeof(g_bReady);i++)
	{
		if(g_bReady[i])
		{
			iReady++;
		}
	}

	if(iReady >= get_pcvar_num(g_pPlayersMin))
	{
		fnReadySystem(false);
		
		switch(GET_PUG_STAGE())
		{
			case STAGE_WARMUP:
			{
				PugStart();
			}
			case STAGE_HALFTIME:
			{
				if(GET_PUG_ROUND() <= get_pcvar_num(g_pRoundsMax))
				{
					PugSecondHalf();
				}
				else
				{
					PugOvertime();
				}
			}
		}
	}
}

public fnReadyTimeOut(id)
{
	id -= TASK_AUTO;
	
	if(g_bReadySystem && is_user_connected(id))
	{
		if(PugIsTeam(id))
		{
			if(get_pcvar_num(g_pAutoReadyKick) > 0)
			{
				new iReadyTime = get_pcvar_num(g_pAutoReadyTime);
					
				new sTime[64];
				get_time_length
				(
					id,
					iReadyTime,
					timeunit_seconds,
					sTime,
					charsmax(sTime)
				);
				
				server_cmd("kick #%i ^"%L^"",get_user_userid(id),LANG_SERVER,"PUG_FORCE_READY_KICK",sTime);
			}
			else
			{
				fnReadyUp(id);
			}
		}
	}
}
