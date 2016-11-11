#include <amxmodx>

#include <PugConst>
#include <PugForwards>

#define LO3_TASK 1990

new g_pSvRestart;

public plugin_init()
{
	register_plugin("Pug Mod (LO3)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	g_pSvRestart = get_cvar_pointer("sv_restart");
}

public PugEventFirstHalf()
{
	fnStart();
}

public PugEventSecondHalf()
{
	fnStart();
}

public PugEventOvertime()
{
	fnStart();
}

public fnStart()
{
	set_task(0.2,"fnRestart",(1 + LO3_TASK));
	set_task(2.2,"fnRestart",(2 + LO3_TASK));
	set_task(5.8,"fnRestart",(3 + LO3_TASK));
	
	set_task(10.0,"fnMessage",(4 + LO3_TASK));
}

public fnMessage()
{
	set_hudmessage(0,255,0,-1.0,0.3,0,6.0,6.0);
	show_hudmessage(0,"--- MATCH IS LIVE ---");
}

public fnRestart(iTask)
{
	set_pcvar_num(g_pSvRestart,(iTask - 1990));
}
