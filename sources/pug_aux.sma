#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

#include <pug_const>
#include <pug_modspecific>
#include <pug_forwards>
#include <pug_stocks>

new g_iHits[33][33];
new g_iDamage[33][33];

new bool:g_bInRound = true;

new g_sMOTD[1600];
new g_sMOTD1[1600];

public plugin_init()
{
	register_plugin("Pug Mod (Aux)",AMXX_VERSION_STR,"Twilight Suzuka");
	
	register_dictionary("pug.txt");
	register_dictionary("pug_aux.txt");
	
	PugRegisterCommand("hp","PugCommandHP",ADMIN_ALL,"HP do time oposto");
	PugRegisterCommand("dmg","PugCommandDamage",ADMIN_ALL,"Dano do round");
	PugRegisterCommand("rdmg","PugCommandRecivedDamage",ADMIN_ALL,"Dano recebido");
	PugRegisterCommand("sum","PugCommandSummary",ADMIN_ALL,"Resumo do round");
	
	PugRegisterCommand("help","PugCommandClient",ADMIN_ALL,"Comandos do cliente");
	PugRegisterAdminCommand("help","PugCommandAdmin",PUG_CMD_LVL,"Comandos do Admin");
}

public plugin_cfg()
{
	PugLoadHelp(ADMIN_ALL);
	PugLoadHelp(PUG_CMD_LVL);
}

public client_putinserver(id) 
{
	arrayset(g_iHits[id],0,sizeof(g_iHits));
	arrayset(g_iDamage[id],0,sizeof(g_iDamage)); 
}

public client_disconnect(id)
{
	for(new i;i < sizeof(g_iHits);i++)
	{
		g_iHits[i][id] = 0;
		g_iDamage[i][id] = 0;
	}
}

public PugLoadHelp(iFlag)
{
	new sCommand[16],sInfo[128],iFlags,iCommands;
	
	if(iFlag == ADMIN_ALL)
	{
		formatex(g_sMOTD,charsmax(g_sMOTD),"<style type='text/css'>body{background:#000;margin:2px;color:#FFB000;font:normal 6px/6px Lucida Console;}</style><table width='100%%'>");
		
		iCommands = get_concmdsnum(iFlag);
		
		for(new i;i < iCommands;i++)
		{
			get_concmd(i,sCommand,charsmax(sCommand),iFlags,sInfo,charsmax(sInfo),iFlag,-1);
			
			if(sCommand[0] == '.')
			{
				replace_all(sInfo,sizeof(sInfo),"<","&#60;");
				replace_all(sInfo,sizeof(sInfo),">","&#62;");
				
				format(g_sMOTD,charsmax(g_sMOTD),"%s<tr><td>%s</td><td>%s</td></tr>",g_sMOTD,sCommand,sInfo);
			}
		}
	}
	else if(iFlag == PUG_CMD_LVL)
	{
		formatex(g_sMOTD1,charsmax(g_sMOTD1),"<style type='text/css'>body{background:#000;margin:2px;color:#FFB000;font:normal 6px/6px Lucida Console;}</style><table width='100%%'>");
		
		iCommands = get_concmdsnum(iFlag);
		
		for(new i;i < iCommands;i++)
		{
			get_concmd(i,sCommand,charsmax(sCommand),iFlags,sInfo,charsmax(sInfo),iFlag,-1);
			
			if(sCommand[0] == '!')
			{
				replace_all(sInfo,sizeof(sInfo),"<","&#60;");
				replace_all(sInfo,sizeof(sInfo),">","&#62;");
				
				format(g_sMOTD1,charsmax(g_sMOTD1),"%s<tr><td>%s</td><td>%s</td></tr>",g_sMOTD1,sCommand,sInfo);
			}
		}
	}
}

public PugRoundStart()
{
	g_bInRound = true;
	
	for(new i;i < sizeof(g_iHits);i++)
	{
		arrayset(g_iHits[i],0,sizeof(g_iHits));	
		arrayset(g_iDamage[i],0,sizeof(g_iDamage));	
	}
}

