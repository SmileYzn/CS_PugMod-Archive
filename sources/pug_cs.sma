#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#include <pug_const>
#include <pug_stocks>
#include <pug_natives>
#include <pug_forwards>
#include <pug_modspecific>

new g_pForceRestart;
new g_pSwitchDelay;
new g_pAllowShield;
new g_pAllowGrenades;
new g_pAllowKill;

new g_pAllowSpec;

new g_pMpLimitTeams;
new g_pSvRestart;

public plugin_init()
{
	register_plugin("Pug Mod (CS)",AMXX_VERSION_STR,"Twilight Suzuka");
	
	register_dictionary("pug.txt");
	register_dictionary("pug_mod.txt");
	
	g_pForceRestart = register_cvar("pug_force_restart","1");
	g_pSwitchDelay = register_cvar("pug_switch_delay","5.0");
	
	g_pAllowShield = register_cvar("pug_allow_shield","0");
	g_pAllowGrenades = register_cvar("pug_allow_grenades","0");
	g_pAllowKill = register_cvar("pug_allow_kill","1");
	
	g_pAllowSpec = get_cvar_pointer("pug_allow_spectators");
	
	g_pSvRestart = get_cvar_pointer("sv_restart");
	g_pMpLimitTeams = get_cvar_pointer("mp_limitteams");

	register_event("HLTV","ev_HLTV","a","1=0","2=0");
	
	register_event("SendAudio","ev_WonTR","a","2=%!MRAD_terwin");
	register_event("SendAudio","ev_WonCT","a","2=%!MRAD_ctwin");
	register_logevent("ev_RoundEnd",2,"1=Round_End");
	
	register_clcmd("jointeam","PugJoinTeam");
	
	register_menucmd(-2,(1<<0)|(1<<1)|(1<<4)|(1<<5),"PugTeamSelect");
	register_menucmd(register_menuid("Team_Select",1),(1<<0)|(1<<1)|(1<<4)|(1<<5),"PugTeamSelect");
	
	register_forward(FM_ClientKill,"PugFwClientKill",false);
}

public plugin_cfg()
{
	PugRegisterTeam("Terrorists");
	PugRegisterTeam("Counter-Terrorists");
}

public plugin_natives()
{
	register_native("PugGetPlayers","CS_GetPlayers");
	register_native("PugGetPlayersTeam","CS_GetPlayersTeam");
	
	register_native("PugTeamsRandomize","CS_TeamsRandomize");
	register_native("PugTeamsBalance","CS_TeamsBalance");
	register_native("PugTeamsOptmize","CS_TeamsOptmize");
	
	register_native("PugGetClientTeam","CS_GetClientTeam");
	register_native("PugSetClientTeam","CS_SetClientTeam");

	register_native("PugRespawnClient","CS_RespawnClient");
	register_native("PugSetGodMode","CS_SetGodModeClient");
	register_native("PugSetClientMoney","CS_SetClientMoney");
	
	register_native("PugRemoveC4","CS_RemoveC4");
}

public CS_GetClientTeam()
{
	return _:cs_get_user_team(get_param(1));
}	

public CS_SetClientTeam()
{
	cs_set_user_team(get_param(1),_:get_param(2));
}

public CS_RespawnClient()
{
	ExecuteHamB(Ham_CS_RoundRespawn,get_param(1));
}

public CS_SetGodModeClient()
{
	set_pev(get_param(1),pev_takedamage,get_param(2) ? DAMAGE_NO : DAMAGE_AIM);
}

public CS_SetClientMoney()
{
	cs_set_user_money(get_param(1),get_param(2),get_param(3));
}

public CS_RemoveC4()
{
	new iRemove = get_param(1);

	new iEnt = -1;

	while((iEnt = engfunc(EngFunc_FindEntityByString,iEnt,"classname",iRemove ? "func_bomb_target" : "_func_bomb_target")) > 0)
	{
		set_pev(iEnt,pev_classname,iRemove ? "_func_bomb_target" : "func_bomb_target");
	}

	while((iEnt = engfunc(EngFunc_FindEntityByString,iEnt,"classname",iRemove ? "info_bomb_target" : "_info_bomb_target")) > 0)
	{
		set_pev(iEnt,pev_classname,iRemove ? "_info_bomb_target" : "info_bomb_target");
	}
}

