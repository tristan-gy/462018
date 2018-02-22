/**
 * The query handler that provides information about the current game. It will
 * also set the start page for the webadmin.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHCurrent extends Object implements(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)

var WebAdmin webadmin;

/**
 * Refresh time of the chat console
 */
var config int ChatRefresh;

/**
 * If true the management console will be available. This will allow users to
 * directly enter console commands on the server. This means that the user will
 * have the ability to shutdown the server or execute commands that change
 * certain core variables.
 */
var config bool bConsoleEnabled;

/**
 * Options in this list are not allowed to be set in the "change game" page.
 * They will removed from the url.
 */
var config array<string> denyUrlOptions;

/**
 * Lists of console commands that are not allowed to be executed.
 */
var config array<string> denyConsoleCommands;

/**
 * if true use the hack to access some special admin commands lick "kickban ...",
 * "restartlevel". If false these commands would not be available
 */
var config bool bAdminConsoleCommandsHack;

/**
 * The AdminCommandHandler class to use for handling the admin console command hack.
 */
var config string AdminCommandHandlerClass;

/**
 * if true team chat will be enabled.
 */
var config bool bEnableTeamChat;

/**
 * Instance that handled "Admin" console command aliases.
 */
var AdminCommandHandler adminCmdHandler;

/**
 * CSS code to make things visible.
 */
var string cssVisible;

/**
 * CSS code to make HTML elements hidden.
 */
var string cssHidden;

/**
 * Will hold a sorted player replication info list.
 */
var array<PlayerReplicationInfo> sortedPRI;

/**
 * Will hold the url where to switch the game to. Game switching a delayed for
 * a few ms.
 */
var private string newUrl;

/**
 * if true the news will be shown on the "current" page
 */
var config bool hideNews;

var NewsDesk newsDesk;

/**
 * Notes which an admin can enter if they feel like
 */
var config array<string> Notes;

//!localization
var localized string menuCurrent, menuCurrentDesc, menuPlayers, menuPlayersDesc,
	menuChat, menuChatDesc, menuChange, menuChangeDesc, menuConsole, menuConsoleDesc,
	menuBots, menuBotsDesc, NotesSaved, msgPlayerNotFound, msgNoHumanPlayer,
	msgVoiceMuted, msgVoiceUnmuted, msgTextMuted, msgTextUnmuted, msgCantBanAdmin,
	msgSessionBanned, msgCantKickAdmin, msgPlayerRemoved, msgTextMute, msgTextUnmute,
	msgExecDisabled, msgChangingGame, msgAddingBots, msgRemovedBots,
	msgNoMutators, msgAddingBotsTeam, msgYes, msgNo, msgScreenshot, rmRealistic,
	rmStandard, rmCustom, msgOff, pbLow, pbMedium, pbHigh, msgUnknown, msgOn,
	msgSessionBanNoROAC, msgNotAllowed, menuServerInfo, menuServerInfoDesc;

var array<string> playerActions;

/**
 * If true, spectators are separated from the player list in the current info page.
 */
var bool separateSpectators;

function init(WebAdmin webapp)
{
	local class<AdminCommandHandler> achc;

	if (Len(AdminCommandHandlerClass) == 0)
	{
  		AdminCommandHandlerClass = class.getPackageName()$".AdminCommandHandler";
		SaveConfig();
	}

	webadmin = webapp;
	if (len(webapp.startpage) == 0)
	{
		webapp.startpage = "/current";
		webapp.SaveConfig();
	}
	if (ChatRefresh < 500) ChatRefresh = 5000;

	if (bAdminConsoleCommandsHack)
	{
		achc = class<AdminCommandHandler>(DynamicLoadObject(AdminCommandHandlerClass, class'class'));
		if (achc != none)
		{
			adminCmdHandler = webadmin.worldinfo.spawn(achc);
		}
	}

	webadmin.WorldInfo.Game.SetTimer(0.1, false, 'CreateTeamChatProxy', self);
	if (!hideNews)
	{
		newsDesk = new class'NewsDesk';
		newsDesk.getNews();
	}
}

function CreateTeamChatProxy()
{
	local TeamChatProxy tcp;
	local int i;

	//KFII-38982 | Adam Massingale | Always spawning team chat proxies even if we're not in a team game like vs
	//this will allow team chat to always take place in case users send team chat messages. the users are all on the same
	//team but we still want to see the messages in webadmin and chat logs.
	//if (bEnableTeamChat) && `isTeamGame(webadmin.WorldInfo.Game))
	if (bEnableTeamChat)
	{
		if (webadmin.WorldInfo.Game.GameReplicationInfo == none)
		{
			webadmin.WorldInfo.Game.SetTimer(0.1, false, 'CreateTeamChatProxy', self);
			return;
		}

		`log("Creating team chat proxies",,'WebAdmin');

		for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length; i++)
		{
			if (webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i] == none) continue;
			tcp = webadmin.WorldInfo.Spawn(class'TeamChatProxy',, name("TeamChatProxy__"$i));
			if (tcp != none)
			{
				tcp.PlayerReplicationInfo.Team = webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i];
			}
			else {
				`log("Failed to create TeamChatProxy for team "$i,,'WebAdmin');
			}
		}
		if (WebAdmin.bChatLog)
		{
			WebAdmin.CreateChatLog();
		}
	}
	else if (WebAdmin.bChatLog)
	{
		WebAdmin.CreateChatLog();
	}
}

function cleanup()
{
	adminCmdHandler = none;
	webadmin = none;
	newsDesk.cleanup();
	newsDesk = none;
	sortedPRI.Remove(0, sortedPRI.Length);
}

function bool producesXhtml()
{
	return true;
}

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/current", menuCurrent, self, menuCurrentDesc, -100);
	menu.addMenu("/current/info", menuServerInfo, self, menuServerInfoDesc, -100);
	menu.addMenu("/current/info+data", "", self);
	menu.addMenu("/current/change", menuChange, self, menuChangeDesc, -90);
	menu.addMenu("/current/change+data", "", self);
	menu.addMenu("/current/change+check", "", self);
	menu.addMenu("/current/players", menuPlayers, self, menuPlayersDesc, -80);
	menu.addMenu("/current/players+data", "", self);;
	menu.addMenu("/current/chat", menuChat, self, menuChatDesc);
	menu.addMenu("/current/chat+data", "", self,,, "/current+chat");
	`if(`WITH_BOTS)
	menu.addMenu("/current/bots", menuBots, self, menuBotsDesc);
	`endif
	if (bConsoleEnabled)
	{
		menu.addMenu("/console", menuConsole, self, menuConsoleDesc);
	}
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/current":
			q.response.Redirect(WebAdmin.Path$"/current/info");
			return true;
		case "/current/info":
			handleCurrent(q);
			return true;
		case "/current/info+data":
			handleCurrentData(q);
			return true;
		case "/current/players":
			handleCurrentPlayers(q);
			return true;
		case "/current/players+data":
			handleCurrentPlayersData(q);
			return true;
		case "/current/chat":
			handleCurrentChat(q);
			return true;
		case "/current/chat+data":
			handleCurrentChatData(q);
			return true;
		case "/console":
			if (bConsoleEnabled)
			{
				handleConsole(q);
				return true;
			}
			return false;
		case "/current/change":
			handleCurrentChange(q);
			return true;
		case "/current/change+data":
			handleCurrentChangeData(q);
			return true;
		case "/current/change+check":
			if (newUrl == "")
			{
				q.response.SendText("ok");
			}
			else {
				q.response.HTTPResponse("HTTP/1.1 503 Service Unavailable");
			}
			return true;
		`if(`WITH_BOTS)
		case "/current/bots":
			handleBots(q);
			return true;
		`endif
	}
	return false;
}

