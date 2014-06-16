#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <pug_const>
#include <pug_menu>
#include <pug_forwards>
#include <pug_modspecific>

new bool:g_bWarmup;

public plugin_init()
{
	register_plugin("Pug Mod Warmup",AMXX_VERSION_STR,"SmileY");
	
	register_forward(FM_SetModel,"PugFwSetModel",true);
	register_forward(FM_CVarGetFloat,"PugFwGetCvar",false);
	
	register_message(get_user_msgid("Money"),"PugMessageMoney");
	
	RegisterHam(Ham_Killed,"player","PugHamKilledPost",true);
	
	register_clcmd("joinclass","PugChooseAppearance");
	register_clcmd("menuselect","PugChooseAppearance");
}

public PugPreStart()
{
	PugRemoveC4(1);
	g_bWarmup = true;
}

public PugFirstHalf()
{
	PugRemoveC4(0);
	g_bWarmup = false;
}

public PugIntermission()
{
	PugRemoveC4(1);
	g_bWarmup = true;
}

public PugSecondHalf()
{
	PugRemoveC4(0);
	g_bWarmup = false;
}

public PugIntermissionOT()
{
	PugRemoveC4(1);
	g_bWarmup = true;
}

public PugOvertime()
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

public PugMessageMoney(iMsg,iDest,id)
{
	if(g_bWarmup)
	{
		if(is_user_alive(id))
		{
			PugSetClientMoney(id,16000,0);
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public PugHamKilledPost(id)
{
	if(g_bWarmup)
	{
		set_task(0.75,"PugRespawn",id);
	}
}

public PugRespawn(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && (1 <= PugGetClientTeam(id) <= 2))
	{
		PugRespawnClient(id);
		PugSetGodMode(id,1);
		
		set_task(6.0,"PugRemoveGodMode",id + 1500);
	}
}

public PugRemoveGodMode(id)
{
	id -= 1500;
	
	if(is_user_alive(id))
	{
		PugSetGodMode(id,0);
	}
}

public PugChooseAppearance(id)
{
	if(g_bWarmup && (get_pdata_int(id,205 /*m_iMenu*/) == 3 /*MENU_CHOOSEAPPEARANCE*/))
	{
		new sCommand[11],sArg[32];
		read_argv(0,sCommand,charsmax(sCommand));
		read_argv(1,sArg,charsmax(sArg));

		engclient_cmd(id,sCommand,sArg);
		ExecuteHam(Ham_Player_PreThink,id);

		set_task(0.75,"PugRespawn",id);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}