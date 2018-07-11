#include <PugCore>

new g_HLTV;
new g_Restart;

public plugin_init()
{
	register_plugin("Pug Mod (LO3)",PUG_VERSION,PUG_AUTHOR);
	
	g_HLTV = register_event("HLTV","HLTV","a","1=0","2=0");
	disable_event(g_HLTV);
}

public PugEvent(State)
{
	if(State == STATE_FIRSTHALF || State == STATE_SECONDHALF || State == STATE_OVERTIME)
	{
		g_Restart = 0;
		enable_event(g_HLTV);
		
		set_cvar_num("sv_restart",1);
	}	
}


public HLTV()
{
	if(g_Restart < 3)
	{
		set_cvar_num("sv_restart",++g_Restart);
	}
	else
	{
		disable_event(g_HLTV);
		
		set_hudmessage(0,255,0,-1.0,0.3,0,6.0,6.0);
		show_hudmessage(0,"--- MATCH IS LIVE ---");
	}
}
