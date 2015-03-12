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
	
	register_event("StatusIcon","PugStatusIcon","be","2=buyzone");
	
	RegisterHamPlayer(Ham_Killed,"PugHamKilledPost",true);
}

public PugEventWarmup()
{
	PugRemoveC4(1);
	g_bWarmup = true;
}

public PugEventFirstHalf()
{
	PugRemoveC4(0);
	g_bWarmup = false;
}

public PugEventHalfTime()
{
	PugRemoveC4(1);
	g_bWarmup = true;
}

public PugEventSecondHalf()
{
	PugRemoveC4(0);
	g_bWarmup = false;
}

public PugEventOvertime()
{
	PugRemoveC4(0);
	g_bWarmup = false;
}

public PugFwSetModel(iEntity)
{
	if(g_bWarmup)
	{
		if(pev_valid(iEntity))
		{
			new sClassname[10];
			pev(iEntity,pev_classname,sClassname,charsmax(sClassname));
			
			if(equal(sClassname,"weaponbox"))
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

public PugHamKilledPost(id)
{
	if(g_bWarmup)
	{
		set_task(0.75,"PugRespawnClient",id);
	}
}

public PugRespawnClient(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && PugIsTeam(id))
	{
		PugRespawn(id);
	}
}

public PugStatusIcon(id)
{
	if(g_bWarmup)
	{
		PugSetGodMode(id,read_data(1) ? 1 : 0);
	}
}

public PugEventJoinedTeam(id,iTeam)
{
	if(g_bWarmup)
	{
		set_task(0.75,"PugRespawnClient",id);
	}
}
