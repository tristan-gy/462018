/**
 * Query Handler for changing the default settings. It will try to find settings
 * handles for all gametypes and mutators. Custom gametypes have to implement a
 * subclass of the Settings class as name it: <GameTypeClass>Settings.
 * for example the gametype: FooBarQuuxGame has a settings class
 * FooBarQuuxGameSettings. See "UTTeamGameSettings" for an example implementation.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHDefaults extends Object implements(IQueryHandler) config(WebAdmin)
	dependson(WebAdminUtils);

`include(WebAdmin.uci)

struct ClassSettingsMapping
{
	var string className;
	var string settingsClass;
};
/**
 * Mapping for classname to settings class. Will be used to resolve classnames
 * for Settings classes that provide configuration possibilities for gametypes/
 * mutators when it can not be automatically found.
 */
var config array<ClassSettingsMapping> SettingsClasses;

struct HasSettingsClass
{
	var string className;
	var bool hasSettings;
};
var config array<HasSettingsClass> HasSettingsCache;

struct ClassSettingsCacheEntry
{
	var string cls;
	var class<WebAdminSettings> settingsCls;
};
var array<ClassSettingsCacheEntry> classSettingsCache;

struct SettingsInstance
{
	var class<WebAdminSettings> cls;
	var WebAdminSettings instance;
};
var array<SettingsInstance> settingsInstances;

/**
 * Settings class used for the general, server wide, settings
 */
var config string GeneralSettingsClass, WelcomeSettingsClass;

var WebAdmin webadmin;

var SettingsRenderer settingsRenderer;

var SettingsMagic settingsMagic;

//!localized
var localized string menuPolicy, menuPolicyDesc, menuBannedId, menuBannedIdDesc,
	menuBannedHash, menuBannedHashDesc, menuSession, menuSessionDesc, menuSettings,
	menuGeneral, menuGeneralDesc, menuPassword, menuPasswordDesc, menuGametypes,
	menuGametypesDesc, menuMutators, menuMutatorsDesc, menuMapCycles, menuMapCyclesDesc,
	menuMLAddition, menuMLAdditionDesc, msgSettingsCacheDesc, msgRemovedPolicy,
	msgNoValidIpMask, msgInvalidPolicy, msgAddedPolicy, msdUpdatedPolicy,
	msgNoValidId, msgAddedBanId, msgNoValidHash, msgBannedHash, msgRemovedSessionBan,
	msgSettingsSaved, msgCantSaveSettings, msgCantLoadSettings, msgGamePWError,
	msgGamePWSaved, msgAdminPWError, msgAdminPWSaved, msgAdminPWEmpty,
	msgMapCycleSaved, msgCantLoadGT, msgImportedMapList, msgInvalidMaplist,
	Untitled, msgCantFindMapCycle, msgCycleDeleted, msgCycleSaved, msgCycleActivated,
	menuServerActors, menuServerActorsDesc, msgServerActorsSaved, msgServerActorsSavedWarn,
	menuWelcome, menuWelcomeDesc, menuIpMask, menuIpMaskDesc,
	msgSessionBansNoROAC, msgMapCycleActivated, msgMapCycleDeleted, msgNewMapCycle,
	mapList, activeTag, msgBansImported, msgBansImporting, msgSessionBansNoBans;

function init(WebAdmin webapp)
{
	if (Len(GeneralSettingsClass) == 0)
	{
		GeneralSettingsClass = class.getPackageName()$".GeneralSettings";
		SaveConfig();
	}
	if (Len(WelcomeSettingsClass) == 0)
	{
		WelcomeSettingsClass = class.getPackageName()$".WelcomeSettings";
		SaveConfig();
	}
	webadmin = webapp;
}

function cleanup()
{
	local int i;
	if (settingsMagic != none)
	{
		settingsMagic.cleanup();
	}
	settingsMagic = none;
	webadmin = none;
	if (settingsRenderer != none)
	{
		settingsRenderer.modifiers.Length = 0;
		settingsRenderer.cleanup();
	}
	settingsRenderer = none;
	for (i = 0; i < settingsInstances.length; i++)
	{
		if (IAdvWebAdminSettings(settingsInstances[i].instance) != none)
		{
			IAdvWebAdminSettings(settingsInstances[i].instance).cleanupSettings();
		}
		else if (settingsInstances[i].instance != none)
		{
			settingsInstances[i].instance.cleanupSettings();
		}
	}
	settingsInstances.Length = 0;
}

