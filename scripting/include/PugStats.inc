#if defined _PugStats_included
	#endinput
#endif
#define _PugStats_included

stock Float:GetAccuracy(iShots,iHits)
{
	if(!iShots)
	{
		return 0.0;
	}
	
	return (100.0 * float(iHits) / float(iShots));
}

stock Float:GetEfficiency(iKills,iDeaths)
{
	if(!iKills)
	{
		return 0.0;
	}
	
	return (100.0 * float(iKills) / float(iKills + iDeaths));
}

stock Float:GetHSP(iHeadShots,iHits)
{
	if(!iHeadShots)
	{
		return 0.0;
	}
	
	return (100.0 * float(iHeadShots) / float(iHits));
}

stock Float:GetADR(iRounds,iDamage)
{
	if(!iRounds)
	{
		return 0.0;
	}
	
	return (float(iDamage) / float(iRounds));
}

stock Float:GetFPR(iRounds,iKills)
{
	if(!iRounds)
	{
		return 0.0;
	}
	
	return (float(iKills) / float(iRounds));
}

stock Float:GetKDR(iKills,iDeaths)
{
	if(!iKills)
	{
		return 0.0;
	}
	
	return (float(iKills) / float(iDeaths));
}

stock Float:GetSkill(Float:fEFF,Float:fACC)
{
	if(!fEFF || !fACC)
	{
		return 0.0;
	}
	
	return ((fEFF + fACC) / 2);
}

stock Float:GetWinPercentage(iRoundsWin,iRoundsPlayed)
{
	if(!iRoundsWin)
	{
		return 0.0;
	}
	
	return (100.0 * float(iRoundsWin) / float(iRoundsPlayed));
}

stock Float:GetLossPercentage(iRoundsLose,iRoundsPlayed)
{
	if(!iRoundsLose)
	{
		return 0.0;
	}
	
	return (100.0 * float(iRoundsLose) / float(iRoundsPlayed));
}
