#include <amxmodx>

#include <pug_stocks>
#include <pug_forwards>

new g_pSvRestart;

CREATE_GEN_FORW_ID(Fw_ID);

public plugin_init()
{
	register_plugin("Live on Three Restarts (Pug Mod)",AMXX_VERSION_STR,"Twilight Suzuka");
	
	g_pSvRestart = get_cvar_pointer("sv_restart");
}

public PugFirstHalf(GEN_FORW_ID(iForward))
{
	Fw_ID = iForward;
	
	PugLO3();
	
	return PLUGIN_HANDLED;
}

public PugSecondHalf(GEN_FORW_ID(iForward))
{
	Fw_ID = iForward;
	
	PugLO3();
	
	return PLUGIN_HANDLED;
}

public PugOvertime(GEN_FORW_ID(iForward))
{
	Fw_ID = iForward;
	
	PugLO3();
	
	return PLUGIN_HANDLED;
}

public PugLO3()
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
	
	ContinueGenForward(Fw_ID);
}

public PugRestartRound(iTask)
{
	set_pcvar_num(g_pSvRestart,(iTask - 1990));
}
