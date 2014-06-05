#if defined _pug_const_included
	#endinput
#endif
#define _pug_const_included

#include <amxmodx>

#pragma semicolon 1

#define PUG_CMD_LVL ADMIN_LEVEL_A
#define PUG_MAX_TEAMS 32
#define PUG_MIN_PLAYERS 5

#define PUG_STATUS_LIVE 0
#define PUG_STATUS_CLEAR 0
#define PUG_STATUS_DEAD (1<<0)
#define PUG_STATUS_WAITING (1<<1)
#define PUG_STATUS_PAUSED (1<<2)
#define PUG_STATUS_UNPAUSED (1<<3)

#define get_x_var(%0) (get_xvar_num(get_xvar_id(%0)))
#define set_x_var(%0,%1) (set_xvar_num(get_xvar_id(%0),%1))

#define GET_PUG_STATUS() get_x_var("g_iStatus")
#define SET_PUG_STATUS(%0) set_x_var("g_iStatus",%0)

stock ADD_PUG_STATUS(iStatus)
{
	do
	{
		new id = get_xvar_id("g_iStatus");
		set_xvar_num(id,get_xvar_num(id) | iStatus);
	}
	while(0)
}

stock REMOVE_PUG_STATUS(iStatus)
{
	do
	{
		new id = get_xvar_id("g_iStatus");
		set_xvar_num(id,get_xvar_num(id) & ~iStatus);
	}
	while(0)
}

enum _:PugStage
{
	PUG_STAGE_WAITING = 0,
	PUG_STAGE_READY,
	PUG_STAGE_START,
	PUG_STAGE_FIRSTHALF,
	PUG_STAGE_INTERMISSION,
	PUG_STAGE_SECONDHALF,
	PUG_STAGE_OVERTIME,
	PUG_STAGE_END
};

stock const g_sStage[PugStage][] =
{
	"Waiting",
	"Readying",
	"Starting",
	"First Half",
	"Intermission",
	"Second Half",
	"Overtime",
	"Finished"
};

#define GET_PUG_STAGE() get_x_var("g_iStage")
#define SET_PUG_STAGE(%0) set_x_var("g_iStage",%0)

#define GET_PUG_ROUND() get_x_var("g_iRounds")

#define GET_CVAR_TOTAL_ROUNDS() get_pcvar_num(get_x_var("g_pMaxRounds"))
#define GET_CVAR_OT_ROUNDS() get_pcvar_num(get_x_var("g_pMaxOTRounds"))

#define GET_CVAR_MAXPLAYERS() get_pcvar_num(get_x_var("g_pMaxPlayers"))
#define SET_CVAR_MAXPLAYERS(%0) set_cvar_num("g_pMaxPlayers",%0)

#define GET_CVAR_MINPLAYERS() get_pcvar_num(get_x_var("g_pMinPlayers"))
#define SET_CVAR_MINPLAYERS(%0) set_cvar_num("g_pMinPlayers",%0)

stock PugGetConfigsDir(sName[],iLen)
{
	get_localinfo("amxx_configsdir",sName,iLen);
	
	format(sName,iLen,"%s/pug-config",sName);
}

stock g_sHead[] = "[PUG]";
