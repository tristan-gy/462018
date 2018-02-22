/**
 * A bit of magic to fake settings classes for gametypes who don't have any.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingsMagic extends Object config(WebAdmin);

`include(WebAdmin.uci)

struct MagicCacheEntry
{
	var class<GameInfo> cls;
	var WebAdminSettings inst;
};
var array<MagicCacheEntry> magicCache;

function cleanup()
{
	local int i;
	for (i = 0; i < magicCache.length; i++)
	{
		magicCache[i].inst.cleanupSettings();
		magicCache[i].inst = none;
	}
	magicCache.length = 0;
}

function WebAdminSettings find(class<GameInfo> GameClass)
{
	local WebAdminSettings result;
	local int idx;

	idx = magicCache.find('cls', GameClass);
	if (idx != INDEX_NONE)
	{
		return magicCache[idx].inst;
	}


	if (class<KFGameInfo_Survival>(GameClass) != none)
	{
		result = _KFGameInfo_Survival(class<KFGameInfo_Survival>(GameClass));
	}
	else if (class<KFGameInfo>(GameClass) != none)
	{
		result = _KFGameInfo(class<KFGameInfo>(GameClass));
	}

	if (result != none)
	{
		result.initSettings();
		magicCache.Length = magicCache.Length+1;
		magicCache[magicCache.Length-1].cls = GameClass;
		magicCache[magicCache.Length-1].inst = result;
	}
	return result;
}

function KFGameInfoSettings _KFGameInfo(class<KFGameInfo> cls)
{
	local KFGameInfoSettings r;
	r = new class'KFGameInfoSettings';
	r.KFGameInfoClass=cls;
	return r;
}

function KFGameInfoSettings _KFGameInfo_Survival(class<KFGameInfo_Survival> cls)
{
	local KFGameInfoSettings r;
	r = new class'KFGameInfo_SurvivalSettings';
	r.KFGameInfoClass=cls;
	return r;
}