// not used here
function bool unhandledQuery(WebAdminQuery q);

function decoratePage(WebAdminQuery q);

function handleCurrentData(WebAdminQuery q)
{
	local string tmp;
	local int idx;

	if (q.request.getVariable("action") ~= "save")
	{
		notes.length = 0;
		tmp = q.request.getVariable("notes");
		idx = InStr(tmp, chr(10));
		while (idx != INDEX_NONE)
		{
			notes[notes.length] = `Trim(Left(tmp, idx));
			tmp = Mid(tmp, idx+1);
			idx = InStr(tmp, chr(10));
		}
		tmp = `Trim(tmp);
		if (len(tmp) > 0)
		{
			notes[notes.length] = tmp;
		}
		SaveConfig();
		webadmin.addMessage(q, NotesSaved);
	}

	if (q.request.getVariable("ajax") == "1")
	{
		q.response.AddHeader("Content-Type: text/xml");
		q.response.SendText("<request>");
  		q.response.SendText("<messages><![CDATA[");
		q.response.SendText(webadmin.renderMessages(q));
		q.response.SendText("]]></messages>");
		q.response.SendText("</request>");
	}
}

function handleCurrent(WebAdminQuery q)
{
	local string players;
	local PlayerReplicationInfo pri;
	local int idx, cnt;
	local string tmp;
	local OnlineGameSettings GameSettings;

	handleCurrentData(q);

	if (!hideNews && newsDesk != none && newsDesk.newsIface != none)
	{
		q.response.subst("news", newsDesk.renderNews(webadmin, q));
	}
	else {
		q.response.subst("news", "");
	}

	tmp = "";
	for (idx = 0; idx < notes.length; idx++)
	{
		tmp $= notes[idx]$chr(10);
	}
	q.response.subst("notes", `HTMLEscape(tmp));

	substGameInfo(q);

	GameSettings = webadmin.WorldInfo.Game.GameInterface.GetGameSettings(webadmin.WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
	if (GameSettings != None)
	{
		if (GameSettings.bAntiCheatProtected)
		{
			q.response.subst("server.anticheat", msgOn);
		}
		else {
			q.response.subst("server.anticheat", msgOff);
		}
	}

	q.response.subst("teams", getCurrentTeamInfo(q));

	q.response.subst("server.name", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.ServerName));

	buildSortedPRI(q.request.getVariable("sortby", "score"), q.request.getVariable("reverse", "true") ~= "true");
	cnt = 0;
	foreach sortedPRI(pri, idx)
	{
		if (separateSpectators && pri.bOnlySpectator)
		{
			continue;
		}
		if (`mod(cnt, 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");
		substPri(q, pri);
		players $= webadmin.include(q, "current_player_row.inc");
		cnt++;
	}
	if (sortedPRI.Length == 0)
	{
		players = webadmin.include(q, "current_player_empty.inc");
	}
	q.response.subst("sorted."$q.request.getVariable("sortby", "score"), "sorted");
	if (!(q.request.getVariable("reverse", "true") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "score"), "true");
	}

	q.response.subst("players", players);
	q.response.subst("rules", webadmin.include(q, getGameTypeIncFile(q, "current_rules")));

	if (separateSpectators) {
		q.response.subst("spectators", getCurrentSpectatorsInfo(q));
	}
	else {
		q.response.subst("spectators", "");
	}

	webadmin.sendPage(q, "current.html");
}

function string getCurrentSpectatorsInfo(WebAdminQuery q)
{
	local array<PlayerReplicationInfo> spectators;
	local PlayerReplicationInfo pri;
	local PlayerController pc;
	local bool inserted, cmp;
	local int idx;
	local string tmp;

	foreach WebAdmin.WorldInfo.AllControllers(class'PlayerController', pc)
	{
		if (pc.PlayerReplicationInfo == none || !pc.PlayerReplicationInfo.bOnlySpectator)
		{
			continue;
		}
		if (MessagingSpectator(PC) != none)
		{
			continue;
		}
		inserted = false;
		foreach spectators(PRI, idx)
		{
			cmp = comparePRI(PRI, PC.PlayerReplicationInfo, "name");
			if (cmp)
			{
				spectators.Insert(idx, 1);
				spectators[idx] = PC.PlayerReplicationInfo;
				inserted = true;
				break;
			}
		}
		if (!inserted)
		{
			spectators.addItem(PC.PlayerReplicationInfo);
		}
	}

	tmp = "";
	if (spectators.Length == 0) {
		return "";
	}

	foreach spectators(PRI, idx)
	{
		if (idx > 0) {
			tmp $= ", ";
		}
		tmp $= `HTMLEscape(pri.PlayerName);
	}
	q.response.subst("spectators.names", tmp);
	q.response.subst("spectators.current", spectators.Length);
	q.response.subst("spectators.max", webadmin.WorldInfo.Game.MaxSpectators);
	return webadmin.include(q, "current_spectators.inc");
}

function substGameInfo(WebAdminQuery q)
{
	local int idx, i;
	local mutator mut;
	local string tmp, tmp2;
	local array<string> activeMuts;

	q.response.subst("game.name", `HTMLEscape(webadmin.WorldInfo.Game.GameName));
	q.response.subst("game.type", webadmin.WorldInfo.Game.class.getPackageName()$"."$webadmin.WorldInfo.Game.class);

	q.response.subst("map.title", `HTMLEscape(webadmin.WorldInfo.Title));
	q.response.subst("map.author", `HTMLEscape(webadmin.WorldInfo.Author));
	q.response.subst("map.name", webadmin.WorldInfo.GetPackageName());
	if (len(webadmin.WorldInfo.Title) > 0)
	{
		q.response.subst("map.title.safe", `HTMLEscape(webadmin.WorldInfo.Title));
	}
	else {
		q.response.subst("map.title.safe", webadmin.WorldInfo.GetPackageName());
	}

	tmp = "/images/maps/"$webadmin.WorldInfo.GetPackageName()$".jpg";
	tmp2 = "/images/maps/"$locs(webadmin.WorldInfo.GetPackageName())$".jpg";
	if (q.response.FileExists(tmp))
	{
		q.response.subst("map.image", tmp);
	}
	else if (q.response.FileExists(tmp2))
	{
		q.response.subst("map.image", tmp2);
	}
	else {
		q.response.subst("map.image", "/images/maps/noimage.png");
	}

	webadmin.dataStoreCache.loadMutators();
	ParseStringIntoArray(webadmin.WorldInfo.Game.ParseOption(getServerOptions(), "mutator"), activeMuts, ",", true);

	mut = webadmin.WorldInfo.Game.BaseMutator;
	while (mut != none)
	{
		tmp2 = mut.class.getPackageName()$"."$mut.class;
		if (activeMuts.find(tmp2) == INDEX_none)
		{
			activeMuts.addItem(tmp2);
		}
		mut = mut.NextMutator;
	}

	tmp = "";
	for (i = 0; i < activeMuts.length; i++)
	{
		if (len(tmp) > 0) tmp $= ", ";
		tmp2 = activeMuts[i];
		for (idx = 0; idx < webadmin.dataStoreCache.mutators.Length; ++idx)
		{
			if (webadmin.dataStoreCache.mutators[idx].ClassName ~= tmp2)
			{
				tmp $= webadmin.dataStoreCache.mutators[idx].FriendlyName;
				break;
			}
		}
		if (idx == webadmin.dataStoreCache.mutators.Length)
		{
			tmp $= tmp2;
		}
	}
	q.response.subst("rules.mutators", tmp);

	q.response.subst("rules.timelimit", webadmin.WorldInfo.Game.TimeLimit);
	q.response.subst("rules.goalscore", webadmin.WorldInfo.Game.GoalScore);
	q.response.subst("rules.maxlives", webadmin.WorldInfo.Game.MaxLives);
	q.response.subst("rules.difficulty", webadmin.WorldInfo.Game.GameDifficulty);

	q.response.subst("rules.maxspectators", webadmin.WorldInfo.Game.MaxSpectators);
	q.response.subst("rules.numspectators", webadmin.WorldInfo.Game.NumSpectators);
	q.response.subst("rules.maxplayers", webadmin.WorldInfo.Game.MaxPlayers);
	q.response.subst("rules.numplayers", webadmin.WorldInfo.Game.NumPlayers);
	q.response.subst("rules.numbots", webadmin.WorldInfo.Game.NumBots);

	q.response.subst("time.timelimit", webadmin.WorldInfo.Game.GameReplicationInfo.TimeLimit);
	q.response.subst("time.elapsed", webadmin.WorldInfo.Game.GameReplicationInfo.ElapsedTime);
	q.response.subst("time.remaining", webadmin.WorldInfo.Game.GameReplicationInfo.RemainingTime);
}

/*
 * Called from #handleCurrent(..)
 */
function string getCurrentTeamInfo(WebAdminQuery q)
{
	local TeamInfo teaminfo;
	local int i;
	local string tmp;

	if (!`isTeamGame(webadmin.WorldInfo.Game)) return "";

	tmp = "";
	for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.teams.length; ++i)
	{
		if (`mod(i, 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");
		teaminfo = webadmin.WorldInfo.Game.GameReplicationInfo.teams[i];
		q.response.subst("team.color", class'WebAdminUtils'.static.ColorToHTMLColor(TeamInfo.TeamColor));
		q.response.subst("team.index", teaminfo.TeamIndex);
		q.response.subst("team.name", `HTMLEscape(class'WebAdminUtils'.static.getTeamNameEx(teaminfo)));
		q.response.subst("team.size", teaminfo.Size);
		q.response.subst("team.score", teaminfo.Score);
		q.response.subst("team.score.int", int(teaminfo.Score));

		tmp $= webadmin.include(q, getGameTypeIncFile(q, "current_team"));
	}
	q.response.subst("teams", tmp);
	return webadmin.include(q, getGameTypeIncFile(q, "current_teams"));
}

function string getGameTypeIncFile(WebAdminQuery q, string base)
{
	local string incFile;
	incFile = base$"_"$locs(webadmin.WorldInfo.Game.class)$".inc";
	if (webadmin.hasIncludeFile(q, incFile)) return incFile;
	return base$".inc";
}

function buildSortedPRI(string sortkey, optional bool reverse=false, optional bool includeBots=true)
{
	local Controller P;
	local PlayerReplicationInfo PRI;
	local int idx;
	local bool cmp, inserted;

	sortedPRI.Remove(0, sortedPRI.Length);

	foreach WebAdmin.WorldInfo.AllControllers(class'Controller', P)
	{
		if (!P.bDeleteMe && P.PlayerReplicationInfo != None && P.bIsPlayer)
		{
			if (!includeBots && P.PlayerReplicationInfo.bBot)
			{
				continue;
			}
			/*
			if (DemoRecSpectator(P) != none)
			{
				// never mess with this one
				continue;
			}
			*/
			inserted = false;
			foreach sortedPRI(PRI, idx)
			{
				cmp = comparePRI(PRI, P.PlayerReplicationInfo, sortkey);
				if (reverse)
				{
					cmp = !cmp;
				}
				if (cmp)
				{
					sortedPRI.Insert(idx, 1);
					sortedPRI[idx] = P.PlayerReplicationInfo;
					inserted = true;
					break;
				}
			}
			if (!inserted)
			{
				sortedPRI.addItem(P.PlayerReplicationInfo);
			}
		}
	}
}

function bool comparePRI(PlayerReplicationInfo PRI1, PlayerReplicationInfo PRI2, string key)
{
	`if(`GAME_UT3)
    local string s1, s2;
	if (key ~= "name")
	{
		if (len(pri1.PlayerName) == 0)
		{
			s1 = pri1.PlayerAlias;
		}
		else {
			s1 = pri1.PlayerName;
		}
		if (len(pri2.PlayerName) == 0)
		{
			s2 = pri2.PlayerAlias;
		}
		else {
			s2 = pri2.PlayerName;
		}
		return caps(s1) > caps(s2);
	}
	else
    `endif
    if (key ~= "playername" `if(`GAME_UT3) `else || key ~= "name" `endif)
	{
		return caps(pri1.PlayerName) > caps(pri2.PlayerName);
	}
	`if(`GAME_UT3)
	else if (key ~= "playeralias")
	{
		return caps(pri1.PlayerAlias) > caps(pri2.PlayerAlias);
	}
	`endif
	else if (key ~= "score")
	{
		return pri1.score > pri2.score;
	}
	else if (key ~= "deaths")
	{
		return pri1.deaths > pri2.deaths;
	}
	else if (key ~= "ping")
	{
		return pri1.ping > pri2.ping;
	}
	else if (key ~= "lives")
	{
		return pri1.NumLives > pri2.numlives;
	}
	`if(`GAME_UT3)
	else if (key ~= "ranking")
	{
		return pri1.playerranking > pri2.playerranking;
	}
	else if (key ~= "teamid")
	{
		return pri1.teamid > pri2.teamid;
	}
	`endif
	else if (key ~= "kills")
	{
		return pri1.kills > pri2.kills;
	}
	else if (key ~= "starttime")
	{
		return pri1.starttime > pri2.starttime;
	}
}

static function string getPlayerKey(PlayerReplicationInfo pri)
{
	return pri.PlayerID$"_"$class'OnlineSubsystem'.static.UniqueNetIdToString(pri.UniqueId)$"_"$pri.CreationTime;
}

function substPri(WebAdminQuery q, PlayerReplicationInfo pri)
{
	local PlayerController pc;

	q.response.subst("player.playerid", pri.PlayerID);
	q.response.subst("player.playerkey", getPlayerKey(pri));
	q.response.subst("player.name", `HTMLEscape(pri.PlayerName));
	q.response.subst("player.playername", `HTMLEscape(pri.PlayerName));
	q.response.subst("player.score", int(pri.score));
	q.response.subst("player.deaths", pri.deaths);
	q.response.subst("player.ping", pri.ping * 4); // this ping value is divided by 4 (250 = 1sec) see bug #40
	q.response.subst("player.exactping", pri.ExactPing);
	q.response.subst("player.lives", pri.numlives);
	if (`isTeamGame(webadmin.WorldInfo.Game) && pri.Team != none)
	{
		q.response.subst("player.teamid", pri.Team.TeamIndex);
		q.response.subst("player.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(pri.Team.TeamColor));
		q.response.subst("player.teamname", `HTMLEscape(class'WebAdminUtils'.static.getTeamNameEx(pri.Team)));
	}
	else {
		q.response.subst("player.teamid", "");
		q.response.subst("player.teamcolor", "transparent");
		q.response.subst("player.teamname", "");
	}
	q.response.subst("player.admin", `HTMLEscape(pri.bAdmin?default.msgYes:default.msgNo));
	q.response.subst("player.bot", `HTMLEscape(pri.bBot?default.msgYes:default.msgNo));
	q.response.subst("player.spectator", `HTMLEscape(pri.bIsSpectator?default.msgYes:default.msgNo));
	q.response.subst("player.kills", pri.kills);
	q.response.subst("player.starttime", pri.starttime);

	pc = PlayerController(pri.Owner);
	if (pc != none)
	{
		if (pc.pawn != none)
		{
			q.response.subst("player.pawn.health", pc.pawn.Health);
			q.response.subst("player.pawn.healthmax", pc.pawn.HealthMax);
		}
		else {
			q.response.subst("player.pawn.health", "");
			q.response.subst("player.pawn.healthmax", "");
		}
	}
}

function int handleCurrentPlayersAction(WebAdminQuery q)
{
	local PlayerReplicationInfo PRI;
	local int idx;
	local string IP, action, kickMessage;
	local PlayerController PC,otherPC;
	`if(`WITH_TEXT_MUTE)
	local KFPlayerController UTPC;
	`endif

	action = q.request.getVariable("action");
	if (action != "")
	{
		//PRI = webadmin.WorldInfo.Game.GameReplicationInfo.FindPlayerByID(int(q.request.getVariable("playerid")));
		IP = q.request.getVariable("playerkey");
		PRI = none;
		for (idx = 0; idx < webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray.length; idx++)
		{
			if (getPlayerKey(webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[idx]) == IP)
			{
				PRI = webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[idx];
				break;
			}
		}
		if (PRI == none)
		{
			webadmin.addMessage(q, msgPlayerNotFound, MT_Warning);
		}
		else if (q.user.canPerform(webadmin.getAuthURL("/current/players#"$action)))
		{
			PC = PlayerController(PRI.Owner);
			if ( NetConnection(PC.Player) == None )
			{
				PC = none;
			}
			if (PC == none)
			{
				webadmin.addMessage(q, msgNoHumanPlayer, MT_Warning);
			}
			else {
				// Default to just the normal kick message
				kickMessage = "Engine.AccessControl.KickedMsg";
				if (action ~= "mutevoice")
				{
					foreach webadmin.WorldInfo.AllControllers(class'PlayerController', otherPC)
					{
						otherPC.ServerMutePlayer(PC.PlayerReplicationInfo.UniqueId);
					}
					webadmin.addMessage(q, repl(msgVoiceMuted, "%s", PRI.PlayerName));
					return 0;
				}
				else if (action ~= "unmutevoice")
				{
					foreach webadmin.WorldInfo.AllControllers(class'PlayerController', otherPC)
					{
						otherPC.ServerUnMutePlayer(PC.PlayerReplicationInfo.UniqueId);
					}
					webadmin.addMessage(q, repl(msgVoiceUnmuted, "%s", PRI.PlayerName));
					return 0;
				}

				`if(`WITH_TEXT_MUTE)
				else if (action ~= "toggletext")
				{
					UTPC = KFPlayerController(PC);
					if (UTPC != none)
					{
						UTPC.bServerMutedText = !UTPC.bServerMutedText;
						if (UTPC.bServerMutedText) webadmin.addMessage(q, repl(msgTextMuted, "%s", PRI.PlayerName));
						else webadmin.addMessage(q, repl(msgTextUnmuted, "%s", PRI.PlayerName));
						return (UTPC.bServerMutedText?2:3);
					}
					return 0;
				}
				`endif

				else if (action ~= "banip" || action ~= "ban ip")
				{
					banByIP(PC);
					kickMessage = "Engine.AccessControl.KickAndPermaBan";
				}
				else if (action ~= "banid" || action ~= "ban unique id")
				{
					banByID(PC);
					kickMessage = "Engine.AccessControl.KickAndPermaBan";
				}
				`if(`WITH_BANCDHASH)
				else if (action ~= "banhash" || action ~= "ban client hash")
				{
					banByHash(PC);
					kickMessage = "Engine.AccessControl.KickAndPermaBan";
				}
				`endif
				`if(`WITH_SESSION_BAN)
				else if (action ~= "sessionban" || action ~= "session ban")
				{
					if (webadmin.WorldInfo.Game.AccessControl.IsAdmin(PC))
					{
						webadmin.addMessage(q, repl(msgCantBanAdmin, "%s", PRI.PlayerName), MT_Error);
						return 0;
					}
					else {
						if (`{AccessControl} (webadmin.WorldInfo.Game.AccessControl) != none)
						{
							`{AccessControl} (webadmin.WorldInfo.Game.AccessControl).KickSessionBanPlayer(PC, PC.PlayerReplicationInfo.UniqueId, "Engine.AccessControl.KickAndSessionBan");
							webadmin.addMessage(q, repl(msgSessionBanned, "%s", PRI.PlayerName));
							return 1;
						}
						else {
							webadmin.addMessage(q, msgSessionBanNoROAC, MT_Error);
							return 1;
						}
					}
				}
				`endif

				if (!webadmin.WorldInfo.Game.AccessControl.KickPlayer(PC, kickMessage))
				{
					webadmin.addMessage(q, repl(msgCantKickAdmin, "%s", PRI.PlayerName), MT_Error);
				}
				else {
					webadmin.addMessage(q, repl(msgPlayerRemoved, "%s", PRI.PlayerName));
					return 1;
				}
			}
		}
		else {
			webadmin.addMessage(q, msgNotAllowed, MT_Error);
		}
	}
	return 0;
}

