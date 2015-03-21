#include <amxmodx>
#include <fakemeta>
#include <csx>
#include <sqlx>

#include <PugConst>
#include <PugStocks>
#include <PugNatives>
#include <PugForwards>
#include <PugCS>
#include <PugDB>

#pragma semicolon 1

#define isPlayer(%0) (1 <= %0 <= MaxClients)

new bool:g_bStats;
new g_pRankedServer;

enum _:eStats
{
	eKills,
	eAssists,
	eDeaths,
	eHeadshots,
	eShots,
	eHits,
	eDamage,
	Float:eRWS,
	eRoundsPlayed,
	eRoundsLose,
	eRoundsWin,
	eMatchsPlayed,
	eMatchsLose,
	eMatchsWin
};

new g_iStats[MAX_PLAYERS][eStats];

enum _:eBomb
{
	bDefuses,
	bDefused,
	bPlants,
	bExplosions
};

new g_iBomb[MAX_PLAYERS][eBomb];

enum _:eStreak
{
	K1,
	K2,
	K3,
	K4,
	K5
};

new g_iStreak[MAX_PLAYERS][eStreak];

enum _:eVersus
{
	V1,
	V2,
	V3,
	V4,
	V5
};

new g_iVersus[MAX_PLAYERS][eVersus];

enum _:eWeaponStats
{
	wKills,
	wDeaths,
	wHeadshots,
	wShots,
	wHits,
	wDamage
};

new g_iWeapon[MAX_PLAYERS][MAX_PLAYERS][eWeaponStats];

enum _:eMatch
{
	mServer[32],
	mAddress[23],
	mMap[32]
};

new g_aMatch[eMatch];

new g_iKills[MAX_PLAYERS];
new g_iDamage[MAX_PLAYERS][MAX_PLAYERS];
new g_iLastManVersus[MAX_PLAYERS];
new g_iGunsEventsIdBitSum;

new Handle:g_hSQL;

public plugin_init()
{
	register_plugin("Pug MOD (Stats)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("PugStats.txt");
	
	g_pRankedServer = create_cvar("pug_ranked_server","1",FCVAR_NONE,"Ativa a contagem do Stats");
	
	new const sGunsEvents[][] =
	{
		"events/awp.sc","events/g3sg1.sc","events/ak47.sc","events/scout.sc","events/m249.sc",
		"events/m4a1.sc","events/sg552.sc","events/aug.sc","events/sg550.sc","events/m3.sc",
		"events/xm1014.sc","events/usp.sc","events/mac10.sc","events/ump45.sc","events/fiveseven.sc",
		"events/p90.sc","events/deagle.sc","events/p228.sc","events/glock18.sc","events/mp5n.sc",
		"events/tmp.sc","events/elite_left.sc","events/elite_right.sc","events/galil.sc","events/famas.sc"
	};
	
	for(new i;i < sizeof(sGunsEvents);++i)
	{
		g_iGunsEventsIdBitSum |= 1 << engfunc(EngFunc_PrecacheEvent,1,sGunsEvents[i]);
	}
	
	register_forward(FM_PlaybackEvent,"FwPlaybackEvent");
	
	PugRegisterCommand("stats","PugCommandStats",ADMIN_ALL,"PUG_DESC_STATS");
	PugRegisterCommand("rank","PugCommandRank",ADMIN_ALL,"PUG_DESC_RANK");
}

public plugin_cfg()
{
	g_hSQL = SQL_MakeDbTuple(SQL_HOST,SQL_USER,SQL_PASSWORD,SQL_DATABASE,SQL_TIMEOUT);
}

public plugin_end()
{
	if(g_hSQL != Empty_Handle)
	{
		SQL_FreeHandle(g_hSQL);
	}
}

public client_putinserver(id)
{
	if(get_pcvar_num(g_pRankedServer))
	{
		arrayset(g_iBomb[id],0,sizeof(g_iBomb[]));
		arrayset(g_iStats[id],0,sizeof(g_iStats[]));
		arrayset(g_iStreak[id],0,sizeof(g_iStreak[]));
		arrayset(g_iVersus[id],0,sizeof(g_iVersus[]));
		
		for(new iWeapon;iWeapon < sizeof(g_iWeapon[]);iWeapon++)
		{
			arrayset(g_iWeapon[id][iWeapon],0,sizeof(g_iWeapon[][]));
		}
	}
}

public client_disconnect(id)
{
	if(get_pcvar_num(g_pRankedServer) && !is_user_bot(id) && !is_user_hltv(id))
	{
		if(g_iStats[id][eRoundsPlayed])
		{
			PugSaveStats(id);
		}
	}
}

public PugEventWarmup()
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = false;
		
		get_mapname(g_aMatch[mMap],charsmax(g_aMatch[mMap]));
		get_cvar_string("hostname",g_aMatch[mServer],charsmax(g_aMatch[mServer]));
		get_cvar_string("net_address",g_aMatch[mAddress],charsmax(g_aMatch[mAddress]));
	}
}