function bool producesXhtml()
{
	return true;
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/policy":
			q.response.Redirect(WebAdmin.Path$"/policy/passwords");
			return true;
		case "/policy/ip":
			handleIPPolicy(q);
			return true;
		case "/policy/bans":
			handleBans(q);
			return true;
		case "/policy/bans+export":
			handleBansExport(q);
			return true;
		case "/policy/bans+import":
			handleBansImport(q);
			return true;
		`if(`WITH_BANCDHASH)
		case "/policy/hashbans":
			handleHashBans(q);
			return true;
		`endif
		`if(`WITH_SESSION_BAN)
		case "/policy/session":
			handleSessionBans(q);
			return true;
		`endif
		case "/settings":
			q.response.Redirect(WebAdmin.Path$"/settings/general");
			return true;
		case "/settings/general":
			handleSettingsGeneral(q);
			return true;
		case "/policy/passwords":
			handleSettingsPasswords(q);
			return true;
		`if(`WITH_WELCOME_SETTINGS)
		case "/settings/welcome":
			handleSettingsWelcome(q);
			return true;
		`endif
		case "/settings/gametypes":
			handleSettingsGametypes(q);
			return true;
		case "/settings/mutators":
			handleSettingsMutators(q);
			return true;
		case "/settings/maplist":
			handleMapList(q);
			return true;
		case "/system/settingscache":
			handleRebuildSettingsCache(q);
			return true;
		case "/settings/serveractors":
			handleServerActors(q);
			return true;
	}
	return false;
}

function bool unhandledQuery(WebAdminQuery q);

function decoratePage(WebAdminQuery q);

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/policy", menuPolicy, self, menuPolicyDesc, -70);
	menu.addMenu("/policy/passwords", menuPassword, self, menuPasswordDesc, -100);
	menu.addMenu("/policy/bans", menuBannedId, self, menuBannedIdDesc, -80);
	menu.addMenu("/policy/bans+export", "", self);
	menu.addMenu("/policy/bans+import", "", self);
	`if(`WITH_BANCDHASH)
	menu.addMenu("/policy/hashbans", menuBannedHash, self, menuBannedHashDesc);
	`endif
	`if(`WITH_SESSION_BAN)
	menu.addMenu("/policy/session", menuSession, self, menuSessionDesc, -90);
	`endif
	menu.addMenu("/policy/ip", menuIpMask, self, menuIpMaskDesc, -50);
	menu.addMenu("/settings", menuSettings, self, "", -50);
	menu.addMenu("/settings/general", menuGeneral, self, menuGeneralDesc, -10);
	`if(`WITH_WELCOME_SETTINGS)
	menu.addMenu("/settings/welcome", menuWelcome, self, menuWelcomeDesc);
	`endif
	menu.addMenu("/settings/gametypes", menuGametypes, self, menuGametypesDesc);
	`if(`WITH_MUTATORS)
	menu.addMenu("/settings/mutators", menuMutators, self, menuMutatorsDesc);
	`endif
	menu.addMenu("/settings/maplist", menuMapCycles, self, menuMapCyclesDesc);
	menu.addMenu("/settings/serveractors", menuServerActors, self, menuServerActorsDesc);
	menu.addMenu("/system/settingscache", "", self, msgSettingsCacheDesc);
}

function handleIPPolicy(WebAdminQuery q)
{
	local string policies;
	local string policy, action;
	local array<string> parts;
	local int i, idx;

	action = q.request.getVariable("action");
	if (action != "")
	{
		idx = -1;
		if (action ~= "modify")
		{
			if (q.request.getVariable("delete") != "")
			{
				idx = int(q.request.getVariable("delete"));
				action = "delete";
			}
			else if (q.request.getVariable("update") != "")
			{
				idx = int(q.request.getVariable("update"));
				action = "update";
			}
		}

		//`Log("Action = "$action);
		if (action ~= "delete")
		{
			if (idx > -1 && idx < webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
			{
				policy = webadmin.worldinfo.game.accesscontrol.IPPolicies[idx];
				webadmin.worldinfo.game.accesscontrol.IPPolicies.Remove(idx, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
				webadmin.addMessage(q, msgRemovedPolicy@policy);
			}
		}
		else {
			policy = q.request.getVariable("ipmask");
			policy -= " ";
			ParseStringIntoArray(policy, parts, ".", false);
			for (i = 0; i < parts.length; i++)
			{
				if (parts[i] == "*")
				{
					continue;
				}
				if (parts[i] != string(int(parts[i])) || int(parts[i]) > 255 || int(parts[i]) < 0 )
				{
					webadmin.addMessage(q, repl(msgNoValidIpMask, "%s", "<code>"$policy$"</code>"), MT_error);
					break;
				}
			}
			if (parts.length > 4 || parts.length < 1)
			{
				webadmin.addMessage(q, repl(msgNoValidIpMask, "%s", "<code>"$policy$"</code>"), MT_error);
				i = -1;
			}
			if (i == parts.length)
			{
				if (q.request.getVariable("policy") == "")
				{
					webadmin.addMessage(q, msgInvalidPolicy, MT_error);
				}
				else {
					policy = q.request.getVariable("policy")$","$policy;
					if (idx == -1)
					{
						webadmin.worldinfo.game.accesscontrol.IPPolicies.AddItem(policy);
						webadmin.addMessage(q, msgAddedPolicy@policy);
					}
					else {
						if (idx < -1 || idx > webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
						{
							idx = webadmin.worldinfo.game.accesscontrol.IPPolicies.length;
						}
						webadmin.worldinfo.game.accesscontrol.IPPolicies[idx] = policy;
						webadmin.addMessage(q, msdUpdatedPolicy@policy);
					}
					webadmin.worldinfo.game.accesscontrol.SaveConfig();
				}
			}
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.IPPolicies.length; i++)
	{
		q.response.subst("policy.id", ""$i);
		policy = webadmin.worldinfo.game.accesscontrol.IPPolicies[i];
		idx = InStr(policy, ",");
		if (idx == INDEX_NONE) idx = InStr(policy, ";");
		q.response.subst("policy.ipmask", `HTMLEscape(Mid(policy, idx+1)));
		q.response.subst("policy.policy", `HTMLEscape(Left(policy, idx)));
		q.response.subst("policy.selected."$Caps(Left(policy, idx)), "selected=\"selected\"");
		policies $= webadmin.include(q, "policy_row.inc");
		q.response.subst("policy.selected."$Caps(Left(policy, idx)), "");
	}

	q.response.subst("policies", policies);
	webadmin.sendPage(q, "policy.html");
}

function handleBans(WebAdminQuery q)
{
	local string bans, action;
	local int i;
	`if(`WITH_BANNEDINFO)
	local BannedInfo NewBanInfo;
	`endif
	local UniqueNetId unid;
	local OnlineSubsystem steamworks;

	steamworks = class'GameEngine'.static.GetOnlineSubsystem();

	action = q.request.getVariable("action");
	if (action ~= "delete")
	{
		action = q.request.getVariable("banid");
		i = InStr(action, "plainid:");
		if (i == INDEX_NONE)
		{
			`if(`WITH_BANNEDINFO)
			i = int(action);
			if (i >= 0 && i < webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Length)
			{
				webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Remove(i, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
			}
			`endif
		}
		else {
			i = int(Mid(action, 8));
			if (i >= 0 && i < webadmin.worldinfo.game.accesscontrol.BannedIDs.Length)
			{
				webadmin.worldinfo.game.accesscontrol.BannedIDs.Remove(i, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
			}
		}
	}
	else if (action ~= "add")
	{
		action = q.request.getVariable("uniqueid");
		action -= " ";
		if (action != "")
		{
			class'OnlineSubsystem'.static.StringToUniqueNetId(action, unid);
		}
		else if (steamworks != none)
		{
			action = q.request.getVariable("steamint64");
			action -= " ";
			steamworks.Int64ToUniqueNetId(action, unid);
		}

		if (class'WebAdminUtils'.static.UniqueNetIdToString(unid) == "")
		{
			webadmin.addMessage(q, repl(msgNoValidId, "%s", "<code>"$action$"</code>"), MT_error);
		}
		else {
			for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedIDs.length; ++i)
			{
				if (webadmin.worldinfo.game.accesscontrol.BannedIDs[i] == unid)
				{
					break;
				}
			}

			if (i == webadmin.worldinfo.game.accesscontrol.BannedIDs.length)
			{
				webadmin.worldinfo.game.accesscontrol.BannedIDs.addItem(unid);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
				webadmin.addMessage(q, msgAddedBanId@class'WebAdminUtils'.static.UniqueNetIdToString(unid));
			}
		}
	}

	`if(`WITH_BANNEDINFO)
	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Length; i++)
	{
		q.response.subst("ban.banid", ""$i);
		unid = webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].BannedID;
		q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
		q.response.subst("ban.playername", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].PlayerName));
		q.response.subst("ban.timestamp", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].TimeStamp));
		bans $= webadmin.include(q, "policy_bans_row.inc");
	}
	`endif

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedIDs.Length; i++)
	{
		q.response.subst("ban.banid", "plainid:"$i);
		unid = webadmin.worldinfo.game.accesscontrol.BannedIDs[i];
		q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
		if (steamworks != none)
		{
			q.response.subst("ban.steamid", steamworks.UniqueNetIdToInt64(unid));
			action = steamworks.UniqueNetIdToPlayerName(unid);
			q.response.subst("ban.steamname", `HTMLEscape(action));
		}
		else {
			q.response.subst("ban.steamid", "");
			q.response.subst("ban.steamname", "");
		}
		q.response.subst("ban.playername", "");
		q.response.subst("ban.timestamp", "");
		bans $= webadmin.include(q, "policy_bans_row.inc");
	}

	if (len(bans) == 0)
	{
		bans = webadmin.include(q, "policy_bans_empty.inc");
	}

	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_bans.html");
}

