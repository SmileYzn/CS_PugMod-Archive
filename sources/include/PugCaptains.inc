#if defined _PugCaptains_included
	#endinput
#endif
#define _PugCaptains_included

#define TASK_HUDLIST 6676
#define PUG_CAPTAIN_MINPLAYERS 4

new g_iCaptain[2];

public PugTeamsCaptains()
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"h");
	
	new iPlayer,sName[2][32],sTeam[2][32];
	
	if(iNum > PUG_CAPTAIN_MINPLAYERS)
	{
		arrayset(g_iCaptain,0,sizeof(g_iCaptain));
		
		for(new i;i < iNum;i++)
		{
			iPlayer = iPlayers[i];
			
			if(!g_iCaptain[0])
			{
				g_iCaptain[0] = iPlayer;
				
				get_user_name(iPlayer,sName[0],charsmax(sName[]));
				
				PugSetClientTeam(iPlayer,1);
				PugGetTeamName(1,sTeam[0]);
				
				continue;
			}
			
			if(!g_iCaptain[1])
			{
				g_iCaptain[1] = iPlayer;
				
				get_user_name(iPlayer,sName[1],charsmax(sName[]));
				
				PugSetClientTeam(iPlayer,2);
				PugGetTeamName(2,sTeam[1]);
				
				continue;
			}
			
			user_silentkill(iPlayer);
			PugSetClientTeam(iPlayer,3);
		}
		
		set_cvar_num("sv_restart",1);
		set_task(0.5,"PugCaptainHud",TASK_HUDLIST, .flags="b");
		set_task(2.0,"PugCaptainMenu",g_iCaptain[random_num(0,1)]);
		
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_ARE",sName[0],sTeam[0],sName[1],sTeam[1]);
	}
	else
	{
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_NEEDED",PUG_CAPTAIN_MINPLAYERS);
		
		PugFirstHalf();
	}
}

public PugCaptainMenu(id)
{
	if(!is_user_connected(id))
	{
		new iPlayers[32],iNum,iPlayer;
		get_players(iPlayers,iNum,"eh","SPECTATOR");
		
		iPlayer = iPlayers[random(iNum)];
		
		new sName[32];
		get_user_name(iPlayer,sName,charsmax(sName));
		
		new sTeam[32];
	
		if(id == g_iCaptain[0])
		{
			g_iCaptain[0] = iPlayer;
			
			PugSetClientTeam(iPlayer,1);
			PugGetTeamName(1,sTeam);
		}
		else if(id == g_iCaptain[1])
		{
			g_iCaptain[1] = iPlayer;
			
			PugSetClientTeam(iPlayer,2);
			PugGetTeamName(2,sTeam);
		}
		
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_NEW",sTeam,sName);
		
		set_task(2.0,"PugCaptainMenu",iPlayer);
		
		return;
	}
	
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"eh","SPECTATOR");
	
	if(iNum)
	{
		if(is_user_bot(id)) PugCaptainAutoPick(id);
		
		else
		{
			PugCancelMenuClient(id);
			
			new iMenu = menu_create("Espectadores:","PugMenuCaptainHandler",1);
			
			new iPlayer,sName[32],sNum[3];
			
			for(new i;i < iNum;i++)
			{
				iPlayer = iPlayers[i];
				
				num_to_str(iPlayer,sNum,charsmax(sNum));
				get_user_name(iPlayer,sName,charsmax(sName));
				
				menu_additem(iMenu,sName,sNum);
			}
			
			menu_setprop(iMenu,MPROP_EXIT,MEXIT_NEVER);
			
			PugDisplayMenuSingle(id,iMenu);
			
			set_task(10.0,"PugCaptainAutoPick",id);
		}
	}
	else
	{
		remove_task(TASK_HUDLIST);
		PugFirstHalf();
	}
}

public PugMenuCaptainHandler(id,iMenu,iKey)
{
	if(iKey != MENU_EXIT)
	{
		new iAccess,sData[3],sOption[32],iBack;
		menu_item_getinfo(iMenu,iKey,iAccess,sData,charsmax(sData),sOption,charsmax(sOption),iBack);
		
		new iPlayer = str_to_num(sData);
		
		if(is_user_connected(iPlayer) && is_user_connected(id))
		{
			remove_task(id);
			
			PugSetClientTeam(iPlayer,PugGetClientTeam(id));
			PugRespawn(iPlayer);
			
			new sName[2][32];
			get_user_name(id,sName[0],charsmax(sName[]));
			get_user_name(iPlayer,sName[1],charsmax(sName[]));
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_PICK",sName[0],sName[1]);
		}
		
		set_task(2.0,"PugCaptainMenu",(id == g_iCaptain[0]) ? g_iCaptain[1] : g_iCaptain[0]);
	}
	
	return PLUGIN_HANDLED;
}

public PugCaptainAutoPick(id)
{
	PugCancelMenuClient(id);
	
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"eh","SPECTATOR");
	
	if(iNum)
	{
		new iPlayer = iPlayers[random(iNum)];
		
		if(is_user_connected(iPlayer) && is_user_connected(id))
		{
			PugSetClientTeam(iPlayer,PugGetClientTeam(id));
			PugRespawn(iPlayer);
			
			new sName[2][32];
			get_user_name(id,sName[0],charsmax(sName[]));
			get_user_name(iPlayer,sName[1],charsmax(sName[]));
			
			client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_PICK",sName[0],sName[1]);
		}
		
		set_task(2.0,"PugCaptainMenu",(id == g_iCaptain[0]) ? g_iCaptain[1] : g_iCaptain[0]);
	}
	else
	{
		remove_task(TASK_HUDLIST);
		PugFirstHalf();
	}
}

#include <PugNatives>

public PugCaptainHud()
{
	new sTRs[512],sCTs[512],sName[32];
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		get_user_name(iPlayer,sName,charsmax(sName));
		
		if(g_iCaptain[0] == iPlayer || g_iCaptain[1] == iPlayer)
		{
			format(sName,charsmax(sName),"%s (C)",sName);
		}
		
		switch(PugGetClientTeam(iPlayer))
		{
			case 1:
			{
				format(sTRs,charsmax(sTRs),"%s%s^n",sTRs,sName);
			}
			case 2:
			{
				format(sCTs,charsmax(sCTs),"%s%s^n",sCTs,sName);
			}
		}
	}
	
	static sTeam[2][32];
	PugGetTeamName(1,sTeam[0]);
	PugGetTeamName(2,sTeam[1]);
	
	set_hudmessage(255,0,0,0.23,0.02,0,0.0,0.6,0.0,0.0,1);
	show_hudmessage(0,"%s:",sTeam[0]);

	set_hudmessage(255,255,255,0.23,0.05,0,0.0,0.6,0.0,0.0,2);
	show_hudmessage(0,sTRs);

	set_hudmessage(0,0,255,0.58,0.02,0,0.0,0.6,0.0,0.0,3);
	show_hudmessage(0,"%s:",sTeam[1]);

	set_hudmessage(255,255,255,0.58,0.05,0,0.0,0.6,0.0,0.0,4);
	show_hudmessage(0,sCTs);
}
