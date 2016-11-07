#if defined _PugMenus_included
	#endinput
#endif
#define _PugMenus_included

#include <PugCS>

new g_iMenuTemp[MAX_PLAYERS+1];
new bool:g_bVoted[MAX_PLAYERS+1];

stock GET_PUG_VOTING()
{
	if(xvar_exists(g_bVoting))
	{
		return get_xvar_num(get_xvar_id(g_bVoting));
	}

	return 0;
}

stock PugDisplayMenuAll(iMenu)
{
	new iPlayers[MAX_PLAYERS],iNum;
	get_players(iPlayers,iNum,"ch");

	new iPlayer;
	
	for(new i;i < iNum;i++) 
	{
		iPlayer = iPlayers[i];

		if(PugIsTeam(iPlayer))
		{
			PugDisplayMenuSingle(iPlayer,iMenu);
		}
	}
}

stock PugDisplayMenuSingle(id,iMenu)
{
	g_iMenuTemp[id] = iMenu;
	g_bVoted[id] = false;
	
	PugDisplayMenuClient(id);
}

public PugDisplayMenuClient(id)
{
	if(is_user_connected(id))
	{
		new iMenu,iNew;
		new iMenuUP = player_menu_info(id,iMenu,iNew);
	
		if((iMenuUP <= 0) || (iMenu < 0))
		{
			menu_display(id,g_iMenuTemp[id]);
		}
		else
		{
			set_task(1.0,"PugDisplayMenuClient",id);
		}
	}
}

stock PugCancelMenu()
{
	new iPlayers[MAX_PLAYERS],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) 
	{
		menu_cancel(iPlayers[i]);
	}
	
	show_menu(0,0,"^n",1);
}

stock PugCancelMenuClient(id)
{
	menu_cancel(id);
	show_menu(id,0,"^n",1);
}

stock bool:PugShoudStopVote()
{
	new iPlayers[MAX_PLAYERS],iNum;
	get_players(iPlayers,iNum,"ch");

	new iPlayer;
	
	for(new i;i < iNum;i++) 
	{
		iPlayer = iPlayers[i];

		if(PugIsTeam(iPlayer))
		{
			if(!g_bVoted[iPlayer])
			{
				return false;
			}
		}
	}

	return true;
}
