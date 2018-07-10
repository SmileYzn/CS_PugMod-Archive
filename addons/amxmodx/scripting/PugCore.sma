#include <PugCore>
#include <PugStocks>
#include <PugCS>

new g_State;

new g_Event;
new g_Return;

new g_PlayersMin;
new g_PlayersMax;

new g_MaxRounds;
new g_MaxRoundsOT;
new g_ForceOvertime;
new g_HandleTime;
new g_AllowSpec;
new g_pBanLeave;

new g_Round;
new g_Score[CsTeams];
new g_Teams[CsTeams][] = 
{
	"Unassigned",
	"Terrorists",
	"Counter-Terrorists",
	"Spectators"
};

public plugin_init()
{
	register_plugin("Pug Mod (Core)",PUG_VERSION,PUG_AUTHOR);
	
	register_dictionary("common.txt");
	register_dictionary("PugCore.txt");
	
	g_Event = CreateMultiForward("PugEvent",ET_IGNORE,FP_CELL);
	
	register_clcmd("say","SayHandle");
	register_clcmd("say_team","SayHandle");
	register_clcmd("jointeam","JoinTeamHandle");
	
	g_PlayersMin 	= create_cvar("pug_players_min","10",FCVAR_NONE,"Minimum of players to start a game");
	g_PlayersMax 	= create_cvar("pug_players_max","10",FCVAR_NONE,"Maximum of players allowed in the teams");
	g_MaxRounds 	= create_cvar("pug_rounds_max","30",FCVAR_NONE,"Rounds to play before start overtime");
	g_MaxRoundsOT 	= create_cvar("pug_rounds_ot","3",FCVAR_NONE,"Win difference to determine a winner in overtime");
	g_ForceOvertime = create_cvar("pug_force_ot","1",FCVAR_NONE,"Force Overtime (0 End game tied, 1 Force Overtime)");
	g_HandleTime 	= create_cvar("pug_handle_time","10.0",FCVAR_NONE,"Time to PUG change states");
	g_AllowSpec 	= create_cvar("pug_allow_spec","0",FCVAR_NONE,"Allow Spectators in game");
	g_pBanLeave 	= create_cvar("pug_drop_ban_time","15",FCVAR_NONE,"Minutes of ban players that leave from game in live");
	
	register_logevent("RoundStart",2,"1=Round_Start");
	register_logevent("RoundEnd",2,"1=Round_End");
	
	register_event("SendAudio","WonTR","a","2=%!MRAD_terwin");
	register_event("SendAudio","WonCT","a","2=%!MRAD_ctwin");
	register_event("SendAudio","RoundDraw","a","2=%!MRAD_rounddraw");
	register_event("TeamScore","TeamScore","a");
	
	PugRegCommand("status","Status",ADMIN_ALL,"PUG_DESC_STATUS");
	PugRegCommand("score","Score",ADMIN_ALL,"PUG_DESC_SCORE");
	PugRegCommand("help","Help",ADMIN_ALL,"PUG_DESC_HELP");
	
	PugRegCommand("help","HelpAdmin",ADMIN_LEVEL_A,"PUG_DESC_HELP_ADMIN");
	PugRegCommand("startpug","StartPug",ADMIN_LEVEL_A,"PUG_DESC_START");
	PugRegCommand("stoppug","StopPug",ADMIN_LEVEL_A,"PUG_DESC_STOP");

	register_menucmd(-2,MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6,"TeamSelectHandle");
	register_menucmd(register_menuid("Team_Select",1),MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6,"TeamSelectHandle");
}

public plugin_cfg()
{
	PugBuildHelpFile(ADMIN_ALL);
	PugBuildHelpFile(ADMIN_LEVEL_A);
	
	set_task(5.0,"NextState");
}

public plugin_natives()
{
	register_library("PugCore");
	
	register_native("PugNext","NextState");
}

public plugin_end()
{
	if(STATE_FIRSTHALF <= g_State <= STATE_OVERTIME)
	{
		g_State = STATE_END;
		ExecuteForward(g_Event,g_Return,g_State);
	}
}

