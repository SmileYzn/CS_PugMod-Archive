#include <amxmodx>
#include <amxmisc>

#include <pug_const>
#include <pug_natives>
#include <pug_stocks>
#include <pug_forwards>

#pragma semicolon 1

new bool:g_bReady[33];

CREATE_GEN_FORW_ID(Fw_PugReady);

public plugin_init()
{
	new hPlugin = register_plugin("Pug Ready",AMXX_VERSION_STR,"SmileY");
	
	register_dictionary("pug.txt");
	register_dictionary("pug_ready.txt");
	
	PugRegisterCommand("ready","PugIsReady",ADMIN_ALL,"O Player esta pronto para o jogo");
	PugRegisterCommand("notready","PugNotReady",ADMIN_ALL,"O Player nao esta pronto para o jogo");
	
	PugRegisterAdminCommand("forceready","PugForceReady",PUG_CMD_LVL,"<Player> - Forca o Player a ficar pronto");
	PugRegisterAdminCommand("forceunready","PugForceNotReady",PUG_CMD_LVL,"<Player> - Forca o Player a nao estar pronto");
	
	Fw_PugReady = CreateGenForward("PugAllReady",hPlugin,get_func_id("PugReadyHandler"));
	
	register_event("ResetHUD","PugKeepUpMenu","b");
	
	PugChangeDisPlay(get_func_id("PugReadyDisPlayReally"),INVALID_PLUGIN_ID);
}

public client_putinserver(id)
{
	PugKeepUpMenu();
}

public client_disconnect(id)
{
	if(GET_PUG_STAGE() == PUG_STAGE_READY)
	{
		if(g_bReady[id])
		{
			g_bReady[id] = false;
		}
		
		PugKeepUpMenu();
	}
}

public client_infochanged(id)
{
	set_task(0.1,"PugKeepUpMenu");
}

public plugin_natives()
{
	register_native("PugNativeReadyPlayers","PugNativeReadyPlayers");
	register_native("PugNativeRegisterReadyDisPlay","PugNativeRegisterReadyDisPlay");
}

public PugNativeReadyPlayers(id,iParams)
{
	new iPlugin = get_param(2);
	PugReadyPlayers(get_param(1),(iPlugin == INVALID_PLUGIN_ID) ? id : iPlugin);
}

public PugNativeRegisterReadyDisPlay(id,iParams)
{
	new iPlugin = get_param(2);
	
	PugChangeDisPlay(get_param(1),(iPlugin == INVALID_PLUGIN_ID) ? id : iPlugin);
}

public PugReadyFunctionID;
public PugReadyPluginID;
public PugReadyPrevStage;

PugReadyPlayers(iFunction,iPlugin = INVALID_PLUGIN_ID)
{
	if(GET_PUG_STAGE() == PUG_STAGE_READY) return;

	PugReadyFunctionID = iFunction;
	PugReadyPluginID = iPlugin;

	PugStartReadyPlayers();
}

public PugStartReadyPlayers()
{
	if(GET_PUG_STATUS() != PUG_STATUS_LIVE)
	{
		return PugSetPauseCall(get_func_id("PugStartReadyPlayers"));
	}

	PugReadyPrevStage = GET_PUG_STAGE();

	SET_PUG_STAGE(PUG_STAGE_READY);
	SET_PUG_STATUS(PUG_STATUS_WAITING);

	arrayset(g_bReady,false,sizeof(g_bReady));

	PugMessage(0,"PUG_READY_UP");
	
	PugKeepUpMenu();

	return PLUGIN_HANDLED;
}

public PugIsReady(id)
{
	if(g_bReady[id] || (GET_PUG_STATUS() != PUG_STATUS_WAITING) || (GET_PUG_STAGE() != PUG_STAGE_READY) || is_user_hltv(id))
	{
		return PugMessage(id,"PUG_CMD_NOTALLOWED");
	}

	g_bReady[id] = true;

	new sName[32];
	get_user_name(id,sName,charsmax(sName));
	
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_PLAYER_READYED",sName);

	PugReadyDisPlay(9999.0);
	PugCheckReady();

	return PLUGIN_HANDLED;
}

public PugNotReady(id)
{
	if(!g_bReady[id] || (GET_PUG_STATUS() != PUG_STATUS_WAITING) || (GET_PUG_STAGE() != PUG_STAGE_READY) || is_user_hltv(id))
	{
		return PugMessage(id,"PUG_CMD_NOTALLOWED");
	}

	g_bReady[id] = false;

	new sName[32];
	get_user_name(id,sName,charsmax(sName));
	
	client_print_color(0,print_team_grey,"^4%s^1 %L",g_sHead,LANG_PLAYER,"PUG_PLAYER_UNREADYED",sName);

	PugReadyDisPlay(9999.0);

	return PLUGIN_HANDLED;
}

public PugForceReady(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOTALLOWED");
	}
	else
	{
		new sArg[32];
		read_argv(1,sArg,charsmax(sArg));
		
		if(equali(sArg,"all"))
		{
			return PugForceReadyAll(id);
		}
		
		new iPlayer = cmd_target(id,sArg,CMDTARGET_OBEY_IMMUNITY);
		
		if(!iPlayer) return PLUGIN_HANDLED;
		
		PugAdminCommandClient(id,"Forcar .ready","PUG_FORCE_READY",iPlayer,PugIsReady(iPlayer));
	}
	
	return PLUGIN_HANDLED;
}

