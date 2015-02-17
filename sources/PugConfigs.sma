#include <amxmodx>

#include <PugConst>
#include <PugForwards>
#include <PugStocks>

#pragma semicolon 1

new g_pHideSlots;
new g_pPlayersMax;
new g_pVisiblePlayers;

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
	
	g_pHideSlots = create_cvar("pug_hide_slots","1",FCVAR_NONE,"Esconder slots extras do servidor",true,0.0,true,1.0);
	
	g_pPlayersMax = get_cvar_pointer("pug_players_max");
	g_pVisiblePlayers = get_cvar_pointer("sv_visiblemaxplayers");
	
	g_pPugMod = create_cvar("pug_config_pugmod","pugmod.rc",FCVAR_NONE,"Configuracao do PUG Mod");
	g_pWarmup = create_cvar("pug_config_warmup","warmup.rc",FCVAR_NONE,"Configuracao do Warmup");
	g_pStart = create_cvar("pug_config_start","start.rc",FCVAR_NONE,"Configuracao executada a cada inicio de votacao");

	g_pLive = create_cvar("pug_config_live","esl.rc",FCVAR_NONE,"Configuracao padrao quando o jogo esta em andamento");
	g_pHalfTime = create_cvar("pug_config_halftime","halftime.rc",FCVAR_NONE,"Configuracao executada na troca de times");
	g_pOvertime = create_cvar("pug_config_overtime","esl-ot.rc",FCVAR_NONE,"Configuracao padrao quando o Overtime esta em andamento");

	g_pFinished = create_cvar("pug_config_end","end.rc",FCVAR_NONE,"Configuracao padrao quando a partida termina");
}

public plugin_cfg()
{
	PugExecConfig(g_pPugMod);
}

public PugEventWarmup()
{
	set_pcvar_num(g_pVisiblePlayers,get_pcvar_bool(g_pHideSlots) ? get_pcvar_num(g_pPlayersMax) : -1);

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
	}
}