public client_connectex(id,const Name[],const IP[],Reason[128])
{
	if(!get_pcvar_num(g_AllowSpec))
	{
		if(get_playersnum() >= get_pcvar_num(g_PlayersMax))
		{
			format(Reason,charsmax(Reason),"%L",LANG_SERVER,"PUG_FULL");
			return PLUGIN_HANDLED;
		}
	}	
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(id,bool:Drop,Msg[],Len)
{
	if(STATE_FIRSTHALF <= g_State <= STATE_OVERTIME)
	{
		if(get_playersnum() < get_pcvar_num(g_PlayersMin) / 2)
		{
			g_State = STATE_END;
			ExecuteForward(g_Event,g_Return,g_State);
		}
		else
		{
			new Time = get_pcvar_num(g_pBanLeave);
			
			if(Time)
			{
				if(equali(Msg,"Timed out") || equali(Msg,"Client sent 'drop'"))
				{
					if(!access(id,ADMIN_LEVEL_A))
					{
						new Auth[35];
						get_user_authid(id,Auth,charsmax(Auth));
											
						server_cmd("banid %i %s;wait;writeid",Time,Auth);
						
						new Name[MAX_NAME_LENGTH];
						get_user_name(id,Name,charsmax(Name));
						
						client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CLIENT_DROP",Name,Time,Msg);
					}
				}
			}
		}
	}
}

public NextState()
{
	switch(g_State)
	{
		case STATE_DEAD:
		{
			g_State = STATE_WARMUP;
		}
		case STATE_WARMUP:
		{
			g_State = STATE_START;
		}
		case STATE_START:
		{
			g_State = STATE_FIRSTHALF;
		}
		case STATE_FIRSTHALF:
		{
			g_State = STATE_HALFTIME;
		}
		case STATE_HALFTIME:
		{
			g_State = (g_Round < get_pcvar_num(g_MaxRounds)) ? STATE_SECONDHALF : STATE_OVERTIME;
		}
		case STATE_SECONDHALF:
		{
			if(g_Round == get_pcvar_num(g_MaxRounds))
			{
				if(get_pcvar_num(g_ForceOvertime))
				{
					g_State = STATE_HALFTIME;
				}
				else
				{
					g_State = STATE_END;
				}
			}
			else
			{
				g_State = STATE_END;
			}
		}
		case STATE_OVERTIME:
		{
			if((g_Round % get_pcvar_num(g_MaxRoundsOT)) == 0)
			{
				g_State = STATE_HALFTIME;
			}
			else
			{
				g_State = STATE_END;
			}
		}
		case STATE_END:
		{
			g_State = STATE_WARMUP;
		}
	}
	
	ExecuteForward(g_Event,g_Return,g_State);
}

public PugEvent(State)
{
	switch(State)
	{
		case STATE_WARMUP:
		{
			client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_BUILD",PUG_VERSION,PUG_AUTHOR);
		}
		case STATE_FIRSTHALF:
		{
			g_Round = 0;
			g_Score[CS_TEAM_T] = 0;
			g_Score[CS_TEAM_CT] = 0;
			
			PugMsg(0,"PUG_LIVE_1ST");
		}
		case STATE_HALFTIME:
		{													
			PugMsg(0,"PUG_HALFTIME");
			set_task(get_pcvar_float(g_HandleTime),"SwapTeams");
		}
		case STATE_SECONDHALF:
		{
			PugMsg(0,"PUG_LIVE_2ND");
		}
		case STATE_OVERTIME:
		{
			PugMsg(0,"PUG_LIVE_OT");
		}
		case STATE_END:
		{
			ShowScores(0,true);
			set_task(get_pcvar_float(g_HandleTime),"NextState");
			
		}
	}
}

public SayHandle(id)
{
	new Args[192];
	read_args(Args,charsmax(Args));
	remove_quotes(Args);
	
	if((Args[0] == '.') || (Args[0] == '!'))
	{
		
		client_cmd(id,Args);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public RoundStart()
{
	if(g_State == STATE_FIRSTHALF || g_State == STATE_SECONDHALF || g_State == STATE_OVERTIME)
	{
		ShowScores(0,false);
		console_print(0,"%s %L",g_Head,LANG_SERVER,"PUG_ROUND_START",g_Round+1);
	}
}

public RoundEnd()
{
	switch(g_State)
	{
		case STATE_FIRSTHALF:
		{
			if(g_Round == (get_pcvar_num(g_MaxRounds) / 2))
			{
				set_task(1.0,"NextState");
			}
		}
		case STATE_SECONDHALF:
		{
			if(g_Score[GetWinner()] > (get_pcvar_num(g_MaxRounds) / 2))
			{
				set_task(1.0,"NextState");
			}
			else
			{
				if(g_Round == get_pcvar_num(g_MaxRounds))
				{
					set_task(1.0,"NextState");
				}
			}
		}
		case STATE_OVERTIME:
		{
			new Rounds = get_pcvar_num(g_MaxRoundsOT);
			
			if((g_Round % Rounds) == 0)
			{
				set_task(1.0,"NextState");
			}
			else if((g_Score[CS_TEAM_T] - g_Score[CS_TEAM_CT]) > Rounds)
			{
				set_task(1.0,"NextState");
			}
			else if((g_Score[CS_TEAM_CT] - g_Score[CS_TEAM_T]) > Rounds)
			{
				set_task(1.0,"NextState");
			}
		}
	}
}

public WonTR()
{
	if(g_State == STATE_FIRSTHALF || g_State == STATE_SECONDHALF || g_State == STATE_OVERTIME)
	{
		g_Round++;
		g_Score[CS_TEAM_T]++;
		
		console_print(0,"%s %L",g_Head,LANG_SERVER,"PUG_ROUND_WON",g_Round,g_Teams[CS_TEAM_T]);
	}
}

public WonCT()
{
	if(g_State == STATE_FIRSTHALF || g_State == STATE_SECONDHALF || g_State == STATE_OVERTIME)
	{
		g_Round++;
		g_Score[CS_TEAM_CT]++;
		
		console_print(0,"%s %L",g_Head,LANG_SERVER,"PUG_ROUND_WON",g_Round,g_Teams[CS_TEAM_CT]);
	}
}

public RoundDraw()
{
	if(g_State == STATE_FIRSTHALF || g_State == STATE_SECONDHALF || g_State == STATE_OVERTIME)
	{
		client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_ROUND_DRAW",g_Round);
	}
}
	
public TeamScore()
{
	if(STATE_FIRSTHALF <= g_State <= STATE_OVERTIME)
	{
		set_gamerules_int("CHalfLifeMultiplay","m_iNumTerroristWins",g_Score[CS_TEAM_T]);
		set_gamerules_int("CHalfLifeMultiplay","m_iNumCTWins",g_Score[CS_TEAM_CT]);
	}
	
	return PLUGIN_CONTINUE;
}

public SwapTeams()
{
	new Temp = g_Score[CS_TEAM_T];
	
	g_Score[CS_TEAM_T] = g_Score[CS_TEAM_CT];
	g_Score[CS_TEAM_CT] = Temp;
	
	PugSwapTeams();
	
	if(PugGetPlayersNum(true) >= get_pcvar_num(g_PlayersMin))
	{
		NextState();
	}
}

public Status(id)
{
	client_print_color
	(
		id,
		print_team_red,
		"%s %L",
		g_Head,
		LANG_SERVER,
		"PUG_STATUS",
		g_States[g_State],
		get_playersnum(),
		get_pcvar_num(g_PlayersMin),
		get_pcvar_num(g_PlayersMax)
	);
	
	return PLUGIN_HANDLED;
}

public Score(id)
{
	if(STATE_FIRSTHALF <= g_State <= STATE_OVERTIME)
	{
		ShowScores(id,false);
	}
	else
	{
		PugMsg(id,"PUG_CMD_ERROR");
	}
	
	return PLUGIN_HANDLED;
}

ShowScores(id,bool:End)
{
	new CsTeams:Winner = GetWinner();
	
	if(Winner)
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,End ? "PUG_END_WONALL" : "PUG_SCORE",g_Teams[Winner],g_Score[Winner],(Winner == CS_TEAM_T) ? g_Score[CS_TEAM_CT] : g_Score[CS_TEAM_T]);
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,End ? "PUG_END_TIED" : "PUG_SCORE_TIED",g_Score[CS_TEAM_T],g_Score[CS_TEAM_CT]);
	}
}

