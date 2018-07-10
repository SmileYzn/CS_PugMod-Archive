#if defined _PugStocks_included
	#endinput
#endif
#define _PugStocks_included

/**
 * Display an message into chat
 *
 * @note This is useful for display messages that not require extra parameters.
 *
 * @param id		Client index or 0 (All users)
 * @param Lang		Language line
 * @noreturn
 */
stock PugMsg(id,Lang[])
{
	client_print_color(id,print_team_red,"%s %L",g_Head,LANG_SERVER,Lang);
}

/**
 * Get Pug Mod configuration directory
 *
 * @note This is useful for get configs directory based on Amx Mod X.
 *
 * @param Patch		Buffer to copy patch to
 * @param Len		Maximum buffer size
 * @noreturn
 */
stock PugGetPath(Path[],Len)
{
	get_localinfo("amxx_configsdir",Path,Len);
	add(Path,Len,"/pug");
}

/**
 * Get Pug Mod configuration file path
 *
 * @note This is useful for get relative file paths
 *
 * @param File		File to include on complete path
 * @param Path		Buffer to copy patch to
 * @param Len		Maximum buffer size
 * @noreturn
 */
stock PugGetFilePath(const File[],Path[],Len)
{
	get_localinfo("amxx_configsdir",Path,Len);
	format(Path,Len,"%s/pug/%s",Path,File);
}

/**
 * Register new client command
 *
 * @note This is useful for register command using translation system,
 * 	 If command have admin flags, will be registred as !%s, if not as .%s
 *
 * @param Command		Command to register
 * @param Function		Function callback
 * @param Flags			Admin flags needed
 * @param Info			Information string
 * @param Translate		Try to translate given information string
 * @noreturn
 */
stock PugRegCommand(const Command[],const Function[],Flags = 0,const Info[] = "",bool:Translate = true)
{
	static Buffer[16];
	formatex(Buffer,charsmax(Buffer),(Flags == ADMIN_ALL) ? ".%s" : "!%s",Command);
	
	if(Info[0] && Translate)
	{
		new Key[64];
		format(Key,charsmax(Key),"%L",LANG_SERVER,Info);

		register_clcmd(Buffer,Function,Flags,Key);
	}
	else
	{
		register_clcmd(Buffer,Function,Flags,Info);
	}
}

/**
 * Execute a PUG function with client as parameter and display a result in chat
 *
 * @note This is only for execute functions that return an value
 *
 * @param id			Caller index (Usually an admin)
 * @param Command		String of the command
 * @param Lang			Lang string in language system
 * @param Target		Target client index
 * @param Check			The function to call or it's result
 * @noreturn
 */
stock PugCommandClient(id,Command[],Lang[],Target,Check)
{
	if(Check)
	{
		new Name[MAX_NAME_LENGTH];
		get_user_name(Target,Name,charsmax(Name));
	
		client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,Lang,Name);
	}
	
	client_print_color(id,print_team_red,"%s %L",g_Head,LANG_PLAYER,Check ? "PUG_CMD_OK" : "PUG_CMD_FAIL",Command);
}

/**
 * Execute a PUG function and display a result in chat
 *
 * @note This is only for execute functions that return an value
 *
 * @param id			Caller index (Usually an admin)
 * @param Command		String of the command
 * @param Lang			Lang string in language system
 * @param Check			The function to call or it's result
 * @noreturn
 */
stock PugCommand(id,Command[],Lang[],Check)
{
	if(Check)
	{
		new Name[MAX_NAME_LENGTH];
		get_user_name(id,Name,charsmax(Name));
		
		client_print_color(0,print_team_red,"%s %L",g_Head,LANG_SERVER,Lang,Name,Command);
	}
	
	client_print_color(id,print_team_red,"%s %L",g_Head,LANG_PLAYER,Check ? "PUG_CMD_OK" : "PUG_CMD_FAIL",Command);
}

/**
 * Build the help file (.html) for commands at config dir
 *
 * @note This is used to automatically build a file with registred commands
 *
 * @param Level			Admin level constant (See amxconst for flags)
 * @param Name			Name of the file to check or build
 * @param Tag			First character to check command (Usually . for PUG)
 * @noreturn
 */
