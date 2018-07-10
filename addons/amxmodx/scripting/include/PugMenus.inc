#if defined _PugMenus_included
	#endinput
#endif
#define _PugMenus_included

 /**
 * Store current view menu id for players
 */
new g_Menu[MAX_PLAYERS+1];

 /**
 * Display an menu for all players that are in teams
 *
 * @param Menu	The menu to display for users
 *
 * @noreturn
 */
stock PugDisplayMenuAll(Menu)
{
	new Players[MAX_PLAYERS],Num;
	get_players(Players,Num,"ch");

	new Player;
	
	for(new i;i < Num;i++) 
	{
		Player = Players[i];

		if(1 <= get_user_team(Player) <= 2)
		{
			PugDisplayMenuSingle(Player,Menu);
		}
	}
}

 /**
 * Display an menu for a single target
 * and store the current menu into a variable
 *
 * @note 	If other menu is showing, this function will try
 *		to display menu every one second until reach target
 *
 * @param id	The client index
 * @param Menu	The menu to display 
 *
 * @noreturn
 */
stock PugDisplayMenuSingle(id,Menu)
{
	g_Menu[id] = Menu;
	PugDisplayMenuClient(id);
}

public PugDisplayMenuClient(id)
{
	if(is_user_connected(id))
	{
		new Menu,New;
		new MenuUP = player_menu_info(id,Menu,New);
	
		if((MenuUP <= 0) || (Menu < 0))
		{
			menu_display(id,g_Menu[id]);
		}
		else
		{
			set_task(1.0,"PugDisplayMenuClient",id);
		}
	}
}

/**
 * Cancel a client menu and invalidate it
 *
 * @param id	The client index
 *
 * @noreturn
 */
stock PugCancelMenu(id)
{
	g_Menu[id] = 0;
	show_menu(id,0,"^n",1);
}
