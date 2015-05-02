#include <amxmodx>
#include <amxmisc>
#include <csx>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>
#include <PugCS>

#pragma semicolon 1

new g_iHits[MAX_PLAYERS][MAX_PLAYERS];
new g_iDamage[MAX_PLAYERS][MAX_PLAYERS];

new bool:g_bRound;

public plugin_init()
{
	register_plugin("Pug MOD (Aux)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("PugCore.txt");
	register_dictionary("PugAux.txt");
	
	PugRegisterCommand("hp","PugCommandHP",ADMIN_ALL,"PUG_DESC_HP");
	PugRegisterCommand("dmg","PugCommandDamage",ADMIN_ALL,"PUG_DESC_DMG");
	PugRegisterCommand("rdmg","PugCommandRecivedDamage",ADMIN_ALL,"PUG_DESC_RDMG");
	PugRegisterCommand("sum","PugCommandSummary",ADMIN_ALL,"PUG_DESC_SUM");
	
	PugRegisterAdminCommand("kick","PugCommandKick",PUG_CMD_LVL,"PUG_DESC_KICK");
	PugRegisterAdminCommand("map","PugCommandMap",PUG_CMD_LVL,"PUG_DESC_MAP");
	PugRegisterAdminCommand("msg","PugCommandMessage",PUG_CMD_LVL,"PUG_DESC_MSG");
	PugRegisterAdminCommand("kill","PugCommandKill",PUG_CMD_LVL,"PUG_DESC_KILL");
	PugRegisterAdminCommand("rcon","PugCommandRcon",PUG_CMD_LVL,"PUG_DESC_RCON");
}

public client_disconnect(id)
{
	for(new i;i < MAX_PLAYERS;i++)
	{
		g_iHits[i][id] = 0;
		g_iDamage[i][id] = 0;
	}
}

public client_damage(iAttacker,iVictim,iDamage,iWP,iPlace,TA)
{
	g_iHits[iAttacker][iVictim]++;
	g_iDamage[iAttacker][iVictim] += iDamage;
}

public PugEventRoundStart()
{
	g_bRound = true;
	
	for(new i;i < MAX_PLAYERS;++i)
	{
		arrayset(g_iHits[i],0,sizeof(g_iHits));
		arrayset(g_iDamage[i],0,sizeof(g_iDamage));	
	}
}

public PugEventRoundEnd()
{
	g_bRound = false;
}

public PugCommandHP(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_FIRSTHALF) || (iStage == PUG_STAGE_SECONDHALF) || (iStage == PUG_STAGE_OVERTIME))
	{
		if((is_user_alive(id) && g_bRound) || !PugIsTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum;
			get_players(iPlayers,iNum,"aeh",(PugGetClientTeam(id) == 1) ? "CT" : "TERRORIST");
			
			if(!iNum)
			{
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
					g_sHead,
					LANG_SERVER,
					"PUG_HP_NONE"
				);
				
				return PLUGIN_HANDLED;
			}
			
			new sName[MAX_NAME_LENGTH],iPlayer;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
			
				get_user_name(iPlayer,sName,charsmax(sName));
			    
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
					g_sHead,
					LANG_SERVER,
					"PUG_HP_CMD",
					sName,
					get_user_health(iPlayer),
					get_user_armor(iPlayer)
				);
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandDamage(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_FIRSTHALF) || (iStage == PUG_STAGE_SECONDHALF) || (iStage == PUG_STAGE_OVERTIME))
	{
		if((is_user_alive(id) && g_bRound) || !PugIsTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[MAX_NAME_LENGTH];
			new iDmg,iHit,iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				iHit = g_iHits[id][iPlayer];
				
				if(iHit)
				{
					++iCheck;
					iDmg = g_iDamage[id][iPlayer];
					
					if(iPlayer == id)
					{
						client_print_color
						(
							id,
							print_team_red,
							"%s %L",
							g_sHead,
							LANG_SERVER,
							"PUG_DMG_SELF",
							iHit,
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,sName,charsmax(sName));
						
						client_print_color
						(
							id,
							print_team_red,
							"%s %L",
							g_sHead,
							LANG_SERVER,
							"PUG_DMG",
							sName,
							iHit,
							iDmg
						);
					}
				}
			}
			
			if(!iCheck)
			{	
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
					g_sHead,
					LANG_SERVER,
					"PUG_NODMG"
				);
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandRecivedDamage(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_FIRSTHALF) || (iStage == PUG_STAGE_SECONDHALF) || (iStage == PUG_STAGE_OVERTIME))
	{
		if((is_user_alive(id) && g_bRound) || !PugIsTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[MAX_NAME_LENGTH];
			new iDmg,iHit,iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				iHit = g_iHits[iPlayer][id];
				
				if(iHit)
				{
					++iCheck;
					iDmg = g_iDamage[iPlayer][id];
					
					if(iPlayer == id)
					{
						client_print_color
						(
							id,
							print_team_red,
							"%s %L",
							g_sHead,
							LANG_SERVER,
							"PUG_RDMG_SELF",
							iHit,
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,sName,charsmax(sName));
						
						client_print_color
						(
							id,
							print_team_red,
							"%s %L",
							g_sHead,
							LANG_SERVER,
							"PUG_RDMG",
							sName,
							iHit,
							iDmg
						);
					}
				}
			}
			
			if(!iCheck)
			{	
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
					g_sHead,
					LANG_SERVER,
					"PUG_NORDMG"
				);
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandSummary(id)
{
	new iStage = GET_PUG_STAGE();
	
	if((iStage == PUG_STAGE_FIRSTHALF) || (iStage == PUG_STAGE_SECONDHALF) || (iStage == PUG_STAGE_OVERTIME))
	{
		if((is_user_alive(id) && g_bRound) || !PugIsTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[MAX_NAME_LENGTH];
			
			new iDmg[2],iHit[2],iCheck;
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				if(id == iPlayer) continue;
				
				iHit[0] = g_iHits[id][iPlayer]; // Hits Done
				iHit[1] = g_iHits[iPlayer][id]; // Hits Recived
				
				if(iHit[0] || iHit[1])
				{
					++iCheck;
				
					iDmg[0] = g_iDamage[id][iPlayer]; // Damage Done
					iDmg[1] = g_iDamage[iPlayer][id]; // Damag Recived
					
					get_user_name(iPlayer,sName,charsmax(sName));
					
					client_print_color
					(
						id,
						print_team_red,
						"%s %L",
						g_sHead,
						LANG_SERVER,
						"PUG_SUM",
						iDmg[0],iHit[0],
						iDmg[1],iHit[1],
						sName,
						(is_user_alive(iPlayer) ? get_user_health(iPlayer) : 0)
					);
				}
			}
			
			if(!iCheck)
			{
				client_print_color
				(
					id,
					print_team_red,
					"%s %L",
					g_sHead,
					LANG_SERVER,
					"PUG_NOSUM"
				);
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	}
	
	return PLUGIN_HANDLED;
}
	
public PugCommandKick(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		new sPlayer[32];
		read_argv(1,sPlayer,charsmax(sPlayer));
		
		new iPlayer = cmd_target(id,sPlayer,CMDTARGET_OBEY_IMMUNITY);
		
		if(iPlayer)
		{
			PugAdminCommandClient(id,"Kick","PUG_KICK",iPlayer,iPlayer);
			
			new sReason[64];
			read_argv(2,sReason,charsmax(sReason));
			remove_quotes(sReason);
			
			if(sReason[0])
			{
				PugDisconnect(iPlayer,sReason);
			}
			else
			{
				PugDisconnect(iPlayer);
			}
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTARGET",sPlayer);
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandMap(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		new sMap[32];
		read_args(sMap,charsmax(sMap));
		remove_quotes(sMap);
		
		if(is_map_valid(sMap))
		{
			engine_changelevel(sMap);
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTARGET",sMap);
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandMessage(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		new sMessage[192];
		read_args(sMessage,charsmax(sMessage));
		remove_quotes(sMessage);
		
		if(sMessage[0])
		{
			client_print_color(0,print_team_red,"%s %s",g_sHead,sMessage);
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_DESC_MSG");
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandKill(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		new sPlayer[32];
		read_argv(1,sPlayer,charsmax(sPlayer));
		
		new iPlayer = cmd_target(id,sPlayer,CMDTARGET_OBEY_IMMUNITY);
		
		if(iPlayer)
		{
			PugAdminCommandClient(id,"Kill","PUG_KILL",iPlayer,user_kill(iPlayer));
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTARGET",sPlayer);
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandRcon(id)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOACCESS");
	}
	else
	{
		new sCommand[192];
		read_args(sCommand,charsmax(sCommand));
		remove_quotes(sCommand);
		
		server_print(sCommand);
		
		if(sCommand[0])
		{
			server_cmd(sCommand);
		}
		else
		{
			client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_DESC_RCON");
		}
	}
	
	return PLUGIN_HANDLED;
}