function handleCurrentPlayers(WebAdminQuery q)
{
	local PlayerReplicationInfo PRI;
	local int idx;
	local string players, IP;
	local PlayerController PC;
	local OnlineSubsystem steamworks;
	local string tmp, playerAct;

	handleCurrentPlayersAction(q);

	steamworks = class'GameEngine'.static.GetOnlineSubsystem();

	playerAct = "";
	for (idx = 0; idx < playerActions.length; ++idx)
	{
		if (!q.user.canPerform(webadmin.getAuthURL(q.request.uri$"#"$playerActions[idx])))
		{
			continue;
		}
		q.response.subst("action.action", `HTMLEscape(playerActions[idx]));
		tmp = Localize("QHCurrent", "PlayerAction_"$playerActions[idx], "WebAdmin");
		if (tmp == "")
		{
			tmp = playerActions[idx];
		}
		q.response.subst("action.text", `HTMLEscape(tmp));
		playerAct $= webadmin.include(q, "current_players_row_action.inc");
	}
	q.response.subst("actions", playerAct);

	buildSortedPRI(q.request.getVariable("sortby", "name"), q.request.getVariable("reverse", "") ~= "true", false);
	foreach sortedPRI(pri, idx)
	{
		PC = PlayerController(pri.owner);
		if (PC == none)
		{
			continue;
		}

		if (`mod(idx, 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");

		substPri(q, pri);
		IP = class'WebAdminUtils'.static.extractIp(PC.GetPlayerNetworkAddress());
		q.response.subst("player.ip", IP);
		q.response.subst("player.uniqueid", class'WebAdminUtils'.static.UniqueNetIdToString(pri.UniqueId));
		if (steamworks != none)
		{
			q.response.subst("player.steamid", steamworks.UniqueNetIdToInt64(pri.UniqueId));
			IP = steamworks.UniqueNetIdToPlayerName(pri.UniqueId);
			q.response.subst("player.steamname", `HTMLEscape(IP));
		}
		else {
			q.response.subst("player.steamname", "");
			q.response.subst("player.steamid", "");
		}
		`if(`WITH_TEXT_MUTE)
		if (KFPlayerController(PC) != none && KFPlayerController(PC).bServerMutedText)
		{
			q.response.subst("player.mutetext", msgTextUnmute);
		}
		else {
			q.response.subst("player.mutetext", msgTextMute);
		}
		`endif
		players $= webadmin.include(q, "current_players_row.inc");
	}
	if (sortedPRI.Length == 0)
	{
		players = webadmin.include(q, "current_players_empty.inc");
	}

	q.response.subst("sorted."$q.request.getVariable("sortby", "name"), "sorted");
	if (!(q.request.getVariable("reverse", "") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "name"), "true");
	}

	q.response.subst("players", players);

	webadmin.sendPage(q, "current_players.html");
}

function handleCurrentPlayersData(WebAdminQuery q)
{
	q.response.AddHeader("Content-Type: text/xml");
	q.response.SendText("<request>");
	switch (handleCurrentPlayersAction(q))
	{
		case 3: // is NOT muted
			q.response.SendText("<text playerkey=\""$q.request.getVariable("playerkey")$"\" label=\""$msgTextMute$"\"/>");
			break;
		case 2: // is muted
			q.response.SendText("<text playerkey=\""$q.request.getVariable("playerkey")$"\" label=\""$msgTextUnmute$"\"/>");
			break;
		case 1:
			q.response.SendText("<kicked playerkey=\""$q.request.getVariable("playerkey")$"\"/>");
			break;
		case 0:
			q.response.SendText("<nop/>");
			break;
	}
	q.response.SendText("<messages><![CDATA[");
	q.response.SendText(webadmin.renderMessages(q));
	q.response.SendText("]]></messages>");
	q.response.SendText("</request>");
}

protected function banByIP(PlayerController PC)
{
	local string IP;
	IP = class'WebAdminUtils'.static.extractIp(PC.GetPlayerNetworkAddress());
 	webadmin.WorldInfo.Game.AccessControl.IPPolicies[webadmin.WorldInfo.Game.AccessControl.IPPolicies.length] = "DENY," $ IP;
	webadmin.WorldInfo.Game.AccessControl.SaveConfig();
}

protected function banByID(PlayerController PC)
{
	`if(`WITH_BANNEDINFO)
	local BannedInfo NewBanInfo;
	if ( PC.PlayerReplicationInfo.UniqueId != PC.PlayerReplicationInfo.default.UniqueId &&
			!webadmin.WorldInfo.Game.AccessControl.IsIDBanned(PC.PlayerReplicationInfo.UniqueID) )
	{
		NewBanInfo.BannedID = PC.PlayerReplicationInfo.UniqueId;
		NewBanInfo.PlayerName = PC.PlayerReplicationInfo.PlayerName;
		NewBanInfo.TimeStamp = Timestamp();
		webadmin.WorldInfo.Game.AccessControl.BannedPlayerInfo.AddItem(NewBanInfo);
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}
	`else
	if ( PC.PlayerReplicationInfo.UniqueId != PC.PlayerReplicationInfo.default.UniqueId &&
			!webadmin.WorldInfo.Game.AccessControl.IsIDBanned(PC.PlayerReplicationInfo.UniqueID) )
	{
		webadmin.WorldInfo.Game.AccessControl.BannedIDs.AddItem(PC.PlayerReplicationInfo.UniqueId);
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}
	`endif
}

`if(`WITH_BANCDHASH)
protected function banByHash(PlayerController PC)
{
	local BannedHashInfo NewBanHashInfo;
	if (PC.HashResponseCache != "" && PC.HashResponseCache != "0" && !webadmin.WorldInfo.Game.AccessControl.IsHashBanned(PC.HashResponseCache))
	{
		NewBanHashInfo.PlayerName = PC.PlayerReplicationInfo.PlayerName;
		NewBanHashInfo.BannedHash = PC.HashResponseCache;
		webadmin.WorldInfo.Game.AccessControl.BannedHashes.AddItem(NewBanHashInfo);
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}
}
`endif

function handleCurrentChat(WebAdminQuery q, optional string page = "current_chat.html")
{
	local string msg;
	local int i;

	msg = q.request.getVariable("message");
	if (len(msg) > 0)
	{
		i = int(q.request.getVariable("teamsay", "-1"));
		if (i < 0 || i >= webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length)
		{
			BroadcastMessage(q.user.getPC(), INDEX_NONE, msg, 'Say');
		}
		else
		{
			BroadcastMessage(q.user.getPC(), i, msg, 'TeamSay');
		}
	}
	procChatData(q, 0, "chat.log");
	q.response.subst("chat.refresh", ChatRefresh);
	q.response.subst("chat.max", class'BasicWebAdminUser'.default.maxHistory);

	msg = "";
	if (bEnableTeamChat && `isTeamGame(webadmin.WorldInfo.Game))
	{
		q.response.subst("team.teamid", -1);
		q.response.subst("team.name", "Everybody");
		q.response.subst("team.checked", "checked=\"checked\"");
		msg $= webadmin.include(q, "current_chat_teamctrl.inc");
		for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length; i++)
		{
			q.response.subst("team.teamid", i);
			q.response.subst("team.name", `HTMLEscape(class'WebAdminUtils'.static.getTeamNameEx(webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i])));
			q.response.subst("team.checked", "");
			msg $= webadmin.include(q, "current_chat_teamctrl.inc");
		}
	}
	q.response.subst("teamsaycontrols", msg);

	webadmin.sendPage(q, page);
}