public PugEventFirstHalf()
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = true;
	}
}

public PugEventHalfTime()
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = false;
	}
}

public PugEventSecondHalf()
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = true;
	}
}

public PugEventOvertime()
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = true;
	}
}

public PugEventEnd(iWinner)
{
	if(get_pcvar_num(g_pRankedServer))
	{
		g_bStats = false;
	
		new iTeam;
		
		for(new i = 1;i <= MaxClients;i++)
		{
			if(is_user_connected(i))
			{
				iTeam = get_user_team(i);
				
				if(1 <= iTeam <= 2)
				{
					g_iStats[i][eMatchsPlayed]++;
					
					if(iTeam == iWinner)
					{
						g_iStats[i][eMatchsWin]++;
					}
					else
					{
						g_iStats[i][eMatchsLose]++;
					}
				}
			}
		}
		
		new sQuery[164];
		
		format
		(
			sQuery,
			charsmax(sQuery),
			"CALL PugSaveMatch('%s', '%s', '%s', %i, %i, %f)",
			g_aMatch[mServer],
			g_aMatch[mAddress],
			g_aMatch[mMap],
			PugGetTeamScore(1),
			PugGetTeamScore(2),
			get_gametime()
		);
		
		SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
	}
}

public client_death(iKiller,iVictim,iWeapon,iPlace,TK)
{
	if(g_bStats)
	{
		if(iKiller != iVictim)
		{
			g_iStats[iKiller][eKills]++;
			g_iStats[iVictim][eDeaths]++;
	
			g_iWeapon[iKiller][iWeapon][wKills]++;
			g_iWeapon[iVictim][iWeapon][wDeaths]++;
			
			g_iKills[iKiller]++;
			
			if(iPlace == HIT_HEAD)
			{
				g_iStats[iKiller][eHeadshots]++;
				g_iWeapon[iKiller][iWeapon][wHeadshots]++;
			}
		}
		
		for(new i = 1;i <= MaxClients;i++)
		{
			if(is_user_connected(i))
			{
				if((g_iDamage[i][iVictim] >= 50) && (i != iKiller))
				{
					g_iStats[i][eAssists]++;
				}
				else
				{
					g_iDamage[i][iVictim] = 0;
				}
				
				if(IsAlone(i) && !g_iLastManVersus[i])
				{
					g_iLastManVersus[i] = GetAliveEnemies(i);
				}
			}
		}
	}
}

public client_damage(iAttacker,iVictim,iDamage,iWeapon,iPlace,iTA)
{
	if(g_bStats && (iAttacker != iVictim))
	{
		g_iStats[iAttacker][eHits]++;
		g_iStats[iAttacker][eDamage] += iDamage;
		
		g_iDamage[iAttacker][iVictim] += iDamage;
		
		g_iWeapon[iAttacker][iWeapon][wHits]++;
		g_iWeapon[iAttacker][iWeapon][wDamage] += iDamage;
	}
}

