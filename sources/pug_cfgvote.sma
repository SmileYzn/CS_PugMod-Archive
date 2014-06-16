#include <amxmodx>
#include <amxmisc>

#include <pug_menu>
#include <pug_const>
#include <pug_stocks>
#include <pug_forwards>
#include <pug_modspecific>

#pragma semicolon 1

new g_pVoteDelay;
new g_pVotePercent;

public g_iMenuConfig;

new g_iConfigVotes[3];

public plugin_init()
{
	register_plugin("Pug Mod Config Votes",AMXX_VERSION_STR,"SmileY");
	
	register_dictionary("pug.txt");
	register_dictionary("pug_vote.txt");
	
	g_pVoteDelay = get_cvar_pointer("pug_vote_delay");
	g_pVotePercent = get_cvar_pointer("pug_vote_percent");
	
	PugRegisterAdminCommand("voteconfig","PugCommandVoteConfig",PUG_CMD_LVL,"Escolha de Config");
	
	g_iMenuConfig = menu_create("Configuracao:","PugVoteConfigHandle",1);
	
	menu_additem(g_iMenuConfig,"ESL (15 Rounds, 1:45 min, $800)","1");
	menu_additem(g_iMenuConfig,"CEVO (15 Rounds, 2:00 min, $800)","2");
	
	menu_setprop(g_iMenuConfig,MPROP_EXIT,MEXIT_NEVER);
}

CREATE_GEN_FORW_ID(Fw_PugFirstHalf);

public PugFirstHalf(GEN_FORW_ID(iForward))
{
	Fw_PugFirstHalf = iForward;

	PugVoteConfigStart();

	return PLUGIN_HANDLED;
}

public PugCommandVoteConfig(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOTALLOWED");
	}
	else PugAdminCommand(id,"escolha de configuracao","PUG_FORCE_VOTE",(GET_PUG_VOTING()) ? 0 : PugVoteConfigStart());

	return PLUGIN_HANDLED;
}

public PugVoteConfigStart()
{
	if(GET_PUG_VOTING())
	{
		set_task(get_pcvar_float(g_pVoteDelay),"PugVoteConfigStart",1990 + g_iMenuConfig);
		
		return PLUGIN_CONTINUE;
	}
	
	arrayset(g_bVoted,false,sizeof(g_bVoted));

	PugDisplayMenuAll(g_iMenuConfig);
	arrayset(g_iConfigVotes,0,charsmax(g_iConfigVotes));

	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTE_START","de configuracao");

	set_task(get_pcvar_float(g_pVoteDelay),"PugVoteConfigEnd",1990 + g_iMenuConfig);
	
	return PLUGIN_HANDLED;
}

public PugVoteConfigHandle(id,iMenu,iKey)
{
	if(iKey < 0)
	{
		return PLUGIN_HANDLED;
	}
 
	new iAccess,iCallBack,sCommand[3],sOption[36];
	menu_item_getinfo(iMenu,iKey, iAccess, sCommand,charsmax(sCommand),sOption,charsmax(sOption),iCallBack);

	g_iConfigVotes[str_to_num(sCommand)]++;

	new sName[32];
	get_user_name(id,sName,charsmax(sName));
		
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTED_FOR",sName,sOption);

	g_bVoted[id] = true;
	
	if(PugShoudStopVote()) PugVoteConfigEnd();
 
	return PLUGIN_HANDLED;
}

public PugVoteConfigEnd()
{
	PugCancelMenu();
	PugVoteConfigCount();

	remove_task(1990 + g_iMenuConfig);
}

stock g_sConfigs[][] = {"SERVER","ESL","CEVO"};

public PugVoteConfigCount()
{
	new iWinner,iWinnerVotes,iVotes;
	
	for(new i;i < sizeof(g_iConfigVotes);i++)
	{
		iVotes = g_iConfigVotes[i];
		
		if(iVotes >= iWinnerVotes)
		{
			iWinner = i;
			iWinnerVotes = iVotes;
		}
		else if(iVotes == iWinnerVotes)
		{
			if(random_num(0,1))
			{
				iWinner = i;
				iWinnerVotes = iVotes;
			}
		}
	}
	
	if(!g_iConfigVotes[iWinner])
	{
		return PugMessage(0,"PUG_VOTE_FAILED_NOVOTES");
	}

	new Float:fTemp = float(PugGetPlayers()) * get_pcvar_float(g_pVotePercent);
	
	if(g_iConfigVotes[iWinner] < floatround(fTemp,floatround_floor))
	{
		return PugMessage(0,"PUG_VOTE_FAILED_INSUF_VOTES");
	}
	
	PugSetConfigs(iWinner);
	
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_VOTE_WON",g_sConfigs[iWinner]);	
	
	ContinueGenForward(Fw_PugFirstHalf);
	
	return PLUGIN_HANDLED;
}

stock PugSetConfigs(iConfig)
{
	switch(iConfig)
	{
		case 1:
		{
			set_cvar_string("pug_config_firsthalf","esl.rc");
			set_cvar_string("pug_config_secondhalf","esl.rc");
			set_cvar_string("pug_config_overtime","esl-overtime.rc");
		}
		case 2:
		{
			set_cvar_string("pug_config_firsthalf","cevo.rc");
			set_cvar_string("pug_config_secondhalf","cevo.rc");
			set_cvar_string("pug_config_overtime","cevo-overtime.rc");
		}
	}
}
