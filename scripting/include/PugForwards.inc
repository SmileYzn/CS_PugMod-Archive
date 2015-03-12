#if defined _PugForwards_included
	#endinput
#endif
#define _PugForwards_included

forward PugEventWarmup(iStage);
forward PugEventStart(iStage);
forward PugEventFirstHalf(iStage);
forward PugEventHalfTime(iStage);
forward PugEventSecondHalf(iStage);
forward PugEventOvertime(iStage);
forward PugEventEnd(iWinner);

forward PugEventRoundStart(iStage);
forward PugEventRoundWinner(iWinner);
forward PugEventRoundEnd(iStage);

forward PugEventJoinedTeam(id,iTeam);