public CS_TeamsRandomize()
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"h");
	
	for(new i;i < iNum;i++)
	{
		if(!(CS_TEAM_T <= cs_get_user_team(iPlayers[i]) <= CS_TEAM_CT))
		{
			iPlayers[i--] = iPlayers[--iNum];
		}
	}
	
	new iPlayer,CsTeams:iTeam = random(2) ? CS_TEAM_T : CS_TEAM_CT;
	
	new iRandom;
	
	while(iNum)
	{
		iRandom = random(iNum);
		
		iPlayer = iPlayers[iRandom];
		
		cs_set_user_team(iPlayer,iTeam);
		
		iPlayers[iRandom] = iPlayers[--iNum];
		
		iTeam = CsTeams:((_:iTeam) % 2 + 1);
	}
	
	if(get_pcvar_num(g_pForceRestart)) set_pcvar_num(g_pSvRestart,1);
}

public CS_TeamsBalance()
{
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");

	new a,b,aPlayer,bPlayer;
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];

		switch(cs_get_user_team(iPlayer))
		{
			case 1:
			{
				++a;
				aPlayer = iPlayer;
			}
			case 2:
			{
				++b;
				bPlayer = iPlayer;
			}
		}
	}
	
	if(a == b) 
	{
		return;
	}
	else if((a + 2) == b)
	{
		cs_set_user_team(aPlayer,_:2);
	}
	else if((b + 2) == a)
	{
		cs_set_user_team(bPlayer,_:1);
	}
	else if((a + b) < GET_CVAR_MINPLAYERS())
	{
		a = PugGetTeamScore(1);
		b = PugGetTeamScore(2);

		if(a < b)
		{
			cs_set_user_team(aPlayer,_:1);
		}
		else if(b < a)
		{
			cs_set_user_team(bPlayer,_:2);
		}
	}
}

public CS_TeamsOptmize()
{
	new iSkills[33],iSorted[33];
	
	new iPlayers[32],iNum,iPlayer;
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		iSorted[iPlayer] = iSkills[iPlayer] = (get_user_time(iPlayer,1) / get_user_frags(iPlayer));
	}
	
	SortIntegers(iSorted,sizeof(iSorted),Sort_Descending);

	new iCheck = 1,iTeams = PugNumTeams();
	
	for(new i;i < sizeof(iSorted);i++)
	{
		for(new a;a < iNum;a++)
		{
			iPlayer = iPlayers[a];
			
			if(iSkills[iPlayer] == iSorted[i])
			{
				PugSetClientTeam(iPlayer,iCheck);
				
				iCheck++;
				if(iCheck > iTeams)
				{
					iCheck = 1;
				}
			}
		}
	}
}

public CS_GetPlayers()
{
	new iPlayers[32],iNum,iCount = 0;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++)
	{
		if(CS_TEAM_T <= cs_get_user_team(iPlayers[i]) <= CS_TEAM_CT)
		{
			iCount++;
		}
	}
	
	return iCount;
}

public CS_GetPlayersTeam()
{
	new iPlayers[32],iNum,iPlayer,iCount = 0;
	get_players(iPlayers,iNum,"ch");
	
	new iTeam = get_param(1);
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		if(is_user_connected(iPlayer) && (get_user_team(iPlayer) == iTeam))
		{
			iCount++;
		}
	}
	
	return iCount;
}

new g_iWhoWon;

public ev_HLTV()
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		g_iWhoWon = 0;
		
		PugCallRoundStart();
	}
}

public ev_WonTR()
{
	g_iWhoWon = 1;
}

public ev_WonCT()
{
	g_iWhoWon = 2;
}

public ev_RoundEnd()
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		PugCallRoundEnd((g_iWhoWon == -1) ? 0 : g_iWhoWon);
		
		g_iWhoWon = -1;
	}
}

public PugIntermission(GEN_FORW_ID(iForward))
{
	PugSwitchTeams();
}

public PugIntermissionOT(GEN_FORW_ID(iForward))
{
	PugSwitchTeams();
}