function BroadcastMessage( Controller Sender, int teamidx, coerce string Msg, name Type )
{
	// We just ignore any filtering done by the BroadcastHandler
	local PlayerController P;
	local TeamInfo oldTeam;
	if (teamidx > INDEX_NONE)
	{
		//oldTeam = Sender.PlayerReplicationInfo.Team;
		//Sender.PlayerReplicationInfo.Team = webadmin.WorldInfo.Game.GameReplicationInfo.Teams[teamidx];
		//webadmin.WorldInfo.Game.BroadcastTeam(Sender, msg, Type);
		//Sender.PlayerReplicationInfo.Team = oldTeam;

		oldTeam = webadmin.WorldInfo.Game.GameReplicationInfo.Teams[teamidx];
		foreach webadmin.WorldInfo.AllControllers(class'PlayerController', P)
		{
			if (P.PlayerReplicationInfo.Team == oldTeam)
			{
				webadmin.WorldInfo.Game.BroadcastHandler.BroadcastText(Sender.PlayerReplicationInfo, P, Msg, Type);
			}
		}
	}
	else {
		//webadmin.WorldInfo.Game.Broadcast(Sender, msg, Type);

		foreach webadmin.WorldInfo.AllControllers(class'PlayerController', P)
		{
			webadmin.WorldInfo.Game.BroadcastHandler.BroadcastText(Sender.PlayerReplicationInfo, P, Msg, Type);
		}
	}
}

