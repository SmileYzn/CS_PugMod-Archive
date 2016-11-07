#if defined _PugConst_included
	#endinput
#endif
#define _PugConst_included

#include <amxmodx>

#define PUG_MOD_VERSION 	"2.0.4"
#define PUG_MOD_AUTHOR		"SmileY"

stock const g_sHead[] = "^4(PUG)^1";

#define PUG_MAX_TEAMS	4
#define PUG_CMD_LVL 	ADMIN_LEVEL_A

enum _:eStage
{
	STAGE_DEAD		= 0,
	STAGE_WARMUP		= 1,
	STAGE_START		= 2,
	STAGE_FIRSTHALF		= 3,
	STAGE_HALFTIME		= 4,
	STAGE_SECONDHALF	= 5,
	STAGE_OVERTIME		= 6,
	STAGE_FINISHED
};

stock const g_sStage[eStage][] =
{
	"Dead",
	"Warmup",
	"Starting",
	"First Half",
	"Half Time",
	"Second Half",
	"Overtime",
	"Finished"
};

stock GET_PUG_STAGE()
{
	if(xvar_exists("g_iStage"))
	{
		return get_xvar_num(get_xvar_id("g_iStage"));
	}
	
	return STAGE_DEAD;
}

stock GET_PUG_ROUND()
{
	if(xvar_exists("g_iRound"))
	{
		return get_xvar_num(get_xvar_id("g_iRound"));
	}
	
	return 0;
}
