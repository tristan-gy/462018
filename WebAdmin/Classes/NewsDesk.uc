/**
 * Retrieves/cached news as reported by the news interface
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class NewsDesk extends Object config(WebAdmin) dependson(WebAdminUtils) dependson(OnlineSubsystem);

`include(WebAdmin.uci)

var config array<string> GameNews;
var config array<string> ContentNews;
var config string LastUpdate;

var OnlineNewsInterface newsIface;

function cleanup()
{
	if (newsIface != none)
	{
		newsIface.ClearReadNewsCompletedDelegate(OnReadNewsCompleted);
	}
	newsIface = none;
}

/**
 * Get the news when needed. Updated once a day
 */
function getNews(optional bool forceUpdate)
{
	local DateTime last, now;

	if (len(lastUpdate) > 0 && !forceUpdate)
	{
		class'WebAdminUtils'.static.getDateTime(now, timestamp());
		class'WebAdminUtils'.static.getDateTime(last, LastUpdate);
		// YY,YYM,MDD
		// 20,081,231
		if (last.year*10000+last.month*100+last.day >= now.year*10000+now.month*100+now.day)
		{
			return;
		}
	}
	`log("Updating news...",,'WebAdmin');
	if (class'GameEngine'.static.GetOnlineSubsystem() != none)
	{
		newsIface = class'GameEngine'.static.GetOnlineSubsystem().NewsInterface;
		if (newsIface == none)
		{
			`log("No OnlineNewsInterface; news desk is unavailable",,'WebAdmin');
			return;
		}
		newsIface.AddReadNewsCompletedDelegate(OnReadNewsCompleted);
		newsIface.ReadNews(0, ONT_GameNews);
		newsIface.ReadNews(0, ONT_ContentAnnouncements);
	}
}

function OnReadNewsCompleted(bool bWasSuccessful, EOnlineNewsType NewsType)
{
	local array<string> data, parsedData;
	local string ln;
	local int i,j;
	if (bWasSuccessful)
	{
		ParseStringIntoArray(newsIface.GetNews(0, NewsType), data, chr(10), false);
		parsedData.length = data.length;
		j = 0;
		for (i = 0; i < data.length; i++)
		{
			ln = `Trim(data[i]);
			if (len(ln) > 0 || j > 0)
			{
				parsedData[j] = ln;
				++j;
			}
		}
		parsedData.length = j;
		if (NewsType == ONT_GameNews) {
			gameNews = parsedData;
		}
		else if(NewsType == ONT_ContentAnnouncements) {
			contentNews = parsedData;
		}
		LastUpdate = TimeStamp();
		SaveConfig();
	}
}

function string renderNews(WebAdmin webadmin, WebAdminQuery q)
{
	local int i;
	local string tmp;
	if (gameNews.length > 0 || contentNews.length > 0)
	{
		for (i = 0; i < gameNews.length; i++)
		{
			if (i > 0) tmp $= "<br />";
			tmp $= `HTMLEscape(gameNews[i]);
		}
		q.response.subst("news.game", tmp);
		tmp = "";
		for (i = 0; i < contentNews.length; i++)
		{
			if (i > 0) tmp $= "<br />";
			tmp $= `HTMLEscape(contentNews[i]);
		}
		q.response.subst("news.content", tmp);
		q.response.subst("news.timestamp", `HTMLEscape(LastUpdate));
	}
	return webadmin.include(q, "news.inc");
}
