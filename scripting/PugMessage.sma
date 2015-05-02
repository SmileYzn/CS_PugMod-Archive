#include <amxmodx>

#include <PugConst>
#include <PugStocks>

#define MSG_TASK 12335

new g_iMessages;
new g_iCurrent;
new Array:g_aMessages;

public plugin_init()
{
	register_plugin("Pug Mod (Messages)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	g_aMessages = ArrayCreate(384);
	
	new sLast[8]
	get_localinfo("_pug_last_message",sLast,charsmax(sLast));
		
	g_iCurrent = str_to_num(sLast);
}

public plugin_cfg()
{
	new sPatch[128];
	PugGetConfigsDir(sPatch,charsmax(sPatch));
	format(sPatch,charsmax(sPatch),"%s/messages.ini",sPatch);
	
	remove_task(MSG_TASK);
	
	if(PugLoadMessages(sPatch))
	{
		set_task(120.0,"PugShowMessage",MSG_TASK);
	}
}

public PugShowMessage()
{
	if(g_iCurrent >= g_iMessages)
	{
		g_iCurrent = 0;
	}
	
	if(g_iMessages)
	{
		new sMessage[384];
		ArrayGetString(g_aMessages,g_iCurrent,sMessage,charsmax(sMessage));

		replace_all(sMessage,charsmax(sMessage),"!G","^4");
		replace_all(sMessage,charsmax(sMessage),"!T","^3");
		replace_all(sMessage,charsmax(sMessage),"!D","^1");
		
		client_print_color(0,print_team_grey,"%s %s",g_sHead,sMessage);
		
		++g_iCurrent;
		
		set_task(120.0,"PugShowMessage",MSG_TASK);
	}
}

public PugLoadMessages(const sPatch[])
{
	if(file_exists(sPatch))
	{
		new iFile = fopen(sPatch,"rb");
		
		new sMessage[384];
		
		while(!feof(iFile) && (g_iMessages < 33))
		{
			fgets(iFile,sMessage,charsmax(sMessage));
			trim(sMessage);
			
			if(sMessage[0] != ';')
			{
				ArrayPushString(g_aMessages,sMessage);
				
				g_iMessages++;
			}
		}
		
		fclose(iFile);
		
		return g_iMessages;
	}
	
	return 0;
}

public plugin_end()
{
	new sLast[8];
	num_to_str(g_iCurrent,sLast,charsmax(sLast));
	
	set_localinfo("pug_last_message",sLast);
}