CsTeams:GetWinner()
{
	if(g_Score[CS_TEAM_T] != g_Score[CS_TEAM_CT])
	{
		return (g_Score[CS_TEAM_T] > g_Score[CS_TEAM_CT]) ? CS_TEAM_T : CS_TEAM_CT;
	}
	
	return CS_TEAM_UNASSIGNED;
}

public Help(id)
{
	new Path[64];
	PugGetFilePath("help.htm",Path,charsmax(Path));
	
	new Title[32];
	format(Title,charsmax(Title),"%L",LANG_SERVER,"PUG_HELP_TITLE");

	show_motd(id,Path,Title);
	
	return PLUGIN_HANDLED;
}

public HelpAdmin(id,Level)
{
	if(access(id,Level))
	{
		new Path[64];
		PugGetFilePath("admin.htm",Path,charsmax(Path));
		
		new Title[32];
		format(Title,charsmax(Title),"%L",LANG_SERVER,"PUG_HELP_TITLE_ADM");
	
		show_motd(id,Path,Title);
	}
	
	return PLUGIN_HANDLED;
}

public StartPug(id,Level)
{
	if(access(id,Level))
	{
		new bool:Check = (g_State == STATE_WARMUP);
		
		if(Check)
		{
			g_State = STATE_START;
			ExecuteForward(g_Event,g_Return,g_State);
			
		}
		
		PugCommand(id,"!startpug","PUG_START_PUG",Check);
	}
	
	return PLUGIN_HANDLED;
}

