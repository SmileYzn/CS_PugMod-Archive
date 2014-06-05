#if defined _pug_menu_included
	#endinput
#endif
#define _pug_menu_included

stock bool:g_bVoted[33];
stock g_iMenuTemp[33];

stock GET_PUG_VOTING()
{
	if(xvar_exists("g_bVoting"))
	{
		return get_xvar_num(get_xvar_id("g_bVoting"));
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
	new iMenu,iKeys;
	new iMenuUP = player_menu_info(id,iMenu,iKeys);

	if((iMenuUP <= 0) || (iMenu < 0))
	{
		menu_display(id,g_iMenuTemp[id],0);
	}
	else set_task(1.0,"PugDisplayMenuClient",id);
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