function handleCurrentChatData(WebAdminQuery q)
{
	local string msg;
	local int i;

	msg = q.request.getVariable("message");
	if (len(msg) > 0)
	{
		i = int(q.request.getVariable("teamsay", "-1"));
		if (i < 0 || i >= webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length)
		{
			BroadcastMessage(q.user.getPC(), INDEX_NONE, msg, 'Say');
		}
		else {
			BroadcastMessage(q.user.getPC(), i, msg, 'TeamSay');
		}
	}
	q.response.AddHeader("Content-Type: text/html");
	q.response.SendStandardHeaders();
	procChatData(q, int(q.session.getString("chatlog.lastid")));
}

function procChatData(WebAdminQuery q, optional int startFrom, optional string substvar)
{
	local string result, tmp;
	local array<MessageEntry> history;
	local MessageEntry entry;
	local string template;
	local bool isteamgame;

	q.user.messageHistory(history, startFrom);

	isteamgame = `isTeamGame(webadmin.WorldInfo.Game);

	foreach history(entry)
	{
		if (entry.type == 'say')
		{
			template = "current_chat_msg.inc";
		}
		else if (entry.type == 'teamsay')
		{
			template = "current_chat_teammsg.inc";
		}
		else {
			template = "current_chat_notice.inc";
		}

		q.response.subst("msg.type", `HTMLEscape(entry.type));
		q.response.subst("msg.username", `HTMLEscape(entry.senderName));
		q.response.subst("msg.text", `HTMLEscape(entry.message));
		q.response.subst("msg.teamname", `HTMLEscape(entry.teamName));
		tmp = "";
		if (entry.sender.bAdmin) {
			tmp @= "admin";
		}
		if (entry.sender.bOnlySpectator) {
			tmp @= "spectator";
		}
		q.response.subst("msg.user.class", `HTMLEscape(tmp));
		if (isteamgame && entry.teamId > INDEX_NONE)
		{
			q.response.subst("msg.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(entry.teamColor));
		}
		else {
			q.response.subst("msg.teamcolor", "transparent");
		}
		if (substvar == "")
		{
			q.response.SendText(webadmin.include(q, template));
		}
		else {
			result $= webadmin.include(q, template);
		}
		startFrom = entry.counter;
	}

	if (substvar != "")
	{
		q.response.subst(substvar, result);
	}
	q.session.putString("chatlog.lastid", ""$startFrom);
}

