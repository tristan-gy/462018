/**
 * This class will do the actual importing of bans from an URL (json data)
 *
 * Copyright 2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class BanImporter extends Object;

enum ImportStatus
{
	IS_DOWNLOADING,
	IS_PARSING,
	IS_DONE,
	IS_ERROR
};

var ImportStatus status;

var string importFromUrl;

var string errorMessage;

var localized string msgIOError, msgInvalidResponse, msgInvalidJson, msgJsonNoBans,
	msgStatusDownloading, msgStatusParsing, msgStatusDone, msgStatusError, msgBadUrl;

var JsonObject jsonBans;

function bool isFinished()
{
	return status == IS_DONE || status == IS_ERROR;
}

function string getStatusStr()
{
	switch (status)
	{
		case IS_DOWNLOADING:
			return msgStatusDownloading;
		case IS_PARSING:
			return msgStatusParsing;
		case IS_DONE:
			return msgStatusDone;
		case IS_ERROR:
			return msgStatusError;
	}
}

function importFrom(string url)
{
	local bool result;
	jsonBans = none;
	errorMessage = "";
	status = IS_DOWNLOADING;
	importFromUrl = url;

	if (url == "")
	{
		status = IS_ERROR;
		errorMessage = msgBadUrl;
		return;
	}

	`log("Importing bans from: "$url,,'WebAdmin');
	result = class'HttpFactory'.static.CreateRequest()
		.SetURL(importFromUrl)
		.SetVerb("GET")
		.SetProcessRequestCompleteDelegate(downloadFinished)
		.SetHeader("X-WebAdmin", "KF2 WebAdmin; BanImporter")
		// This header prevents caching in the client which could prevent a download.
		.SetHeader("If-Modified-Since", "Thu, 1 Jan 1970 00:00:00 GMT")
		.ProcessRequest();

	if (!result)
	{
		`log("Failed to initiate HTTP request.",,'WebAdmin');
		status = IS_ERROR;
		errorMessage = msgIOError;
	}
}

function downloadFinished(HttpRequestInterface request, HttpResponseInterface response, bool bDidSucceed)
{
	`log("Webserver responded with code: "$response.GetResponseCode(),, 'WebAdmin');
	if (!bDidSucceed)
	{
		`log("Ban import failed. IO Error?",,'WebAdmin');
		status = IS_ERROR;
		errorMessage = msgIOError;
		return;
	}
	if (response.GetResponseCode() == 200)
	{
		if (parseBans(response.GetContentAsString()))
		{
			status = IS_DONE;
			return;
		}
		status = IS_ERROR;
		errorMessage = Repl(errorMessage, "%content-type%", response.GetContentType());
		errorMessage = Repl(errorMessage, "%content-length%", response.GetContentLength());
		return;
	}
	status = IS_ERROR;
	errorMessage = msgInvalidResponse;
	errorMessage = Repl(errorMessage, "%content-type%", response.GetContentType());
	errorMessage = Repl(errorMessage, "%content-length%", response.GetContentLength());
	errorMessage = Repl(errorMessage, "%response-code%", response.GetResponseCode());
	return;
}

function bool parseBans(string data)
{
	local JsonObject json;

	json = class'JsonObject'.static.DecodeJson(data);
	if (json == none)
	{
		errorMessage = msgInvalidJson;
		return false;
	}

	jsonBans = json.GetObject("bans");
	if (jsonBans == none)
	{
		errorMessage = msgJsonNoBans;
		return false;
	}

	foreach jsonBans.ObjectArray(json)
	{
		if (json.HasKey("uniqueNetId") || json.HasKey("steamId64") )
		{
			return true;
		}
	}

	errorMessage = msgJsonNoBans;
	return false;
}

function int applyBansTo(AccessControl accessControl, OnlineSubsystem steamWorks)
{
	local JsonObject json;
	local string tmp;
	local UniqueNetId netid;
	local int cnt, idx;

	foreach jsonBans.ObjectArray(json)
	{
		tmp = json.GetStringValue("uniqueNetId");
		tmp -= " ";
		if (tmp != "") {
			class'OnlineSubsystem'.static.StringToUniqueNetId(tmp, netid);
		}
		else if (steamWorks != none) {
			tmp = json.GetStringValue("steamId64");
			tmp -= " ";
			steamWorks.Int64ToUniqueNetId(tmp, netid);
		}
		if (class'WebAdminUtils'.static.UniqueNetIdToString(netid) == "")
		{
			// invalid id
			continue;
		}
		for (idx = 0; idx < accessControl.BannedIDs.length; ++idx)
		{
			if (accessControl.BannedIDs[idx] == netid)
			{
				break;
			}
		}
		if (idx == accessControl.BannedIDs.length)
		{
			// does not exist yet
			accessControl.BannedIDs.addItem(netid);
			++cnt;
		}
	}
	return cnt;
}
