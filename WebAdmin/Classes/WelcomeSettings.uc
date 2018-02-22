/**
 * Settings handled for the server's Welcome Page.
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WelcomeSettings extends WebAdminSettings implements(IAdvWebAdminSettings);

`include(WebAdmin.uci)

`if(`WITH_WELCOME_SETTINGS)
var KFGameInfo gameinfo;

function setCurrentGameInfo(GameInfo instance)
{
	gameinfo = KFGameInfo(instance);
}

function cleanupSettings()
{
	gameinfo = none;
	super.cleanupSettings();
}

function advInitSettings(WorldInfo worldinfo, DataStoreCache dscache);

function bool advSaveSettings(WebRequest request, WebAdminMessages messages)
{
	class'KFGameInfo'.default.BannerLink = request.GetVariable("BannerLink", "");
	class'KFGameInfo'.default.ClanMotto = Repl(Repl(request.GetVariable("ClanMotto", ""), Chr(10), "@nl@"), Chr(13), "");
	class'KFGameInfo'.default.ClanMottoColor = class'WebAdminUtils'.static.HTMLColorToColor(request.GetVariable("ClanMottoColor", ""));
	class'KFGameInfo'.default.ServerMOTD = Repl(Repl(request.GetVariable("ServerMOTD", ""), Chr(10), "@nl@"), Chr(13), "");
	class'KFGameInfo'.default.ServerMOTDColor = class'WebAdminUtils'.static.HTMLColorToColor(request.GetVariable("ServerMOTDColor", ""));
	class'KFGameInfo'.default.WebSiteLink = request.GetVariable("WebLink", "");
	class'KFGameInfo'.default.WebLinkColor = class'WebAdminUtils'.static.HTMLColorToColor(request.GetVariable("WebLinkColor", ""));
	class'KFGameInfo'.static.StaticSaveConfig();

	if (gameinfo != none)
	{
		gameinfo.BannerLink = class'KFGameInfo'.default.BannerLink;
		gameinfo.ClanMotto = class'KFGameInfo'.default.ClanMotto;
		gameinfo.ClanMottoColor = class'KFGameInfo'.default.ClanMottoColor;
		gameinfo.ServerMOTD = class'KFGameInfo'.default.ServerMOTD;
		gameinfo.ServerMOTDColor = class'KFGameInfo'.default.ServerMOTDColor;
		gameinfo.WebSiteLink = class'KFGameInfo'.default.WebSiteLink;
		gameinfo.WebLinkColor = class'KFGameInfo'.default.WebLinkColor;
		gameinfo.SaveConfig();
	}
	return true;
}

function advRenderSettings(WebResponse response, SettingsRenderer renderer,
	optional string substName = "settings", optional ISettingsPrivileges privileges)
{
	if (gameinfo != none)
	{
		response.Subst("BannerLink", gameinfo.BannerLink);
		response.Subst("ClanMotto", repl(gameinfo.ClanMotto, "@nl@", chr(10)));
		response.Subst("ClanMottoColor", class'WebAdminUtils'.static.ColorToHTMLColor(gameinfo.ClanMottoColor));
		response.Subst("ServerMOTD", repl(gameinfo.ServerMOTD, "@nl@", chr(10)));
		response.Subst("ServerMOTDColor", class'WebAdminUtils'.static.ColorToHTMLColor(gameinfo.ServerMOTDColor));
		response.Subst("WebLink", gameinfo.WebSiteLink);
		response.Subst("WebLinkColor", class'WebAdminUtils'.static.ColorToHTMLColor(gameinfo.WebLinkColor));
	}
	else {
		response.Subst("BannerLink", class'KFGameInfo'.default.BannerLink);
		response.Subst("ClanMotto", repl(class'KFGameInfo'.default.ClanMotto, "@nl@", chr(10)));
		response.Subst("ClanMottoColor", class'WebAdminUtils'.static.ColorToHTMLColor(class'KFGameInfo'.default.ClanMottoColor));
		response.Subst("ServerMOTD", repl(class'KFGameInfo'.default.ServerMOTD, "@nl@", chr(10)));
		response.Subst("ServerMOTDColor", class'WebAdminUtils'.static.ColorToHTMLColor(class'KFGameInfo'.default.ServerMOTDColor));
		response.Subst("WebLink", class'KFGameInfo'.default.WebSiteLink);
		response.Subst("WebLinkColor", class'WebAdminUtils'.static.ColorToHTMLColor(class'KFGameInfo'.default.WebLinkColor));
	}
}

`else
function advInitSettings(WorldInfo worldinfo, DataStoreCache dscache);
function cleanupSettings();
function bool advSaveSettings(WebRequest request, WebAdminMessages messages);
function advRenderSettings(WebResponse response, SettingsRenderer renderer, optional string substName = "settings", optional ISettingsPrivileges privileges);
`endif

defaultProperties
{

}