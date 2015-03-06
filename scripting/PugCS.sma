#include <amxmodx>
#include <Amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

#include <PugCS>
#include <PugConst>
#include <PugNatives>

#pragma semicolon 1

#define isTeam(%0) (CS_TEAM_T <= cs_get_user_team(%0) <= CS_TEAM_CT)

new g_pForceRestart;
new g_pSwitchDelay;
new g_pAllowShield;
new g_pAllowGrenades;
new g_pTeamMoney;

new g_pPlayersMin;
new g_pPlayersMax;
new g_pAllowSpec;
new g_pSvRestart;
new g_pMpStartMoney;

public plugin_init()
{
	register_plugin("Pug MOD (CS)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("PugCS.txt");
	
	g_pForceRestart = create_cvar("pug_force_restart","0");
	g_pSwitchDelay = create_cvar("pug_switch_delay","5.0");
	g_pAllowShield = create_cvar("pug_allow_shield","1");
	g_pAllowGrenades = create_cvar("pug_allow_grenades","0");
	g_pTeamMoney = create_cvar("pug_show_money","1");
	
	g_pPlayersMin = get_cvar_pointer("pug_players_min");
	g_pPlayersMax = get_cvar_pointer("pug_players_max");
	g_pAllowSpec = get_cvar_pointer("pug_allow_spectators");
	g_pSvRestart = get_cvar_pointer("sv_restart");
	g_pMpStartMoney = get_cvar_pointer("mp_startmoney");
	
	register_event("SendAudio","ev_WonTR","a","2=%!MRAD_terwin");
	register_event("SendAudio","ev_WonCT","a","2=%!MRAD_ctwin");
	register_event("SendAudio","ev_Draw","a","2=%!MRAD_rounddraw");
	
	register_logevent("ev_RoundStart",2,"1=Round_Start");
	register_logevent("ev_RoundEnd",2,"1=Round_End");
	
	register_clcmd("jointeam","PugJoinTeam");

	register_menucmd(-2,MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6,"PugTeamSelect");
	register_menucmd(register_menuid("Team_Select",1),MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6,"PugTeamSelect");
	
	RegisterHamPlayer(Ham_Spawn,"PugSpawnPost",true);
}

public plugin_cfg()
{
	PugRegisterTeam("Terrorists");
	PugRegisterTeam("Counter-Terrorists");
}	

public plugin_natives()
{
	register_library("PugCS");
	
	register_native("PugGetClientTeam","CS_GetClientTeam");
	register_native("PugSetClientTeam","CS_SetClientTeam");
	
	register_native("PugGetPlayers","CS_GetPlayers");
	
	register_native("PugIsTeam","CS_IsTeam");
	register_native("PugRespawn","CS_Respawn");
	register_native("PugSetGodMode","CS_SetGodMode");
	register_native("PugSetMoney","CS_SetMoney");
	register_native("PugRemoveC4","CS_RemoveC4");
	
	register_native("PugTeamsRandomize","CS_TeamsRandomize");
	register_native("PugTeamsBalance","CS_TeamsBalance");
	register_native("PugTeamsOptmize","CS_TeamsOptmize");
}

public CS_GetClientTeam()
{
	return _:cs_get_user_team(get_param(1));
}

public CS_SetClientTeam()
{
	cs_set_user_team(get_param(1),_:get_param(2));
}

public CS_GetPlayers()
{
	new iPlayers[32],iNum,iCount = 0;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++)
	{
		if(isTeam(iPlayers[i]))
		{
			iCount++;
		}
	}

	return iCount;
}

public CS_IsTeam()
{
	new iPlayer = get_param(1);
	
	if(isTeam(iPlayer))
	{
		return true;
	}
	
	return false;
}

public CS_Respawn()
{
	ExecuteHam(Ham_CS_RoundRespawn,get_param(1));
}

public CS_SetGodMode()
{
	set_pev(get_param(1),pev_takedamage,get_param(2) ? DAMAGE_NO : DAMAGE_AIM);
}

public CS_SetMoney()
{
	cs_set_user_money(get_param(1),get_param(2),get_param(3));
}