function handleConsole(WebAdminQuery q)
{
	local string cmd, result;
	local int i;
	local bool denied;

	cmd = q.request.getVariable("command");
	if (len(cmd) > 0)
	{
		denied = false;
		for (i = 0; i < denyConsoleCommands.length; i++)
		{
			if (denyConsoleCommands[i] ~= cmd || InStr(cmd$" ", denyConsoleCommands[i]$" ") == 0)
			{
				denied = true;
				break;
			}
		}

		if (!denied)
		{
			result = "";
			if (bAdminConsoleCommandsHack && adminCmdHandler != none)
			{
				// hack to blend in some admin exec commands
				denied = adminCmdHandler.execute(cmd, result, q.user.getPC());
			}
			if (!denied)
			{
				result = webadmin.WorldInfo.Game.ConsoleCommand(cmd, false);
			}
			q.response.subst("console.command", `HTMLEscape(cmd));
			q.response.subst("console.results", repl(`HTMLEscape(result), chr(10), "<br />"$chr(10)));
			q.response.subst("console.visible", cssVisible);
		}
		else {
			q.response.subst("console.command", `HTMLEscape(cmd));
			q.response.subst("console.results", `HTMLEscape(msgExecDisabled));
			q.response.subst("console.visible", cssVisible);
		}
	}
	else {
		q.response.subst("console.command", "");
		q.response.subst("console.results", "");
		q.response.subst("console.visible", cssHidden);
	}
	webadmin.sendPage(q, "console.html");
}

event ChangeGameTimer()
{
	if (Len(newUrl) > 0)
	{
		webadmin.WorldInfo.ServerTravel(newUrl, true);
		//newUrl = "";
	}
}

/**
 * Get the actual server options. Don't use "webadmin.WorldInfo.Game.ServerOptions" because
 * that will get lost quickly;
 */
function string getServerOptions()
{
	local string serverOptions;
	local int idx;
	serverOptions = webadmin.WorldInfo.GetLocalURL();
	idx = InStr(serverOptions, "?");
	if (idx > 0)
	{
		// starts with a mapname (always?)
		serverOptions = Mid(serverOptions, idx);
	}
	return serverOptions;
}

