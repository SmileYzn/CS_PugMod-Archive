#include <amxmodx>

#include <PugConst>
#include <PugForwards>

new g_pSvRestart;

public plugin_init()
{
	register_plugin("Pug MOD (LO3)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	g_pSvRestart = get_cvar_pointer("sv_restart");
}

public plugin_natives()
{
	register_library("PugLO3");
	
	register_native("PugLO3","LO3");
}

public PugEventFirstHalf()
{
	LO3();
}

public PugEventSecondHalf()
{
	LO3();
}

public PugEventOvertime()
{
	LO3();
}

public LO3()
{
	set_task(0.2,"PugRestartRound",1 + 1990);
	set_task(2.2,"PugRestartRound",2 + 1990);
	set_task(5.8,"PugRestartRound",3 + 1990);
	
	set_task(10.0,"PugLiveMessage");
}

public PugLiveMessage()
{
	set_hudmessage(0,255,0,-1.0,0.3,0,6.0,6.0);
	show_hudmessage(0,"--- MATCH IS LIVE ---");
}

public PugRestartRound(iTask)
{
	set_pcvar_num(g_pSvRestart,(iTask - 1990));
}