public StopPug(id,Level)
{
	if(access(id,Level) || (id == 0))
	{
		new bool:Check = (STATE_FIRSTHALF <= g_State <= STATE_OVERTIME);
		
		if(Check)
		{
			g_State = STATE_END;
			ExecuteForward(g_Event,g_Return,g_State);
			
		}
		
		PugCommand(id,"!stoppug","PUG_STOP_PUG",Check);
	}
	
	return PLUGIN_HANDLED;
}

public JoinTeamHandle(id)
{
	new Arg[2];
	read_argv(1,Arg,charsmax(Arg));
	
	return CheckTeam(id,str_to_num(Arg));
}

public TeamSelectHandle(id,Key)
{
	return CheckTeam(id,Key + 1);
}

public CheckTeam(id,NewTeam)
{
	new OldTeam = _:cs_get_user_team(id);
	
	if(NewTeam == OldTeam)
	{
		PugMsg(id,"PUG_TEAM_SAME");
		return PLUGIN_HANDLED;
	}
	
	if(NewTeam == 5)
	{
		PugMsg(id,"PUG_TEAM_AUTO");
		return PLUGIN_HANDLED;
	}
	
	if(NewTeam == 6)
	{
		if(!get_pcvar_num(g_AllowSpec) && !access(id,ADMIN_LEVEL_A))
		{
			PugMsg(id,"PUG_TEAM_SPEC");
			return PLUGIN_HANDLED;
		}
	}
	
	if(STATE_START <= g_State <= STATE_OVERTIME)
	{
		if(OldTeam == 1 || OldTeam == 2)
		{
			PugMsg(id,"PUG_TEAM_NONE");
			return PLUGIN_HANDLED;
		}
	}
	
	if(PugGetPlayersTeamNum(true,NewTeam) >= get_pcvar_num(g_PlayersMax) / 2)
	{
		PugMsg(id,"PUG_TEAM_FULL");
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