function handleBansExport(WebAdminQuery q)
{
	local JsonObject result, bans, banJson;
	local OnlineSubsystem steamworks;
	local int i;
	local int year,month,dayofweek,day,hour,minute,second,msec;

	GetSystemTime(year,month,dayofweek,day,hour,minute,second,msec);

	result = new class'JsonObject';
	result.SetStringValue("serverName", webadmin.WorldInfo.Game.GameReplicationInfo.ServerName);
	result.SetStringValue("timestamp", class'WebAdminUtils'.static.iso8601datetime(year,month,day,hour,minute,second,msec));

	steamworks = class'GameEngine'.static.GetOnlineSubsystem();

	bans = new class'JSonObject';
	result.SetObject("bans", bans);
	for (i = 0; i < webadmin.WorldInfo.Game.accesscontrol.BannedIDs.Length; ++i)
	{
		banJson = createBanJson(i, steamworks);
		if (banJson != none)
		{
			bans.ObjectArray.addItem(banJson);
		}
	}

	q.response.AddHeader("Content-Type: application/json");
	q.response.AddHeader("Content-Disposition: attachment; filename=\"server-bans.json\"");
	q.response.SendText(class'JsonObject'.static.EncodeJson(result));
}

function handleBansImport(WebAdminQuery q)
{
	local string action;
	local BanImporter banImporter;
	local int cnt;

	action = q.request.getVariable("action");
	if (action ~= "import")
	{
		banImporter = new class 'BanImporter';
		banImporter.importFrom(q.request.getVariable("importurl"));
		q.session.putObject("BanImporter", banImporter);
	}
	else {
		banImporter = BanImporter(q.session.getObject("BanImporter"));
	}

	if (banImporter == none) {
		q.response.Redirect(WebAdmin.Path$"/policy/bans");
		return;
	}

	q.response.subst("importer.status", banImporter.status);
	q.response.subst("importer.statusMessage", banImporter.getStatusStr());
	q.response.subst("importer.url", banImporter.importFromUrl);

	if (banImporter.status == IS_ERROR) {
		webadmin.addMessage(q, banImporter.errorMessage, MT_ERROR);
		q.session.removeObject("BanImporter");
	}
	else if (banImporter.status == IS_DONE) {
		cnt = banImporter.applyBansTo(webadmin.WorldInfo.Game.AccessControl,
			class'GameEngine'.static.GetOnlineSubsystem());
		webadmin.addMessage(q, repl(msgBansImported, "%i", cnt));
		q.session.removeObject("BanImporter");
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}

	webadmin.sendPage(q, "policy_bans_importing.html");
}

