/**
 * DataStore access class.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2015 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DataStoreCache extends Object config(WebAdmin);

`include(WebAdmin.uci)

/**
 *  Instance providing lookup functionality. Don't access directly, use getDatasource()
 */
var UIDataStore_GameResource datasource;

/**
 * List of gametypes
 */
var array<DCEGameInfo> gametypes;

/**
 * List of all maps
 */
var array<DCEMapInfo> maps;

struct GameTypeMaps
{
	var string gametype;
	var array<DCEMapInfo> maps;
};
var array<GameTypeMaps> gameTypeMapCache;

struct MutatorGroup
{
	var string GroupName;
	var array<DCEMutator> mutators;
};

/**
 * List of mutators grouped by group
 */
var array<MutatorGroup> mutatorGroups;

/**
 * Simple list of all mutators
 */
var array<DCEMutator> mutators;

struct GameTypeMutators
{
	var string gametype;
	var array<MutatorGroup> mutatorGroups;
};

/**
 * Cache of the mutators available for a specific gametype
 */
var array<GameTypeMutators> gameTypeMutatorCache;

struct MutatorAllowance
{
	var string id;
	var bool allowed;
};
/**
 * Cache mutator allowance to avoid loading packages at runtime as much as
 * possible.
 */
var config array<MutatorAllowance> allowanceCache;

`define WITH_WEAPONS
`if(`WITH_WEAPONS)
var array<UIWeaponSummary> weapons;
`endif

function cleanup()
{
	gametypes.remove(0, gametypes.length);
	maps.remove(0, maps.length);
	gameTypeMapCache.remove(0, gameTypeMapCache.length);
	mutatorGroups.remove(0, mutatorGroups.length);
	gameTypeMutatorCache.remove(0, gameTypeMutatorCache.length);
	`if(`WITH_WEAPONS)
	weapons.remove(0, weapons.length);
	`endif
}

function array<DCEGameInfo> getGameTypes(optional string sorton = "FriendlyName")
{
	local array<DCEGameInfo> result;
	local int i, j;
	if (gametypes.Length == 0)
	{
		loadGameTypes();
	}
	if (sorton ~= "FriendlyName")
	{
		result = gametypes;
		return result;
	}
	for (i = 0; i < gametypes.length; i++)
	{
		for (j = 0; j < result.length; j++)
		{
			if (compareGameType(result[j], gametypes[i], sorton))
			{
				result.Insert(j, 1);
				result[j] =  gametypes[i];
				break;
			}
		}
		if (j == result.length)
		{
			result.AddItem(gametypes[i]);
		}
	}
	return result;
}

/**
 * Resolve a partial classname of a gametype (e.g. without package name) to the
 * entry in the cache list.
 */
function int resolveGameType(coerce string classname)
{
	local int idx;
	if (gametypes.Length == 0)
	{
		loadGameTypes();
	}
	classname = "."$classname;
	for (idx = 0; idx < gametypes.length; idx++)
	{
		if (Right("."$gametypes[idx].data.ClassName, Len(classname)) ~= classname)
		{
			return idx;
		}
	}
	return INDEX_NONE;
}

function loadGameTypes()
{
	local array<UIResourceDataProvider> ProviderList;
	local UIGameInfoSummary item;
	local DCEGameInfo entry;
	local int i, j;

	if (gametypes.Length > 0)
	{
		return;
	}

	getDatasource().GetResourceProviders('GameTypes', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UIGameInfoSummary(ProviderList[i]);
		if (item.bIsDisabled) {
			continue;
		}

		for (j = 0; j < gametypes.length; j++)
		{
			if (gametypes[j].name == item.name)
			{
				`log("Found duplicate game mode with name: "$item.name,,'WebAdmin');
				break;
			}
		}
		if (j != gametypes.length)
		{
			continue;
		}

		entry = new(self, string(item.name)) class'DCEGameInfo';
		entry.init(item);

		for (j = 0; j < gametypes.length; j++)
		{
			if (compareGameType(gametypes[j], entry, "FriendlyName"))
			{
				gametypes.Insert(j, 1);
				gametypes[j] =  entry;
				break;
			}
		}
		if (j == gametypes.length)
		{
			gametypes.AddItem(entry);
		}
	}
}

static function bool compareGameType(DCEGameInfo g1, DCEGameInfo g2, string sorton)
{
	if (sorton ~= "FriendlyName")
	{
		return g1.FriendlyName > g2.FriendlyName;
	}
	else if (sorton ~= "GameName")
	{
		return g1.data.GameName > g2.data.GameName;
	}
	else if (sorton ~= "Description")
	{
		return g1.Description > g2.Description;
	}
	else if (sorton ~= "ClassName" || sorton ~= "GameMode")
	{
		return g1.data.ClassName > g2.data.ClassName;
	}
	else if (sorton ~= "GameAcronym" || sorton ~= "Acronym")
	{
		return g1.data.GameAcronym > g2.data.GameAcronym;
	}
	else if (sorton ~= "GameSettingsClass")
	{
		return g1.data.GameSettingsClassName > g2.data.GameSettingsClassName;
	}
}

