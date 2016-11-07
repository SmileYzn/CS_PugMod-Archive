#if defined _PugCaptains_included
	#endinput
#endif
#define _PugCaptains_included

#define PUG_CAPTAIN_MINPLAYERS 4

new g_iCaptain[2];

public PugTeamsCaptains()
{
	new iPlayers[MAX_PLAYERS],iNum;
	get_players(iPlayers,iNum,"h");
	
	if(iNum > PUG_CAPTAIN_MINPLAYERS)
	{	
		new iPlayer;
		
		for(new i;i < iNum;i++)
		{
			iPlayer = iPlayers[i];
			
			user_silentkill(iPlayer);
			PugSetClientTeam(iPlayer,3);
		}
		
		arrayset(g_iCaptain,0,sizeof(g_iCaptain));
		
		g_iCaptain[0] = iPlayers[random(iNum)];
		g_iCaptain[1] = iPlayers[random(iNum)];
		
		while(g_iCaptain[0] == g_iCaptain[1])
		{
			g_iCaptain[1] = iPlayers[random(iNum)];
		}
		
		PugSetClientTeam(g_iCaptain[0],1);
		PugSetClientTeam(g_iCaptain[1],2);
		
		new sName[2][32];
		
		get_user_name(g_iCaptain[0],sName[0],charsmax(sName[]));
		get_user_name(g_iCaptain[1],sName[1],charsmax(sName[]));
		
		new sTeam[2][32];
		
		PugGetTeamName(CS_TEAM_T,sTeam[0]);
		PugGetTeamName(CS_TEAM_CT,sTeam[1]);
		
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_ARE",sName[0],sTeam[0],sName[1],sTeam[1]);
		
		PugCaptainHud();
		set_task(2.0,"PugCaptainMenu",g_iCaptain[random_num(0,1)]);
	}
	else
	{
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_NEEDED",PUG_CAPTAIN_MINPLAYERS);
		
		PugFirstHalf();
	}
}

public PugCaptainMenu(id)
{
	PugCaptainHud();
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"eh","SPECTATOR");
	
	if(!is_user_connected(id) && (iNum > 0))
	{
		iPlayer = iPlayers[random(iNum)];
		
		new sName[32];
		get_user_name(iPlayer,sName,charsmax(sName));
		
		new sTeam[32];
	
		if(id == g_iCaptain[0])
		{
			g_iCaptain[0] = iPlayer;
			
			PugSetClientTeam(iPlayer,1);
			PugGetTeamName(CS_TEAM_T,sTeam);
		}
		else if(id == g_iCaptain[1])
		{
			g_iCaptain[1] = iPlayer;
			
			PugSetClientTeam(iPlayer,2);
			PugGetTeamName(CS_TEAM_CT,sTeam);
		}
		
		set_task(2.0,"PugCaptainMenu",iPlayer);
		
		client_print_color(0,print_team_red,"%s %L",g_sHead,LANG_SERVER,"PUG_CAPTAINS_NEW",sTeam,sName);
	}
	else
	{
		if(iNum)
		{
			if(is_user_bot(id))
			{
				PugCaptainAutoPick(id);
			}
			else
			{
				PugCancelMenuClient(id);
				
				new iMenu = menu_create("Players:","PugMenuCaptainHandler");
				
				new sName[32],sNum[3];
				
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
			PugFirstHalf();
		}
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
		
		PugCaptainHud();
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
		
		PugCaptainHud();
		set_task(2.0,"PugCaptainMenu",(id == g_iCaptain[0]) ? g_iCaptain[1] : g_iCaptain[0]);
	}
	else
	{
		PugFirstHalf();
	}
}

#include <amxmodx>

public PugCaptainHud()
{
	new iPlayers[MAX_PLAYERS],iNum,iPlayer;
	get_players(iPlayers,iNum,"h");
	
	new sName[32],iSelectedCT,sList[4][320],iTeam,iSpecs;

	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		get_user_name(iPlayer,sName,charsmax(sName));
		
		if((iPlayer == g_iCaptain[0]) || (iPlayer == g_iCaptain[1]))
		{
			add(sName,charsmax(sName)," (C)");
		}
		
		iTeam = PugGetClientTeam(iPlayer);
		
		switch(iTeam)
		{
			case 2: iSelectedCT++;
			case 3: iSpecs++;
		}
		
		add(sName,charsmax(sName),"^n");
		add(sList[iTeam],charsmax(sList[]),sName);
	}
	
	for(new i = 0;i < 5 - iSelectedCT;i++)
	{
		add(sList[2],charsmax(sList[]),"^n");
	}
	
	static sTeam[2][32];
	PugGetTeamName(CS_TEAM_T,sTeam[0]);
	PugGetTeamName(CS_TEAM_CT,sTeam[1]);

	set_hudmessage(0,255,0,0.75,0.02,0,0.0,99.0,0.0,0.0,1);
	show_hudmessage(0,sTeam[0]);
	
	set_hudmessage(255,255,255,0.75,0.02,0,0.0,99.0,0.0,0.0,2);
	show_hudmessage(0,"^n%s",sList[1]);

	if(iSpecs)
	{
		set_hudmessage(0,255,0,0.75,0.28,0,0.0,99.0,0.0,0.0,3);
		show_hudmessage(0,"%s^n^n^n^n^n^n%L",sTeam[1],LANG_SERVER,"PUG_CAPTAINS_UNASSIGNED");
		
		set_hudmessage(255,255,255,0.75,0.28,0,0.0,99.0,0.0,0.0,4);
		show_hudmessage(0,"^n%s^n%s",sList[2],sList[3]);
	}
	else
	{
		set_hudmessage(0,255,0,0.75,0.28,0,0.0,99.0,0.0,0.0,3);
		show_hudmessage(0,sTeam[1]);
		
		set_hudmessage(255,255,255,0.75,0.28,0,0.0,99.0,0.0,0.0,4);
		show_hudmessage(0,"^n%s",sList[2]);
	}
}
