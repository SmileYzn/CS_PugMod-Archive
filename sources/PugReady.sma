#include <amxmodx>
#include <amxmisc>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugNatives>
#include <PugCS>

#pragma semicolon 1

new bool:g_bReadySystem;
new g_bReady[33];

new g_pPlayersMin;
new g_pRoundsMax;

public plugin_init()
{
	register_plugin("Pug MOD (Ready System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("PugCore.txt");
	register_dictionary("PugReady.txt");
	
	g_pPlayersMin = get_cvar_pointer("pug_players_min");
	g_pRoundsMax = get_cvar_pointer("pug_rounds_max");
	
	PugRegisterCommand("ready","PugReadyUp",ADMIN_ALL,"Jogador esta pronto para o jogo");
	PugRegisterCommand("notready","PugReadyDown",ADMIN_ALL,"O jogador nao esta mais pronto");
	
	PugRegisterAdminCommand("forceready","PugForceReady",PUG_CMD_LVL,"<Player> - Forca o Player a ficar pronto");
	
	register_event("ResetHUD","PugKeepMenu","b");
}

public client_putinserver(id)
{
	g_bReady[id] = false;
	PugKeepMenu();
}

public client_disconnect(id)
{
	set_task(0.1,"PugKeepMenu");
}

public client_infochanged(id)
{
	set_task(0.1,"PugKeepMenu");
}

public PugEventWarmup()
{
	ReadySystem(true);
}

public PugEventStart()
{
	ReadySystem(false);
}

public PugEventFirstHalf()
{
	ReadySystem(false);
}

public PugEventHalfTime()
{
	ReadySystem(true);
}

public PugEventSecondHalf()
{
	ReadySystem(false);
}

public PugEventOvertime()
{
	ReadySystem(false);
}

ReadySystem(bool:bActive)
{
	switch(g_bReadySystem = bActive)
	{
		case true:
		{
			arrayset(g_bReady,0,sizeof(g_bReady));
			PugKeepMenu();
	
			client_print_color(0,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_SAY_READY");
		}
		case false:
		{
			PugReadyDisPlay(0.0);
			arrayset(g_bReady,0,sizeof(g_bReady));
			
			client_print_color(0,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_ALL_READY");
		}
	}
}

public PugKeepMenu()
{
	if(g_bReadySystem)
	{
		PugReadyDisPlay(9999.0);
	}
}

PugReadyDisPlay(Float:fHoldTime)
{
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	new sReady[256],sNotReady[256],sName[MAX_NAME_LENGTH];
	
	new iPlayersNum,iReadys;
	
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
			format(sReady,charsmax(sReady),"%s%s^n",sReady,sName);
		}
		else
		{
			format(sNotReady,charsmax(sNotReady),"%s%s^n",sNotReady,sName);
		}
	}
	
	new iMinPlayers = get_pcvar_num(g_pPlayersMin);

	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHoldTime,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_UNREADY",(iPlayersNum - iReadys),iMinPlayers);

	set_hudmessage(0,255,0,0.58,0.02,0,0.0,fHoldTime,0.0,0.0,2);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_READY",iReadys,iMinPlayers);

	set_hudmessage(255,255,225,0.58,0.05,0,0.0,fHoldTime,0.0,0.0,1);
	show_hudmessage(0,sReady);

	set_hudmessage(255,255,225,0.23,0.05,0,0.0,fHoldTime,0.0,0.0,4);
	show_hudmessage(0,sNotReady);
}

public PugReadyUp(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_WARMUP) || (iStage == PUG_STAGE_HALFTIME))
	{
		if(PugIsTeam(id))
		{
			if(!g_bReady[id])
			{
				g_bReady[id] = true;
				
				new sName[MAX_NAME_LENGTH];
				get_user_name(id,sName,charsmax(sName));
				
				client_print_color(0,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_READY",sName);
				
				PugKeepMenu();
				PugCheckReady();
			}
			else
			{
				client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_READYED");
			}
		}
		else
		{
			client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_TEAM");
		}
	}
	else
	{
		client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NEEDED");
	}
	
	return PLUGIN_HANDLED;
}

public PugReadyDown(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_WARMUP) || (iStage == PUG_STAGE_HALFTIME))
	{
		if(PugIsTeam(id))
		{
			if(g_bReady[id])
			{
				g_bReady[id] = false;
				
				new sName[MAX_NAME_LENGTH];
				get_user_name(id,sName,charsmax(sName));
				
				client_print_color(0,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_UNREADY",sName);
				
				PugKeepMenu();
				PugCheckReady();
			}
			else
			{
				client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NOTREADY");
			}
		}
		else
		{
			client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_TEAM");
		}
	}
	else
	{
		client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_PLAYER_NEEDED");
	}
	
	return PLUGIN_HANDLED;
}

public PugForceReady(id,iLevel)
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
		
		PugAdminCommandClient(id,"Forcar .ready","PUG_FORCE_READY",iPlayer,PugReadyUp(iPlayer));
	}
	
	return PLUGIN_HANDLED;
}

PugCheckReady()
{
	if(PugGetReadyNum() >= get_pcvar_num(g_pPlayersMin))
	{
		switch(GET_PUG_STAGE())
		{
			case PUG_STAGE_WARMUP:
			{
				PugStart();
			}
			case PUG_STAGE_HALFTIME:
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

PugGetReadyNum()
{
	new iReady = 0;
	
	for(new i;i < sizeof(g_bReady);i++)
	{
		if(g_bReady[i])
		{
			iReady++;
		}
	}
	
	return iReady;
}