static function string getMapPrefix(string MapName)
{
	local int idx;
	idx = InStr(MapName, "-");
	if (idx == INDEX_NONE) idx = InStr(MapName, "-");
	if (idx == INDEX_NONE) return "";
	return Caps(Left(MapName, idx));
}

function array<DCEMapInfo> getMaps(optional string gametype = "", optional string sorton = "MapName")
{
	local array<DCEMapInfo> result, workset;
	local int i, j, idx;
	local array<string> prefixes;
	local string prefix;

	if (maps.Length == 0)
	{
		loadMaps();
	}

	if (gametype == "")
	{
		workset = maps;
	}
	else {
		idx = resolveGameType(gametype);
		if (idx == INDEX_NONE)
		{
			`Log("gametype not found "$gametype);
			return result;
		}
		j = gameTypeMapCache.find('gametype', gametypes[idx].data.ClassName);
		if (j == INDEX_NONE)
		{
			ParseStringIntoArray(Caps(gametypes[idx].data.MapPrefix), prefixes, "|", true);
			for (i = 0; i < maps.length; i++)
			{
				prefix = getMapPrefix(maps[i].data.MapName);
				if (prefixes.find(prefix) > INDEX_NONE)
				{
					workset.AddItem(maps[i]);
				}
			}
			gameTypeMapCache.add(1);
			gameTypeMapCache[gameTypeMapCache.length-1].gametype = gametypes[idx].data.ClassName;
			gameTypeMapCache[gameTypeMapCache.length-1].maps = workset;
		}
		else {
			workset = gameTypeMapCache[j].maps;
		}
	}

	if (sorton ~= "MapName")
	{
		return workset;
	}

	for (i = 0; i < workset.length; i++)
	{
		for (j = 0; j < result.length; j++)
		{
			if (compareMap(result[j], workset[i], sorton))
			{
				result.Insert(j, 1);
				result[j] =  workset[i];
				break;
			}
		}
		if (j == result.length)
		{
			result.AddItem(workset[i]);
		}
	}
	return result;
}

/**
 * Get a list of gametypes for the given map
 */
function array<string> getGametypesByMap(string MapName)
{
	local string prefix;
	local array<string> result, prefixes;
	local int i;

	prefix = getMapPrefix(MapName);
	if (len(prefix) == 0) return result;
	loadGameTypes();

	for (i = 0; i < gametypes.length; ++i)
	{
		ParseStringIntoArray(Caps(gametypes[i].data.MapPrefix), prefixes, "|", true);
		if (prefixes.find(prefix) > INDEX_NONE)
		{
			result.AddItem(gametypes[i].data.ClassName);
		}
	}

	return result;
}

function loadMaps()
{
	local array<UIResourceDataProvider> ProviderList;
	local UIMapSummary item;
	local DCEMapInfo entry;
	local int i, j;

	if (maps.Length > 0)
	{
		return;
	}
	gameTypeMapCache.Remove(0, gameTypeMapCache.length);

	getDatasource().GetResourceProviders('Maps', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UIMapSummary(ProviderList[i]);

		for (j = 0; j < maps.length; j++)
		{
			if (maps[j].name == item.name)
			{
				`log("Found duplicate map with name: "$item.name,,'WebAdmin');
				break;
			}
		}
		if (j != maps.length)
		{
			continue;
		}

		entry = new(self, string(item.name)) class'DCEMapInfo';
		entry.init(item);


		for (j = 0; j < maps.length; j++)
		{
			if (compareMap(maps[j], entry, "MapName"))
			{
				maps.Insert(j, 1);
				maps[j] =  entry;
				break;
			}
		}
		if (j == maps.length)
		{
			maps.AddItem(entry);
		}
	}
}

static function bool compareMap(DCEMapInfo g1, DCEMapInfo g2, string sorton)
{
	if (sorton ~= "MapName")
	{
		return g1.data.MapName > g2.data.MapName;
	}
	else if (sorton ~= "DisplayName")
	{
		return g1.data.DisplayName > g2.data.DisplayName;
	}
	else if (sorton ~= "FriendlyName")
	{
		return g1.FriendlyName > g2.FriendlyName;
	}
	else if (sorton ~= "Description")
	{
		return g1.Description > g2.Description;
	}
}