function handleCurrentChange(WebAdminQuery q)
{
	local DCEGameInfo gametype;
	local string serverOptions;
	local string currentGameType, curmap, curmiscurl;
	local array<string> currentMutators, opts;
	local string substvar, substvar2;
	local int idx, i, j;
	local Mutator mut;
	local array<KeyValuePair> options;

 	webadmin.dataStoreCache.loadGameTypes();

 	currentGameType = q.request.getVariable("gametype");
 	curmap = q.request.getVariable("map");

	serverOptions = getServerOptions();
 	curmiscurl = serverOptions;
 	opts = denyUrlOptions;
 	opts.AddItem("mutator");
 	opts.AddItem("game");
 	opts.AddItem("team");
 	opts.AddItem("name");
 	opts.AddItem("class");
 	opts.AddItem("character");
 	opts.AddItem("listen");
	curmiscurl = class'WebAdminUtils'.static.removeUrlOptions(curmiscurl, opts);
 	curmiscurl = q.request.getVariable("urlextra", curmiscurl);

 	idx = int(q.request.getVariable("mutatorGroupCount", "0"));
 	for (i = 0; i < idx; i++)
 	{
 		substvar = q.request.getVariable("mutgroup"$i, "");
 		if (len(substvar) > 0)
 		{
 			if (currentMutators.find(substvar) == INDEX_NONE)
 			{
 				currentMutators.addItem(substvar);
 			}
 		}
 	}

 	if (q.request.getVariable("action") ~= "change" || q.request.getVariable("action") ~= "change game")
 	{
 		options.length = 0;
 		class'WebAdminUtils'.static.parseUrlOptions(options, curmiscurl);
 		if (currentMutators.length > 0)
 		{
 			JoinArray(currentMutators, substvar2, ",");
 			class'WebAdminUtils'.static.parseUrlOptions(options, "mutator="$substvar2);
 		}
 		class'WebAdminUtils'.static.parseUrlOptions(options, "game="$currentGameType);
 		i = InStr(curmap, "?");
 		if (i != INDEX_NONE)
 		{
 			class'WebAdminUtils'.static.parseUrlOptions(options, Mid(curmap, i+1));
 			curmap = Left(curmap, i);
 		}
 		// remove denied options
 		for (i = 0; i < denyUrlOptions.length; i++)
 		{
 			for (j = options.length-1; j >= 0; j--)
 			{
 				if (options[j].key ~= denyUrlOptions[i])
 				{
 					options.remove(j, 1);
 				}
 			}
 		}

		// construct url
 		substvar = curmap;
 		for (i = 0; i < options.length; i++)
 		{
 			substvar $= "?"$options[i].key;
 			if (Len(options[i].value) > 0)
 			{
 				substvar $= "="$options[i].value;
 			}
 		}

		webadmin.addMessage(q, msgChangingGame);
		q.response.subst("newurl", `HTMLEscape(substvar));
		webadmin.sendPage(q, "current_changing.html");

		// add deny options when they were set on previous the commandline
		for (i = 0; i < denyUrlOptions.length; i++)
 		{
 			if (webadmin.WorldInfo.Game.HasOption(serverOptions, denyUrlOptions[i]))
 			{
 				substvar $= "?"$denyUrlOptions[i];
 				substvar2 = webadmin.WorldInfo.Game.ParseOption(serverOptions, denyUrlOptions[i]);
 				if (len(substvar2) > 0)
 				{
 					substvar $= "="$substvar2;
 				}
 			}
		}

		newUrl = substvar;
		if (webadmin.WorldInfo.NetMode == NM_ListenServer)
		{
			// make sure this parameter is included for map switches.
			newUrl $= "?listen";
		}
		webadmin.WebServer.SetTimer(0.5, false, 'ChangeGameTimer', self);
 		return;
 	}

 	if (currentGameType == "")
 	{
 		currentGameType = string(webadmin.WorldInfo.Game.class);
 		curmap = string(webadmin.WorldInfo.GetPackageName());
 		ParseStringIntoArray(webadmin.WorldInfo.Game.ParseOption(serverOptions, "mutator"), currentMutators, ",", true);
		mut = webadmin.WorldInfo.Game.BaseMutator;
		while (mut != none)
		{
			substvar = mut.class.getPackageName()$"."$mut.class;
			currentMutators.addItem(substvar);
			mut = mut.NextMutator;
		}
 	}
 	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		currentGameType = webadmin.dataStoreCache.gametypes[idx].data.ClassName;
 		if (curmap == "")
 		{
 			//curmap = webadmin.dataStoreCache.gametypes[idx].data.DefaultMap;
 		}
 	}
 	else {
 		currentGameType = "";
 	}

	substvar = "";
 	foreach webadmin.dataStoreCache.gametypes(gametype)
 	{
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.data.ClassName));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(gametype.FriendlyName));
 		//q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.data.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(gametype.Description));
 		if (currentGameType ~= gametype.data.ClassName)
 		{
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	procCurrentChange(q, currentGameType, curmap, currentMutators, substvar, substvar2, idx);
	q.response.subst("maps", substvar);
	q.response.subst("mutators", substvar2);
	q.response.subst("mutator.groups", idx);

	q.response.subst("urlextra", curmiscurl);
	Joinarray(denyUrlOptions, substvar, ", ", true);
	q.response.subst("urlextra.deny", substvar);

	webadmin.sendPage(q, "current_change.html");
}

function procCurrentChange(WebAdminQuery q, string currentGameType, string curmap, array<string> currentMutators,
	out string outMaps, out string outMutators, out int outMutatorGroups)
{
	local string substvar2, substvar3, mutname;
	local int idx, i, j, k;
	local array<DCEMapInfo> maps;
	local array<MutatorGroup> mutators;

	outMaps = "";
 	if (currentGameType != "")
 	{
 		maps = webadmin.dataStoreCache.getMaps(currentGameType);
 		for (i = 0; i < maps.length; i++)
 		{
			q.response.subst("map.mapname", `HTMLEscape(maps[i].data.MapName));
 			q.response.subst("map.friendlyname", `HTMLEscape(maps[i].FriendlyName));
 			//q.response.subst("map.mapid", string(maps[i].data.MapID));
 			//q.response.subst("map.numplayers", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].data.NumPlayers)));
 			q.response.subst("map.description", `HTMLEscape(maps[i].Description));
	 		if (curmap ~= maps[i].MapName)
 			{
 				q.response.subst("map.selected", "selected=\"selected\"");
	 		}
 			else {
 				q.response.subst("map.selected", "");
	 		}
 			outMaps $= webadmin.include(q, "current_change_map.inc");
 		}
 	}

	outMutators = "";
	outMutatorGroups = 0;
 	if (currentGameType != "")
 	{
 		mutators = webadmin.dataStoreCache.getMutators(currentGameType);
 		idx = 0;
 		for (i = 0; i < mutators.length; i++)
 		{
 			if ((mutators[i].mutators.Length == 1) || len(mutators[i].GroupName) == 0)
 			{
 				for (j = 0; j < mutators[i].mutators.Length; j++)
 				{
 					q.response.subst("mutator.formtype", "checkbox");
	 				q.response.subst("mutator.groupid", "mutgroup"$(mutators.Length+outMutatorGroups));
 					q.response.subst("mutator.classname", `HTMLEscape(mutators[i].mutators[j].ClassName));
 					q.response.subst("mutator.id", "mutfield"$(++idx));
 					mutname = mutators[i].mutators[j].FriendlyName;
 					if (len(mutname) == 0) mutname = mutators[i].mutators[j].ClassName;
 					q.response.subst("mutator.friendlyname", `HTMLEscape(mutname));
 					q.response.subst("mutator.description", `HTMLEscape(mutators[i].mutators[j].Description));
	 				if (currentMutators.find(mutators[i].mutators[j].ClassName) != INDEX_NONE)
 					{
 						q.response.subst("mutator.selected", "checked=\"checked\"");
		 			}
 					else {
		 				q.response.subst("mutator.selected", "");
	 				}
 					substvar3 $= webadmin.include(q, "current_change_mutator.inc");
 					outMutatorGroups++;
 				}
 			}
 			else {
 				substvar2 = "";
 				k = INDEX_NONE;

	 			for (j = 0; j < mutators[i].mutators.Length; j++)
 				{
 					q.response.subst("mutator.formtype", "radio");
	 				q.response.subst("mutator.groupid", "mutgroup"$i);
 					q.response.subst("mutator.classname", `HTMLEscape(mutators[i].mutators[j].ClassName));
 					q.response.subst("mutator.id", "mutfield"$(++idx));
 					mutname = mutators[i].mutators[j].FriendlyName;
 					if (len(mutname) == 0) mutname = mutators[i].mutators[j].ClassName;
 					q.response.subst("mutator.friendlyname", `HTMLEscape(mutname));
 					q.response.subst("mutator.description", `HTMLEscape(mutators[i].mutators[j].Description));
					if (currentMutators.find(mutators[i].mutators[j].ClassName) != INDEX_NONE)
 					{
 						k = j;
 						q.response.subst("mutator.selected", "checked=\"checked\"");
			 		}
 					else {
			 			q.response.subst("mutator.selected", "");
 					}
	 				substvar2 $= webadmin.include(q, "current_change_mutator.inc");
 				}

 				q.response.subst("mutator.formtype", "radio");
	 			q.response.subst("mutator.groupid", "mutgroup"$i);
 				q.response.subst("mutator.classname", "");
 				q.response.subst("mutator.id", "mutfield"$(++idx));
 				q.response.subst("mutator.friendlyname", "none");
 				q.response.subst("mutator.description", "");
 				if (k == INDEX_NONE)
 				{
 					q.response.subst("mutator.selected", "checked=\"checked\"");
			 	}
 				else {
			 		q.response.subst("mutator.selected", "");
 				}
 				substvar2 = webadmin.include(q, "current_change_mutator.inc")$substvar2;

 				q.response.subst("group.id", "mutgroup"$i);
 				q.response.subst("group.name", Locs(mutators[i].GroupName));
 				q.response.subst("group.mutators", substvar2);
	 			outMutators $= webadmin.include(q, "current_change_mutator_group.inc");
	 		}
 		}
 		if (len(substvar3) > 0)
 		{
 			q.response.subst("group.id", "mutgroup0");
	 		q.response.subst("group.name", "");
 			q.response.subst("group.mutators", substvar3);
 			outMutators = webadmin.include(q, "current_change_mutator_nogroup.inc")$outMutators;
 		}
 	}
 	outMutatorGroups = outMutatorGroups+mutators.Length;
 	if (mutators.Length == 0)
 	{
 		outMutators = "<span class=\"noMutatorsMsg\">"$msgNoMutators$"</span>";
 	}
}

