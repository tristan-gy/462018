/**
 * Server wide settings
 *
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class GeneralSettings extends WebAdminSettings;

`include(WebAdmin.uci)
`include(SettingsMacros.uci)

var GameInfo gameinfo;

function setCurrentGameInfo(GameInfo instance)
{
	super.setCurrentGameInfo(instance);
	gameinfo = instance;
	// reload values
	if (gameinfo != none)
	{
		initSettings();
	}
}

function cleanupSettings()
{
	gameinfo = none;
	super.cleanupSettings();
}

function initSettings()
{
	local OnlineGameSettings GameSettings;
	local GameEngine GEngine;

	GEngine = GameEngine(class'Engine'.static.GetEngine());

	// Server Information
	if (gameinfo != none && gameinfo.GameReplicationInfo != none)
	{
		SetStringPropertyByName('ServerName', gameinfo.GameReplicationInfo.ServerName);
	}
	else
	{
		SetStringPropertyByName('ServerName', class'GameReplicationInfo'.default.ServerName);
	}

	if (GEngine != none)
	{
		`SetBoolPropertyByName('bUsedForTakeover', GEngine.bUsedForTakeover);
	}
	else
	{
		`SetBoolPropertyByName('bUsedForTakeover', class'GameEngine'.default.bUsedForTakeover);
	}

	// Connection settings
	`GI_SetIntPropertyByName(,, MaxPlayers);
	`GI_SetFloatPropertyByName(,, MaxIdleTime);

	// Cheat Detection
	if (gameinfo != none)
	{
		GameSettings = gameinfo.GameInterface.GetGameSettings(gameinfo.PlayerReplicationInfoClass.default.SessionName);
	}
	if (GameSettings != None)
	{
		SetIntPropertyByName('bAntiCheatProtected', int(GameSettings.bAntiCheatProtected));
	}
	else
	{
		SetIntPropertyByName('bAntiCheatProtected', int(false));
	}

	// Game settings
	`GI_SetFloatPropertyByName(,, GameDifficulty);
	`GI_SetIntPropertyByName(, KFGameInfo, GameLength);
	`GI_SetBoolPropertyByName(, KFGameInfo, bDisableTeamCollision);
	// TODO: use custom map list?

	// Administration settings
	`GI_SetBoolPropertyByName(,, bAdminCanPause);
	if (gameinfo != none && KFAccessControl(gameinfo.AccessControl) != none)
	{
		`SetBoolPropertyByName('bSilentAdminLogin', KFAccessControl(gameinfo.AccessControl).bSilentAdminLogin);
	}
	else
	{
		`SetBoolPropertyByName('bSilentAdminLogin', class'KFAccessControl'.default.bSilentAdminLogin);
	}

	// Map Voting
	`GI_SetBoolPropertyByName(, KFGameInfo, bDisableMapVote);
	`GI_SetFloatPropertyByName(, KFGameInfo, MapVoteDuration);
	`GI_SetFloatPropertyByName(, KFGameInfo, MapVotePercentage);

	// Kick voting
	`GI_SetBoolPropertyByName(, KFGameInfo, bDisableKickVote);
	`GI_SetFloatPropertyByName(, KFGameInfo, KickVotePercentage);

	// Chat
	`GI_SetBoolPropertyByName(, KFGameInfo, bDisableVOIP);
	`GI_SetBoolPropertyByName(, KFGameInfo, bDisablePublicTextChat);
	`GI_SetBoolPropertyByName(, KFGameInfo, bPartitionSpectators);
}

function saveSettings()
{
	local int val;
	local OnlineGameSettings GameSettings;
	local GameEngine GEngine;
	local bool bWasUsedForTakeover;

	GEngine = GameEngine(class'Engine'.static.GetEngine());

	// Cheat Detection
	if (gameinfo != none)
	{
		GameSettings = gameinfo.GameInterface.GetGameSettings(gameinfo.PlayerReplicationInfoClass.default.SessionName);
	}
	if (GameSettings != None)
	{
		GetIntPropertyByName('bAntiCheatProtected', val);
		if (GameSettings.bAntiCheatProtected != (val != 0))
		{
			GameSettings.bAntiCheatProtected = val != 0;
			gameinfo.GameInterface.UpdateOnlineGame(gameinfo.PlayerReplicationInfoClass.default.SessionName, GameSettings, true);
		}
	}

	// GRI
	GetStringPropertyByName('ServerName', class'GameReplicationInfo'.default.ServerName);
	class'GameReplicationInfo'.static.StaticSaveConfig();
	if (gameinfo != none && gameinfo.GameReplicationInfo != none)
	{
		GetStringPropertyByName('ServerName', gameinfo.GameReplicationInfo.ServerName);
		gameinfo.GameReplicationInfo.SaveConfig();
	}

	`GetBoolPropertyByName('bUsedForTakeover', class'GameEngine'.default.bUsedForTakeover);
	class'GameEngine'.static.StaticSaveConfig();
	if (GEngine != none)
	{
		bWasUsedForTakeover = GEngine.bUsedForTakeover;
		`GetBoolPropertyByName('bUsedForTakeover', GEngine.bUsedForTakeover);
		GEngine.SaveConfig();
		if (!GEngine.bUsedForTakeover)
		{
			GEngine.bAvailableForTakeover = false;
		}
		else if (!bWasUsedForTakeover)
		{
			GEngine.bAvailableForTakeover = true;
		}
	}

	// AccessControl
	`GetBoolPropertyByName('bSilentAdminLogin', class'KFAccessControl'.default.bSilentAdminLogin);
	class'KFAccessControl'.static.StaticSaveConfig();
	if (gameinfo != none && `{AccessControl} (gameinfo.AccessControl) != none)
	{
		`GetBoolPropertyByName('bSilentAdminLogin', KFAccessControl(gameinfo.AccessControl).bSilentAdminLogin);
		gameinfo.AccessControl.SaveConfig();
	}

	// KFGameInfo
	`GI_GetBoolPropertyByName(, KFGameInfo, bDisableTeamCollision);

	`GI_GetBoolPropertyByName(, KFGameInfo, bDisableVOIP);
	`GI_GetBoolPropertyByName(, KFGameInfo, bDisablePublicTextChat);
	`GI_GetBoolPropertyByName(, KFGameInfo, bPartitionSpectators);

	`GI_GetBoolPropertyByName(, KFGameInfo, bDisableMapVote);
	`GI_GetFloatPropertyByName(, KFGameInfo, MapVoteDuration);
	`GI_GetFloatPropertyByName(, KFGameInfo, MapVotePercentage);

	`GI_GetBoolPropertyByName(, KFGameInfo, bDisableKickVote);
	`GI_GetFloatPropertyByName(, KFGameInfo, KickVotePercentage);
	class'KFGameInfo'.static.StaticSaveConfig();

	// GameInfo
	`GI_GetIntPropertyByName('MaxPlayers',, MaxPlayers);
	`GI_GetBoolPropertyByName('bAdminCanPause',, bAdminCanPause);
	`GI_GetFloatPropertyByName('MaxIdleTime',, MaxIdleTime);
	class'GameInfo'.static.StaticSaveConfig();

	if (gameinfo != none) {
		gameinfo.SaveConfig();

		// WD JMH - Make sure the advertised settings get updated now
		gameinfo.UpdateGameSettings();
		gameinfo.UpdateGameSettingsCounts();
	}

	// The following values should only change on map change
	`GI_GetIntPropertyByName(, KFGameInfo, GameLength);
	class'KFGameInfo'.static.StaticSaveConfig();

	`GI_GetFloatPropertyByName('GameDifficulty',, GameDifficulty);
	class'GameInfo'.static.StaticSaveConfig();
}

defaultproperties
{
	SettingsGroups.Add((groupId="Server",pMin=0,pMax=100))
	SettingsGroups.Add((groupId="Connection",pMin=100,pMax=200))
	SettingsGroups.Add((groupId="CheatDetection",pMin=200,pMax=300))
	SettingsGroups.Add((groupId="Game",pMin=300,pMax=400))
	SettingsGroups.Add((groupId="Administration",pMin=500,pMax=600))
	SettingsGroups.Add((groupId="MapVoting",pMin=600,pMax=650))
	SettingsGroups.Add((groupId="KickVoting",pMin=650,pMax=700))
	SettingsGroups.Add((groupId="Chat",pMin=700,pMax=800))


	//The labels for all of these properties are in WebAdmin.int
	//They MUST mirror the order of these entries, or the labels and choices will be on the wrong property

	// Server Information
	Properties.Add((PropertyId=0,Data=(Type=SDT_String)))
 	PropertyMappings.Add((Id=0,name="ServerName",MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	Properties.Add((PropertyId=1,Data=(Type=SDT_Int32)))
 	PropertyMappings.Add((Id=1,name="bUsedForTakeover",MappingType=PVMT_IdMapped,ValueMappings=((Id=1),(Id=0))))

	// Connection settings
	Properties.Add((PropertyId=101,Data=(Type=SDT_Int32)))
 	PropertyMappings.Add((Id=101,name="MaxPlayers",MappingType=PVMT_Ranged,MinVal=0,MaxVal=12,RangeIncrement=1))
 	Properties.Add((PropertyId=102,Data=(Type=SDT_Float)))
 	PropertyMappings.Add((Id=102,name="MaxIdleTime",MappingType=PVMT_Ranged,MinVal=0,MaxVal=300,RangeIncrement=5))

 	// Cheat Detection
 	Properties.Add((PropertyId=200,Data=(Type=SDT_Int32)))
 	PropertyMappings.Add((Id=200,name="bAntiCheatProtected",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

 	// Game settings
 	Properties.Add((PropertyId=302,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=302,name="bDisableTeamCollision",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
	Properties.Add((PropertyId=303,Data=(Type=SDT_Float)))
	PropertyMappings.Add((Id=303,name="GameDifficulty",MappingType=PVMT_PredefinedValues,ValueMappings=((Id=0),(Id=1),(Id=2),(Id=3)),PredefinedValues=((Type=SDT_Float),(Type=SDT_Float),(Type=SDT_Float),(Type=SDT_Float)),MinVal=0,MaxVal=3,RangeIncrement=1))
	FloatPredefinedValues.Add((PropertyId=303,Values=(0,1,2,3)))
	Properties.Add((PropertyId=304,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=304,name="GameLength",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1),(Id=2),(Id=3)),PredefinedValues=((Type=SDT_Int32),(Type=SDT_Int32),(Type=SDT_Int32),(Type=SDT_Int32)),MinVal=0,MaxVal=3,RangeIncrement=1))

	// Administration settings
	Properties.Add((PropertyId=500,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=500,name="bAdminCanPause",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
	Properties.Add((PropertyId=501,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=501,name="bSilentAdminLogin",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

	// Chat
 	Properties.Add((PropertyId=701,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=701,name="bDisableVOIP",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
	Properties.Add((PropertyId=702,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=702,name="bDisablePublicTextChat",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
	Properties.Add((PropertyId=703,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=703,name="bPartitionSpectators",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

	// Kick voting
	`def_boolproperty(650, "bDisableKickVote")
	`def_floatproperty(654, "KickVotePercentage", 0, 1.0, 0.05)

	// Map Voting
	`def_boolproperty(600, "bDisableMapVote")
	`def_floatproperty(601, "MapVoteDuration", 10, 300, 5)
	`def_floatproperty(602, "MapVotePercentage", 0, 100, 5)
}