public FwPlaybackEvent(iFlags,id,iEvent)
{
	if(g_bStats && isPlayer(id) && (g_iGunsEventsIdBitSum & (1 << iEvent)))
	{
		g_iStats[id][eShots]++;
		g_iWeapon[id][get_user_weapon(id)][wShots]++;
	}
}

public bomb_planted(iPlanter)
{
	if(g_bStats)
	{
		g_iBomb[iPlanter][bPlants]++;
	}
}

public bomb_defusing(iDefuser)
{
	if(g_bStats)
	{
		g_iBomb[iDefuser][bDefuses]++;
	}
}
public bomb_defused(iDefuser)
{
	if(g_bStats)
	{
		g_iBomb[iDefuser][bDefused]++;
	}
}

public bomb_explode(iPlanter,iDefuser)
{
	if(g_bStats)
	{
		g_iBomb[iPlanter][bExplosions]++;
	}
}

public PugEventRoundStart()
{
	if(g_bStats)
	{
		arrayset(g_iKills,0,sizeof(g_iKills));
		arrayset(g_iLastManVersus,0,sizeof(g_iLastManVersus));
		
		for(new i;i < sizeof(g_iDamage);i++)
		{
			arrayset(g_iDamage[i],0,sizeof(g_iDamage[]));
		}
	}
}

public PugEventRoundWinner(iWinner)
{
	if(g_bStats)
	{
		new i,iTeam[MAX_PLAYERS],iStats[8],iBody[8],iTeamDamage,iDamageDone[MAX_PLAYERS];
		
		for(i = 1;i <= MaxClients;i++)
		{
			if(is_user_connected(i))
			{
				iTeam[i] = get_user_team(i);
				
				if(1 <= iTeam[i] <= 2)
				{
					if(iTeam[i] == iWinner)
					{
						g_iStats[i][eRoundsWin]++;
		
						if(IsAlone(i))
						{
							g_iVersus[i][g_iLastManVersus[i]]++;
						}
						
						get_user_rstats(i,iStats,iBody);
						iTeamDamage += (iDamageDone[i] = iStats[6]);
					}
					else
					{
						g_iStats[i][eRoundsLose]++;
					}
				
					g_iStats[i][eRoundsPlayed]++;
					
					if(g_iKills[i])
					{
						g_iStreak[i][g_iKills[i]]++;
					}
				}
			}
		}
	 
		for(i = 1;i <= MaxClients;i++)
		{
			if(is_user_connected(i) && (iTeam[i] == iWinner))
			{
				g_iStats[i][eRWS] += float(iDamageDone[i]) / float(iTeamDamage);
			}
		}
	}
}

bool:IsAlone(id)
{
	if(is_user_alive(id))
	{
		new sTeam[12];
		
		if(1 <= get_user_team(id,sTeam,charsmax(sTeam)) <= 2)
		{
			new iPlayers[32],iNum;
			get_players(iPlayers,iNum,"ae",sTeam);
			
			return (iNum == 1) ? true : false;
		}
	}

	return false;
}

GetAliveEnemies(id)
{
	if(is_user_alive(id))
	{
		new iPlayers[32],iNum;
		get_players(iPlayers,iNum,"ae",(get_user_team(id) == 1) ? "CT" : "TERRORIST");
	
		return iNum;
	}

	return -1;
}

