#include <PugCore>

new g_SvRestart;
new g_RestartNum;
new g_Event;

public plugin_init()
{
	register_plugin("Pug Mod (LO3)",PUG_VERSION,PUG_AUTHOR);
	
	g_SvRestart = get_cvar_pointer("sv_restart");
	
	g_Event = register_event("HLTV","HLTV","a","1=0","2=0");
	disable_event(g_Event);
}

public PugEvent(State)
{
	if(State == STATE_FIRSTHALF || State == STATE_SECONDHALF || State == STATE_OVERTIME)
	{
		g_RestartNum = 0;
		enable_event(g_Event);
		set_pcvar_num(g_SvRestart,1);
	}
}

public HLTV()
{
	if(g_RestartNum < 3)
	{
		set_pcvar_num(g_SvRestart,++g_RestartNum);
	}
	else
	{
		set_hudmessage(0,255,0,-1.0,0.3,0,6.0,6.0);
		show_hudmessage(0,"--- MATCH IS LIVE ---");
		
		disable_event(g_Event);
	}
}
