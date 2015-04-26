#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#include <PugConst>
#include <PugCS>
#include <PugForwards>

new bool:g_bWarmup;

public plugin_init()
{
	register_plugin("Pug MOD (Warmup)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_forward(FM_SetModel,"PugFwSetModel",true);
	register_forward(FM_CVarGetFloat,"PugFwGetCvar",false);
	
	register_message(get_user_msgid("Money"),"PugMessageMoney");
}

public PugEventWarmup()
{
	PugMapObjectives(1);
	g_bWarmup = true;
}

public PugEventFirstHalf()
{
	PugMapObjectives(0);
	g_bWarmup = false;
}

public PugEventHalfTime()
{
	PugMapObjectives(1);
	g_bWarmup = true;
}

public PugEventSecondHalf()
{
	PugMapObjectives(0);
	g_bWarmup = false;
}

public PugEventOvertime()
{
	PugMapObjectives(0);
	g_bWarmup = false;
}

public PugFwSetModel(iEntity)
{
	if(g_bWarmup)
	{
		if(pev_valid(iEntity))
		{
			new sClassName[10];
			pev(iEntity,pev_classname,sClassName,charsmax(sClassName));
			
			if(equal(sClassName,"weaponbox"))
			{
				set_pev(iEntity,pev_nextthink,get_gametime() + 0.1);
			}
		}
	}
}

public PugFwGetCvar(const sCvar[])
{
	if(g_bWarmup)
	{
		if(equal(sCvar,"mp_buytime"))
		{
			forward_return(FMV_FLOAT,99999.0);
		
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public PugMessageMoney(iMsg,iMsgDest,id)
{
	if(g_bWarmup)
	{
		if(is_user_alive(id))
		{
			PugSetMoney(id,16000,0);
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PugPlayerKilled(id)
{
	if(g_bWarmup)
	{
		set_task(0.75,"PugRespawnPlayer",id);
	}
}

public PugRespawnPlayer(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && PugIsTeam(id))
	{
		PugRespawn(id);
		PugSetGodMode(id,1);
		
		set_task(3.0,"PugUnProtect",id);
	}
}

public PugUnProtect(id)
{
	if(is_user_alive(id))
	{
		PugSetGodMode(id,0);
	}
}

public PugPlayerJoined(id,iTeam)
{
	if(g_bWarmup)
	{
		set_task(0.75,"PugRespawnClient",id);
	}
}
