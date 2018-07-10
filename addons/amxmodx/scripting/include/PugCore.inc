#if defined _PugCore_included
	#endinput
#endif
#define _PugCore_included

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#if AMXX_VERSION_NUM < 183 
	#assert AMX Mod X v1.8.3 or later library required!
#endif 

#pragma reqlib "PugCore"
	#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib "PugCore"
#endif

#define PUG_VERSION	"3.0.0"
#define PUG_AUTHOR 	"SmileY"

stock const g_Head[] = "^4[PUG]^1";

enum _:States
{
	STATE_DEAD,
	STATE_WARMUP,
	STATE_START,
	STATE_FIRSTHALF,
	STATE_HALFTIME,
	STATE_SECONDHALF,
	STATE_OVERTIME,
	STATE_END
};

stock const g_States[States][] =
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

/**
 * Call next Pug Mod State
 *
 * @note This is useful for call Pug Mod states automatically.
 *
 * @noreturn
 */
native PugNext();

/**
 * Called just after the Pug Mod change the state
 *
 * @note This is useful to do what you want :D
 *
 * @param State		The new state that was called
 *
 * @noreturn
 */
forward PugEvent(State);