public PugRoundStartFailed()
{
	g_bInRound = true;
	
	for(new i;i < sizeof(g_iHits);i++)
	{
		arrayset(g_iHits[i],0,sizeof(g_iHits));	
		arrayset(g_iDamage[i],0,sizeof(g_iDamage));	
	}
}

public PugRoundEnd(iWinner)
{
	g_bInRound = false;
}

public PugRoundEndFailed()
{
	g_bInRound = false;
}

public  client_damage(iAttacker,iVictim,iDamage,iWeapon,iPlace,TA)
{
	g_iHits[iAttacker][iVictim]++;
	g_iDamage[iAttacker][iVictim] += iDamage;
}

public PugCommandHP(id)
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		if(is_user_alive(id) && g_bInRound)
		{
			client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"ah");
			
			if(!iNum) PugMessage(id,"PUG_AUX_HP_ALIVE");
			
			new sName[32];
			new iTeam = PugGetClientTeam(id);
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				if(iTeam != PugGetClientTeam(iPlayer))
				{
					get_user_name(iPlayer,sName,charsmax(sName));
				    
					client_print_color
					(
						id,
						print_team_grey,
						"^4%s^1 %L",
						g_sHead,
						LANG_SERVER,
						"PUG_AUX_HP",
						sName,
						get_user_health(iPlayer),
						get_user_armor(iPlayer)
					);
				}
			}
		}
	}
	else client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	
	return PLUGIN_HANDLED;
}

public PugCommandDamage(id)
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		if(is_user_alive(id) && g_bInRound)
		{
			client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[32];
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
							print_team_grey,
							"^4%s^1 %L",
							g_sHead,
							LANG_SERVER,
							"PUG_AUX_DMG_SELF",
							iHit,
							(iHit > 1) ? "vezes" : "vez",
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,sName,charsmax(sName));
						
						client_print_color
						(
							id,
							print_team_grey,
							"^4%s^1 %L",
							g_sHead,
							LANG_SERVER,
							"PUG_AUX_DMG",
							sName,
							iHit,
							(iHit > 1) ? "vezes" : "vez",
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
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_AUX_NODMG"
				);
			}
		}
	}
	else client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	
	return PLUGIN_HANDLED;
}

public PugCommandRecivedDamage(id)
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		if(is_user_alive(id) && g_bInRound)
		{
			client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[32];
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
							print_team_grey,
							"^4%s^1 %L",
							g_sHead,
							LANG_SERVER,
							"PUG_AUX_RDMG_SELF",
							iHit,
							(iHit > 1) ? "vezes" : "vez",
							iDmg
						);
					}
					else
					{
						get_user_name(iPlayer,sName,charsmax(sName));
						
						client_print_color
						(
							id,
							print_team_grey,
							"^4%s^1 %L",
							g_sHead,
							LANG_SERVER,
							"PUG_AUX_RDMG",
							sName,
							iHit,
							(iHit > 1) ? "vezes" : "vez",
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
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_AUX_NORDMG"
				);
			}
		}
	}
	else client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	
	return PLUGIN_HANDLED;
}

public PugCommandSummary(id)
{
	if(GET_PUG_STATUS() == PUG_STATUS_LIVE)
	{
		if(is_user_alive(id) && g_bInRound)
		{
			client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
		}
		else
		{
			new iPlayers[32],iNum,iPlayer;
			get_players(iPlayers,iNum,"h");
			
			new sName[32];
			
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
						print_team_grey,
						"^4%s^1 %L",
						g_sHead,
						LANG_SERVER,
						"PUG_AUX_SUM",
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
					print_team_grey,
					"^4%s^1 %L",
					g_sHead,
					LANG_SERVER,
					"PUG_AUX_NOSUM"
				);
			}
		}
	}
	else client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTALLOWED");
	
	return PLUGIN_HANDLED;
}

public PugCommandClient(id)
{
	if(g_sMOTD[0])
	{
		show_motd(id,g_sMOTD,"Comandos Registrados");
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandAdmin(id,iLevel)
{
	if(access(id,iLevel) && g_sMOTD1[0])
	{
		show_motd(id,g_sMOTD1,"Comandos Registrados");
	}
	
	return PLUGIN_HANDLED;
}
