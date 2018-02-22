/**
 * Load the Killing Floor 2 datastore provider
 *
 * Copyright (C) 2015 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DataStoreCacheKF extends DataStoreCache;

function UIDataStore_GameResource getDatasource()
{
	if (datasource == none)
	{
		class'KFUIDataStore_GameResource'.static.InitializeProviders();
		datasource = KFUIDataStore_GameResource(class'UIRoot'.static.StaticResolveDataStore(class'KFUIDataStore_GameResource'.default.Tag));
	}
	return datasource;
}

// FIXME: temp solution because gametypes are not defined in DefaultKFGameContent.ini yet
/*
function loadGameTypes()
{
	local UIGameInfoSummary item;
	local DCEGameInfo entry;
	if (gametypes.Length > 0)
	{
		return;
	}

	item = new(self, "Survival") class'UIGameInfoSummary';
	item.ClassName = "KFGameContent.KFGameInfo_Survival";
	item.MapPrefix = "KF";
	item.GameSettingsClassName = "KFGame.KFOnlineGameSettings";

	entry = new(self, string(item.name)) class'DCEGameInfo';
	entry.init(item);

	gametypes.AddItem(entry);
}
*/