function JsonObject createBanJson(int idx, OnlineSubsystem steamworks)
{
	local JsonObject result;
	local AccessControl ac;
	local UniqueNetId unid;

	ac = webadmin.WorldInfo.Game.accesscontrol;
	if (ac.BannedIDs.Length < idx+1 || idx < 0)
	{
		return none;
	}
	unid = ac.BannedIDs[idx];

	result = new class'JsonObject';
	result.SetStringValue("uniqueNetId", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
	if (steamworks != none)
	{
		result.SetStringValue("steamId64", steamworks.UniqueNetIdToInt64(unid));
		result.SetStringValue("steamName", steamworks.UniqueNetIdToPlayerName(unid));
	}
	return result;
}

`if(`WITH_BANCDHASH)
function handleHashBans(WebAdminQuery q)
{
	local string bans, action;
	local int i;
	local BannedHashInfo NewBanInfo;

	action = q.request.getVariable("action");
	if (action ~= "delete")
	{
		i = int(q.request.getVariable("banid"));
		if (i > -1 && i < webadmin.worldinfo.game.accesscontrol.BannedHashes.Length)
		{
			webadmin.worldinfo.game.accesscontrol.BannedHashes.Remove(i, 1);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
		}
	}
	else if (action ~= "add")
	{
		action = q.request.getVariable("hashresponse");
		action -= " ";
		if (action == "0")
		{
			webadmin.addMessage(q, repl(msgNoValidHash, "%s", "<code>"$action$"</code>"), MT_error);
		}
		else {
			NewBanInfo.BannedHash = action;
			NewBanInfo.playername = q.request.getVariable("playername");
			webadmin.worldinfo.game.accesscontrol.BannedHashes.AddItem(NewBanInfo);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
			webadmin.addMessage(q, msgBannedHash@action);
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedHashes.Length; i++)
	{
		q.response.subst("ban.banid", ""$i);
		q.response.subst("ban.hash", webadmin.worldinfo.game.accesscontrol.BannedHashes[i].BannedHash);
		q.response.subst("ban.playername", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedHashes[i].PlayerName));
		bans $= webadmin.include(q, "policy_hashbans_row.inc");
	}

	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_hashbans.html");
}
`endif

`if(`WITH_SESSION_BAN)
function handleSessionBans(WebAdminQuery q)
{
	local `{AccessControl} roac;
	local UniqueNetId unid, empty;
	local string bans;
	local int i;
	local OnlineSubsystem steamworks;

	roac = `{AccessControl} (webadmin.worldinfo.game.accesscontrol);
	steamworks = class'GameEngine'.static.GetOnlineSubsystem();

	if (roac != none && q.request.getVariable("action") ~= "revoke")
	{
		i = int(q.request.getVariable("banid", "-1"));
		if (i > -1 && i < roac.SessionBannedIDs.length)
		{
			unid = roac.SessionBannedIDs[i];
			roac.SessionBannedIDs.remove(i, 1);
			webadmin.addMessage(q, repl(msgRemovedSessionBan, "%1", class'OnlineSubsystem'.static.UniqueNetIdToString(unid)));
		}
	}

	if (roac != none)
	{
		for (i = 0; i < roac.SessionBannedIDs.Length; i++)
		{
			q.response.subst("ban.banid", i);
			unid = roac.SessionBannedIDs[i];
			if (empty == unid)
			{
				q.response.subst("ban.uniqueid", "");
				q.response.subst("ban.uniqueid.visible", "display: none");
			}
			else {
				q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
				`if(`WITH_BANNEDINFO)
				if (webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.find('BannedID', unid) != INDEX_NONE)
				{
					q.response.subst("ban.uniqueid.visible", "display: none");
				}
				else {
				`endif
					q.response.subst("ban.uniqueid.visible", "");
				`if(`WITH_BANNEDINFO)
				}
				`endif
			}

			if (steamworks != none)
			{
				q.response.subst("ban.steamname", `HTMLEscape(steamworks.UniqueNetIdToPlayerName(unid)));
				q.response.subst("ban.steamid", steamworks.UniqueNetIdToInt64(unid));
			}
			else {
				q.response.subst("ban.steamname", "");
				q.response.subst("ban.steamid", "");
			}

			bans $= webadmin.include(q, "policy_session_row.inc");
		}
		if (roac.SessionBannedIDs.Length == 0)
		{
			q.response.subst("sessionban.empty", msgSessionBansNoBans);
			bans = webadmin.include(q, "policy_session_empty.inc");
		}
	}
	else {
		`log("Current AccessControl class: "$webadmin.worldinfo.game.accesscontrol.class$" ; Expecting subclass of: `{AccessControl}",,'WebAdmin');
		q.response.subst("sessionban.empty", msgSessionBansNoROAC);
		bans = webadmin.include(q, "policy_session_empty.inc");
	}
	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_session.html");
}
`endif

function handleRebuildSettingsCache(WebAdminQuery q)
{
	local array<DCEGameInfo> gts;
	local int i;

	if (q.request.getVariable("action") ~= "rebuild")
	{
		HasSettingsCache.length = 0;
		gts = webadmin.dataStoreCache.getGameTypes();
		for (i = 0; i < gts.length; i++)
		{
			HasSettings(gts[i].ClassName);
		}
		webadmin.dataStoreCache.loadMutators();
		for (i = 0; i < webadmin.dataStoreCache.mutators.length; i++)
		{
			HasSettings(webadmin.dataStoreCache.mutators[i].ClassName);
		}
		webadmin.addMessage(q, "Settings cache has been rebuild.");
	}

	webadmin.addMessage(q, "<form action=\""$WebAdmin.Path$q.Request.URI$"\" method=\"post\">"
		$"<p>Only rebuild the settings cache when the server is empty. It is strongly adviced to restart the game after rebuilding has been completed.</p>"
		$"<p><button type=\"submit\" name=\"action\" value=\"rebuild\">Rebuild cache</button></p></form>", MT_Warning);

	q.response.Subst("page.title", "Rebuild Settings Cache");
	webadmin.sendPage(q, "message.html");
}

function bool HasSettings(string forClass)
{
	local int i;
	i = HasSettingsCache.find('classname', locs(forClass));
	if (i != INDEX_NONE)
	{
		return HasSettingsCache[i].hasSettings;
	}
	i = HasSettingsCache.length;
	HasSettingsCache.length = i+1;
	HasSettingsCache[i].className = locs(forClass);
	HasSettingsCache[i].hasSettings = getSettingsClassFqn(forClass, true) != none;
	SaveConfig();
	return HasSettingsCache[i].hasSettings;
}

/**
 * Get the settings class by the fully qualified name
 */
function class<WebAdminSettings> getSettingsClassFqn(string forClass, optional bool bSilent=false)
{
	local int idx;
	local class<WebAdminSettings> result;
	if (len(forClass) == 0) return none;

	idx = classSettingsCache.find('cls', Locs(forClass));
	if (idx != INDEX_NONE)
	{
		return classSettingsCache[idx].settingsCls;
	}
	idx = InStr(forClass, ".");
	if (idx == INDEX_NONE)
	{
		result = getSettingsClass("", forClass, bSilent);
	}
	else {
		result = getSettingsClass(Left(forClass, idx), Mid(forClass, idx+1), bSilent);
	}
	if (result != none)
	{
		idx = HasSettingsCache.find('classname', locs(forClass));
		if (idx != INDEX_NONE)
		{
			HasSettingsCache[idx].hasSettings = true;
			SaveConfig();
		}
	}
	return result;
}

/**
 * Find the settings class. package name could be empty
 */
function class<WebAdminSettings> getSettingsClass(string pkgName, string clsName, optional bool bSilent=false)
{
	local string className, settingsClass;
	local class<WebAdminSettings> result;
	local int idx;
	local ClassSettingsCacheEntry cacheEntry;

	if (len(clsName) == 0) return none;

	idx = classSettingsCache.find('cls', Locs(pkgName$"."$clsName));
	if (idx != INDEX_NONE)
	{
		return classSettingsCache[idx].settingsCls;
	}

	cacheEntry.cls = Locs(pkgName$"."$clsName);

	idx = settingsClasses.find('className', clsName);
	if (idx == INDEX_NONE)
	{
		className = cacheEntry.cls;
		idx = settingsClasses.find('className', className);
	}
	if (idx != INDEX_NONE)
	{
		result = class<WebAdminSettings>(DynamicLoadObject(settingsClasses[idx].settingsClass, class'class'));
		if (result == none)
		{
			`Log("Unable to load settings class "$settingsClasses[idx].settingsClass$" for the class "$settingsClasses[idx].className,,'WebAdmin');
		}
		else {
			cacheEntry.settingsCls = result;
			classSettingsCache.addItem(cacheEntry);
			return result;
		}
	}
	// try to find it automatically
	settingsClass = rewriteSettingsClassname(pkgName, clsName);

	result = class<WebAdminSettings>(DynamicLoadObject(settingsClass, class'class', true));
	if (result != none)
	{
		cacheEntry.settingsCls = result;
		classSettingsCache.addItem(cacheEntry);
		return result;
	}
	// not in the same package, try the find the object (only works when it was loaded)
	result = class<WebAdminSettings>(FindObject(clsName$"Settings", class'class'));
	if (result == none)
	{
		if (!bSilent)
		{
			`Log("Settings class "$settingsClass$" for class "$pkgName$"."$clsName$" not found (auto detection).",,'WebAdmin');
		}
	}
	// even cache a none result
	cacheEntry.settingsCls = result;
	classSettingsCache.addItem(cacheEntry);
	return result;
}

function string rewriteSettingsClassname(string pkgName, string clsName)
{
	return pkgName$"."$clsName$"Settings";
}

/**
 * Try to find the settings class for the provided class
 */
function class<WebAdminSettings> getSettingsClassByClass(class forClass, optional bool bSilent=false)
{
	return getSettingsClass(string(forClass.getPackageName()), string(forClass.name), bSilent);
}

function WebAdminSettings getSettingsInstance(class<WebAdminSettings> cls)
{
	local WebAdminSettings instance;
	local int idx;
	idx = settingsInstances.find('cls', cls);
	if (idx == INDEX_NONE)
	{
		instance = new cls;
		idx = settingsInstances.length;
		settingsInstances.Length = idx+1;
		settingsInstances[idx].cls = cls;
		settingsInstances[idx].instance = instance;
		if (IAdvWebAdminSettings(instance) != none)
		{
			IAdvWebAdminSettings(instance).advInitSettings(webadmin.WorldInfo, webadmin.dataStoreCache);
		}
		else {
			instance.initSettings();
		}
	}
	return settingsInstances[idx].instance;
}

function SettingsRenderer getSettingsRenderer()
{
	if (settingsRenderer == none)
	{
		settingsRenderer = new class'SettingsRenderer';
		settingsRenderer.init(webadmin.path);
	}
	return settingsRenderer;
}

function handleSettingsGametypes(WebAdminQuery q)
{
	local string currentGameType, substvar, tmp;
	local DCEGameInfo editGametype, gametype;
	local int idx;
	local class<WebAdminSettings> settingsClass;
	local class<GameInfo> gi;
	local WebAdminSettings settings;
	local ISettingsPrivileges privs;
	local bool liveAdjust, settingsSaved;

	currentGameType = q.request.getVariable("gametype");
	if (currentGameType == "")
 	{
 		currentGameType = string(webadmin.WorldInfo.Game.class);
 	}
 	webadmin.dataStoreCache.loadGameTypes();
 	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		editGametype = webadmin.dataStoreCache.gametypes[idx];
 		currentGameType = editGametype.data.ClassName;
 	}
 	else {
 		editGametype = none;
 		currentGameType = "";
 	}

 	substvar = "";
 	foreach webadmin.dataStoreCache.gametypes(gametype)
 	{
 		if (!q.user.canPerform(webadmin.getAuthURL(q.request.uri$"/"$gametype.data.ClassName)))
		{
			continue;
 		}
 		tmp = "";
 		if (!HasSettings(gametype.data.ClassName))
 		{
 			//continue;
 			tmp = " &sup1;";
 		}
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.data.ClassName));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(gametype.FriendlyName)$tmp);
 		//q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.data.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(gametype.Description));
 		if (currentGameType ~= gametype.data.ClassName)
 		{
 			q.response.subst("editgametype.name", `HTMLEscape(gametype.FriendlyName)$tmp);
 			q.response.subst("editgametype.class", `HTMLEscape(gametype.data.ClassName));
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	if ((editGametype != none) && len(editGametype.data.ClassName) > 0 && q.user.canPerform("webadmin://"$q.request.uri$"/"$editGametype.data.ClassName))
	{
		gi = class<GameInfo>(DynamicLoadObject(editGametype.data.ClassName, class'class'));
		if (gi != none)
		{
			settingsClass = getSettingsClassFqn(editGametype.data.ClassName);
		}
		if (settingsClass != none)
		{
			settings = getSettingsInstance(settingsClass);
		}
		if (settings == none)
		{
			if (settingsMagic == none)
			{
				settingsMagic = new class'SettingsMagic';
			}
			settings = settingsMagic.find(gi);
		}
	}

	if (settings != none)
	{
		getSettingsRenderer();

		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			liveAdjust = q.request.getVariable("liveAdjust", "0") == "1";

			if (!liveAdjust) {
				settings.setCurrentGameInfo(none);
			}
			if (IAdvWebAdminSettings(settings) != none)
			{
				if (IAdvWebAdminSettings(settings).advSaveSettings(q.request, webadmin.getMessagesObject(q)))
				{
					webadmin.addMessage(q, msgSettingsSaved);
				}
			}
			else {
				applySettings(settings, q.request);
				settingsRenderer.ensureSettingValues(settings);
				settings.saveSettings();
				webadmin.addMessage(q, msgSettingsSaved);
			}

			settingsSaved = true;
		}
		else {
			liveAdjust = true;
		}

		if (liveAdjust) {
			settings.setCurrentGameInfo(webadmin.WorldInfo.Game);
		}

		privs = q.user.getSettingsPrivileges();
		if (privs != none)
		{
			privs.setBasePrivilegeUri(webadmin.getAuthURL(q.request.uri$"/"$editGametype.data.ClassName));
		}

		if (!settingsSaved) {
			settingsRenderer.ensureSettingValues(settings);
		}

		if (IAdvWebAdminSettings(settings) != none)
		{
			settingsRenderer.initEx(settings, q.response);
			IAdvWebAdminSettings(settings).advRenderSettings(q.response, settingsRenderer,, privs);
		}
		else {
			settingsRenderer.render(settings, q.response,, privs);
		}
	}
	else if (editGametype != none) {
		webadmin.addMessage(q, msgCantSaveSettings, MT_Warning);
	}

	if (KFGameInfoSettings(settings) == none || KFGameInfoSettings(settings).gameinfo == none)
	{
		q.response.subst("liveAdjustStyle", "style=\"display: none;\"");
	}

	if (liveAdjust) {
		q.response.subst("liveAdjustChecked", "checked=\"checked\"");
	}
	else {
		q.response.subst("liveAdjustChecked", "");
	}

 	webadmin.sendPage(q, "default_settings_gametypes.html");
}

/**
 * Apply the settings received from the response to the settings instance
 */
static function applySettings(WebAdminSettings settings, WebRequest request, optional string prefix = "settings_")
{
	local int i, idx;
	local name sname;
	local string val;

	for (i = 0; i < settings.LocalizedSettingsMappings.Length; i++)
	{
		idx = settings.LocalizedSettingsMappings[i].Id;
		sname = settings.GetStringSettingName(idx);
		if (request.GetVariableCount(prefix$sname) > 0)
		{
			val = request.GetVariable(prefix$sname);
			settings.SetStringSettingValue(idx, int(val), false);
		}
	}
	for (i = 0; i < settings.PropertyMappings.Length; i++)
	{
		idx = settings.PropertyMappings[i].Id;
		sname = settings.GetPropertyName(idx);
		if (request.GetVariableCount(prefix$sname) > 0)
		{
			val = request.GetVariable(prefix$sname);
			settings.SetPropertyFromStringByName(sname, val);
		}
	}
}

function handleSettingsGeneral(WebAdminQuery q)
{
	local class<WebAdminSettings> settingsClass;
	local WebAdminSettings settings;
	local float Difficulty; 
	local int Length;
	local bool bNoLiveAdjust;
	local KFGameInfo KFGI;
 
	settingsClass = class<WebAdminSettings>(DynamicLoadObject( GeneralSettingsClass, class'class' ));
	if( settingsClass != none )
	{
		settings = getSettingsInstance( settingsClass );
	}

	if( settings != none )
	{
		if( q.request.getVariable( "action" ) ~= "save" || q.request.getVariable( "action" ) ~= "save settings" )
		{
			KFGI = KFGameInfo(webadmin.WorldInfo.Game);
			Difficulty = float(q.request.getVariable( "settings_GameDifficulty" ));
			Length = int(q.request.getVariable( "settings_GameLength" ));
			if( KFGI != none && (KFGI.GameDifficulty != Difficulty || KFGI.GameLength != Length) )
			{
				bNoLiveAdjust = true;
			}
		}

		genericSettingsHandler( q, settings, bNoLiveAdjust );
	}
	else 
	{
		`Log("Failed to load the general settings class "$GeneralSettingsClass,,'WebAdmin');
		webadmin.addMessage( q, msgCantLoadSettings, MT_Warning );
	}

 	webadmin.sendPage( q, "default_settings_general.html" );
}

