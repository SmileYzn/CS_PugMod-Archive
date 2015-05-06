#if defined _PugKnifeRound_included
	#endinput
#endif
#define _PugKnifeRound_included

#define PUG_TASK_KNIFE_VOTE 1773

new g_iVotesNum[2];
new g_iTeamWinner;
new bool:g_bKnifeRound = false;

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

public PugKnifeRound()
{
	g_bKnifeRound = true;

	register_event("CurWeapon","PugEventCurWeapon","be","1=1","2!29");

	PugExecConfig(get_cvar_pointer("pug_config_live"));
	PugLO3();

	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_KNIFE_START");
}

public PugEventCurWeapon(id)
{
	if(g_bKnifeRound)
	{
		engclient_cmd(id,"weapon_knife");
	}
}

public PugEventRoundWinner(iWinner)
{
	if(g_bKnifeRound)
	{
		new sTeam[32];
		PugGetTeamName(iWinner,sTeam);

		g_bKnifeRound = false;
		g_iTeamWinner = iWinner;

		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_KNIFE_WINNER",sTeam);

		new iMenu = menu_create("Team:","PugVoteKnifeHandle");

		menu_additem(iMenu,"Terrorist","0");
		menu_additem(iMenu,"Counter-Terrorist","1");

		menu_setprop(iMenu,MPROP_EXIT,MEXIT_NEVER);

		PugDisplayMenuTeam(iMenu,iWinner);

		arrayset(g_iVotesNum,0,sizeof(g_iVotesNum));

		set_task(get_pcvar_float(get_cvar_pointer("pug_vote_delay")),"PugKnifeRoundEnd",PUG_TASK_KNIFE_VOTE);
	}
}

public PugVoteKnifeHandle(id,iMenu,iKey)
{
	if(iKey != MENU_EXIT)
	{
		new iAccess,iCallBack,sCommand[3],sOption[32];
		menu_item_getinfo(iMenu,iKey,iAccess,sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);

		g_iVotesNum[str_to_num(sCommand)]++;

		new sName[MAX_NAME_LENGTH];
		get_user_name(id,sName,charsmax(sName));

		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_VOTE_CHOOSED",sName,sOption);
	}

	return PLUGIN_HANDLED;
}

public PugKnifeRoundEnd()
{
	PugCancelMenu();

	new iTeamChoosed = g_iTeamWinner;

	if(g_iVotesNum[0] > g_iVotesNum[1])
	{
		iTeamChoosed = 1;
	}
	else if(g_iVotesNum[0] < g_iVotesNum[1])
	{
		iTeamChoosed = 2;
	}

	if(g_iTeamWinner != iTeamChoosed)
	{
		PugTeamsSwap();
	}

	new sTeam[32];
	PugGetTeamName(iTeamChoosed,sTeam);

	client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_KNIFE_WINNER_CHOOSED",sTeam);

	PugFirstHalf();
}
