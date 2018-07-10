#include <PugCore>
#include <PugStocks>
#include <PugCS>

new bool:g_Warmup;

new g_MsgMoney;
new g_MsgHideWeapon;

new HamHook:g_HamKilled;
new HamHook:g_HamSpawn;

new g_FMSetModel;

#define HUD_HIDE_TIMER (1<<4)
#define HUD_HIDE_MONEY (1<<5)

public plugin_init()
{
	register_plugin("Pug Mod (Warmup)",PUG_VERSION,PUG_AUTHOR);

	g_HamKilled = RegisterHamPlayer(Ham_Killed,"HamKilled",true);
	g_HamSpawn = RegisterHamPlayer(Ham_Spawn,"HamSpawn",true);
	
	register_clcmd("joinclass","JoinClass");
	register_clcmd("menuselect","JoinClass");
}

public PugEvent(State)
{
	g_Warmup = (State == STATE_WARMUP || State == STATE_START || State == STATE_HALFTIME);
	
	if(g_Warmup)
	{
		g_MsgMoney = register_message(get_user_msgid("Money"),"MsgMoney");
		g_MsgHideWeapon = register_message(get_user_msgid("HideWeapon"),"MsgHideWeapon");
		
		EnableHamForward(g_HamKilled);
		EnableHamForward(g_HamSpawn);
		
		g_FMSetModel = register_forward(FM_SetModel,"SetModel",true);
	}
	else
	{
		unregister_message(get_user_msgid("Money"),g_MsgMoney);
		unregister_message(get_user_msgid("HideWeapon"),g_MsgHideWeapon);
		
		DisableHamForward(g_HamKilled);
		DisableHamForward(g_HamSpawn);
		
		unregister_forward(FM_SetModel,g_FMSetModel,true);
	}
	
	PugSetMapObjectives(g_Warmup);
}

public CS_OnBuy(id,Weapon)
{
	if(g_Warmup)
	{
		if(cs_get_weapon_class(Weapon) == CS_WEAPONCLASS_GRENADE || Weapon == CSW_SHIELDGUN)
		{
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public MsgMoney(Msg,Dest,id)
{
	if(g_Warmup)
	{
		if(is_user_alive(id))
		{
			cs_set_user_money(id,16000,0);
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public MsgHideWeapon()
{
	if(g_Warmup)
	{
		set_msg_arg_int(1,ARG_BYTE,get_msg_arg_int(1)|HUD_HIDE_TIMER|HUD_HIDE_MONEY);
	}
}

public HamKilled(id)
{
	if(g_Warmup)
	{
		set_task(0.75,"Respawn",id);
	}
}

public Respawn(id)
{
	if(g_Warmup)
	{
		if(is_user_connected(id) && !is_user_alive(id) && isTeam(id))
		{
			ExecuteHamB(Ham_CS_RoundRespawn,id);
		}
	}
}

public HamSpawn(id)
{
	if(g_Warmup)
	{
		set_pev(id,pev_takedamage,DAMAGE_NO);
		set_task(3.0,"UnProtect",id);	
	}
}

public UnProtect(id)
{
	if(is_user_alive(id))
	{
		set_pev(id,pev_takedamage,DAMAGE_AIM);
	}
}

public SetModel(Ent)
{
	if(g_Warmup)
	{
		if(pev_valid(Ent))
		{
			new Name[MAX_NAME_LENGTH];
			pev(Ent,pev_classname,Name,charsmax(Name));
			
			if(equali(Name,"weaponbox"))
			{
				set_pev(Ent,pev_effects,EF_NODRAW);
				set_pev(Ent,pev_nextthink,get_gametime() + 0.1);
			}
			else if(equali(Name,"weapon_shield"))
			{
				set_pev(Ent,pev_effects,EF_NODRAW);
				set_task(0.1,"RemoveEnt",Ent);
			}
		}
	}
}

public RemoveEnt(Ent)
{
	if(pev_valid(Ent))
	{
		dllfunc(DLLFunc_Think,Ent);
	}
}

public JoinClass(id)
{
	if(g_Warmup)
	{
		if(get_ent_data(id,"CBasePlayer","m_iMenu") == CS_Menu_ChooseAppearance)
		{
			set_task(0.75,"Respawn",id);
		}
	}
}