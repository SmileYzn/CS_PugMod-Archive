#include <amxmodx>

#define MAX_FLOOD_REPEAT	4
#define MIN_FLOOD_TIME 		0.75
#define MIN_FLOOD_NEXT_TIME	4.0

new g_Flood[MAX_PLAYERS+1];
new Float:g_Flooding[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin("Pug Mod (Anti Flood)",AMXX_VERSION_STR,"AMXX Dev Team");

	register_clcmd("say","Filter");
	register_clcmd("say_team","Filter");
	register_clcmd("jointeam","Filter");
	register_clcmd("chooseteam","Filter");
}

public Filter(id)
{
	new Float:NexTime = get_gametime();
		
	if(g_Flooding[id] > NexTime)
	{
		if(g_Flood[id] >= MAX_FLOOD_REPEAT)
		{
			g_Flooding[id] = NexTime + MIN_FLOOD_TIME + MIN_FLOOD_NEXT_TIME;
			return PLUGIN_HANDLED;
		}

		g_Flood[id]++;
	}
	else if(g_Flood[id])
	{
		g_Flood[id]--;
	}
		
	g_Flooding[id] = NexTime + MIN_FLOOD_TIME;

	return PLUGIN_CONTINUE;
}
