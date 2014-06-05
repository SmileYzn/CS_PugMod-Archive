#if defined _pug_forwards_included
	#endinput
#endif
#define _pug_forwards_included

#include <gen_forw_stocks>

forward PugPreStart(GEN_FORW_ID(iForward));
forward PugFirstHalf(GEN_FORW_ID(iForward));
forward PugIntermission(GEN_FORW_ID(iForward));
forward PugSecondHalf(GEN_FORW_ID(iForward));
forward PugIntermissionOT(GEN_FORW_ID(iForward));
forward PugOvertime(GEN_FORW_ID(iForward));

forward PugAllReady(GEN_FORW_ID(iForward));

// forward PugHLTV();

forward PugRoundStart();
forward PugRoundStartFailed();

forward PugRoundEnd(iWinner);
forward PugRoundEndFailed();

forward PugWinner(iWinner);
forward PugFinished();
