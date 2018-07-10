#include <PugCore>
#include <PugStocks>

new g_Config[States];

public plugin_init()
{
	register_plugin("Pug Mod (Config System)",PUG_VERSION,PUG_AUTHOR);

	g_Config[STATE_DEAD]		= create_cvar("pug_cfg_pugmod","pugmod.rc",FCVAR_NONE,"Config executed for pugmod cvars");
	g_Config[STATE_WARMUP]		= create_cvar("pug_cfg_warmup","warmup.rc",FCVAR_NONE,"Used at warmup session in pug mod");
	g_Config[STATE_START]		= create_cvar("pug_cfg_start","start.rc",FCVAR_NONE,"Executed when vote session starts");
	g_Config[STATE_FIRSTHALF]	= create_cvar("pug_cfg_1st","esl.rc",FCVAR_NONE,"Used when the match begin (Live config)");
	g_Config[STATE_HALFTIME]	= create_cvar("pug_cfg_halftime","halftime.rc",FCVAR_NONE,"Used at half-time session");
	g_Config[STATE_SECONDHALF]	= create_cvar("pug_cfg_2nd","esl.rc",FCVAR_NONE,"Used when the match begin (Live config)");
	g_Config[STATE_OVERTIME]	= create_cvar("pug_cfg_overtime","esl-ot.rc",FCVAR_NONE,"Used at Overtime session");
	g_Config[STATE_END]		= create_cvar("pug_cfg_end","end.rc",FCVAR_NONE,"Executed when the match ends");
}

public plugin_cfg()
{
	PugEvent(STATE_DEAD);
}

public PugEvent(State)
{
	new File[MAX_NAME_LENGTH];
	get_pcvar_string(g_Config[State],File,charsmax(File));
	
	if(File[0] != '^0')
	{
		new Path[64];
		PugGetFilePath(File,Path,charsmax(Path));
		
		server_cmd("exec %s",Path);
	}
}