function bool genericSettingsHandler( WebAdminQuery q, WebAdminSettings settings, optional bool bNoLiveAdjust=false )
{
	local ISettingsPrivileges privs;
	local bool settingsSaved, liveAdjust;

	settingsSaved = false;

	if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
	{
		liveAdjust = bNoLiveAdjust ? false : q.request.getVariable("liveAdjust", "0") == "1";
		if (!liveAdjust) {
			settings.setCurrentGameInfo(none);
		}

		if (IAdvWebAdminSettings(settings) != none)
		{
			if (IAdvWebAdminSettings(settings).advSaveSettings(q.request, webadmin.getMessagesObject(q)))
			{
				webadmin.addMessage(q, msgSettingsSaved);
			}
		}
		else {
			applySettings(settings, q.request);
			settingsRenderer.ensureSettingValues(settings);
			settings.saveSettings();
			webadmin.addMessage(q, msgSettingsSaved);
		}

		settingsSaved = true;
	}
	else {
		liveAdjust = true;
	}

	getSettingsRenderer();

	if (liveAdjust) {
		settings.setCurrentGameInfo(WebAdmin.WorldInfo.Game);
	}

	if (!settingsSaved)
	{
		settingsRenderer.ensureSettingValues(settings);
	}

	privs = q.user.getSettingsPrivileges();
	if (privs != none)
	{
		privs.setBasePrivilegeUri(webadmin.getAuthURL(q.request.uri));
	}

	if (IAdvWebAdminSettings(settings) != none)
	{
		settingsRenderer.initEx(settings, q.response);
		IAdvWebAdminSettings(settings).advRenderSettings(q.response, settingsRenderer,, privs);
	}
	else {
		settingsRenderer.render(settings, q.response,, privs);
	}

	if (liveAdjust) {
		q.response.subst("liveAdjustChecked", "checked=\"checked\"");
	}
	else {
		q.response.subst("liveAdjustChecked", "");
	}

	return settingsSaved;
}

