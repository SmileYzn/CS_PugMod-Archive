#include <amxmodx>
#include <amxmisc>

#include <PugConst>
#include <PugStocks>

#pragma semicolon 1

new g_iAdminCount;

#define ADMIN_LOOKUP	(1<<0)
#define ADMIN_NORMAL	(1<<1)
#define ADMIN_STEAM	(1<<2)
#define ADMIN_IPADDR	(1<<3)
#define ADMIN_NAME	(1<<4)

new bool:g_bCaseSensitiveName[33];

new g_pMode;
new g_pPasswordField;
new g_pDefaultAccess;

public plugin_init()
{
	register_plugin("Pug Mod (Admin)",PUG_MOD_VERSION,"AMXX Dev Team");
	
	register_dictionary("PugAdmin.txt");
	
	g_pMode = register_cvar("pug_acess_mode","1");
	g_pPasswordField = register_cvar("pug_password_field","_password");
	g_pDefaultAccess = register_cvar("pug_default_access","z");

	remove_user_flags(0,read_flags("z"));
}

public plugin_cfg()
{
	new sPatch[64];
	get_configsdir(sPatch,charsmax(sPatch));
	format(sPatch,charsmax(sPatch),"%s/users.ini",sPatch);
	
	PugLoadAdmins(sPatch);
}

PugLoadAdmins(sFile[])
{
	new iFile = fopen(sFile,"r");
	
	if(iFile)
	{
		new sText[512],sFlags[32],sAccess[32],sAuth[32],sPassword[32];
		
		while(!feof(iFile))
		{
			fgets(iFile,sText,charsmax(sText));
			trim(sText);
			
			if(sText[0] != ';') 
			{
				sFlags[0] = 0;
				sAccess[0] = 0;
				sAuth[0] = 0;
				sPassword[0] = 0;
	
				if(parse(sText,sAuth,charsmax(sAuth),sPassword,charsmax(sPassword),sAccess,charsmax(sAccess),sFlags,charsmax(sFlags)) > 1)
				{
					g_iAdminCount++;
					admins_push(sAuth,sPassword,read_flags(sAccess),read_flags(sFlags));
				}
			}
		}
		
		fclose(iFile);
	}
	
	server_print("* %i %L",g_iAdminCount,LANG_SERVER,(g_iAdminCount > 1) ? "PUG_ADMINS_LOADED" : "PUG_ADMIN_LOADED");
	
	return g_iAdminCount;
}

