#include <amxmodx>

#include <pug_stocks>
#include <pug_forwards>

public g_pStart;
public g_pReady;
public g_pPregame;
public g_pFirstHalf;
public g_pIntermission;
public g_pSecondHalf;
public g_pInermissionOT;
public g_pOvertime;
public g_pRoundStart;
public g_pRoundEnd;
public g_pWinner;
public g_pFinished;

public plugin_init()
{
	register_plugin("Pug Mod Configs",AMXX_VERSION_STR,"SmileY");
	
	g_pStart 		= register_cvar("pug_config_start","pug.rc");
	g_pReady 		= register_cvar("pug_config_ready","");
	g_pPregame 		= register_cvar("pug_config_pregame","pregame.rc");
	g_pFirstHalf 		= register_cvar("pug_config_firsthalf","esl.rc");
	g_pIntermission		= register_cvar("pug_config_intermission","intermission.rc");
	g_pSecondHalf 		= register_cvar("pug_config_secondhalf","esl.rc");
	g_pInermissionOT 	= register_cvar("pug_config_intermission_ot","intermission.rc");
	g_pOvertime 		= register_cvar("pug_config_overtime","esl-overtime.rc");
	g_pRoundStart 		= register_cvar("pug_config_round_start","");
	g_pRoundEnd 		= register_cvar("pug_config_round_end","");
	g_pWinner 		= register_cvar("pug_config_winner","");
	g_pFinished 		= register_cvar("pug_config_finished","finished.rc");
}

public plugin_cfg()
{
	PugExecConfig(g_pStart);
}

public PugPreStart(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pPregame);
}

public PugAllReady(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pReady);
}

public PugFirstHalf(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pFirstHalf);
}

public PugIntermission(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pIntermission);
}

public PugSecondHalf(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pSecondHalf);
}

public PugIntermissionOT(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pInermissionOT);
}

public PugOvertime(GEN_FORW_ID(iForward))
{
	PugExecConfig(g_pOvertime);
}

public PugRoundStart()
{
	PugExecConfig(g_pRoundStart);
}

public PugRoundEnd(iWinner)
{
	PugExecConfig(g_pRoundStart);
}

public PugWinner(iWinner)
{
	PugExecConfig(g_pWinner);
}

public PugFinished()
{
	PugExecConfig(g_pFinished);
}

bool:PugExecConfig(hConvar)
{
	new sFile[32];
	get_pcvar_string(hConvar,sFile,charsmax(sFile));
	
	if(sFile[0] != '^0')
	{
		new sDir[128];
		PugGetConfigsDir(sDir,charsmax(sDir));
		
		format(sDir,charsmax(sDir),"%s/%s",sDir,sFile);
		
		server_cmd("exec %s",sDir);
		
		return true;
	}
	
	return false;
}