function handleSettingsWelcome(WebAdminQuery q)
{
	local class<WebAdminSettings> settingsClass;
	local WebAdminSettings settings;

	settingsClass = class<WebAdminSettings>(DynamicLoadObject(WelcomeSettingsClass, class'class'));
	if (settingsClass != none)
	{
		settings = getSettingsInstance(settingsClass);
	}

	if (settings != none)
	{
		genericSettingsHandler(q, settings);
	}
	else {
		`Log("Failed to load the welcome page settings class "$WelcomeSettingsClass,,'WebAdmin');
		webadmin.addMessage(q, msgCantLoadSettings, MT_Warning);
	}

 	webadmin.sendPage(q, "default_settings_welcome.html");
}

function handleSettingsPasswords(WebAdminQuery q)
{
	local string action, pw1, pw2;
	action = q.request.getVariable("action");
	if (action ~= "gamepassword")
	{
		pw1 = q.request.getVariable("gamepw1");
		pw2 = q.request.getVariable("gamepw2");
		if (pw1 != pw2)
		{
			webadmin.addMessage(q, msgGamePWError, MT_Error);
		}
		else {
			webadmin.WorldInfo.Game.AccessControl.SetGamePassword(pw1);
			webadmin.WorldInfo.Game.AccessControl.SaveConfig();
			webadmin.addMessage(q, msgGamePWSaved);
		}
	}
	else if (action ~= "adminpassword")
	{
		pw1 = q.request.getVariable("adminpw1");
		pw2 = q.request.getVariable("adminpw2");
		if (pw1 != pw2)
		{
			webadmin.addMessage(q, msgAdminPWError, MT_Error);
		}
		else if (len(pw1) == 0)
		{
			webadmin.addMessage(q, msgAdminPWEmpty, MT_Error);
		}
		else {
			webadmin.WorldInfo.Game.AccessControl.SetAdminPassword(pw1);
			webadmin.WorldInfo.Game.AccessControl.SaveConfig();
			webadmin.addMessage(q, msgAdminPWSaved);
		}
	}
	q.response.subst("has.gamepassword", `HTMLEscape(webadmin.WorldInfo.Game.AccessControl.RequiresPassword()));
	webadmin.sendPage(q, "default_settings_password.html");
}

