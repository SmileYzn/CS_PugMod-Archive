#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <time>

#include <PugConst>
#include <PugStocks>
#include <PugDB>

#pragma semicolon 1

#define HIDE_NAME_CHANGE

new Handle:g_hSQL;

new g_sContact[32];

public plugin_init()
{
	register_plugin("Pug MOD (DB System)",PUG_MOD_VERSION,PUG_MOD_AUTHOR);
	
	register_dictionary("time.txt");
	register_dictionary("PugCore.txt");
	register_dictionary("PugDB.txt");
	
#if defined HIDE_NAME_CHANGE
	register_message(get_user_msgid("SayText"),"PugMessageSayText");
#endif
	
	PugRegisterAdminCommand("ban","PugCommandBan",PUG_CMD_LVL,"<Player|Steam> [Tempo (Minutos)] [Motivo] - Banir um Player");
	PugRegisterAdminCommand("unban","PugCommandRemoveBan",PUG_CMD_LVL,"<Steam> - Remove o ban do um Player");
}

public plugin_cfg()
{
	g_hSQL = SQL_MakeDbTuple(SQL_HOST,SQL_USER,SQL_PASSWORD,SQL_DATABASE,SQL_TIMEOUT);
	
	if(g_hSQL != Empty_Handle)
	{
		get_cvar_string("sv_contact",g_sContact,charsmax(g_sContact));
		
		set_task(60.0,"PugUpdateBans",154789, .flags="b");
	}
}

public plugin_end()
{
	if(g_hSQL != Empty_Handle)
	{
		SQL_FreeHandle(g_hSQL);
	}
}

public PugUpdateBans()
{
	new sQuery[32];
	formatex(sQuery,charsmax(sQuery),"CALL PugUpdateBans(%i)",time());
	
	SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
}