public PugForceNotReady(id,iLevel)
{
	if(!access(id,PUG_CMD_LVL) && (id != 0))
	{
		PugMessage(id,"PUG_CMD_NOTALLOWED");
	}
	else
	{
		new sArg[32];
		read_argv(1,sArg,charsmax(sArg));
		
		if(equali(sArg,"all"))
		{
			return PugForceReadyAll(id);
		}
		
		new iPlayer = cmd_target(id,sArg,CMDTARGET_OBEY_IMMUNITY);
		
		if(!iPlayer) return PLUGIN_HANDLED;
		
		PugAdminCommandClient(id,"Forcar .notready","PUG_FORCE_UNREADY",iPlayer,PugNotReady(iPlayer));
	}
	
	return PLUGIN_HANDLED;
}

public PugForceReadyAll(id)
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) PugIsReady(iPlayers[i]);

	PugAdminCommand(id,"Forcar .ready","PUG_FORCE_ALL_READY",1);
	
	return PLUGIN_HANDLED;
}

public PugForceNotReadyAll(id)
{
	new iPlayers[32],iNum;
	get_players(iPlayers,iNum,"ch");
	
	for(new i;i < iNum;i++) PugNotReady(iPlayers[i]);

	PugAdminCommand(id,"Forcar .notready","PUG_FORCE_ALL_UNREADY",1);
	
	return PLUGIN_HANDLED;
}

public PugKeepUpMenu()
{
	if((GET_PUG_STAGE() == PUG_STAGE_READY) && (GET_PUG_STATUS() == PUG_STATUS_WAITING))
	{
		PugReadyDisPlay(9999.0);
	}
}

public PugCheckReady()
{
	new iReady = 0;
	
	for(new i;i < sizeof(g_bReady);i++)
	{
		if(g_bReady[i]) iReady++;
	}
	
	if(iReady >= GET_CVAR_MINPLAYERS())
	{
		PugReadyDisPlay(0.1);
		PugReady();
	}
	else PugReadyDisPlay(9999.0);
}

public PugReadyDisPlayFunctionID;
public PugReadyDisPlayPluginID;

public PugChangeDisPlay(iFunction,iPlugin)
{
	PugReadyDisPlayFunctionID = iFunction;
	PugReadyDisPlayPluginID = iPlugin;
	
	PugKeepUpMenu();
}

public PugReadyDisPlay(Float:fHold)
{
	callfunc_begin_i(PugReadyDisPlayFunctionID,PugReadyDisPlayPluginID);
	callfunc_push_float(fHold);
	callfunc_end();
}

public PugReadyDisPlayReally(Float:fHold)
{
	new sReady[512],sNotReady[512],sName[32];
	
	new iPlayers[32],iNum,iPlayer;
	get_players(iPlayers,iNum,"ch");
	
	new iReadys,iPlayerNum;
	
	for(new i;i < iNum;i++)
	{
		iPlayer = iPlayers[i];
		
		iPlayerNum++;
		get_user_name(iPlayer,sName,charsmax(sName));

		if(g_bReady[iPlayer])
		{
			iReadys++;
			
			format(sReady,charsmax(sReady),"%s%s^n",sReady,sName);
		}
		else format(sNotReady,charsmax(sNotReady),"%s%s^n",sNotReady,sName);
	}
	
	new iMinPlayers = GET_CVAR_MINPLAYERS();

	set_hudmessage(0,255,0,0.23,0.02,0,0.0,fHold,0.0,0.0,3);
	show_hudmessage(0,"Aquecendo (%i de %i):",(iPlayerNum - iReadys),iMinPlayers);

	set_hudmessage(0,255,0,0.58,0.02,0,0.0,fHold,0.0,0.0,2);
	show_hudmessage(0,"Prontos (%i de %i):",iReadys,iMinPlayers);

	set_hudmessage(255,255,225,0.58,0.05,0,0.0,fHold,0.0,0.0,1);
	show_hudmessage(0,sReady);

	set_hudmessage(255,255,225,0.23,0.05,0,0.0,fHold,0.0,0.0,4);
	show_hudmessage(0,sNotReady);
}

public PugReady()
{
	if(GET_PUG_STAGE() != PUG_STAGE_READY)
	{
		return PLUGIN_CONTINUE;
	}
	else if(GET_PUG_STATUS() != PUG_STATUS_WAITING)
	{
		return PugSetPauseCall(get_func_id("PugReady"));
	}
	
	ExecuteGenForward(Fw_PugReady);
	
	return PLUGIN_HANDLED;
}

public PugReadyHandler()
{
	if(GET_PUG_STATUS() != PUG_STATUS_WAITING)
	{
		return PugSetPauseCall(get_func_id("PugReadyHandler"));
	}
	
	SET_PUG_STATUS(PUG_STATUS_LIVE);
	SET_PUG_STAGE(PugReadyPrevStage);

	PugMessage(0,"PUG_IS_READY");

	callfunc_begin_i(PugReadyFunctionID,PugReadyPluginID);
	callfunc_end();

	return PLUGIN_HANDLED;
}
