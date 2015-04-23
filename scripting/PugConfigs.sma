#include <amxmodx>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>

#pragma semicolon 1

new g_pPugMod;
new g_pWarmup;
new g_pStart;
new g_pLive;
new g_pHalfTime;
new g_pOvertime;
new g_pFinished;

public plugin_init()
{
	register_plugin("Pug MOD (Configs)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);

	g_pPugMod = create_cvar("pug_config_pugmod","pugmod.rc",FCVAR_NONE,"Config executed for pugmod cvars");
	g_pWarmup = create_cvar("pug_config_warmup","warmup.rc",FCVAR_NONE,"Used at warmup session in pug mod");
	g_pStart = create_cvar("pug_config_start","start.rc",FCVAR_NONE,"Executed when vote session starts");
	g_pLive = create_cvar("pug_config_live","esl.rc",FCVAR_NONE,"Used when the match begin (Live config)");
	g_pHalfTime = create_cvar("pug_config_halftime","halftime.rc",FCVAR_NONE,"Used at half-time session");
	g_pOvertime = create_cvar("pug_config_overtime","esl-ot.rc",FCVAR_NONE,"Used at Overtime session");
	g_pFinished = create_cvar("pug_config_end","end.rc",FCVAR_NONE,"Executed when the match ends");
	
	PugExecConfig(g_pPugMod);
}

public PugEventWarmup()
{
	PugExecConfig(g_pWarmup);
}

public PugEventStart()
{
	PugExecConfig(g_pStart);
}

public PugEventFirstHalf()
{
	PugExecConfig(g_pLive);
}

public PugEventHalfTime()
{
	PugExecConfig(g_pHalfTime);
}

public PugEventSecondHalf()
{
	PugExecConfig(g_pLive);
}

public PugEventOvertime()
{
	PugExecConfig(g_pOvertime);
}

public PugEventEnd()
{
	PugExecConfig(g_pFinished);
}

PugExecConfig(hConvar)
{
	new sFile[32];
	get_pcvar_string(hConvar,sFile,charsmax(sFile));
	
	if(sFile[0] != '^0')
	{
		new sDir[128];
		PugGetConfigsDir(sDir,charsmax(sDir));
		
		format(sDir,charsmax(sDir),"%s/%s",sDir,sFile);
		
		server_cmd("exec %s",sDir);
		server_exec();
	}
}
