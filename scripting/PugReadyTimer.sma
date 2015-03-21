#include <amxmodx>
#include <time>

#include <PugConst>
#include <PugForwards>
#include <PugNatives>
#include <PugCS>

#pragma semicolon 1

new g_pWarmupTime,g_iTimeOut;
new g_pPlayersMin;
new g_pRoundsMax;
new g_pSwitchDelay;

new bool:g_bJoined[33] = {false,...};

public plugin_init()
{
	register_plugin("Pug MOD (Timer System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("time.txt");
	
	g_pWarmupTime = create_cvar("pug_warmup_time","1.0",FCVAR_NONE,"Warmup Timeout",true,1.0,true,30.0);
	
	g_pPlayersMin = get_cvar_pointer("pug_players_min");
	g_pRoundsMax = get_cvar_pointer("pug_rounds_max");
	g_pSwitchDelay = get_cvar_pointer("pug_switch_delay");
	
	hook_cvar_change(g_pPlayersMin,"PugReadySystemConvarChange");
}

public PugEventJoinedTeam(id,iTeam)
{
	switch(GET_PUG_STAGE())
	{
		case PUG_STAGE_WARMUP,PUG_STAGE_HALFTIME:
		{
			if(PugIsTeam(id))
			{
				g_bJoined[id] = true;
				
				if(PugGetJoinedNum() >= get_pcvar_num(g_pPlayersMin))
				{
					PugTimerSystem(true);
				}
			}
		}
	}
}

public client_disconnect(id)
{
	switch(GET_PUG_STAGE())
	{
		case PUG_STAGE_WARMUP,PUG_STAGE_HALFTIME:
		{
			if(g_bJoined[id])
			{
				g_bJoined[id] = false;
				
				if(PugGetJoinedNum() < get_pcvar_num(g_pPlayersMin))
				{
					PugTimerSystem(false);
					set_task(1.0,"PugWaitMessage",181, .flags="b");
				}
			}
		}
	}
}

public PugEventWarmup()
{
	set_task(1.0,"PugWaitMessage",181, .flags="b");
}

public PugEventHalfTime()
{
	if(PugGetPlayers() >= get_pcvar_num(g_pPlayersMin))
	{
		new Float:fDelay = get_pcvar_float(g_pSwitchDelay);
		
		set_task(fDelay,"PugContinue");
	}
	else
	{
		set_task(1.0,"PugWaitMessage",181, .flags="b");
	}
}

public PugWaitMessage()
{
	new iNeed = get_pcvar_num(g_pPlayersMin) - PugGetPlayers();

	set_hudmessage(0,255,0,0.58,0.02,0,1.0,1.0,0.0,0.0,1);
	show_hudmessage(0,"Waiting more %i %s to start.",iNeed,(iNeed > 1) ? "players" : "player");
}

public PugContinue()
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

PugGetJoinedNum()
{
	new iPlayers = 0;
	
	for(new i;i < sizeof(g_bJoined);i++)
	{
		if(g_bJoined[i])
		{
			iPlayers++;
		}
	}
	
	return iPlayers;
}

PugTimerSystem(bool:bActive)
{
	if(bActive)
	{
		remove_task(181);
		
		g_iTimeOut = floatround(get_pcvar_float(g_pWarmupTime) * 60);
		
		if(g_iTimeOut)
		{
			set_task(1.0,"PugTimer",GET_PUG_STAGE(), .flags="b");
		}
	}
	else
	{
		remove_task(GET_PUG_STAGE());
	}
}

public PugTimer(iStage)
{
	g_iTimeOut--;
	
	if(g_iTimeOut > 0)
	{
		new sTime[64];
		get_time_length(LANG_SERVER,g_iTimeOut,timeunit_seconds,sTime,charsmax(sTime));

		if(g_iTimeOut > 10)
		{
			set_hudmessage(0,255,0,-1.0,0.15,0,1.0,1.0,0.0,0.0,1);
		}
		else
		{
			set_hudmessage(255,0,0,-1.0,0.15,0,1.0,1.0,0.0,0.0,1);
		}
		
		show_hudmessage(0,"%s: %s",g_sPugStage[iStage],sTime);
	}
	else
	{
		PugTimerSystem(false);
		
		PugContinue();
	}
}

public PugReadySystemConvarChange(pCvar,const Old[],const New[])
{
	switch(GET_PUG_STAGE())
	{
		case PUG_STAGE_WARMUP,PUG_STAGE_HALFTIME:
		{
			if((PugGetJoinedNum() >= str_to_num(New)) && !task_exists(GET_PUG_STAGE()))
			{
				PugTimerSystem(true);
			}
		}
	}
}
