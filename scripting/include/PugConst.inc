#if defined _PugConst_included
	#endinput
#endif
#define _PugConst_included

#include <amxmodx>

#define PUG_MOD_VERSION 	"1.0.0"
#define PUG_MOD_AUTHOR		"SmileY"

stock const g_sHead[] = "^4[PugMod]^1";

#define PUG_CMD_LVL 	ADMIN_LEVEL_A
#define PUG_MAX_TEAMS 	4

enum _:PugStages
{
	PUG_STAGE_DEAD = 0,
	PUG_STAGE_WARMUP,
	PUG_STAGE_START,
	PUG_STAGE_FIRSTHALF,
	PUG_STAGE_HALFTIME,
	PUG_STAGE_SECONDHALF,
	PUG_STAGE_OVERTIME,
	PUG_STAGE_FINISHED
};

stock const g_sPugStage[PugStages][] =
{
	"Setup",
	"Warmup",
	"Starting",
	"First Half",
	"Half Time",
	"Second Half",
	"Overtime",
	"Finished"
};

#define PUG_STAGE_VAR "g_iStage"

stock GET_PUG_STAGE()
{
	if(xvar_exists(PUG_STAGE_VAR))
	{
		return get_xvar_num(get_xvar_id(PUG_STAGE_VAR));
	}
	
	return PUG_STAGE_DEAD;
}

#define PUG_ROUND_VAR "g_iRound"

stock GET_PUG_ROUND()
{
	if(xvar_exists(PUG_ROUND_VAR))
	{
		return get_xvar_num(get_xvar_id(PUG_ROUND_VAR));
	}
	
	return 0;
}
