#include <amxmodx>

#pragma semicolon 1

new g_fFlood[33];
new Float:g_fFlooding[33];

public plugin_init()
{
	register_plugin("Pug MOD (Anti Flood)",AMXX_VERSION_STR,"AMXX Dev Team");

	register_clcmd("say","PugFloodCheck");
	register_clcmd("say_team","PugFloodCheck");

	register_clcmd("jointeam","PugFloodCheck");
	register_clcmd("chooseteam","PugFloodCheck");
}

public PugFloodCheck(id)
{
	new Float:fNexTime = get_gametime();
		
	if(g_fFlooding[id] > fNexTime)
	{
		if(g_fFlood[id] >= 4)
		{
			g_fFlooding[id] = fNexTime + 0.75 + 4.0;

			return PLUGIN_HANDLED;
		}

		g_fFlood[id]++;
	}
	else if(g_fFlood[id])
	{
		g_fFlood[id]--;
	}
		
	g_fFlooding[id] = fNexTime + 0.75;

	return PLUGIN_CONTINUE;
}
