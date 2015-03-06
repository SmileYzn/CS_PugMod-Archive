#if defined _PugMenus_included
	#endinput
#endif
#define _PugMenus_included

stock bool:g_bVoted[33];
stock g_iMenuTemp[33];

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

stock PugDisplayMenuAll(iMenu)
{
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) 
	{
		iPlayer = iPlayers[i];
		
		g_iMenuTemp[iPlayer] = iMenu;
		
		PugDisplayMenuClient(iPlayer);
	}
}

stock PugDisplayMenuSingle(id,iMenu)
{
	g_iMenuTemp[id] = iMenu;
	
	PugDisplayMenuClient(id);
}

public PugDisplayMenuClient(id)
{
	if(is_user_connected(id))
	{
		new iMenu,iMenuNew;
		new iMenuUP = player_menu_info(id,iMenu,iMenuNew);

		if((iMenuUP <= 0) || (iMenu < 0))
		{
			menu_display(id,g_iMenuTemp[id],0);
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
}

stock PugCancelMenuClient(id)
{
	menu_cancel(id);
	show_menu(id,0,"^n",1);
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
