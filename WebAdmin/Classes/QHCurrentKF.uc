/**
 * Adds Killing Floor 2 specific information to current Query handler.
 *
 * Copyright 2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHCurrentKF extends QHCurrent;

`include(WebAdmin.uci)

function registerMenuItems(WebAdminMenu menu)
{
	super.registerMenuItems(menu);
	menu.addMenu("/current+gamesummary", "", self);
	menu.addMenu("/current/chat+frame", "", self);
	menu.addMenu("/current/chat+frame+data", "", self);
	menu.setVisibility("/current/chat", false);
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/current+gamesummary":
			handleAjaxGamesummary(q);
			return true;
		case "/current/chat+frame":
			q.response.subst("page.css.class", "chatframe");
			handleCurrentChat(q, "current_chat_frame.html");
			return true;
		case "/current/chat+frame+data":
			handleCurrentChatData(q);
			return true;
	}
	return super.handleQuery(q);
}

function decoratePage(WebAdminQuery q)
{
	if (q.user == none)
	{
		q.response.subst("gamesummary", "");
		q.response.subst("chatwindow", "");
		return;
	}
	decorateGameSummary(q);
	decorateChatWindow(q);
}

function substGameInfo(WebAdminQuery q)
{
	local KFGameInfo kfGameInfo;
	local string str;
	local int i;
	super.substGameInfo(q);

	i = int(webadmin.WorldInfo.Game.GameDifficulty);
	if (i == webadmin.WorldInfo.Game.GameDifficulty) {
		str = Localize("KFCommon_LocalizedStrings", "DifficultyStrings["$i$"]", "KFGame");
	}
	else {
		str = "";
	}
	if (len(str) == 0) {
		str = string(webadmin.WorldInfo.Game.GameDifficulty);
	}
	q.response.subst("rules.difficulty.text", str);

	kfGameInfo = KFGameInfo(webadmin.WorldInfo.Game);
	if (kfGameInfo != none)
	{
		q.response.subst("rules.minnetplayers", kfGameInfo.MinNetPlayers);
		q.response.subst("rules.mapvote", `HTMLEscape(kfGameInfo.bDisableMapVote?default.msgOff:default.msgOn));
		q.response.subst("rules.kickvote", `HTMLEscape(kfGameInfo.bDisableKickVote?default.msgOff:default.msgOn));
	}

	if (KFGameInfo_Survival(webadmin.WorldInfo.Game) != none)
	{
		substGameInfoSurvival(q);
	}
}

function substGameInfoSurvival(WebAdminQuery q)
{
	local KFGameInfo_Survival gameinfo;
	local KFGameReplicationInfo gri;
	local int deadMonsters;

	gameinfo = KFGameInfo_Survival(webadmin.WorldInfo.Game);
	gri = gameinfo.MyKFGRI;

	q.response.subst("wave.num", gameinfo.WaveNum);
	q.response.subst("wave.max", gameinfo.WaveMax-1);
	// total number spawned so far minus living monsters
	deadMonsters = gameinfo.NumAISpawnsQueued - gameinfo.GetMonsterAliveCount();
	q.response.subst("wave.monsters.pending", gri.WaveTotalAICount - deadMonsters);
	q.response.subst("wave.monsters.dead", deadMonsters);
	q.response.subst("wave.monsters.total", gri.WaveTotalAICount);
}

function substPri(WebAdminQuery q, PlayerReplicationInfo pri)
{
	local KFPlayerReplicationInfo ropri;

	super.substPri(q, pri);

	ropri = KFPlayerReplicationInfo(pri);
	if (ropri != none)
	{
		q.response.subst("player.perk.class", `HTMLEscape(ropri.CurrentPerkClass));
		if (ropri.CurrentPerkClass != none)
		{
			q.response.subst("player.perk.name", `HTMLEscape(ropri.CurrentPerkClass.default.PerkName));
		}
		else {
			q.response.subst("player.perk.name", "");
		}
		q.response.subst("player.perk.level", ropri.GetActivePerkLevel());
	}
}

function bool comparePRI(PlayerReplicationInfo PRI1, PlayerReplicationInfo PRI2, string key)
{
	local KFPlayerReplicationInfo kpri1, kpri2;
	kpri1 = KFPlayerReplicationInfo(pri1);
	kpri2 = KFPlayerReplicationInfo(pri2);

	if (kpri1 != none && kpri2 != none)
	{
		if (key ~= "perk")
		{
			return caps(kpri1.CurrentPerkClass.default.PerkName) > caps(kpri2.CurrentPerkClass.default.PerkName);
		}
		else if (key != "perklevel")
		{
			return kpri1.GetActivePerkLevel() > kpri2.GetActivePerkLevel();
		}
	}
	return super.comparePRI(PRI1, PRI2, key);
}

function handleAjaxGamesummary(WebAdminQuery q)
{
	q.response.AddHeader("Content-Type: text/xml");
	q.response.SendText("<response>");
  	q.response.SendText("<gamesummary><![CDATA[");
	q.response.SendText(renderGameSummary(q));
	q.response.SendText("]]></gamesummary>");
	q.response.SendText("</response>");
}

function decorateGameSummary(WebAdminQuery q)
{
	q.response.subst("gamesummary.details", renderGameSummary(q));
	q.response.subst("gamesummary", webadmin.include(q, "gamesummary_base.inc"));
}

function string renderGameSummary(WebAdminQuery q)
{
	substGameInfo(q);
	return webadmin.include(q, getGameTypeIncFile(q, "gamesummary"));
}

function decorateChatWindow(WebAdminQuery q)
{
	if (InStr(q.request.URI, "/current/chat") == 0) {
		q.response.subst("chatwindow", "");
		return;
	}
	q.response.subst("chatwindow", webadmin.include(q, "current_chat_frame.inc"));
}

defaultproperties
{
	separateSpectators=true
}