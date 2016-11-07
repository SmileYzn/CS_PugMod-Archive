#include <amxmodx>

#pragma semicolon 1

#define MAX_FLOOD_REPEAT	4
#define MIN_FLOOD_TIME 		0.75
#define MIN_FLOOD_NEXT_TIME	4.0

new g_fFlood[33];
new Float:g_fFlooding[33];

public plugin_init()
{
	register_plugin("Pug Mod (Anti Flood)",AMXX_VERSION_STR,"AMXX Dev Team");

	register_clcmd("say","CheckFlood");
	register_clcmd("say_team","CheckFlood");

	register_clcmd("jointeam","CheckFlood");
	register_clcmd("chooseteam","CheckFlood");
}

public CheckFlood(id)
{
	new Float:fNexTime = get_gametime();
		
	if(g_fFlooding[id] > fNexTime)
	{
		if(g_fFlood[id] >= MAX_FLOOD_REPEAT)
		{
			g_fFlooding[id] = fNexTime + MIN_FLOOD_TIME + MIN_FLOOD_NEXT_TIME;

			return PLUGIN_HANDLED;
		}

		g_fFlood[id]++;
	}
	else if(g_fFlood[id])
	{
		g_fFlood[id]--;
	}
		
	g_fFlooding[id] = fNexTime + MIN_FLOOD_TIME;

	return PLUGIN_CONTINUE;
}