function handleSettingsMutators(WebAdminQuery q)
{
	local DCEMutator mutator, editMutator;
	local string currentMutator, substvar;
	local class<Mutator> mut;
	local class<WebAdminSettings> settingsClass;
	local WebAdminSettings settings;
	local int idx;
	local ISettingsPrivileges privs;

	currentMutator = q.request.getVariable("mutator");
 	webadmin.dataStoreCache.loadMutators();
 	for (idx = 0; idx < webadmin.dataStoreCache.mutators.length; idx++)
 	{
 		if (webadmin.dataStoreCache.mutators[idx].ClassName ~= currentMutator)
 		{
 			break;
 		}
 	}
	if (idx >= webadmin.dataStoreCache.mutators.length) idx = INDEX_NONE;
 	if (idx > INDEX_NONE)
 	{
 		editMutator = webadmin.dataStoreCache.mutators[idx];
 		currentMutator = editMutator.ClassName;
 	}
 	else {
 		editMutator = none;
 		currentMutator = "";
 	}

 	substvar = "";
 	foreach webadmin.dataStoreCache.mutators(mutator)
 	{
 		if (!HasSettings(mutator.ClassName))
 		{
 			continue;
 		}
 		if (!q.user.canPerform("webadmin://"$q.request.uri$"/"$mutator.ClassName))
		{
			continue;
 		}
 		q.response.subst("mutator.classname", `HTMLEscape(mutator.ClassName));
 		q.response.subst("mutator.friendlyname", `HTMLEscape(mutator.FriendlyName));
 		q.response.subst("mutator.description", `HTMLEscape(mutator.Description));

 		if (currentMutator ~= mutator.ClassName)
 		{
 			q.response.subst("editmutator.name", `HTMLEscape(mutator.FriendlyName));
 			q.response.subst("editmutator.class", `HTMLEscape(mutator.ClassName));
 			q.response.subst("editmutator.description", `HTMLEscape(mutator.Description));
 			q.response.subst("mutator.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("mutator.selected", "");
 		}
 		substvar $= webadmin.include(q, "default_settings_mutators_select.inc");
 	}
 	q.response.subst("mutators", substvar);

 	if ((editMutator != none) && len(editMutator.ClassName) > 0 && q.user.canPerform("webadmin://"$q.request.uri$"/"$editMutator.ClassName))
	{
		mut = class<Mutator>(DynamicLoadObject(editMutator.ClassName, class'class'));
		if (mut != none)
		{
			settingsClass = getSettingsClassFqn(editMutator.ClassName);
		}
		if (settingsClass != none)
		{
			settings = getSettingsInstance(settingsClass);
		}
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			if (IAdvWebAdminSettings(settings) != none)
			{
				if (IAdvWebAdminSettings(settings).advSaveSettings(q.request, webadmin.getMessagesObject(q)))
				{
					webadmin.addMessage(q, msgSettingsSaved);
				}
			}
			else {
				applySettings(settings, q.request);
				settings.saveSettings();
				webadmin.addMessage(q, msgSettingsSaved);
			}
		}

		getSettingsRenderer();

		privs = q.user.getSettingsPrivileges();
		if (privs != none)
		{
			privs.setBasePrivilegeUri(q.request.uri);
		}

		if (IAdvWebAdminSettings(settings) != none)
		{
			settingsRenderer.initEx(settings, q.response);
			IAdvWebAdminSettings(settings).advRenderSettings(q.response, settingsRenderer,, privs);
		}
		else {
			settingsRenderer.render(settings, q.response,, privs);
		}
		q.response.subst("settings", webadmin.include(q, "default_settings_mutators.inc"));
	}
	else if (editMutator != none) {
		webadmin.addMessage(q, msgCantLoadSettings, MT_Warning);
	}

	webadmin.sendPage(q, "default_settings_mutators.html");
}