public PugSwitchTeams()
{
	set_task(get_pcvar_float(g_pSwitchDelay),"PugSwitchTeamsReally",1337);
}

public PugSwitchTeamsReally()
{
	new iScore = PugGetTeamScore(1);
	PugSetTeamScore(1,PugGetTeamScore(2));
	PugSetTeamScore(2,iScore);

	new iLimitTeams = get_pcvar_num(g_pMpLimitTeams);
	set_pcvar_num(g_pMpLimitTeams,0);

	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");

	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];

		switch(cs_get_user_team(iPlayer))
		{
			case CS_TEAM_T: cs_set_user_team(iPlayer,CS_TEAM_CT);
			case CS_TEAM_CT: cs_set_user_team(iPlayer,CS_TEAM_T);
		}
	}

	set_pcvar_num(g_pMpLimitTeams,iLimitTeams);
	
	if(get_pcvar_num(g_pForceRestart)) set_pcvar_num(g_pSvRestart,1);
}

public PugJoinTeam(id) 
{
	new sArg[3];
	read_argv(1,sArg,charsmax(sArg));

	return PugCheckTeam(id,str_to_num(sArg));
}

public PugTeamSelect(id,iKey) return PugCheckTeam(id,iKey + 1);

public PugCheckTeam(id,iTeamNew) 
{
	new iTeam = get_user_team(id);
	
	if((GET_PUG_STATUS() == PUG_STATUS_LIVE) || (PUG_STAGE_FIRSTHALF <= GET_PUG_STAGE() <= PUG_STAGE_OVERTIME))
	{
		if((iTeam == 1) || (iTeam == 2))
		{
			client_print_color
			(
				id,
				print_team_grey,
				"^4%s^1 %L",
				g_sHead,
				LANG_SERVER,
				"PUG_SELECTTEAM_NOSWITCH"
			);
			
			return PLUGIN_HANDLED;
		}
	}
	
	if(iTeam == iTeamNew)
	{
		client_print_color
		(
			id,
			print_team_grey,
			"^4%s^1 %L",
			g_sHead,
			LANG_SERVER,
			"PUG_SELECTTEAM_SAMETEAM"
		);
		
		return PLUGIN_HANDLED;
	}
	
	switch(iTeamNew)
	{
		case 1,2:
		{
			new iMaxPlayers = (GET_CVAR_MAXPLAYERS() / 2);
			
			new iPlayers[32],iNum[CsTeams];
			get_players(iPlayers,iNum[CS_TEAM_T],"eh","TERRORIST");
			get_players(iPlayers,iNum[CS_TEAM_CT],"eh","CT");
			
			if((iNum[CS_TEAM_T] >= iMaxPlayers) && (iTeamNew == 1))
			{
				client_print_color
				(
					id,
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_SELECTTEAM_TEAMFULL"
				);
				
				return PLUGIN_HANDLED;
			}
			else if((iNum[CS_TEAM_CT] >= iMaxPlayers) && (iTeamNew == 2))
			{
				client_print_color
				(
					id,
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_SELECTTEAM_TEAMFULL"
				);
				
				return PLUGIN_HANDLED;
			}
		}
		case 5:
		{
			client_print_color
			(
				id,
				print_team_grey,
				"^4%s^1 %L",
				g_sHead,
				LANG_SERVER,
				"PUG_SELECTTEAM_NOAUTO"
			);
			
			return PLUGIN_HANDLED;
		}
		case 6:
		{
			if(!access(id,PUG_CMD_LVL) && !get_pcvar_num(g_pAllowSpec))
			{
				client_print_color
				(
					id,
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_SELECTTEAM_NOSPC"
				);
				
				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public CS_OnBuy(id,iWeapon)
{
	switch(iWeapon)
	{
		case CSI_HEGRENADE,CSI_FLASHBANG,CSI_SMOKEGRENADE:
		{
			if(GET_PUG_STATUS() != PUG_STATUS_LIVE)
			{
				return !get_pcvar_num(g_pAllowGrenades);
			}
		}
		case CSI_SHIELDGUN:
		{
			return !get_pcvar_num(g_pAllowShield);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public PugFwClientKill(id)
{
	if(is_user_alive(id) && !get_pcvar_num(g_pAllowKill))
	{
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}