#if defined _pug_stocks_included
	#endinput
#endif
#define _pug_stocks_included

#include <pug_const>

#pragma semicolon 1

stock PugMessage(id,sLang[])
{
	if(!id) server_print("%s %L",g_sHead,LANG_SERVER,sLang);
	
	client_print_color
	(
		id,
		print_team_grey,
		"^4%s^1 %L",
		g_sHead,
		(id == 0) ? LANG_SERVER : LANG_PLAYER,
		sLang
	);
	
	return PLUGIN_HANDLED;
}

stock PugRegisterCommand(const sCommand[],const sFunction[],iFlags = 0,const sInfo[]="")
{
	static sBuffer[16];
	formatex(sBuffer,charsmax(sBuffer),".%s",sCommand);
	
	register_clcmd(sBuffer,sFunction,iFlags,sInfo);
}

stock PugRegisterAdminCommand(const sCommand[],const sFunction[],iFlags = 0,const sInfo[]="")
{
	static sBuffer[16];
	formatex(sBuffer,charsmax(sBuffer),"!%s",sCommand);
	
	register_concmd(sBuffer,sFunction,iFlags,sInfo);
}

stock PugAdminCommand(id,sCommand[],sLang[],iCheck)
{
	if(iCheck)
	{
		new sName[32];
		get_user_name(id,sName,charsmax(sName));

		client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,sLang,sName);
	}
	
	client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,iCheck ? "PUG_CMD_SUCCESS" : "PUG_CMD_FAILURE",sCommand);
}

stock PugAdminCommandClient(id,sCommand[],sLang[],iClient,iCheck)
{
	if(iCheck)
	{
		new sName[32];
		get_user_name(iClient,sName,charsmax(sName));
		
		client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_SERVER,sLang,sName);
	}
	
	client_print_color(id,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,iCheck ? "PUG_CMD_SUCCESS" : "PUG_CMD_FAILURE",sCommand);
}

stock PugDisconnect(const id,const sReason[] = "",any:...)
{
	if(sReason[0])
	{
		new sMessage[192];
		vformat(sMessage,charsmax(sMessage),sReason,3);

		message_begin(MSG_ONE_UNRELIABLE,SVC_DISCONNECT,{0,0,0},id);
		write_string(sMessage);
		message_end();
	}
	else server_cmd("kick #%i",get_user_userid(id));
}