PugGetAccess(id,sName[],sAuth[],sIP[],sPassword[])
{
	new index = -1;
	new iResult = 0;
	
	static iCount;
	static iFlags;
	static iAccess;
	static sAuthData[44];
	static sPw[32];
	
	g_bCaseSensitiveName[id] = false;

	iCount = admins_num();
	
	for(new i;i < iCount;++i)
	{
		iFlags = admins_lookup(i,AdminProp_Flags);
		
		admins_lookup(i,AdminProp_Auth,sAuthData,charsmax(sAuthData));
		
		if(iFlags & FLAG_AUTHID)
		{
			if(equal(sAuth,sAuthData))
			{
				index = i;
				
				break;
			}
		}
		else if(iFlags & FLAG_IP)
		{
			new c = strlen(sAuthData);
			
			if(sAuthData[c - 1] == '.')
			{
				if(equal(sAuthData,sIP,c))
				{
					index = i;
					
					break;
				}
			}
			else if(equal(sIP,sAuthData))
			{
				index = i;
				
				break;
			}
		} 
		else 
		{
			if(iFlags & FLAG_CASE_SENSITIVE)
			{
				if(iFlags & FLAG_TAG)
				{
					if(contain(sName,sAuthData) != -1)
					{
						index = i;
						g_bCaseSensitiveName[id] = true;
						
						break;
					}
				}
				else if(equal(sName,sAuthData))
				{
					index = i;
					g_bCaseSensitiveName[id] = true;
					
					break;
				}
			}
			else
			{
				if(iFlags & FLAG_TAG)
				{
					if(containi(sName,sAuthData) != -1)
					{
						index = i;
						
						break;
					}
				}
				else if(equali(sName,sAuthData))
				{
					index = i;
					
					break;
				}
			}
		}
	}

	if(index != -1)
	{
		iAccess = admins_lookup(index,AdminProp_Access);

		if(iFlags & FLAG_NOPASS)
		{
			iResult |= 8;
			new sFlags[32];
			
			get_flags(iAccess,sFlags,charsmax(sFlags));
			set_user_flags(id,iAccess);
		}
		else 
		{
			admins_lookup(index,AdminProp_Password,sPw,charsmax(sPw));

			if (equal(sPassword,sPw))
			{
				iResult |= 12;
				set_user_flags(id,iAccess);
				
				new sFlags[32];
				get_flags(iAccess,sFlags,charsmax(sFlags));
			} 
			else 
			{
				iResult |= 1;
				
				if(iFlags & FLAG_KICK)
				{
					iResult |= 2;
				}
			}
		}
	}
	else if(get_pcvar_float(g_pMode) == 2.0)
	{
		iResult |= 2;
	} 
	else 
	{
		new sDefault[32];
		get_pcvar_string(g_pDefaultAccess,sDefault,charsmax(sDefault));
		
		if(!strlen(sDefault))
		{
			copy(sDefault,sizeof(sDefault),"z");
		}
		
		new iDefault = read_flags(sDefault);
		
		if(iDefault)
		{
			iResult |= 8;
			set_user_flags(id,iDefault);
		}
	}
	
	return iResult;
}

PugAccessUser(id,sName[] = "")
{
	remove_user_flags(id);
	new sIP[32],sAuth[32],sPassword[32],sPwField[32],sUserName[32];
	
	get_user_ip(id,sIP,charsmax(sIP),1);
	get_user_authid(id,sAuth,charsmax(sAuth));
	
	if(sName[0])
	{
		copy(sUserName,charsmax(sUserName),sName);
	}
	else
	{
		get_user_name(id,sUserName,charsmax(sUserName));
	}
	
	get_pcvar_string(g_pPasswordField,sPwField,charsmax(sPwField));
	get_user_info(id,sPwField,sPassword,charsmax(sPassword));
	
	new iResult = PugGetAccess(id,sUserName,sAuth,sIP,sPassword);
	
	if(iResult & 1)
	{
		console_print(id,"* %L",LANG_SERVER,"PUG_PASSWORD_INCORRECT");
	}
	
	if(iResult & 2)
	{
		PugDisconnect(id,"%L",LANG_SERVER,"PUG_SERVER_ACCESS");
		
		return PLUGIN_HANDLED;
	}
	
	if(iResult & 4)
	{
		console_print(id,"* %L",LANG_SERVER,"PUG_PASSWORD_ACCEPTED");
	}
	
	if(iResult & 8)
	{
		console_print(id,"* %L",LANG_SERVER,"PUG_PERMISSIONS_OK");
	}
	
	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if(is_user_connected(id) && get_pcvar_num(g_pMode))
	{
		new sName[2][32];
		
		get_user_name(id,sName[0],charsmax(sName[]));
		get_user_info(id,"name",sName[1],charsmax(sName[]));
	
		if(g_bCaseSensitiveName[id])
		{
			if(!equal(sName[0],sName[1]))
			{
				PugAccessUser(id,sName[1]);
			}
		}
		else
		{
			if(!equali(sName[0],sName[1]))
			{
				PugAccessUser(id,sName[1]);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	g_bCaseSensitiveName[id] = false;
	
	return get_pcvar_num(g_pMode) ? PugAccessUser(id) : PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if(!is_dedicated_server() && (id == 1))
	{
		return get_pcvar_num(g_pMode) ? PugAccessUser(id) : PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}