function handleMapList(WebAdminQuery q)
{
	local string currentGameType, substvar;
	local DCEGameInfo editGametype, gametype;
	local int idx, i, maplistidx, activeidx;
	local GameMapCycle cycle;
	local array<GameMapCycle> cycles;
	local array<DCEMapInfo> allMaps;
	local array<string> postcycle;

	// get the maplist cycle index
	maplistidx = int(q.request.getVariable("maplistidx", "-2"));
	if (maplistidx == -2)
	{
		if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
		{
			maplistidx = `{GameInfo} (webadmin.WorldInfo.Game).ActiveMapCycle;
		}
	}

	// get the maplist cycle
	if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
	{
		cycles = `{GameInfo} (webadmin.WorldInfo.Game).GameMapCycles;
	}
	else {
		cycles = class'`{GameInfo}'.default.GameMapCycles;
	}
	maplistidx = min(maplistidx, cycles.length-1);
	if (maplistidx >= 0)
	{
		cycle = cycles[maplistidx];
	}

	if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
	{
		activeidx = `{GameInfo} (webadmin.WorldInfo.Game).ActiveMapCycle;
	}
	else {
		activeidx = class'`{GameInfo}'.default.ActiveMapCycle;
	}

	if (activeidx == maplistidx || maplistidx < 0) {
		q.response.subst("mlactive", "disabled=\"disabled\"");
	}
	else {
		q.response.subst("mlactive", "");
	}

	// gametype to list the maps for
	currentGameType = q.request.getVariable("gametype");
	if (currentGameType == "")
 	{
 		// get gametype based on first map
 		if (cycle.Maps.Length > 0)
 		{
			postcycle = webadmin.dataStoreCache.getGametypesByMap(cycle.Maps[0]);
			if (postcycle.Length > 0)
			{
				currentGameType = postcycle[0];
			}
		}

		if (currentGameType == "")
 		{
 			currentGameType = string(webadmin.WorldInfo.Game.class);
 		}
 	}

 	webadmin.dataStoreCache.loadGameTypes();
 	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		editGametype = webadmin.dataStoreCache.gametypes[idx];
 		currentGameType = editGametype.data.ClassName;
 	}
 	else {
 		editGametype = none;
 		currentGameType = "";
 	}

	// create gametype selection list
 	substvar = "";
 	foreach webadmin.dataStoreCache.gametypes(gametype)
 	{
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.data.ClassName));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(gametype.FriendlyName));
 		//q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.data.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(gametype.Description));
 		if (currentGameType ~= gametype.data.ClassName)
 		{
 			q.response.subst("editgametype.name", `HTMLEscape(gametype.FriendlyName));
 			q.response.subst("editgametype.class", `HTMLEscape(gametype.data.ClassName));
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	if ((editGametype != none) && len(editGametype.data.ClassName) > 0)
	{
		allMaps = webadmin.dataStoreCache.getMaps(editGametype.data.ClassName);
	}

	if (len(q.request.getVariable("mapcycle")) > 0)
	{
		ParseStringIntoArray(q.request.getVariable("mapcycle"), postcycle, chr(10), true);
		cycle.Maps.length = 0;
		//cycle.RoundLimits.length = 0;
		for (i = 0; i < postcycle.length; i++)
		{
			substvar = `Trim(postcycle[i]);
			if (len(substvar) > 0)
			{
				//idx = InStr(substvar, "?");
				//if (idx != INDEX_NONE)
				//{
					//tmp = mid(substvar, idx);
					//idx = class'GameInfo'.static.GetIntOption(tmp, "RoundLimit", 0);
					//substvar = class'WebAdminUtils'.static.removeUrlOption(substvar, "RoundLimit");
				//}
				//else {
				//	idx = 0;
				//}
				cycle.Maps[cycle.Maps.length] = substvar;
				//cycle.RoundLimits[cycle.Maps.length-1] = idx;
			}
		}

		if (len(q.request.getVariable("activate")) > 0)
		{
			if (maplistidx >= 0 && maplistidx < cycles.length)
			{
				class'`{GameInfo}'.default.ActiveMapCycle = maplistidx;
				class'`{GameInfo}'.static.StaticSaveConfig();
				if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
				{
					`{GameInfo} (webadmin.WorldInfo.Game).ActiveMapCycle = class'`{GameInfo}'.default.ActiveMapCycle;
				}
				q.response.subst("mlactive", "disabled=\"disabled\"");
				webadmin.addMessage(q, repl(msgMapCycleActivated, "%i", string(maplistidx+1)));
				activeidx = maplistidx;
			}
		}
		else if (len(q.request.getVariable("delete")) > 0)
		{
			if (maplistidx >= 0 && maplistidx < cycles.length)
			{
				cycles.Remove(maplistidx, 1);
				class'`{GameInfo}'.default.GameMapCycles = cycles;
				class'`{GameInfo}'.static.StaticSaveConfig();
				if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
				{
					`{GameInfo} (webadmin.WorldInfo.Game).GameMapCycles = class'`{GameInfo}'.default.GameMapCycles;
				}
				webadmin.addMessage(q, msgMapCycleDeleted);
				q.response.subst("mlactive", "disabled=\"disabled\"");
				maplistidx = -1;
				cycle.Maps.Length = 0;
				//cycle.RoundLimits.Length = 0;
			}
		}
		else if (len(q.request.getVariable("action")) > 0)
		{
			if (maplistidx == INDEX_NONE) maplistidx = cycles.length;
			cycles[maplistidx] = cycle;
			class'`{GameInfo}'.default.GameMapCycles = cycles;
			class'`{GameInfo}'.static.StaticSaveConfig();
			if (`{GameInfo} (webadmin.WorldInfo.Game) != none)
			{
				`{GameInfo} (webadmin.WorldInfo.Game).GameMapCycles = class'`{GameInfo}'.default.GameMapCycles;
			}
			webadmin.addMessage(q, msgMapCycleSaved);
			// can now be activated
			if (activeidx == maplistidx || maplistidx < 0) {
				q.response.subst("mlactive", "disabled=\"disabled\"");
			}
			else {
				q.response.subst("mlactive", "");
			}
		}
	}

	if (maplistidx > -1)
	{
		q.response.subst("mldeletable", "");
	}
	else {
		q.response.subst("mldeletable", "disabled=\"disabled\"");
	}

	// create maplist selection list
	q.response.subst("maplistidx", string(maplistidx));
	q.response.subst("editmaplist.friendlyname", `HTMLEscape(msgNewMapCycle));
 	substvar = "";
 	for (idx = 0; idx < cycles.length; ++idx)
 	{
 		// TODO: localize
 		q.response.subst("maplist.friendlyname", `HTMLEscape(repl(mapList, "%i", (idx+1))$(activeidx == idx?" "$activeTag:"")));
 		q.response.subst("maplist.index", string(idx));
 		if (maplistidx == idx)
 		{
 			q.response.subst("maplist.selected", "selected=\"selected\"");
 			q.response.subst("editmaplist.friendlyname", `HTMLEscape("Map cycle #"$(idx+1)));
 		}
 		else {
 			q.response.subst("maplist.selected", "");
 		}
 		substvar $= webadmin.include(q, "default_maplist_select.inc");
 	}
 	q.response.subst("maplists", substvar);

	substvar = "";
	for (i = 0; i < allMaps.length; i++)
	{
		if (i > 0) substvar $= chr(10);
		substvar $= allMaps[i].data.MapName;
	}
	q.response.subst("allmaps.plain", `HTMLEscape(substvar));

	substvar = "";
	for (i = 0; i < cycle.Maps.length; i++)
	{
		if (i > 0) substvar $= chr(10);
		substvar $= cycle.Maps[i];
		//if (cycle.RoundLimits.length > i)
		//{
		//	if (cycle.RoundLimits[i] > 0)
		//	{
		//		substvar $= "?RoundLimit="$cycle.RoundLimits[i];
		//	}
		//}
	}
	q.response.subst("cycle.plain", `HTMLEscape(substvar));

	q.response.subst("maplist_editor", webadmin.include(q, "default_maplist_editor.inc"));

 	webadmin.sendPage(q, "default_maplist.html");
}

function handleServerActors(WebAdminQuery q)
{
	local string tmp;
	local array<string> tmpa;
	local int i;
	local GameEngine gameengine;
	local bool foundWebAdmin;

	if (q.request.getVariable("action") ~= "save")
	{
		ParseStringIntoArray(q.request.getVariable("serveractors"), tmpa, chr(10), true);
		class'KFGameEngine'.default.ServerActors.length = 0;
		foundWebAdmin = false;
		for (i = 0; i < tmpa.length; i++)
		{
			tmp = `Trim(tmpa[i]);
			if (len(tmp) > 0)
			{
				if (tmp ~= "IpDrv.WebServer") foundWebAdmin = true;
				class'KFGameEngine'.default.ServerActors.addItem(tmp);
			}
		}
		if (!foundWebAdmin)
		{
			class'KFGameEngine'.default.ServerActors.addItem("IpDrv.WebServer");
			`Log("Force added WebServer to server actors list",,'WebAdmin');
		}
		class'KFGameEngine'.static.StaticSaveConfig();
		gameengine = GameEngine(FindObject("Transient.GameEngine_0", class'KFGameEngine'));
		if (gameengine != none)
		{
			gameengine.ServerActors = class'KFGameEngine'.default.ServerActors;
			webadmin.addMessage(q, msgServerActorsSaved);
		}
		else {
			webadmin.addMessage(q, msgServerActorsSavedWarn, MT_Warning);
		}
	}

	tmp = "";
	for (i = 0; i < class'KFGameEngine'.default.ServerActors.length; i++)
	{
		if (i > 0) tmp $= chr(10);
		tmp $= class'KFGameEngine'.default.ServerActors[i];
	}
	q.response.subst("serveractors", tmp);
	webadmin.sendPage(q, "default_serveractors.html");
}

defaultproperties
{
}