PugSaveStats(id)
{
	new sQuery[1024];
	
	new sSteam[35];
	get_user_authid(id,sSteam,charsmax(sSteam));
	
	format
	(
		sQuery,
		charsmax(sQuery),
		"CALL PugSaveStats('%s', %i, %i, %i, %i, %i, %i, %i, %f, %i, %i, %i, %i, %i, %i)",
		sSteam,
		g_iStats[id][eKills],
		g_iStats[id][eAssists],
		g_iStats[id][eDeaths],
		g_iStats[id][eHeadshots],
		g_iStats[id][eShots],
		g_iStats[id][eHits],
		g_iStats[id][eDamage],
		g_iStats[id][eRWS],
		g_iStats[id][eRoundsPlayed],
		g_iStats[id][eRoundsLose],
		g_iStats[id][eRoundsWin],
		g_iStats[id][eMatchsPlayed],
		g_iStats[id][eMatchsLose],
		g_iStats[id][eMatchsWin]
	);
	
	format
	(
		sQuery,
		charsmax(sQuery),
		"%s;CALL PugSaveBomb('%s', %i, %i, %i, %i)",
		sQuery,
		sSteam,
		g_iBomb[id][bDefuses],
		g_iBomb[id][bDefused],
		g_iBomb[id][bPlants],
		g_iBomb[id][bExplosions]
	);
	
	format
	(
		sQuery,
		charsmax(sQuery),
		"%s;CALL PugSaveStreak('%s', %i, %i, %i, %i, %i)",
		sQuery,
		sSteam,
		g_iStreak[id][K1],
		g_iStreak[id][K2],
		g_iStreak[id][K3],
		g_iStreak[id][K4],
		g_iStreak[id][K5]
	);
	
	format
	(
		sQuery,
		charsmax(sQuery),
		"%s;CALL PugSaveVersus('%s', %i, %i, %i, %i, %i)",
		sQuery,
		sSteam,
		g_iVersus[id][V1],
		g_iVersus[id][V2],
		g_iVersus[id][V3],
		g_iVersus[id][V4],
		g_iVersus[id][V5]
	);
	
	format(sQuery,charsmax(sQuery),"%s;CALL PugCalcStats('%s')",sQuery,sSteam);

	SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
	
	sQuery = "^0";
	new sWeapon[32];
	
	for(new iWeapon;iWeapon < sizeof(g_iWeapon[]);iWeapon++)
	{
		if(g_iWeapon[id][iWeapon][wShots] || g_iWeapon[id][iWeapon][wDeaths])
		{
			get_weaponname(iWeapon,sWeapon,charsmax(sWeapon));
			
			format
			(
				sQuery,
				charsmax(sQuery),
				"CALL PugSaveWeapon(%i, '%s', %i, %i, %i, %i, %i, %i, '%s');%s",
				iWeapon,
				sWeapon,
				g_iWeapon[id][iWeapon][wKills],
				g_iWeapon[id][iWeapon][wDeaths],
				g_iWeapon[id][iWeapon][wHeadshots],
				g_iWeapon[id][iWeapon][wShots],
				g_iWeapon[id][iWeapon][wHits],
				g_iWeapon[id][iWeapon][wDamage],
				sSteam,
				sQuery
			);
		}
	}
	
	if(sQuery[0])
	{
		SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
	}
}

public PugHandlerSQL(iState,Handle:hQuery,sError[],iError,sData[],iData)
{
	if(iState != TQUERY_SUCCESS)
	{
		if(iError)
		{
			server_print(sError);
		}
	}
	
	SQL_FreeHandle(hQuery);
}

public PugCommandStats(id)
{
	new sAlias[35];
	read_args(sAlias,charsmax(sAlias));
	remove_quotes(sAlias);
	
	if(!sAlias[0])
	{
		get_user_authid(id,sAlias,charsmax(sAlias));
	}
	
	new sURL[128];
	formatex
	(
		sURL,
		charsmax(sURL),
		"http://localhost/stats.php?Alias=%s",
		sAlias
	);
	
	show_motd(id,sURL,sAlias);
	
	return PLUGIN_HANDLED;
}

public PugCommandRank(id)
{
	new sIP[32];
	get_user_ip(id,sIP,charsmax(sIP),true);
	
	show_motd(id,"http://localhost/top.php","TOP 10 Players");
	
	return PLUGIN_HANDLED;
}
