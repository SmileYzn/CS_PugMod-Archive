#include <PugCore>
#include <PugStocks>
#include <PugCS>

#define TASK_HUDLIST 1337

new bool:g_ReadySystem = false;
new bool:g_Ready[MAX_PLAYERS+1];

new g_PlayersMin;

public plugin_init()
{
	register_plugin("Pug Mod (Ready System)",PUG_VERSION,PUG_AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("PugReady.txt");
	
	g_PlayersMin = get_cvar_pointer("pug_players_min");
	
	PugRegCommand("ready","Ready",ADMIN_ALL,"PUG_DESC_READY");
	PugRegCommand("notready","NotReady",ADMIN_ALL,"PUG_DESC_NOTREADY");
	
	PugRegCommand("forceready","ForceReady",ADMIN_LEVEL_A,"PUG_DESC_FORCEREADY");
}

public client_putinserver(id)
{
	g_Ready[id] = false;
}

public PugEvent(State)
{
	switch(State)
	{
		case STATE_WARMUP:
		{
			ReadySystem(true);
		}
		case STATE_START:
		{
			if(g_ReadySystem)
			{
				ReadySystem(false);
			}
		}
		case STATE_HALFTIME:
		{
			if(PugGetPlayersNum(true) < get_pcvar_num(g_PlayersMin))
			{
				ReadySystem(true);
			}
		}
	}
}

ReadySystem(bool:Enable)
{
	arrayset(g_Ready,false,sizeof(g_Ready));
	
	if(Enable)
	{
		g_ReadySystem = true;
		set_task(0.5,"HudList",TASK_HUDLIST, .flags="b");
		PugMsg(0,"PUG_READY_START");
	}
	else
	{
		g_ReadySystem = false;
		remove_task(TASK_HUDLIST);
	}
}

public Ready(id)
{
	if(g_ReadySystem)
	{
		if(!g_Ready[id])
		{
			if(isTeam(id))
			{
				g_Ready[id] = true;
				
				new Name[MAX_NAME_LENGTH];
				get_user_name(id,Name,charsmax(Name));
				
				client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_READY",Name);
				
				return CheckReady();
			}
		}
	}

	PugMsg(id,"PUG_CMD_ERROR");
	
	return PLUGIN_HANDLED;
}

public NotReady(id)
{
	if(g_ReadySystem)
	{
		if(g_Ready[id])
		{
			if(isTeam(id))
			{
				g_Ready[id] = false;
				
				new Name[MAX_NAME_LENGTH];
				get_user_name(id,Name,charsmax(Name));
				
				client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_NOTREADY",Name);
				
				return PLUGIN_HANDLED;
			}
		}
	}
	
	PugMsg(id,"PUG_CMD_ERROR");
	
	return PLUGIN_HANDLED;
}

public ForceReady(id,Level)
{
	if(access(id,Level))
	{
		new Arg[MAX_NAME_LENGTH];
		read_argv(1,Arg,charsmax(Arg));
		
		new Player = cmd_target(id,Arg,CMDTARGET_NO_BOTS|CMDTARGET_OBEY_IMMUNITY);
		
		if(!Player)
		{
			return PLUGIN_HANDLED;
		}
		
		PugCommandClient(id,"!forceready","PUG_FORCE_READY",Player,Ready(Player));
	}
	
	return PLUGIN_HANDLED;
}

CheckReady()
{
	new Count;
	
	for(new i;i < sizeof(g_Ready);i++)
	{
		if(g_Ready[i])
		{
			Count++;
		}
	}
	
	if(Count >= get_pcvar_num(g_PlayersMin))
	{
		ReadySystem(false);
		
		PugMsg(0,"PUG_ALL_READY");
		PugNext();
	}
	
	return PLUGIN_HANDLED;
}

public HudList()
{
	new Players[MAX_PLAYERS],Num,Player;
	get_players(Players,Num,"ch");
	
	new List[2][512];
	new Name[MAX_NAME_LENGTH];
	
	new Readys,PlayersCount;
	
	for(new i;i < Num;i++)
	{
		Player = Players[i];
		
		if(isTeam(Player))
		{
			PlayersCount++;
			get_user_name(Player,Name,charsmax(Name));
			
			if(g_Ready[Player])
			{
				Readys++;
				formatex(List[0],charsmax(List[]),"%s%s^n",List[0],Name);
			}
			else
			{
				formatex(List[1],charsmax(List[]),"%s%s^n",List[1],Name);
			}
		}
	}
	
	new MinPlayers = get_pcvar_num(g_PlayersMin);
	
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,0.6,0.0,0.0);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_LIST_NOTREADY",(PlayersCount - Readys),MinPlayers);

	set_hudmessage(0,255,0,0.58,0.02,0,0.0,0.6,0.0,0.0);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_LIST_READY",Readys,MinPlayers);

	set_hudmessage(255,255,225,0.58,0.02,0,0.0,0.6,0.0,0.0);
	show_hudmessage(0,"^n%s",List[0]);

	set_hudmessage(255,255,225,0.23,0.02,0,0.0,0.6,0.0,0.0);
	show_hudmessage(0,"^n%s",List[1]);
}
