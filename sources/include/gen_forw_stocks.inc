#if defined _gen_forw_stocks_included
	#endinput
#endif
#define _gen_forw_stocks_included

#include <amxmodx>

#pragma semicolon 1

#define GEN_FORW_LEN 		37
#define CREATE_GEN_FORW_ID(%0) 	new %0[GEN_FORW_LEN]
#define GEN_FORW_ID(%0) 	%0[GEN_FORW_LEN]

#define GEN_FORW_START_ID 	0
#define GEN_FORW_HPID 		1
#define GEN_FORW_HFID 		2
#define GEN_FORW_POS 		3
#define GEN_FORW_FUNC_STR 	4

stock CreateGenForward(fw_Function[],hPlugin,hFunction,iPlugin = 0)
{
	new fw_ID[GEN_FORW_LEN];

	fw_ID[GEN_FORW_START_ID] = iPlugin;
	fw_ID[GEN_FORW_POS] = iPlugin; 

	fw_ID[GEN_FORW_HPID] = hPlugin;
	fw_ID[GEN_FORW_HFID] = hFunction;

	copy(fw_ID[GEN_FORW_FUNC_STR],GEN_FORW_LEN - GEN_FORW_FUNC_STR,fw_Function);

	return fw_ID;
}

stock ExecuteGenForward(GEN_FORW_ID(fw_ID))
{
	new iPlugins = get_pluginsnum();
	new iFunctionID;
	
	new i = fw_ID[GEN_FORW_POS] = fw_ID[GEN_FORW_START_ID]; 
	++fw_ID[GEN_FORW_POS];

	for( ;i < iPlugins;++i,++fw_ID[GEN_FORW_POS])
	{
		iFunctionID = get_func_id(fw_ID[GEN_FORW_FUNC_STR],i);
		
		if(iFunctionID == -1) continue;

		if(callfunc_begin_i(iFunctionID,i) == 1)
		{
			callfunc_push_array(fw_ID,GEN_FORW_LEN);

			if(callfunc_end () == PLUGIN_HANDLED)
			{
				return;
			}
		}
	}

	callfunc_begin_i(fw_ID[GEN_FORW_HFID],fw_ID[GEN_FORW_HPID]);
	callfunc_end();
}

stock ContinueGenForward(GEN_FORW_ID(fw_ID))
{
	new iPlugins = get_pluginsnum();
	new iFunctionID;
	
	new i = fw_ID[GEN_FORW_POS];
	++fw_ID[GEN_FORW_POS];

	for( ; i < iPlugins;++i,++fw_ID[GEN_FORW_POS])
	{
		iFunctionID = get_func_id(fw_ID[GEN_FORW_FUNC_STR],i);

		if(iFunctionID == -1) continue;

		if(callfunc_begin_i(iFunctionID,i) == 1)
		{
			callfunc_push_array(fw_ID,GEN_FORW_LEN);

			if(callfunc_end() == PLUGIN_HANDLED)
			{
				return;
			}
		}
	}

	callfunc_begin_i(fw_ID[GEN_FORW_HFID],fw_ID[GEN_FORW_HPID]);
	callfunc_end();
}
