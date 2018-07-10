#include <PugCore>
#include <PugStocks>

public plugin_init()
{
	register_plugin("Pug Mod (Manager)",AMXX_VERSION_STR,"SmileY");
	
	register_dictionary("common.txt");
	register_dictionary("PugAdmin.txt");
	
	PugRegCommand("kick","Kick",ADMIN_LEVEL_A,"PUG_DESC_KICK");
	PugRegCommand("kill","Kill",ADMIN_LEVEL_A,"PUG_DESC_KILL");
	PugRegCommand("rcon","Rcon",ADMIN_LEVEL_A,"PUG_DESC_RCON");
	PugRegCommand("map","Map",ADMIN_LEVEL_A,"PUG_DESC_MAP");
	PugRegCommand("msg","Msg",ADMIN_LEVEL_A,"PUG_DESC_MSG");
	PugRegCommand("ban","Ban",ADMIN_LEVEL_A,"PUG_DESC_BAN");
}

public plugin_cfg()
{
	new Path[64];
	PugGetFilePath("admins.rc",Path,charsmax(Path));
	
	if(file_exists(Path))
	{
		new SMCParser:Handle = SMC_CreateParser();
		
		if(Handle != Invalid_SMCParser)
		{
			SMC_SetReaders(Handle,"OnKeyValue");
			SMC_ParseFile(Handle,Path);
		}
		
		SMC_DestroyParser(Handle);
	}
	
	remove_user_flags(0,read_flags("z"));
}

public SMCResult:OnKeyValue(SMCParser:handle,const Key[],const Value[],any:data)
{
	admins_push(Key,"",read_flags(Value),FLAG_AUTHID|FLAG_NOPASS);	
	return SMCParse_Continue;
}

public client_authorized(id)
{
	new Steam[35],Auth[35];
	get_user_authid(id,Steam,charsmax(Steam));
	
	for(new i;i < admins_num();i++)
	{
		admins_lookup(i,AdminProp_Auth,Auth,charsmax(Auth));
		
		if(equali(Steam,Auth))
		{
			set_user_flags(id,admins_lookup(i,AdminProp_Access));
			return PLUGIN_CONTINUE;
		}
	}
	
	set_user_flags(id,ADMIN_USER);
	
	return PLUGIN_CONTINUE;
}

public Kick(id,Level)
{
	if(access(id,Level))
	{
		new Name[MAX_NAME_LENGTH];
		read_argv(1,Name,charsmax(Name));
		
		new Player = cmd_target(id,Name,CMDTARGET_OBEY_IMMUNITY);
		
		if(Player)
		{		
			new Reason[32];
			read_argv(2,Reason,charsmax(Reason));
			remove_quotes(Reason);
			
			server_cmd("kick #%i ^"%s^"",get_user_userid(Player),Reason);
		}
		
		PugCommandClient(id,"!kick","PUG_KICK",Player,Player);
	}
	
	return PLUGIN_HANDLED;
}

public Kill(id,Level)
{
	if(access(id,Level))
	{
		new Name[MAX_NAME_LENGTH];
		read_argv(1,Name,charsmax(Name));
		
		new Player = cmd_target(id,Name,CMDTARGET_OBEY_IMMUNITY);
		
		if(Player)
		{
			user_kill(Player,1)
		}

		PugCommandClient(id,"!kill","PUG_KILL",Player,Player);
	}
	
	return PLUGIN_HANDLED;
}

public Rcon(id,Level)
{
	if(access(id,Level))
	{
		new Text[256];
		read_args(Text,charsmax(Text));
		remove_quotes(Text);
		
		if(Text[0])
		{
			server_cmd(Text);
		}
		
		PugCommand(id,"!rcon","PUG_RCON",Text[0]);
	}
	
	return PLUGIN_HANDLED;
}

public Map(id,Level)
{
	if(access(id,Level))
	{
		new Name[32];
		read_args(Name,charsmax(Name));
		remove_quotes(Name);
		
		new IsMap = is_map_valid(Name);
		
		if(IsMap)
		{
			engine_changelevel(Name);
		}
		
		PugCommand(id,"!map","PUG_MAP",IsMap);
	}
	
	return PLUGIN_HANDLED;
}

public Msg(id,Level)
{
	if(access(id,Level))
	{
		new Text[256];
		read_args(Text,charsmax(Text));
		remove_quotes(Text);
		
		if(Text[0])
		{
			new Name[MAX_NAME_LENGTH];
			get_user_name(id,Name,charsmax(Name));
			
			client_print_color(0,print_team_red,"%s ^3(%s) ^1%s",g_Head,Name,Text);
		}
	}
	
	return PLUGIN_HANDLED;
}

public Ban(id,Level)
{
	if(access(id,Level))
	{
		new Name[MAX_NAME_LENGTH];
		read_argv(1,Name,charsmax(Name));
		
		new Player = cmd_target(id,Name,CMDTARGET_OBEY_IMMUNITY);
		
		if(Player)
		{
			new Time = read_argv_int(2);
			
			server_cmd("banid %i #%i kick;writeid",Time,get_user_userid(Player));
		}
		
		PugCommandClient(id,"!ban","PUG_BAN",Player,Player);
	}
	
	return PLUGIN_HANDLED;
}
