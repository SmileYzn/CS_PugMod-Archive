#include <amxmodx>

#include <PugConst>
#include <PugStocks>
#include <PugMenus>

#pragma semicolon 1

new g_pURL;
new g_pFormat;
new g_pAddress;

public plugin_init()
{
	register_plugin("Pug Mod (Easy Anti Cheat)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	g_pURL 		= create_cvar("pug_eac_url","http://eac.maxigames.com.br/shots/cstrike",FCVAR_NONE,"URL that uses for show EAC screenshots");
	g_pFormat 	= create_cvar("pug_eac_url_format","<url>/<server>/<date>/<guid>",FCVAR_NONE,"URL order of main address from EAC");
	
	g_pAddress 	= get_cvar_pointer("net_address");

	PugRegisterCommand("eac","PugCommandEAC",ADMIN_ALL,"EAC Shots",false);
}

public PugCommandEAC(id)
{
	new iMenu = menu_create("Easy Anti Cheat","PugEacHandler");
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	new sName[32],sID[10];
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		get_user_name(iPlayer,sName,charsmax(sName));
		
		num_to_str(iPlayer,sID,charsmax(sID));
		menu_additem(iMenu,sName,sID);
	}

	PugDisplayMenuSingle(id,iMenu);

	return PLUGIN_HANDLED;
}

public PugEacHandler(id,iMenu,iKey)
{
	if(iKey == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	
	new iAccess,iCallBack,sCommand[3],sOption[32];
	menu_item_getinfo(iMenu,iKey,iAccess,sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);
	
	new sSteam[35];
	get_user_authid(str_to_num(sCommand),sSteam,charsmax(sSteam));
	replace_all(sSteam,charsmax(sSteam),":",".");
	
	new sURL[128];
	get_pcvar_string(g_pURL,sURL,charsmax(sURL));
	
	new sFormat[256];
	get_pcvar_string(g_pFormat,sFormat,charsmax(sFormat));
	
	new sServer[23];
	get_pcvar_string(g_pAddress,sServer,charsmax(sServer));
	replace_all(sServer,charsmax(sServer),":","_");
	
	new sDate[11];
	get_time("%d.%m.%Y",sDate,charsmax(sDate));
	
	replace(sFormat,charsmax(sFormat),"<url>",sURL);
	replace(sFormat,charsmax(sFormat),"<server>",sServer);
	replace(sFormat,charsmax(sFormat),"<date>",sDate);
	replace(sFormat,charsmax(sFormat),"<guid>",sSteam);
	
	console_print(id,"=====================");
	console_print(id,"Steam: %s",sSteam);
	console_print(id,"Date: %s (Server: %s)",sDate,sServer);
	console_print(id,"URL: ^"%s^"",sFormat);
	console_print(id,"=====================");
	
	show_motd(id,sFormat,sSteam);
	
	return PLUGIN_HANDLED;
}