#if defined HIDE_NAME_CHANGE 
public PugMessageSayText()
{
	new sArg[32];
	get_msg_arg_string(2,sArg,charsmax(sArg));
	
	if(containi(sArg,"name") != -1)
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
#endif

public client_putinserver(id)
{
	if(!is_user_hltv(id) && !is_user_bot(id))
	{
		PugLoginClient(id);
		PugCheckBanClient(id);
	}
}

public client_disconnect(id)
{
	if(PUG_STAGE_START <= GET_PUG_STAGE() <= PUG_STAGE_OVERTIME)
	{
		new sSteam[35];
		get_user_authid(id,sSteam,charsmax(sSteam));
		
		new sQuery[64];
		formatex(sQuery,charsmax(sQuery),"CALL PugAddLeave('%s')",sSteam);
		
		SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
	}
}

public PugLoginClient(id)
{
	new sSteam[35];
	get_user_authid(id,sSteam,charsmax(sSteam));
	
	new sQuery[128];
	formatex(sQuery,charsmax(sQuery),"CALL PugGetPlayer('%s')",sSteam);
	
	new sData[1];
	sData[0] = id;
	
	SQL_ThreadQuery(g_hSQL,"PugHandlerLogin",sQuery,sData,sizeof(sData));
}

public PugHandlerLogin(iState,Handle:hQuery,sError[],iError,sData[])
{
	new id = sData[0];
	
	if(iState == TQUERY_SUCCESS)
	{
		new iResult = SQL_MoreResults(hQuery);
		
		if(!iResult)
		{
			PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_REGISTER",g_sContact);
		}
		else if(iResult > 1)
		{
			PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_DUPLICATED",g_sContact);
		}
		else
		{
			new sName[32];
			SQL_ReadResult(hQuery,SQL_FieldNameToNum(hQuery,SQL_ROW_NAME),sName,charsmax(sName));
			
			set_user_info(id,"name",sName);
			client_cmd(id,"name ^"%s^"",sName);
		}
	}
	else
	{
		PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_ERROR",g_sContact);
	}
	
	SQL_FreeHandle(hQuery);
}

public PugCheckBanClient(id)
{
	new sQuery[64];
	get_user_authid(id,sQuery,charsmax(sQuery));
	
	format(sQuery,charsmax(sQuery),"CALL PugGetBans('%s')",sQuery);
	
	new iData[1];
	iData[0] = id;
	
	SQL_ThreadQuery(g_hSQL,"PugBanCheckHandler",sQuery,iData,sizeof(iData));
}

public PugBanCheckHandler(iState,Handle:hQuery,sError[],iError,sData[])
{
	if(iState == TQUERY_SUCCESS)
	{
		if(SQL_NumResults(hQuery))
		{
			new iLength = SQL_ReadResult(hQuery,SQL_FieldNameToNum(hQuery,SQL_ROW_LENGTH));
			new iTime = time();
			
			if((iLength >= iTime) || !iLength)
			{
				new sReason[64];
				SQL_ReadResult(hQuery,SQL_FieldNameToNum(hQuery,SQL_ROW_REASON),sReason,charsmax(sReason));
			
				new sUntil[32];
				SQL_ReadResult(hQuery,SQL_FieldNameToNum(hQuery,SQL_ROW_UNBAN),sUntil,charsmax(sUntil));
				
				new id = sData[0];
				
				if(iLength > 0)
				{
					new sRemain[32];
					PugGetBanTimeLeft(iLength,sRemain,charsmax(sRemain));
					
					PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_BANNED_TEMP",sReason,sUntil,sRemain);
				}
				else
				{
					PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_BANNED_PERM",sReason,sUntil,g_sContact);
				}
			}
		}
	}
}

public PugCommandBan(id,iLevel,iCid)
{
	if(!cmd_access(id,iLevel,iCid,2))
	{
		return PLUGIN_HANDLED;
	}
	else
	{
		new sArg[35];
		read_argv(1,sArg,charsmax(sArg));
		
		new iPlayer = cmd_target(id,sArg,CMDTARGET_OBEY_IMMUNITY);
		
		new sSteam[35];
		
		if(iPlayer)
		{
			get_user_authid(iPlayer,sSteam,charsmax(sSteam));
		}
		else
		{
			if(!isSteam(sArg))
			{
				client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTARGET",sArg);
				
				return PLUGIN_HANDLED;
			}
			else
			{
				copy(sSteam,charsmax(sSteam),sArg);
			}
		}
		
		new sTime[10];
		read_argv(2,sTime,charsmax(sTime));
		
		new iLength,sDate[32];
		PugGetBanTimeLength(sTime,iLength,sDate,charsmax(sDate));
		
		new sReason[64];
		read_argv(3,sReason,charsmax(sReason));
		
		if(!sReason[0])
		{
			formatex(sReason,charsmax(sReason),"%L",LANG_SERVER,"PUG_DB_REASON_NONE");
		}
		
		new sQuery[128];
		formatex(sQuery,charsmax(sQuery),"CALL PugBanSteam('%s', %i, '%s', '%s')",sSteam,iLength,sDate,sReason);
		
		SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery);
		
		client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_DB_PLAYER_ADDED_BAN",sSteam,sReason,sDate);
		
		if(iPlayer)
		{
			if(iLength > 0)
			{
				new sRemain[32];
				PugGetBanTimeLeft(iLength,sRemain,charsmax(sRemain));
				
				PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_BANNED_TEMP",sReason,sDate,sRemain);
			}
			else
			{
				PugDisconnect(id,"%L",LANG_SERVER,"PUG_DB_BANNED_PERM",sReason,sDate,g_sContact);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugCommandRemoveBan(id,iLevel,iCid)
{
	if(!cmd_access(id,iLevel,iCid,2))
	{
		return PLUGIN_HANDLED;
	}
	else
	{
		new sArg[35];
		read_args(sArg,charsmax(sArg));
		remove_quotes(sArg);
		
		if(isSteam(sArg))
		{
			new sQuery[64];
			formatex(sQuery,charsmax(sQuery),"CALL PugRemoveBan('%s')",sArg);
			
			new sData[1];
			sData[0] = id;
			
			SQL_ThreadQuery(g_hSQL,"PugHandlerSQL",sQuery,sData,charsmax(sData));
		}
		else
		{
			client_print_color(id,print_team_red,"^4%s^1 %L",g_sHead,LANG_SERVER,"PUG_CMD_NOTARGET",sArg);
		}
	}
	
	return PLUGIN_HANDLED;
}

public PugHandlerSQL(iState,Handle:hQuery,sError[],iError,sData[],iData)
{
	if(iState != TQUERY_SUCCESS)
	{
		if(iError)
		{
			server_print(sError);
		}
	}
	
	SQL_FreeHandle(hQuery);
}

PugGetBanTimeLeft(iSeconds,sTime[],iLen)
{
	if(iSeconds > 0)
	{
		get_time_length(0,(iSeconds - time()),timeunit_seconds,sTime,iLen);
	}
	else
	{
		formatex(sTime,iLen,"%L",LANG_SERVER,"PUG_DB_LEFT_PERM");
	}
}

PugGetBanTimeLength(sTime[],&iLength,sDuration[],iLen)
{
	new iTime = str_to_num(sTime);

	if(iTime > 0)
	{
		iLength = (time() + (iTime * 60));
		format_time(sDuration,iLen,"%d/%m/%Y (%H:%M)",iLength);
	}
	else
	{
		formatex(sDuration,iLen,"%L",LANG_SERVER,"PUG_DB_LENGTH_PERM");
	}
}

bool:isSteam(sString[])
{
	if(contain(sString,"STEAM_0:") > -1)
	{
		return true;
	}
	
	return false;
}
