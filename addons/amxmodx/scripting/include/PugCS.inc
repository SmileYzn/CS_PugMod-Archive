#if defined _PugCS_included
	#endinput
#endif
#define _PugCS_included

#include <cstrike>
#include <csx>

/**
 * Check if a client is in a valid team
 *
 * @return 	Return true or false
 */
 #define isTeam(%0) (CS_TEAM_T <= cs_get_user_team(%0) <= CS_TEAM_CT)
 
 /**
 * Get players count in teams
 *
 * @param Bots	If true, will also count bots
 *
 * @return 	Return the number of active players in teams
 */
 stock PugGetPlayersNum(bool:Bots)
 {
	new Players[MAX_PLAYERS],Num[2];
	
	get_players(Players,Num[0],Bots ? "he" : "che","TERRORIST");
	get_players(Players,Num[1],Bots ? "he" : "che","CT");
	
	return Num[0] + Num[1];
}

 /**
 * Get players count in specific team
 *
 * @param Bots	If true, will also count bots
 * @param Team	Team to count
 *
 * @return 	Return the number of active players
 */
 stock PugGetPlayersTeamNum(bool:Bots,Team)
 {
 	if(1 <= Team <= 2)
	{
		new Players[MAX_PLAYERS],Num;
		get_players(Players,Num,Bots ? "he" : "che",(Team == 1) ? "TERRORIST" : "CT");
	
		return Num;
	}
	
	return 0;
}

 /**
 * Organize teams by player skills or randomly chosen
 *
 * @param Skill		If true, teams will be sorted using skill algorithm,			
 * 			otherwise players will be randomly chosen.
 *
 * @noreturn
 */
stock PugRamdomizeTeams(bool:Skill)
{
	if(!Skill)
	{
		new Players[MAX_PLAYERS],Num;
		get_players(Players,Num);
		
		for(new i;i < Num;i++)
		{
			if(!isTeam(Players[i]))
			{
				Players[i--] = Players[--Num];
			}
		}
	    
		new Player,Team = random(2) ? 1 : 2;
		new Random;
		
		while(Num)
		{
			Random = random(Num);
			
			Player = Players[Random];
			
			cs_set_user_team(Player,CsTeams:Team);
			
			Players[Random] = Players[--Num];
			
			Team = (Team % 2 + 1);
		}
	}
	else
	{
		new Skills[MAX_PLAYERS],Sorted[MAX_PLAYERS];
		
		new Players[MAX_PLAYERS],Num,Player;
		get_players(Players,Num,"h");
		
		new Frags;
		
		for(new i;i < Num;i++)
		{
			Player = Players[i];
			
			Frags = get_user_frags(Player);
			Sorted[Player] = Skills[Player] = (get_user_time(Player,1) / ((Frags < 1) ? 1 : Frags));
		}
		
		SortIntegers(Sorted,sizeof(Sorted),Sort_Descending);
	
		new CsTeams:Check = CS_TEAM_T;
		
		for(new i;i < sizeof(Sorted);i++)
		{
			for(new j;j < Num;j++)
			{
				Player = Players[j];
				
				if(Skills[Player] == Sorted[i])
				{
					cs_set_user_team(Player,Check);
					
					Check++;
					
					if(Check > CS_TEAM_CT)
					{
						Check = CS_TEAM_T;
					}
				}
			}
		}
	}
}

/**
 * Swap Teams in Counter-Strike way
 *
 * @noreturn
 */
stock PugSwapTeams()
{
	new Players[MAX_PLAYERS],Num,Player;
	get_players(Players,Num,"h");
	
	for(new i;i < Num;i++)
	{
		Player = Players[i];
		
		switch(get_user_team(Player))
		{
			case 1:
			{
				cs_set_user_team(Player,CS_TEAM_CT);
			}
			case 2:
			{
				cs_set_user_team(Player,CS_TEAM_T);
			}
		}
	}
}

 /**
 * Allow or block map objectives
 *
 * @param Block		If true, map objectives will be blocked
 *			Set to false to allow map objectives
 *
 * @noreturn
 */
stock PugSetMapObjectives(bool:Block)
{
	static Ents[][] =
	{
		"func_bomb_target",
		"info_bomb_target",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone"
	};
	
	static _Ents[][] =
	{
		"_func_bomb_target",
		"_info_bomb_target",
		"_func_hostage_rescue",
		"_info_hostage_rescue",
		"_info_vip_start",
		"_func_vip_safetyzone",
		"_func_escapezone"
	};
	
	new Ent = -1;

	for(new i;i < sizeof(Ents);i++)
	{
		while((Ent = engfunc(EngFunc_FindEntityByString,Ent,"classname",Block ? Ents[i] : _Ents[i])) > 0)
		{
			set_pev(Ent,pev_classname,Block ? _Ents[i] : Ents[i]);
		}
	}
}
