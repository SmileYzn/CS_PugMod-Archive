#if defined _PugStocks_included
	#endinput
#endif
#define _PugStocks_included

#include <amxmodx>

stock PugMessage(id,sLang[])
{
	if(!id)
	{
		server_print("* %L",LANG_SERVER,sLang);
	}
	
	client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_SERVER,sLang);
	
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
	
	register_clcmd(sBuffer,sFunction,iFlags,sInfo);
}

stock PugGetConfigsDir(sPatch[],iLen)
{
	get_localinfo("amxx_configsdir",sPatch,iLen);
	
	format(sPatch,iLen,"%s/pug",sPatch);
}

stock PugAdminCommand(id,sCommand[],sLang[],iCheck)
{
	if(iCheck)
	{
		new sName[MAX_NAME_LENGTH];
		get_user_name(id,sName,charsmax(sName));
		
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,sLang,sName);
	}
	
	client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_PLAYER,iCheck ? "PUG_CMD_SUCCESS" : "PUG_CMD_FAILURE",sCommand);
}

stock PugAdminCommandClient(id,sCommand[],sLang[],iClient,iCheck)
{
	if(iCheck)
	{
		new sName[MAX_NAME_LENGTH];
		get_user_name(iClient,sName,charsmax(sName));
	
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,sLang,sName);
	}
	
	client_print_color(id,print_team_red,"%s %L",g_sHead,LANG_PLAYER,iCheck ? "PUG_CMD_SUCCESS" : "PUG_CMD_FAILURE",sCommand);
}

stock PugDisconnect(const id,const sReason[] = "",any:...)
{
	if(sReason[0])
	{
		new sMessage[192];
		vformat(sMessage,charsmax(sMessage),sReason,3);
	
		message_begin(MSG_ONE_UNRELIABLE,SVC_DISCONNECT,_,id);
		write_string(sMessage);
		message_end();
	}
	else
	{
		server_cmd("kick #%i",get_user_userid(id));
	}
}

stock PugGetPercent(iValue,tValue)
{     
	return floatround(floatmul(float(iValue) / float(tValue),100.0));
}

stock PugBuildHelpFile(iLevel,sFileName[],sTag[])
{
	new sDir[64];
	PugGetConfigsDir(sDir,charsmax(sDir));
	format(sDir,charsmax(sDir),"%s/%s",sDir,sFileName);
	
	if(!file_exists(sDir))
	{
		new iCommands = get_concmdsnum(iLevel);
		
		if(iCommands)
		{
			new iFile = fopen(sDir,"wt");
			fputs(iFile,"<style type='text/css'>body{background:#000;margin:2px;color:#FFB000;font-family:Tahoma}</style><table width='100%%'>");
			
			new sCommand[32],sInfo[128],iFlags;
			
			for(new i;i < iCommands;i++)
			{
				get_concmd(i,sCommand,charsmax(sCommand),iFlags,sInfo,charsmax(sInfo),iLevel);
				
				if(sCommand[0] == sTag[0])
				{
					replace_all(sInfo,sizeof(sInfo),"<","&#60;");
					replace_all(sInfo,sizeof(sInfo),">","&#62;");
				
					fprintf(iFile,"<tr><td>%s</td><td>%s</td></tr>",sCommand,sInfo);
				}
			}
			
			fclose(iFile);
		}
	}
}

/* Not used for now (Old and not updated stock)
stock PugRconCommand(const szHost[],iPort,const szPass[],const szCommand[])
{
	new iError;
	new iSocket = socket_open(szHost,iPort,SOCKET_UDP,iError);
	
	switch(iError)
	{
		case 1:
		{
			socket_close(iSocket);
			server_print("* Error on creating the socket.");
		
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			socket_close(iSocket);
			server_print("* Error on resolve the given hostname.");
			
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			socket_close(iSocket);
			server_print("* Error on connecting.");
			
			return PLUGIN_HANDLED;
		}
	}
	
	new iSend[256],sData[512],szRcon[32],szNone[64];
	
	formatex(iSend,sizeof(iSend),"%c%c%c%cchallenge rcon",255,255,255,255); // Separar esses dois :D
	socket_send2(iSocket,iSend,charsmax(iSend));
	
	if(!socket_change(iSocket,2000000))
	{
		socket_close(iSocket);
		server_print("* No response from %s:%d",szHost,iPort);
		
		return PLUGIN_HANDLED;
	}
	
	socket_recv(iSocket,sData,charsmax(sData));
	parse(sData,szNone,charsmax(szNone),szNone,charsmax(szNone),szRcon,charsmax(szRcon));
	
	formatex(sData,sizeof(sData),"%c%c%c%crcon %s ^"%s^" %s",0xFF,0xFF,0xFF,0xFF,szRcon,szPass,szCommand);
	socket_send2(iSocket,sData,charsmax(sData));
	
	if(socket_change(iSocket))
	{
		new szBuffer[2048];
		socket_recv(iSocket,szBuffer,charsmax(szBuffer));
		
		server_print(szBuffer);
	}
	
	socket_close(iSocket);
	
	return PLUGIN_HANDLED;
}
*/