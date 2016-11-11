#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#include <PugConst>
#include <PugCS>
#include <PugForwards>

new bool:g_bWarmup;

new g_pPlayersMin;
new g_pAutoStartHalf;

new g_hMsgWeapon;

#define HUD_HIDE_TIMER (1<<4)
#define HUD_HIDE_MONEY (1<<5)

public plugin_init()
{
	register_plugin("Pug Mod (Warmup)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	g_pPlayersMin = get_cvar_pointer("pug_players_min");
	g_pAutoStartHalf = get_cvar_pointer("pug_force_auto_swap");
	
	g_hMsgWeapon = get_user_msgid("HideWeapon");
	
	register_forward(FM_SetModel,"FwSetModel",true);
	
	register_message(get_user_msgid("Money"),"MsgMoney");
	register_message(g_hMsgWeapon,"MsgHideWeapon");
	
	register_event("ResetHUD","EvResetHud","b");
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
	if(!get_pcvar_bool(g_pAutoStartHalf) || (get_playersnum(0) < get_pcvar_num(g_pPlayersMin)))
	{
		PugMapObjectives(1);
		g_bWarmup = true;
	}
}

public PugEventSecondHalf()
{
	if(g_bWarmup)
	{
		PugMapObjectives(0);
		g_bWarmup = false;
	}
}

public PugEventOvertime()
{
	if(g_bWarmup)
	{
		PugMapObjectives(0);
		g_bWarmup = false;
	}
}

public FwSetModel(iEntity)
{
	if(g_bWarmup)
	{
		if(pev_valid(iEntity))
		{
			new sClassName[32];
			pev(iEntity,pev_classname,sClassName,charsmax(sClassName));
			
			if(equali(sClassName,"weaponbox"))
			{
				set_pev(iEntity,pev_effects,EF_NODRAW);
				set_pev(iEntity,pev_nextthink,get_gametime() + 0.1);
			}
			
			if(equali(sClassName,"weapon_shield"))
			{
				set_pev(iEntity,pev_effects,EF_NODRAW);
				set_task(0.1,"fnRemoveEntity",iEntity);
			}
		}
	}
}

public fnRemoveEntity(iEntity)
{
	dllfunc(DLLFunc_Think,iEntity);
}

public MsgMoney(iMsg,iMsgDest,id)
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

public EvResetHud(id)
{
	if(g_bWarmup)
	{
		message_begin(MSG_ONE,g_hMsgWeapon,_,id);
		write_byte(HUD_HIDE_TIMER|HUD_HIDE_MONEY);
		message_end();
	}
}

public MsgHideWeapon()
{
	if(g_bWarmup)
	{
		set_msg_arg_int(1,ARG_BYTE,get_msg_arg_int(1)|HUD_HIDE_TIMER|HUD_HIDE_MONEY);
	}
}

public PugPlayerKilled(id)
{
	if(g_bWarmup)
	{
		set_task(0.75,"fnRespawn",id);
	}
}

public fnRespawn(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && PugIsTeam(id))
	{
		PugRespawn(id);
		PugSetGodMode(id,1);
		
		set_task(3.0,"fnUnProtect",id);
	}
}

public fnUnProtect(id)
{
	if(is_user_alive(id))
	{
		PugSetGodMode(id,0);
	}
}

public PugPlayerJoined(id,CsTeams:iTeam)
{
	if(g_bWarmup)
	{
		set_task(0.75,"fnRespawn",id);
	}
}