function array<MutatorGroup> getMutators(optional string gametype = "", optional string sorton = "FriendlyName")
{
	local array<MutatorGroup> result, workset;
	local int j, idx;

	if (mutatorGroups.Length == 0)
	{
		loadMutators();
	}

	if (gametype == "")
	{
		workset = mutatorGroups;
	}
	else {
		idx = resolveGameType(gametype);
		if (idx == INDEX_NONE)
		{
			`Log("gametype not found "$gametype);
			result.length = 0;
			return result;
		}
		j = gameTypeMutatorCache.find('gametype', gametypes[idx].data.ClassName);
		if (j == INDEX_NONE)
		{
			workset = filterMutators(mutatorGroups, gametypes[idx].data.ClassName);
			gameTypeMutatorCache.add(1);
			gameTypeMutatorCache[gameTypeMutatorCache.length-1].gametype = gametypes[idx].data.ClassName;
			gameTypeMutatorCache[gameTypeMutatorCache.length-1].mutatorGroups = workset;
		}
		else {
			workset = gameTypeMutatorCache[j].mutatorGroups;
		}
	}

	if (sorton ~= "FriendlyName")
	{
		return workset;
	}

	return workset;
	// TODO: implement sorting
	/*
	for (i = 0; i < workset.length; i++)
	{
		for (j = 0; j < result.length; j++)
		{
			if (compareMap(result[j], workset[i], sorton))
			{
				result.Insert(j, 1);
				result[j] =  workset[i];
				break;
			}
		}
		if (j == result.length)
		{
			result.AddItem(workset[i]);
		}
	}
	return result;
	*/
}

/**
 * Filter the source mutator group list on the provided gametype
 */
function array<MutatorGroup> filterMutators(array<MutatorGroup> source, string gametype)
{
	local int i, j, k;
	local array<MutatorGroup> result;
	local MutatorGroup group;
	local class<GameInfo> GameModeClass;
	local bool findGameType, allowanceChanged;
	local string GameTypeMutatorId;

	findGameType = true;

	for (i = 0; i < source.length; i++)
	{
		group.GroupName = source[i].groupname;
		group.mutators.length = 0;
		for (j = 0; j < source[i].mutators.length; j++)
		{
			if (source[i].mutators[j].data.SupportedGameTypes.length > 0)
			{
				k = source[i].mutators[j].data.SupportedGameTypes.Find(gametype);
				if (k != INDEX_NONE)
				{
					group.mutators.AddItem(source[i].mutators[j]);
				}
			}
			else {
				GameTypeMutatorId = gametype$"@"$source[i].mutators[j].data.ClassName;
				k = allowanceCache.find('id', GameTypeMutatorId);
				if (k != INDEX_NONE)
				{
					if (allowanceCache[k].allowed)
					{
						group.mutators.AddItem(source[i].mutators[j]);
					}
				}
				else {
					if (GameModeClass == none && findGameType)
					{
						findGameType = false;
						GameModeClass = class<GameInfo>(DynamicLoadObject(gametype, class'class'));
						if (GameModeClass == none)
						{
							`Log("DataStoreCache::filterMutators() - Unable to find game class: "$gametype);
						}
					}
					if(GameModeClass != none)
					{
						allowanceChanged = true;
						k = allowanceCache.length;
						allowanceCache.length = k+1;
						allowanceCache[k].id = GameTypeMutatorId;
						if (GameModeClass.static.AllowMutator(source[i].mutators[j].data.ClassName))
						{
							group.mutators.AddItem(source[i].mutators[j]);
							allowanceCache[k].allowed = true;
						}
					}
				}
			}
		}
		if (group.mutators.length > 0)
		{
			result.AddItem(group);
		}
	}
	if (allowanceChanged)
	{
		SaveConfig();
	}
	return result;
}

