#include <PugCore>
#include <PugStocks>
#include <PugCS>

new g_DeadTalk;
new g_TeamMoney;
new g_KeepScore;

new g_Hits[MAX_PLAYERS+1][MAX_PLAYERS+1];
new g_Damage[MAX_PLAYERS+1][MAX_PLAYERS+1];
new g_Frags[MAX_PLAYERS+1][2];

new bool:g_Live;
new bool:g_Round;

public plugin_init()
{
	register_plugin("Pug Mod (Aux)",PUG_VERSION,PUG_AUTHOR);

	register_dictionary("PugCore.txt");
	register_dictionary("PugAux.txt");
	
	g_DeadTalk = create_cvar("pug_dead_talk","1",FCVAR_NONE,"Allow Dead talk when match is live");
	g_TeamMoney = create_cvar("pug_team_money","1",FCVAR_NONE,"Display Teammates money at round start");
	g_KeepScore = create_cvar("pug_fix_scores","1",FCVAR_NONE,"Keep scoreboard after change teams");

	PugRegCommand("hp","HP",ADMIN_ALL,"PUG_DESC_HP");
	PugRegCommand("dmg","Damage",ADMIN_ALL,"PUG_DESC_DMG");
	PugRegCommand("rdmg","RecivedDamage",ADMIN_ALL,"PUG_DESC_RDMG");
	PugRegCommand("sum","Summary",ADMIN_ALL,"PUG_DESC_SUM");
	
	register_logevent("RoundStart",2,"1=Round_Start");
	register_logevent("RoundEnd",2,"1=Round_End");
	
	register_forward(FM_Voice_SetClientListening,"FMVoiceSetClientListening",false);
	
	register_event("StatusIcon","OnBuyZone","bef","1=1","2=buyzone");
	
	register_message(get_user_msgid("TeamScore"),"TeamScore");
	register_message(get_user_msgid("ScoreInfo"),"ScoreInfo");
}

public PugEvent(State)
{
	g_Live = (State == STATE_FIRSTHALF || State == STATE_SECONDHALF || State == STATE_OVERTIME);
	
	if(State == STATE_HALFTIME)
	{
		if(get_pcvar_num(g_KeepScore))
		{
			new Players[MAX_PLAYERS],Num,Player;
			
			get_players(Players,Num,"h");
			
			for(new i;i < Num;i++)
			{
				Player = Players[i];
				
				g_Frags[Player][0] = get_user_frags(Player);
				g_Frags[Player][1] = get_user_deaths(Player);
			}
		}
	}
	
}

public client_putinserver(id)
{
	for(new i;i < MAX_PLAYERS;i++)
	{
		g_Hits[i][id] = 0;
		g_Damage[i][id] = 0;
	}
	
	arrayset(g_Frags[id],0,sizeof(g_Frags[]));
}

public client_damage(Attacker,Victim,Dmg)
{
	g_Hits[Attacker][Victim]++;
	g_Damage[Attacker][Victim] += Dmg;
}

public RoundStart()
{
	g_Round = true;
	
	for(new i;i < MAX_PLAYERS;i++)
	{
		arrayset(g_Hits[i],0,sizeof(g_Hits));
		arrayset(g_Damage[i],0,sizeof(g_Damage));	
	}
}

public RoundEnd()
{
	g_Round = false;
}

