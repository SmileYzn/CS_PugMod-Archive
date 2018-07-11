#include <PugCore>
#include <PugStocks>
#include <PugMenus>
#include <PugCS>

#define TASK_VOTE 2018
#define TASK_LIST 2019
	
#define MAX_MAPS 		32
#define MAX_TEAM 		5
#define MIN_PLAYERS_CAPTAIN 	4

new g_VoteDelay;
new g_MapVoteType;
new g_MapVote;
new g_TeamEnforcement;

new g_MenuMain;
new g_MenuMap;
new g_MenuTeams;

new g_MapCount;
new g_MapNames[MAX_MAPS][MAX_NAME_LENGTH];
new g_MapVotes[MAX_MAPS];

new g_TeamTypes[MAX_TEAM][MAX_NAME_LENGTH];
new g_TeamVotes[MAX_TEAM];

new g_VotesNum;

new g_Voted[MAX_PLAYERS+1];
new g_Votes[MAX_PLAYERS+1];

new g_Captain[2];

public plugin_init()
{
	register_plugin("Pug Mod (Menu System)",PUG_VERSION,PUG_AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("PugMenus.txt");

	g_VoteDelay		= create_cvar("pug_vote_delay","15.0",FCVAR_NONE,"How long voting session goes on");
	g_MapVoteType		= create_cvar("pug_vote_map_enabled","1",FCVAR_NONE,"Active vote map in pug (0 Disable, 1 Enable, 2 Random map)");
	g_MapVote		= create_cvar("pug_vote_map","0",FCVAR_NONE,"Determine if current map will have the vote map (Not used at Pug config file)");
	g_TeamEnforcement	= create_cvar("pug_teams_enforcement","0",FCVAR_NONE,"The teams method for assign teams (0 Vote, 1 Captains, 2 Automatic, 3 None, 4 Skill)");

	PugRegCommand("votekick","VoteKick",ADMIN_ALL,"PUG_DESC_VOTEKICK");
	
	register_clcmd("vote","HLDSBlock");
	register_clcmd("votemap","HLDSBlock");
}

public plugin_cfg()
{
	new Title[32];
	format(Title,charsmax(Title),"%L",LANG_SERVER,"PUG_HUD_MAP");
	
	g_MapCount = PugBuildMapsMenu(Title,"MenuMapHandle",g_MenuMap,g_MapNames,sizeof(g_MapNames));
	
	format(Title,charsmax(Title),"%L",LANG_SERVER,"PUG_HUD_TEAM");
	
	g_MenuTeams = menu_create(Title,"MenuVoteTeamHandle");
	
	format(g_TeamTypes[0],charsmax(g_TeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_VOTE");
	format(g_TeamTypes[1],charsmax(g_TeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_CAPTAIN");
	format(g_TeamTypes[2],charsmax(g_TeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_AUTO");
	format(g_TeamTypes[3],charsmax(g_TeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_NONE");
	format(g_TeamTypes[4],charsmax(g_TeamTypes[]),"%L",LANG_SERVER,"PUG_TEAM_TYPE_SKILL");
	
	menu_additem(g_MenuTeams,g_TeamTypes[1],"1");
	menu_additem(g_MenuTeams,g_TeamTypes[2],"2");
	menu_additem(g_MenuTeams,g_TeamTypes[3],"3");
	menu_additem(g_MenuTeams,g_TeamTypes[4],"4");
	
	menu_setprop(g_MenuTeams,MPROP_EXIT,MEXIT_NEVER);
}

public client_disconnected(id,bool:Drop,Msg[],Len)
{
	if(g_Voted[id])
	{
		new Players[MAX_PLAYERS],Num;
		get_players(Players,Num,"h");
		
		for(new i;i < Num;i++)
		{
			if(g_Voted[id] & (1 << Players[i]))
			{
				g_Votes[Players[i]]--;
			}
		}
		
		g_Voted[id] = 0;
	}
}

public PugEvent(State)
{
	if(State == STATE_START)
	{
		new VoteType = get_pcvar_num(g_MapVoteType);
		
		if(get_pcvar_num(g_MapVote) && (VoteType > 0))
		{
			switch(VoteType)
			{
				case 1:
				{
					MapVoteStart();
				}
				case 2:
				{
					new Map[MAX_NAME_LENGTH];
					get_mapname(Map,charsmax(Map));
					
					new MapId = random(g_MapCount);
			
					while(equali(Map,g_MapNames[MapId]) || !is_map_valid(g_MapNames[MapId]))
					{
						MapId = random(g_MapCount);
					}
					
					set_pcvar_num(g_MapVote,0);
					
					set_task(5.0,"ChangeMap",MapId);
					client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEMAP_NEXTMAP",g_MapNames[MapId]);
				}
			}
		}
		else
		{
			new Type = get_pcvar_num(g_TeamEnforcement);
			
			if(Type)
			{
				ChangeTeams(Type);
			}
			else
			{
				TeamVoteStart();
			}	
		}
	}
	else if(State == STATE_END)
	{
		set_pcvar_num(g_MapVote,1);
	}
}

public MapVoteStart()
{
	g_VotesNum = 0;
	arrayset(g_MapVotes,0,sizeof(g_MapVotes));

	PugDisplayMenuAll(g_MenuMap);
	
	client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEMAP_START");
	
	set_task(0.5,"HudListMap",TASK_LIST, .flags="b");
	set_task(get_pcvar_float(g_VoteDelay),"MapVoteEnd",TASK_VOTE);
}

public HudListMap()
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,0.7,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_MAP");
	
	new Result[256];
	
	for(new i;i < g_MapCount;i++)
	{
		if(g_MapVotes[i])
		{
			format(Result,charsmax(Result),"%s[%i] %s^n",Result,g_MapVotes[i],g_MapNames[i]);
		}
	}
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,0.7,0.0,0.0,4);
	
	if(Result[0])
	{
		show_hudmessage(0,Result);
	}
	else
	{
		show_hudmessage(0,"%L",LANG_SERVER,"PUG_NOVOTES");
	}
		
}

public MenuMapHandle(id,Menu,Key)
{
	if(Key == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new Access,CallBack,Num[3],Option[MAX_NAME_LENGTH];
	menu_item_getinfo(Menu,Key,Access,Num,charsmax(Num),Option,charsmax(Option),CallBack);
	
	g_VotesNum++;
	g_MapVotes[str_to_num(Num)]++;
	
	new Name[MAX_NAME_LENGTH];
	get_user_name(id,Name,charsmax(Name));
	
	client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTE_CHOOSED",Name,Option);
	
	if(g_VotesNum >= PugGetPlayersNum(false))
	{
		MapVoteEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public MapVoteEnd()
{
	PugCancelMenu(0);
	remove_task(TASK_VOTE);
	remove_task(TASK_LIST);
	
	if(!MapVoteCount())
	{
		set_task(get_pcvar_float(g_VoteDelay),"MapVoteStart",TASK_VOTE);
	}
}

MapVoteCount()
{
	new Winner,WinnerVotes,Votes;

	for(new i;i < g_MapCount;i++)
	{
		Votes = g_MapVotes[i];
		
		if(Votes > WinnerVotes)
		{
			Winner = i;
			WinnerVotes = Votes;
		}
		else if(Votes == WinnerVotes)
		{
			if(random_num(0,1))
			{
				Winner = i;
				WinnerVotes = Votes;
			}
		}
	}

	if(!g_MapVotes[Winner])
	{
		client_print_color(0,print_team_red,"%s %L %L",g_Head,LANG_SERVER,"PUG_VOTEMAP_FAIL",LANG_SERVER,"PUG_NOVOTES");
		return 0;
	}


	set_pcvar_num(g_MapVote,0);
	set_task(5.0,"ChangeMap",Winner);
	client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEMAP_NEXTMAP",g_MapNames[Winner]);
	
	return g_MapVotes[Winner];
}

public ChangeMap(Map)
{
	server_cmd("changelevel %s",g_MapNames[Map]);
}

public TeamVoteStart()
{
	g_VotesNum = 0;
	arrayset(g_TeamVotes,0,sizeof(g_TeamVotes));

	PugDisplayMenuAll(g_MenuTeams);
	
	client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_TEAMVOTE_START");
	
	set_task(0.5,"HudListTeam",TASK_LIST, .flags="b");
	set_task(get_pcvar_float(g_VoteDelay),"TeamVoteEnd",TASK_VOTE);
	
	return PLUGIN_HANDLED;
}

public HudListTeam()
{
	set_hudmessage(0,255,0,0.23,0.02,0,0.0,0.7,0.0,0.0,3);
	show_hudmessage(0,"%L",LANG_SERVER,"PUG_HUD_TEAM");
	
	new Result[128];
	
	for(new i;i < MAX_TEAM;i++)
	{
		if(g_TeamVotes[i])
		{
			format(Result,charsmax(Result),"%s[%i] %s^n",Result,g_TeamVotes[i],g_TeamTypes[i]);
		}
	}
	
	set_hudmessage(255,255,255,0.23,0.05,0,0.0,0.7,0.0,0.0,4);
	
	if(Result[0])
	{
		show_hudmessage(0,Result);
	}
	else
	{
		show_hudmessage(0,"%L",LANG_SERVER,"PUG_NOVOTES");
	}
}

public MenuVoteTeamHandle(id,Menu,Key)
{
	if(Key == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	 
	new Access,CallBack,Num[3],Option[MAX_NAME_LENGTH];
	menu_item_getinfo(Menu,Key,Access,Num,charsmax(Num),Option,charsmax(Option),CallBack);
	
	g_VotesNum++;
	g_TeamVotes[str_to_num(Num)]++;

	new Name[MAX_NAME_LENGTH];
	get_user_name(id,Name,charsmax(Name));
	
	client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTE_CHOOSED",Name,Option);
	
	if(g_VotesNum >= PugGetPlayersNum(false))
	{
		TeamVoteEnd();
	}
	 
	return PLUGIN_HANDLED;
}

public TeamVoteEnd()
{
	PugCancelMenu(0);

	remove_task(TASK_VOTE);
	remove_task(TASK_LIST);
	
	if(!TeamVoteCount())
	{
		set_task(get_pcvar_float(g_VoteDelay),"TeamVoteStart",TASK_VOTE);
	}
}

TeamVoteCount()
{
	new Winner,WinnerVotes,Votes;

	for(new i;i < sizeof(g_TeamVotes);i++)
	{
		Votes = g_TeamVotes[i];
		
		if(Votes > WinnerVotes)
		{
			Winner = i;
			WinnerVotes = Votes;
		}
		else if(Votes == WinnerVotes)
		{
			if(random_num(0,1))
			{
				Winner = i;
				WinnerVotes = Votes;
			}
		}
	}

	if(!g_TeamVotes[Winner])
	{
		client_print_color(0,print_team_red,"%s %L %L",g_Head,LANG_SERVER,"PUG_TEAMVOTE_FAIL",LANG_SERVER,"PUG_NOVOTES");
		return 0;
	}
	
	ChangeTeams(Winner);
	
	return g_TeamVotes[Winner];
}

ChangeTeams(Type)
{
	switch(Type)
	{
		case 1:
		{
			new Players[MAX_PLAYERS],Num;
			get_players(Players,Num,"h");
			
			if(Num > MIN_PLAYERS_CAPTAIN)
			{	
				new Player;
				
				for(new i;i < Num;i++)
				{
					Player = Players[i];
					
					user_silentkill(Player);
					cs_set_user_team(Player,CS_TEAM_SPECTATOR);
				}
				
				arrayset(g_Captain,0,sizeof(g_Captain));
				
				g_Captain[0] = Players[random(Num)];
				g_Captain[1] = Players[random(Num)];
				
				while(g_Captain[0] == g_Captain[1])
				{
					g_Captain[1] = Players[random(Num)];
				}
				
				cs_set_user_team(g_Captain[0],CS_TEAM_T);
				cs_set_user_team(g_Captain[1],CS_TEAM_CT);
				
				new Name[2][MAX_NAME_LENGTH];
				get_user_name(g_Captain[0],Name[0],charsmax(Name[]));
				get_user_name(g_Captain[1],Name[1],charsmax(Name[]));
				
				ExecuteHamB(Ham_CS_RoundRespawn,g_Captain[0]);
				ExecuteHamB(Ham_CS_RoundRespawn,g_Captain[1]);
				
				client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CAPTAINS_ARE",Name[0],Name[1]);
				
				set_task(0.5,"HudListTeams",TASK_LIST, .flags="b");
				set_task(2.0,"CaptainMenu",g_Captain[random_num(0,1)]);
			}
			else
			{
				PugNext();
			}
		}
		case 2:
		{
			PugRamdomizeTeams(false);
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_TEAMS_RANDOM");
			PugNext();
		}
		case 3:
		{
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_TEAMS_SAME");
			PugNext();
		}
		case 4:
		{
			PugRamdomizeTeams(true);
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_TEAMS_SKILL");
			PugNext();
		}
	}
}

public MainMenu(id,Level)
{
	if(access(id,Level) && (id != 0))
	{
		PugDisplayMenuSingle(id,g_MenuMain);
	}
	
	return PLUGIN_HANDLED;
}

public MainMenuHandle(id,Menu,Key)
{
	if(Key != MENU_EXIT)
	{
		new Access,CallBack,Command[64],Option[MAX_NAME_LENGTH];
		menu_item_getinfo(Menu,Key,Access,Command,charsmax(Command),Option,charsmax(Option),CallBack);
		
		client_cmd(id,Command);
	}

	return PLUGIN_HANDLED;
}

public VoteKick(id)
{
	if(isTeam(id) && get_playersnum() > 3)
	{
		new Menu = menu_create("Players:","VoteKickMenuHandle");
		
		new Team[13];
		get_user_team(id,Team,charsmax(Team));
		
		new Players[MAX_PLAYERS],Num;
		new Player,Name[MAX_NAME_LENGTH];
		new Temp[3];
		
		get_players(Players,Num,"he",Team);
		
		for(new i;i < Num;i++)
		{
			Player = Players[i];
			
			if((Player != id) && !is_user_admin(Player))
			{
				get_user_name(Player,Name,charsmax(Name));
				num_to_str(Player,Temp,charsmax(Temp));
				
				if(g_Voted[id] & (1 << Player))
				{
					menu_additem(Menu,Name,Temp,_,menu_makecallback("VoteKickMenuCallBack"));
				}
				else
				{
					menu_additem(Menu,Name,Temp);
				}
			}
		}
		
		menu_display(id,Menu);
	}
	else
	{
		client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEKICK_BLOCK");
	}
	
	return PLUGIN_HANDLED;
}

public VoteKickMenuCallBack(id,Menu,Key)
{
	new Access,CallBack,Num[3],Option[MAX_NAME_LENGTH];
	menu_item_getinfo(Menu,Key,Access,Num,charsmax(Num),Option,charsmax(Option),CallBack);
	
	new Player = str_to_num(Num);
	
	if(is_user_connected(Player))
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEKICK_ALREADY",Option);
	}
	
	return ITEM_DISABLED;
}

public VoteKickMenuHandle(id,Menu,Key)
{
	if(Key == MENU_EXIT)
	{
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
	
	new Access,CallBack,Num[3],Option[MAX_NAME_LENGTH];
	menu_item_getinfo(Menu,Key,Access,Num,charsmax(Num),Option,charsmax(Option),CallBack);
	
	new Player = str_to_num(Num);
	
	if(is_user_connected(Player))
	{
		g_Votes[Player]++;
		g_Voted[id] |= (1 << Player);
		
		new Need = PugGetPlayersTeamNum(true,get_user_team(id)) - 2;
		
		if(g_Votes[Player] < Need)
		{
			new Name[MAX_NAME_LENGTH];
			get_user_name(id,Name,charsmax(Name));
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEKICK_VOTED",Name,Option,g_Votes[Player],Need);
		}
		else
		{
			server_cmd("kick #%i ^"%L^"",get_user_userid(Player),LANG_SERVER,"PUG_VOTEKICK_MSG");
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_VOTEKICK_KICKED",Option,g_Votes[Player],Need);
		}
	}
	
	return PLUGIN_HANDLED;
}

public CaptainMenu(id)
{
	new Players[MAX_PLAYERS],Num,Player;
	get_players(Players,Num,"eh","SPECTATOR");
	
	if(!is_user_connected(id) && (Num > 0))
	{
		Player = Players[random(Num)];
		
		new Name[MAX_NAME_LENGTH];
		get_user_name(Player,Name,charsmax(Name));
		
		if(id == g_Captain[0])
		{
			g_Captain[0] = Player;
			cs_set_user_team(Player,CS_TEAM_T);
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CAPTAINS_NEW_T",Name);
		}
		else if(id == g_Captain[1])
		{
			g_Captain[1] = Player;
			cs_set_user_team(Player,CS_TEAM_CT);
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CAPTAINS_NEW_CT",Name);
		}
		
		set_task(2.0,"CaptainMenu",Player);
	}
	else
	{
		if(Num)
		{
			if(is_user_bot(id))
			{
				CaptainAutoPick(id);
			}
			else
			{
				PugCancelMenu(id);
				
				new Menu = menu_create("Players:","MenuCaptainHandler");
				
				new Name[MAX_NAME_LENGTH],Option[3];
				
				for(new i;i < Num;i++)
				{
					Player = Players[i];
					
					num_to_str(Player,Option,charsmax(Option));
					get_user_name(Player,Name,charsmax(Name));
					
					menu_additem(Menu,Name,Option);
				}
				
				menu_setprop(Menu,MPROP_EXIT,MEXIT_NEVER);
				
				PugDisplayMenuSingle(id,Menu);
				
				set_task(10.0,"CaptainAutoPick",id);
			}
		}
		else
		{
			remove_task(TASK_LIST);
			PugNext();
		}
	}
}

public MenuCaptainHandler(id,Menu,Key)
{
	if(Key != MENU_EXIT)
	{
		new Access,Data[3],Option[MAX_NAME_LENGTH],Back;
		menu_item_getinfo(Menu,Key,Access,Data,charsmax(Data),Option,charsmax(Option),Back);
		
		new Player = str_to_num(Data);
		
		if(is_user_connected(Player) && is_user_connected(id))
		{
			remove_task(id);
			
			cs_set_user_team(Player,cs_get_user_team(id));
			ExecuteHamB(Ham_CS_RoundRespawn,Player);
			
			new Name[MAX_NAME_LENGTH];
			get_user_name(id,Name[0],charsmax(Name));
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CAPTAINS_PICK",Name,Option);
		}
		
		set_task(2.0,"CaptainMenu",(id == g_Captain[0]) ? g_Captain[1] : g_Captain[0]);
	}
	
	return PLUGIN_HANDLED;
}

public CaptainAutoPick(id)
{
	PugCancelMenu(id);
	
	new Players[MAX_PLAYERS],Num;
	get_players(Players,Num,"eh","SPECTATOR");
	
	if(Num)
	{
		new Player = Players[random(Num)];
		
		if(is_user_connected(Player) && is_user_connected(id))
		{
			cs_set_user_team(Player,cs_get_user_team(id));
			ExecuteHamB(Ham_CS_RoundRespawn,Player);
			
			new Name[2][MAX_NAME_LENGTH];
			get_user_name(id,Name[0],charsmax(Name[]));
			get_user_name(Player,Name[1],charsmax(Name[]));
			
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CAPTAINS_PICK",Name[0],Name[1]);
		}
		
		set_task(2.0,"CaptainMenu",(id == g_Captain[0]) ? g_Captain[1] : g_Captain[0]);
	}
	else
	{
		remove_task(TASK_LIST);
		PugNext();
	}
}

public HudListTeams()
{
	new Players[MAX_PLAYERS],Num,Player;
	get_players(Players,Num,"h");
	
	new Name[MAX_NAME_LENGTH],SelectedCT,List[4][320],Team,Specs;

	for(new i;i < Num;i++)
	{
		Player = Players[i];
		
		get_user_name(Player,Name,charsmax(Name));
		
		if((Player == g_Captain[0]) || (Player == g_Captain[1]))
		{
			add(Name,charsmax(Name)," (C)");
		}
		
		Team = get_user_team(Player);
		
		switch(Team)
		{
			case 2: SelectedCT++;
			case 3: Specs++;
		}
		
		add(Name,charsmax(Name),"^n");
		add(List[Team],charsmax(List[]),Name);
	}
	
	for(new i = 0;i < 5 - SelectedCT;i++)
	{
		add(List[2],charsmax(List[]),"^n");
	}

	set_hudmessage(0,255,0,0.75,0.02,0,0.0,99.0,0.0,0.0,1);
	show_hudmessage(0,"Terrorists");
	
	set_hudmessage(255,255,255,0.75,0.02,0,0.0,99.0,0.0,0.0,2);
	show_hudmessage(0,"^n%s",List[1]);

	if(Specs)
	{
		set_hudmessage(0,255,0,0.75,0.28,0,0.0,99.0,0.0,0.0,3);
		show_hudmessage(0,"CTs^n^n^n^n^n^n%L",LANG_SERVER,"PUG_CAPTAINS_UNASSIGNED");
		
		set_hudmessage(255,255,255,0.75,0.28,0,0.0,99.0,0.0,0.0,4);
		show_hudmessage(0,"^n%s^n%s",List[2],List[3]);
	}
	else
	{
		set_hudmessage(0,255,0,0.75,0.28,0,0.0,99.0,0.0,0.0,3);
		show_hudmessage(0,"CTs");
		
		set_hudmessage(255,255,255,0.75,0.28,0,0.0,99.0,0.0,0.0,4);
		show_hudmessage(0,"^n%s",List[2]);
	}
}

public HLDSBlock(id)
{
	return PLUGIN_HANDLED;
}