function loadMutators()
{
	local array<UIResourceDataProvider> ProviderList;
	local KFMutatorSummary item;
	local DCEMutator entry;
	local int i, j, groupid, emptyGroupId;
	local array<string> groups;
	local string group;

	if (mutatorGroups.Length > 0)
	{
		return;
	}
	mutators.Remove(0, mutators.length);
	gameTypeMutatorCache.Remove(0, gameTypeMutatorCache.length);

	emptyGroupId = 0;
	// the empty group
	mutatorGroups.Length = 1;

	getDatasource().GetResourceProviders('Mutators', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = KFMutatorSummary(ProviderList[i]);
		if (item.bIsDisabled)
		{
			continue;
		}

		for (j = 0; j < mutators.length; j++)
		{
			if (mutators[j].name == item.name)
			{
				`log("Found duplicate mutator with name: "$item.name,,'WebAdmin');
				break;
			}
		}
		if (j != mutators.length)
		{
			continue;
		}

		entry = new(self, string(item.Name)) class'DCEMutator';
		entry.init(item);

		groups = item.GroupNames;
		if (groups.length == 0)
		{
			groups.AddItem("");
		}
		foreach groups(group)
		{
			groupid = mutatorGroups.find('GroupName', group);
			if (groupid == INDEX_NONE)
			{
				for (groupid = 0; groupid < mutatorGroups.length; groupid++)
				{
					if (mutatorGroups[groupid].GroupName > group)
					{
						break;
					}
				}
				mutatorGroups.Insert(groupid, 1);
				mutatorGroups[groupid].GroupName = Caps(group);
			}
			if (emptyGroupId == -1 && len(group) == 0)
			{
				emptyGroupId = groupid;
			}
			for (j = 0; j < mutatorGroups[groupid].mutators.length; j++)
			{
				if (compareMutator(mutatorGroups[groupid].mutators[j], entry, "FriendlyName"))
				{
					mutatorGroups[groupid].mutators.Insert(j, 1);
					mutatorGroups[groupid].mutators[j] =  entry;
					break;
				}
			}
			if (j == mutatorGroups[groupid].mutators.length)
			{
				mutatorGroups[groupid].mutators.AddItem(entry);
			}
		}

		for (j = 0; j < mutators.length; j++)
		{
			if (compareMutator(mutators[j], entry, "FriendlyName"))
			{
				mutators.Insert(j, 1);
				mutators[j] =  entry;
				break;
			}
		}
		if (j == mutators.length)
		{
			mutators.AddItem(entry);
		}
	}

	if (emptyGroupId == -1)
	{
		emptyGroupId = mutatorGroups.length;
		mutatorGroups[emptyGroupId].GroupName = "";
	}

	// remove groups with single entries
	for (i = mutatorGroups.length-1; i >= 0 ; i--)
	{
		if (i == emptyGroupId) continue;
		if (mutatorGroups[i].mutators.length > 1) continue;
		entry = mutatorGroups[i].mutators[0];
		for (j = 0; j < mutatorGroups[emptyGroupId].mutators.length; j++)
		{
			if (mutatorGroups[emptyGroupId].mutators[j] == entry)
			{
				break;
			}
			if (compareMutator(mutatorGroups[emptyGroupId].mutators[j], entry, "FriendlyName"))
			{
				mutatorGroups[emptyGroupId].mutators.Insert(j, 1);
				mutatorGroups[emptyGroupId].mutators[j] =  entry;
				break;
			}
		}
		if (j == mutatorGroups[emptyGroupId].mutators.length)
		{
			mutatorGroups[emptyGroupId].mutators.AddItem(entry);
		}
		mutatorGroups.Remove(i, 1);
	}
	if (mutatorGroups[emptyGroupId].mutators.Length == 0)
	{
		mutatorGroups.Remove(emptyGroupId, 1);
	}
}

static function bool compareMutator(DCEMutator m1, DCEMutator m2, string sorton)
{
	if (sorton ~= "ClassName")
	{
		return m1.data.ClassName > m2.data.ClassName;
	}
	else if (sorton ~= "FriendlyName")
	{
		return m1.FriendlyName > m2.FriendlyName;
	}
	else if (sorton ~= "Description")
	{
		return m1.Description > m2.Description;
	}
}

`if(`WITH_WEAPONS)
function loadWeapons()
{
	local array<UIResourceDataProvider> ProviderList;
	local UIWeaponSummary item;
	local int i, j;

	if (weapons.Length > 0)
	{
		return;
	}

	getDatasource().GetResourceProviders('Weapons', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UIWeaponSummary(ProviderList[i]);

		for (j = 0; j < weapons.length; j++)
		{
			if (compareWeapon(weapons[j], item, "FriendlyName"))
			{
				weapons.Insert(j, 1);
				weapons[j] =  item;
				break;
			}
		}
		if (j == weapons.length)
		{
			weapons.AddItem(item);
		}
	}
}

static function bool compareWeapon(UIWeaponSummary w1, UIWeaponSummary w2, string sorton)
{
	if (sorton ~= "ClassName")
	{
		return w1.ClassName > w2.ClassName;
	}
	else if (sorton ~= "FriendlyName")
	{
		return w1.FriendlyName > w2.FriendlyName;
	}
	else if (sorton ~= "Description")
	{
		return w1.Description > w2.Description;
	}
	/*
	else if (sorton ~= "AmmoClassPath")
	{
		return w1.AmmoClassPath > w2.AmmoClassPath;
	}
	*/
	/*
	// not available everywhere, and not really that interesting
	else if (sorton ~= "MeshReference")
	{
		return w1.MeshReference > w2.MeshReference;
	}
	*/
}
`endif

function UIDataStore_GameResource getDatasource()
{
	if (datasource == none)
	{
		datasource = UIDataStore_GameResource(class'UIRoot'.static.StaticResolveDataStore(class'UIDataStore_GameResource'.default.Tag));
	}
	return datasource;
}
