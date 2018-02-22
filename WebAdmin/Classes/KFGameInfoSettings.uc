/**
 * Generic settings for all builtin gametypes
 *
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class KFGameInfoSettings extends WebAdminSettings;

`include(WebAdmin.uci)
`include(SettingsMacros.uci)

`define GIV_CLASS KFGameInfo
`define GIV_VAR KFGameInfoClass

var class<`{GIV_CLASS}> `{GIV_VAR};

var GameInfo gameinfo;

function setCurrentGameInfo(GameInfo instance)
{
	if (instance != none)
	{
		if (!ClassIsChildOf(instance.class, `{GIV_VAR}))
		{
			return;
		}
	}
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
	if (`{GIV_VAR} == none) return;
 	`GIV_SetIntPropertyByName('GameStartDelay', GameStartDelay);
 	`GIV_SetIntPropertyByName('ReadyUpDelay', ReadyUpDelay);
 	`GIV_SetIntPropertyByName('EndOfGameDelay', EndOfGameDelay);
	`GIV_SetBoolPropertyByName('bDisablePickups', bDisablePickups);
//	`GIV_SetBoolPropertyByName('bEnableObjectives', bEnableObjectives);
//	`GIV_SetBoolPropertyByName('bEnableCoopObjectives', bEnableCoopObjectives);
}

function saveSettings()
{
	saveInternal();
	if (gameinfo != none) {
		gameinfo.SaveConfig();
	}
	`{GIV_VAR}.static.StaticSaveConfig();
}

protected function saveInternal()
{
	local int val;
	if (`{GIV_VAR} == none) return;
	`GIV_GetIntPropertyByName('GameStartDelay', GameStartDelay);
 	`GIV_GetIntPropertyByName('ReadyUpDelay', ReadyUpDelay);
 	`GIV_GetIntPropertyByName('EndOfGameDelay', EndOfGameDelay);
	`GIV_GetBoolPropertyByName('bDisablePickups', bDisablePickups);
//	`GIV_GetBoolPropertyByName('bEnableObjectives', bEnableObjectives);
//	`GIV_GetBoolPropertyByName('bEnableCoopObjectives', bEnableCoopObjectives);
}

defaultproperties
{
	SettingsGroups.Add((groupId="Rules",pMin=0,pMax=100))
	SettingsGroups.Add((groupId="Game",pMin=100,pMax=200))
	SettingsGroups.Add((groupId="Advanced",pMin=1000,pMax=1100))

	KFGameInfoClass=class'KFGameInfo'

	Properties[0]=(PropertyId=1,Data=(Type=SDT_Int32))
	PropertyMappings[0]=(Id=1,name="EndOfGameDelay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)

	Properties[1]=(PropertyId=2,Data=(Type=SDT_Int32))
	PropertyMappings[1]=(Id=2,name="GameStartDelay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)

	Properties[2]=(PropertyId=3,Data=(Type=SDT_Int32))
	PropertyMappings[2]=(Id=3,name="ReadyUpDelay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)

	Properties[3]=(PropertyId=4,Data=(Type=SDT_Int32))
	PropertyMappings[3]=(Id=4,name="bDisablePickups",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1)))

//	Properties[4]=(PropertyId=5,Data=(Type=SDT_Int32))
//	PropertyMappings[4]=(Id=5,name="bEnableObjectives",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1)))

//	Properties[5]=(PropertyId=6,Data=(Type=SDT_Int32))
//	PropertyMappings[5]=(Id=6,name="bEnableCoopObjectives",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1)))
}