function handleCurrentChangeData(WebAdminQuery q)
{
	local string currentGameType, curmap;
	local array<string> currentMutators;
	local string substMaps, substMutators, tmp;
	local int idx;

	currentGameType = q.request.getVariable("gametype");
	curmap = "";
	currentMutators.length = 0;

	webadmin.dataStoreCache.loadGameTypes();
	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		currentGameType = webadmin.dataStoreCache.gametypes[idx].data.ClassName;
 		//curmap = webadmin.dataStoreCache.gametypes[idx].data.DefaultMap;
 	}
 	else {
 		currentGameType = "";
 	}

 	for (idx = 0; idx < int(q.request.getVariable("mutatorGroupCount", "0")); idx++)
 	{
 		tmp = q.request.getVariable("mutgroup"$idx, "");
 		if (len(tmp) > 0)
 		{
 			if (currentMutators.find(tmp) == INDEX_NONE)
 			{
 				currentMutators.addItem(tmp);
 			}
 		}
 	}

	procCurrentChange(q, currentGameType, curmap, currentMutators, substMaps, substMutators, idx);
	//q.response.SendText("<result>");

	q.response.AddHeader("Content-Type: text/html");

	q.response.SendText("<select id=\"map\">");
	q.response.SendText(substMaps);
	q.response.SendText("</select>");

	q.response.SendText("<div id=\"mutators\">");
	q.response.SendText(substMutators);
	q.response.SendText("</div>");

	q.response.SendText("<input type=\"hidden\" id=\"mutatorGroupCount\" value=\""$idx$"\" />");

	//q.response.SendText("</result>");
}

`if(`WITH_BOTS)
function handleBots(WebAdminQuery q)
{
	local int i,j;
	local string sv1, tmp;
	local PlayerReplicationInfo pri;
	local Controller PC;

	sv1 = q.request.getVariable("action", "");

	if (sv1 ~= "addbots")
	{
		i = int(q.request.getVariable("numbots", "0"));
		j = int(q.request.getVariable("toteam", "-1"));
		if (i > 0)
		{
			ROGameInfo(webadmin.WorldInfo.Game).AddBots(i, j);
			if (j == -1)
			{
				webadmin.addMessage(q, repl(msgAddingBots, "%d", string(i)));
			}
			else {
				webadmin.addMessage(q, repl(repl(msgAddingBotsTeam, "%d", string(i)), "%team", class'WebAdminUtils'.static.getTeamName(j)));
			}
		}
	}

	if (sv1 ~= "killbots")
	{
		tmp = "";
		for (i = 0; i < q.request.GetVariableCount("bot"); ++i)
		{
			sv1 = q.request.getVariableNumber("bot", i, "");
			if (len(sv1) > 0)
			{
				PRI = none;
				for (j = 0; j < webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray.length; j++)
				{
					if (getPlayerKey(webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[j]) == sv1)
					{
						PRI = webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[j];
						break;
					}
				}
				if (PRI != none)
				{
					PC = Controller(PRI.Owner);
					if (PC != none)
					{
						if (len(tmp) > 0) tmp $= ", ";
						tmp $= PRI.PlayerName;
						if (PC.Pawn != none) PC.Pawn.Destroy();
						PC.Destroy();
					}
				}
			}
		}
		if (len(tmp) > 0)
		{
			webadmin.addMessage(q, repl(msgRemovedBots, "%s", tmp));
		}
	}

	tmp = "";
	if (`isTeamGame( webadmin.WorldInfo.Game))
	{
		// don't bother adding team selection when team balancing is enabled
		if (ROGameInfo(webadmin.WorldInfo.Game) == none || !ROGameInfo(webadmin.WorldInfo.Game).bBalanceTeams)
		{
			q.response.subst("team.teamid", -1);
			q.response.subst("team.name", "Any team");
			q.response.subst("team.checked", "checked=\"checked\"");
			tmp $= webadmin.include(q, "current_bots_teamctrl.inc");
			for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length; i++)
			{
				q.response.subst("team.teamid", i);
				q.response.subst("team.name", `HTMLEscape(class'WebAdminUtils'.static.getTeamNameEx(webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i])));
				q.response.subst("team.checked", "");
				tmp $= webadmin.include(q, "current_bots_teamctrl.inc");
			}
		}
	}
	if (tmp != "")
	{
		q.response.subst("teamcontrols", tmp);
		tmp = webadmin.include(q, "current_bots_teams.inc");
	}
	q.response.subst("teamcontrols", tmp);

	q.response.subst("playerlimit", webadmin.worldinfo.game.MaxPlayers);

	buildSortedPRI(q.request.getVariable("sortby", "score"), q.request.getVariable("reverse", "true") ~= "true");
	j = 0;
	tmp = "";
	foreach sortedPRI(pri)
	{
		if (!pri.bBot)
		{
			continue;
		}
		++j;
		if (`mod(j, 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");
		substPri(q, pri);
		tmp $= webadmin.include(q, "current_bot_row.inc");
	}
	if (sortedPRI.Length == 0)
	{
		tmp = webadmin.include(q, "current_bot_empty.inc");
	}
	q.response.subst("sorted."$q.request.getVariable("sortby", "score"), "sorted");
	if (!(q.request.getVariable("reverse", "true") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "score"), "true");
	}

	q.response.subst("bots", tmp);

	webadmin.sendPage(q, "current_bots.html");
}
`endif

defaultproperties
{
	cssVisible=""
	cssHidden="display: none;"

	playerActions.Add("kick")
	playerActions.Add("sessionban")
	playerActions.Add("banip")
	playerActions.Add("banid")
	playerActions.Add("mutevoice")
	playerActions.Add("unmutevoice")
}