public HP(id)
{
	if(g_Live)
	{
		if((is_user_alive(id) && g_Round) || !isTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
		}
		else
		{
			new Players[MAX_PLAYERS],Num;
			get_players(Players,Num,"aeh",(get_user_team(id) == 1) ? "CT" : "TERRORIST");
			
			if(!Num)
			{
				client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_HP_NONE");
				return PLUGIN_HANDLED;
			}
			
			new Name[MAX_NAME_LENGTH],Player;
			
			for(new i;i < Num;i++)
			{
				Player = Players[i];
			
				get_user_name(Player,Name,charsmax(Name));
				client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_HP_CMD",Name,get_user_health(Player),get_user_armor(Player));
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
	}
	
	return PLUGIN_HANDLED;
}

public Damage(id)
{
	if(g_Live)
	{
		if((is_user_alive(id) && g_Round) || !isTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
		}
		else
		{
			new Players[MAX_PLAYERS],Num,Player;
			get_players(Players,Num,"h");
			
			new Name[MAX_NAME_LENGTH];
			new Dmg,Hit,Check;
			
			for(new i;i < Num;i++)
			{
				Player = Players[i];
				Hit = g_Hits[id][Player];
				
				if(Hit)
				{
					++Check;
					Dmg = g_Damage[id][Player];
					
					if(Player == id)
					{
						client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_DMG_SELF",Hit,Dmg);
					}
					else
					{
						get_user_name(Player,Name,charsmax(Name));						
						client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_DMG",Name,Hit,Dmg);
					}
				}
			}
			
			if(!Check)
			{
				client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_NODMG");
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
	}
	
	return PLUGIN_HANDLED;
}

public RecivedDamage(id)
{
	if(g_Live)
	{
		if((is_user_alive(id) && g_Round) || !isTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
		}
		else
		{
			new Players[MAX_PLAYERS],Num,Player;
			get_players(Players,Num,"h");
			
			new Name[MAX_NAME_LENGTH];
			new Dmg,Hit,Check;
			
			for(new i;i < Num;i++)
			{
				Player = Players[i];
				Hit = g_Hits[Player][id];
				
				if(Hit)
				{
					++Check;
					Dmg = g_Damage[Player][id];
					
					if(Player == id)
					{
						client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_RDMG_SELF",Hit,Dmg);
					}
					else
					{
						get_user_name(Player,Name,charsmax(Name));						
						client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_RDMG",Name,Hit,Dmg);
					}
				}
			}
			
			if(!Check)
			{	
				client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_NORDMG");
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
	}
	
	return PLUGIN_HANDLED;
}

public Summary(id)
{
	if(g_Live)
	{
		if((is_user_alive(id) && g_Round) || !isTeam(id))
		{
			client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
		}
		else
		{
			new Players[MAX_PLAYERS],Num,Player;
			get_players(Players,Num,"h");
			
			new Name[MAX_NAME_LENGTH];
			
			new Dmg[2],Hit[2],Check;
			
			for(new i;i < Num;i++)
			{
				Player = Players[i];
				
				if(id == Player)
				{
					continue;
				}
				
				Hit[0] = g_Hits[id][Player]; // Hits Done
				Hit[1] = g_Hits[Player][id]; // Hits Recived
				
				if(Hit[0] || Hit[1])
				{
					++Check;
					
					Dmg[0] = g_Damage[id][Player]; // Damage Done
					Dmg[1] = g_Damage[Player][id]; // Damag Recived
					
					get_user_name(Player,Name,charsmax(Name));
					client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_SUM",Dmg[0],Hit[0],Dmg[1],Hit[1],Name,(is_user_alive(Player) ? get_user_health(Player) : 0));
				}
			}
		
			if(!Check)
			{
				client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_NOSUM");
			}
		}
	}
	else
	{
		client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,"PUG_CMD_ERROR");
	}
	
	return PLUGIN_HANDLED;
}

public FMVoiceSetClientListening(Recv,Sender,bool:Listen)
{
	if(g_Live)
	{
		if(Recv != Sender)
		{
			if(get_pcvar_num(g_DeadTalk))
			{
				if(is_user_connected(Recv) && is_user_connected(Sender))
				{
					if(get_user_team(Recv) == get_user_team(Sender))
					{
						engfunc(EngFunc_SetClientListening,Recv,Sender,true);
						return FMRES_SUPERCEDE;
					}
				}
			}
		}
	}
	
	return FMRES_IGNORED;
} 

public OnBuyZone(id)
{
	if(g_Live)
	{
		if(get_pcvar_num(g_TeamMoney))
		{
			new Team[13];
			get_user_team(id,Team,charsmax(Team));
		
			new Players[MAX_PLAYERS],Num,Player;
			get_players(Players,Num,"eh",Team);
		
			new Name[MAX_NAME_LENGTH],List[MAX_NAME_LENGTH*10];
		
			for(new i;i < Num;i++)
			{
				Player = Players[i];
				
				get_user_name(Player,Name,charsmax(Name));
		
				format(List,charsmax(List),"%s%s $ %i^n",List,Name,cs_get_user_money(Player));
			}
			
			set_hudmessage(0,255,0,0.58,0.02,0,3.0,10.0,0.0,0.0,3);
			show_hudmessage(id,Team);

			set_hudmessage(255,255,225,0.58,0.05,0,3.0,10.0,0.0,0.0,4);
			show_hudmessage(id,List);
		}
	}
}

public TeamScore()
{
	if(get_pcvar_num(g_KeepScore))
	{
		new Buff[16];
		get_msg_arg_string(1,Buff,charsmax(Buff));

		set_msg_arg_int(2,ARG_SHORT,PugGetScore((Buff[0] == 'T') ? 1 : 2));
	}
}

public ScoreInfo(Msg,Dest)
{
	if(get_pcvar_num(g_KeepScore))
	{
		if(Dest == MSG_ALL || Dest == MSG_BROADCAST)
		{
			if(get_msg_arg_int(5)) 
			{
				new id = get_msg_arg_int(1); 
			
				set_msg_arg_int(2,ARG_SHORT,get_msg_arg_int(2) + g_Frags[id][0]);
				set_msg_arg_int(3,ARG_SHORT,get_msg_arg_int(3) + g_Frags[id][1]);
			}
		}
	}
}  