public CS_RemoveC4(id,iParams)
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
	get_players(iPlayers,iNum);
	
	for(new i;i < iNum;i++)
	{
		if(!isTeam(iPlayers[i]))
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
			case CS_TEAM_T:
			{
				++a;
				aPlayer = iPlayer;
			}
			case CS_TEAM_CT:
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
		cs_set_user_team(aPlayer,CS_TEAM_T);
	}
	else if((b + 2) == a)
	{
		cs_set_user_team(bPlayer,CS_TEAM_CT);
	}
	else if((a + b) < get_pcvar_num(g_pPlayersMin))
	{
		a = PugGetTeamScore(1);
		b = PugGetTeamScore(2);

		if(a < b)
		{
			cs_set_user_team(aPlayer,CS_TEAM_T);
		}
		else if(b < a)
		{
			cs_set_user_team(bPlayer,CS_TEAM_CT);
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

public ev_RoundStart()
{
	PugRoundStart();
}

public ev_RoundEnd()
{
	PugRoundEnd();
}

public ev_WonTR()
{
	PugRoundWinner(1);
}

public ev_WonCT()
{
	PugRoundWinner(2);
}

public ev_Draw()
{
	PugRoundWinner(0);
}

public PugEventHalfTime()
{
	set_task(get_pcvar_float(g_pSwitchDelay),"PugSwitchTeams");
}

public PugSwitchTeams()
{
	new iScore = PugGetTeamScore(1);
	PugSetTeamScore(1,PugGetTeamScore(2));
	PugSetTeamScore(2,iScore);
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		switch(cs_get_user_team(iPlayer))
		{
			case CS_TEAM_T:
			{
				cs_set_user_team(iPlayer,CS_TEAM_CT);
			}
			case CS_TEAM_CT:
			{
				cs_set_user_team(iPlayer,CS_TEAM_T);
			}
		}
	}
	
	if(get_pcvar_num(g_pForceRestart))
	{
		set_pcvar_num(g_pSvRestart,1);
	}
}

public PugJoinTeam(id)
{
	new sArg[3];
	read_argv(1,sArg,charsmax(sArg));
	
	return PugCheckTeam(id,str_to_num(sArg));
}

public PugTeamSelect(id,iKey)
{
	return PugCheckTeam(id,iKey + 1);
}

public PugCheckTeam(id,iTeamNew) 
{
	new iTeamOld = _:cs_get_user_team(id);
	
	if(PUG_STAGE_START <= GET_PUG_STAGE() <= PUG_STAGE_OVERTIME)
	{
		if((iTeamOld == 1) || (iTeamOld == 2))
		{
			client_print_color
			(
				id,
				print_team_red,
				"%s %L",
				g_sHead,
				LANG_SERVER,
				"PUG_SELECTTEAM_NOSWITCH"
			);
			
			return PLUGIN_HANDLED;
		}
	}
	
	if(iTeamOld == iTeamNew)
	{
		client_print_color
		(
			id,
			print_team_red,
			"%s %L",
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
			new iMaxPlayers = (get_pcvar_num(g_pPlayersMax) / 2);
			
			new iPlayers[32],iNum[CsTeams];
			get_players(iPlayers,iNum[CS_TEAM_T],"eh","TERRORIST");
			get_players(iPlayers,iNum[CS_TEAM_CT],"eh","CT");
			
			if((iNum[CS_TEAM_T] >= iMaxPlayers) && (iTeamNew == 1))
			{
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
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
					print_team_red,
					"%s %L",
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
				print_team_red,
				"%s %L",
				g_sHead,
				LANG_SERVER,
				"PUG_SELECTTEAM_NOAUTO"
			);
			
			return PLUGIN_HANDLED;
		}
		case 6:
		{
			if(!get_pcvar_num(g_pAllowSpec) && !access(id,PUG_CMD_LVL))
			{
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
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

public PugSpawnPost(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_FIRSTHALF) || (iStage == PUG_STAGE_SECONDHALF) || (iStage == PUG_STAGE_OVERTIME))
	{
		if(is_user_alive(id) && isTeam(id) && get_pcvar_num(g_pTeamMoney) && (cs_get_user_money(id) != get_pcvar_num(g_pMpStartMoney)))
		{
			set_task(0.1,"PugMoneyTeam",id);
		}
	}
}

public PugMoneyTeam(id)
{
	new sTeam[13];
	get_user_team(id,sTeam,charsmax(sTeam));

	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"aeh",sTeam);

	new sName[32],sHud[512],iMoney;

	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];

		iMoney = cs_get_user_money(iPlayer);
		get_user_name(iPlayer,sName,charsmax(sName));

		format
		(
			sHud,
			charsmax(sHud),
			"%s%s $ %i^n",
			sHud,
			sName,
			iMoney
		);
	}
	
	set_hudmessage(0,255,0,0.58,0.02,0,0.0,10.0,0.0,0.0,1);
	show_hudmessage(id,(sTeam[0] == 'C') ? "Counter-Terrorists:" : "Terrorists:");
	
	set_hudmessage(255,255,225,0.58,0.05,0,0.0,10.0,0.0,0.0,2);
	show_hudmessage(id,sHud);
}

public CS_OnBuy(id,iItem)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_WARMUP) || (iStage == PUG_STAGE_START) || (iStage == PUG_STAGE_HALFTIME))
	{
		if((iItem == CSI_FLASHBANG) || (iItem == CSI_HEGRENADE) || (iItem == CSI_SMOKEGRENADE) && !get_pcvar_num(g_pAllowGrenades))
		{
			return PLUGIN_HANDLED;
		}
	}
	
	if((iItem == CSI_SHIELDGUN) && !get_pcvar_num(g_pAllowShield))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
