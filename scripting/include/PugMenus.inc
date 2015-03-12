#if defined _PugMenus_included
	#endinput
#endif
#define _PugMenus_included

stock bool:g_bVoted[33];
stock g_iMenuTemp[33] = {0,...};
stock g_iMenuPage[33] = {0,...};
stock g_iMenuTime[33] = {-1,...};

#include <amxmodx>

#define PUG_VOTING_VAR "g_bVoting"

stock GET_PUG_VOTING()
{
	if(xvar_exists(PUG_VOTING_VAR))
	{
		return get_xvar_num(get_xvar_id(PUG_VOTING_VAR));
	}

	return 0;
}

stock PugDisplayMenuAll(iMenu,iPage = 0,iTime = -1)
{
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) 
	{
		iPlayer = iPlayers[i];
		
		g_iMenuTemp[iPlayer] = iMenu;
		g_iMenuPage[iPlayer] = iPage;
		g_iMenuTime[iPlayer] = iTime;
		
		PugDisplayMenuClient(iPlayer);
	}
}

stock PugDisplayMenuSingle(id,iMenu,iPage = 0,iTime = -1)
{
	g_iMenuTemp[id] = iMenu;
	g_iMenuPage[id] = iPage;
	g_iMenuTime[id] = iTime;
	
	PugDisplayMenuClient(id);
}

#include <PugCS>

public PugDisplayMenuClient(id)
{
	if(is_user_connected(id))
	{
		new iMenu,iMenuNew,iMenuPage;
		new iMenuUP = player_menu_info(id,iMenu,iMenuNew,iMenuPage);

		if((iMenuUP <= 0) && (iMenu <= 0) && (iMenuNew < 0) && (iMenuPage == 0))
		{
			menu_display(id,g_iMenuTemp[id],g_iMenuPage[id],g_iMenuTime[id]);
		}
		else
		{
			set_task(1.0,"PugDisplayMenuClient",id);
		}
	}
}

stock PugCancelMenu()
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) 
	{
		menu_cancel(iPlayers[i]);
	}
	
	show_menu(0,0,"^n",1);
	
	arrayset(g_iMenuTemp,0,sizeof(g_iMenuTemp));
	arrayset(g_iMenuPage,0,sizeof(g_iMenuPage));
	arrayset(g_iMenuTime,-1,sizeof(g_iMenuTime));
}

stock PugCancelMenuClient(id)
{
	menu_cancel(id);
	show_menu(id,0,"^n",1);
	
	g_iMenuTemp[id] = 0;
	g_iMenuPage[id] = 0;
	g_iMenuTime[id] = -1;
}

stock bool:PugShoudStopVote()
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) 
	{
		if(!g_bVoted[iPlayers[i]])
		{
			return false;
		}
	}

	return true;
}