stock PugBuildHelpFile(Level)
{
	new Path[64];
	
	PugGetFilePath((Level == ADMIN_ALL) ? "help.htm" : "admin.htm",Path,charsmax(Path));
	
	if(!file_exists(Path))
	{
		new Commands = get_concmdsnum(Level);
		
		if(Commands)
		{
			new File = fopen(Path,"wt");
			fputs(File,"<style type='text/css'>body{background:#000;margin:2px;color:#FFB000;font-family:Tahoma}</style><table width='100%%'>");
			
			new String[MAX_NAME_LENGTH],Flag,Info[128];
			
			for(new i;i < Commands;i++)
			{
				get_concmd(i,String,charsmax(String),Flag,Info,charsmax(Info),Level);
				
				if((String[0] == ((Level == ADMIN_ALL) ? '.' : '!')) && Info[0])
				{
					replace_all(Info,sizeof(Info),"<","&#60;");
					replace_all(Info,sizeof(Info),">","&#62;");
				
					fprintf(File,"<tr><td>%s</td><td>%s</td></tr>",String,Info);
				}
			}
			
			fclose(File);
		}
	}
}

/**
 * Build the pugmod.rc file (.rc) for cvars in PUG config dir
 *
 * @note This is used to automatically build a file with registred cvars
 *
 * @param Name			Name of the file to check or build
 * @param Help			Build file as html to help admins
 * @noreturn
 */
stock PugBuildCvarsFile(File[],bool:Help)
{
	new Path[64];
	PugGetFilePath(File,Path,charsmax(Path));
	
	if(!file_exists(Path))
	{
		new CvarsNum = get_plugins_cvarsnum();
		
		if(CvarsNum)
		{
			new File = fopen(Path,"wt");
			
			if(Help)
			{
				fputs(File,"<style type='text/css'>body{background:#000;margin:2px;color:#FFB000;font-family:Tahoma}</style><table width='100%%'>");
			}
			
			new Name[MAX_NAME_LENGTH],Flag,Plugin,Handle,Desc[128],Value[MAX_NAME_LENGTH];
			
			for(new i;i < CvarsNum;i++)
			{
				if(get_plugins_cvar(i,Name,charsmax(Name),Flag,Plugin,Handle,Desc,charsmax(Desc)))
				{
					if((Name[0] == 'p') && (Name[1] == 'u') && (Name[2] == 'g'))
					{
						if(Help)
						{
							replace_all(Desc,sizeof(Desc),"<","&#60;");
							replace_all(Desc,sizeof(Desc),">","&#62;");
							
							fprintf(File,"<tr><td>%s</td><td>%s</td></tr>",Name,Desc);
						}
						else
						{
							get_pcvar_string(Handle,Value,charsmax(Value));
							
							fprintf(File,"%s		^"%s^"			// %s^n",Name,Value,Desc);
						}
					}
				}
			}
			
			fclose(File);
		}
	}
}

/**
 * Build the maps menu
 *
 * @note This is used to automatically build a file with registred commands
 *
 * @param Level			Admin level constant (See amxconst for flags)
 * @param Name			Name of the file to check or build
 * @param Tag			First character to check command (Usually . for PUG)
 * @noreturn
 */
stock PugBuildMapsMenu(Title[],Handler[],Menu,Data[][],Len)
{
	new Path[64];
	PugGetFilePath("maps.rc",Path,charsmax(Path));
	
	if(file_exists(Path))
	{
		new File = fopen(Path,"rb");
		new Line[32],Num[3],Count;
		
		Menu = menu_create(Title,Handler);
		menu_setprop(Menu,MPROP_EXIT,MEXIT_NEVER);
		
		new Map[32];
		get_mapname(Map,charsmax(Map));
	
		while(!feof(File) && (Count < Len))
		{
			fgets(File,Line,charsmax(Line));
			trim(Line);
			
			if(is_map_valid(Line) && !equali(Map,Line))
			{
				copy(Data[Count],Len,Line);
				num_to_str(Count,Num,charsmax(Num));
				
				menu_additem(Menu,Line,Num);
				Count++;
			}
		}
		
		fclose(File);
		return Count;
	}
	
	return 0;
}
