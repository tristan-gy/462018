/**
 * The main entry point for the Red Orchestra 2 WebAdmin. This manages
 * the initial web page request and authentication and session handling.
 * The eventual processing of the request will be done by query handlers.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdmin extends WebApplication dependsOn(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)

/**
 * The menu handler
 */
var WebAdminMenu menu;

/**
 * The authorization handler instance
 */
var IWebAdminAuth auth;

/**
 * Defines the authentication handler class to use instead of the default one.
 */
var globalconfig string AuthenticationClass;

/**
 * The default authentication class
 */
var class/*<IWebAdminAuth>*/ defaultAuthClass;

/**
 * The session handler
 */
var ISessionHandler sessions;

/**
 * The session handler to use instead of the default session handler
 */
var globalconfig string SessionHandlerClass;

/**
 * The default session handler class
 */
var class/*<ISessionHandler>*/ defaultSessClass;

/**
 * The loaded handlers.
 */
var array<IQueryHandler> handlers;

/**
 * The list of query handlers to automativally load
 */
var globalconfig array<string> QueryHandlers;

/**
 * If set to true, use HTTP Basic authentication rather than a HTML form. Using
 * HTTP authentication gives the functionality of automatic re-authentication.
 */
var globalconfig bool bHttpAuth;

/**
 * The starting page. Defaults to /current
 */
var globalconfig string startpage;

/**
 * local storage. Used to construct the auth URLs.
 */
var protected string serverIp;

`if(`isdefined(COOKIE_PREFIX))
/**
 * Prefix used in cookie names to make them safer for multiple servers on the
 * same machine.
 */
var string cookiePrefix;
`endif

/**
 * DataStoreCache class to use, should be a subclass of DataStoreCache
 */
var globalconfig string DataStoreCacheClass;

/**
 * Default datastorecache class to use
 */
var class/*<DataStoreCache>*/ defaultDataStoreCacheClass;

/**
 * Cached datastore values
 */
var DataStoreCache dataStoreCache;

/**
 * If true start the chatlogging functionality
 */
var globalconfig bool bChatLog;

/**
 * A hack to cleanup the stale PlayerController instances which are not being
 * garbage collected but stay around due to the streaming level loading.
 */
var PCCleanUp pccleanup;

/**
 * Used to keep track of config file updated to make sure certain changes are
 * made. The dedicated server doesn't automatically merge updated config files.
 */
var globalconfig int cfgver;

/**
 * If true pages will be served as application/xhtml+xml when the browser
 * supports it, and when the QH claims it supports it.
 */
var globalconfig bool bUseStrictContentType;

var array<WebAdminSkin> Skins;

var string SkinData;

/**
 * Number of octets in the IPv4 to validate for the session. for example, a
 * value of 3 allows the IP to be between x.y.z.0-x.y.z.255 . A value of 0
 * disables validation. Values higher than 4 are useless (because of IPv4).
 */
var globalconfig int sessionOctetValidation;


//!localization
var localized string menuLogout, menuLogoutDesc, AccessDenied, msgNoPrivs,
	msgNoStartPage, msgLogoutNotice, msgUnableToLogout, error404, msgNotFound,
	msgSessionCreateFail, msgWrongAuthCookie, error403, error401, pageLogin,
	pageLoginDesc, pageAboutTitle, pageAboutDesc, msgUnknownDataType, msgInvalidToken,
	msgMaxLoginTries;

/**
 * Defines a subdirectory who's files will override the standard files. Used for
 * localized files.
 */
var localized string HTMLSubDirectory;

/**
 * Used to hash passwords
 */
var HashLib hashLib;

struct FailedAuthRecord
{
	var string ip;
	var int count;
	var string lastUpdate;
};

var array<FailedAuthRecord> authFails;

var globalconfig int MaxAuthFails;

function init()
{
	local class/*<IWebAdminAuth>*/ authClass;
	local class/*<ISessionHandler>*/ sessClass;
	local class/*<DataStoreCache>*/ dscClass;
	local class<Actor> aclass;
	local IpAddr ipaddress;
	local int i;
	local bool doSaveConfig;

    `Log("Starting Killing Floor 2 WebAdmin...",,'WebAdmin');

    doSaveConfig = false;

    CleanupMsgSpecs();

    `if(`WITH_WEBCONX_FIX)
	WebServer.AcceptClass = class'WebConnectionEx';
    `endif

	if (class'WebConnection'.default.MaxValueLength < 4096)
	{
		class'WebConnection'.default.MaxValueLength = 4096;
		class'WebConnection'.static.StaticSaveConfig();
	}

	super.init();

	if (QueryHandlers.length == 0)
	{
		QueryHandlers[0] = class.getPackageName()$".QHCurrentKF";
		QueryHandlers[1] = class.getPackageName()$".QHDefaultsKF";
		QueryHandlers[3] = class.getPackageName()$".WebAdminSystemSettings";
		doSaveConfig = true;
	}

	if (MaxAuthFails == 0)
	{
		MaxAuthFails = 5;
	}

	if (doSaveConfig)
	{
		SaveConfig();
	}

	if (len(DataStoreCacheClass) != 0)
	{
		dscClass = class(DynamicLoadObject(DataStoreCacheClass, class'Class'));
	}
	if (dscClass == none)
	{
		dscClass = defaultDataStoreCacheClass;
	}
	dataStoreCache = DataStoreCache(new(Self) dscClass);

	menu = new(Self) class'WebAdminMenu';
	menu.webadmin = self;
	menu.addMenu("/about", "", none,, MaxInt-1);
	menu.addMenu("/data", "", none,, MaxInt-1);
	menu.addMenu("/logout", menuLogout, none, menuLogoutDesc, MaxInt);

	if (len(AuthenticationClass) != 0)
	{
		authClass = class(DynamicLoadObject(AuthenticationClass, class'Class'));
	}
	if (authClass == none)
	{
		authClass = defaultAuthClass;
	}

	`Log("Creating IWebAdminAuth instance from: "$authClass,,'WebAdmin');
	if (!ClassIsChildOf(authClass, class'Actor'))
	{
		auth = new(self) authClass;
	}
	else {
		aclass = class<Actor>(DynamicLoadObject(""$authClass, class'Class'));
		auth = Worldinfo.spawn(aclass);
	}
	auth.init(Worldinfo);

    hashLib = new class'Sha1HashLib';
    if (!auth.supportHashAlgorithm(hashLib.getAlgName()))
	{
		`Log(""$authClass$" does not support hash algorithm "$hashLib.getAlgName(),,'WebAdmin');
		hashLib = none;
    }

	if (len(SessionHandlerClass) != 0)
	{
		sessClass = class(DynamicLoadObject(SessionHandlerClass, class'class'));
	}
	if (sessClass == none)
	{
		sessClass = defaultSessClass;
	}

	`Log("Creating ISessionHandler instance from: "$sessClass,,'WebAdmin');
	if (!ClassIsChildOf(sessClass, class'Actor'))
	{
		sessions = new(self) sessClass;
	}
	else {
		aclass = class<Actor>(DynamicLoadObject(""$sessClass, class'Class'));
		sessions = Worldinfo.spawn(aclass);
	}

	WebServer.GetLocalIP(ipaddress);
	serverIp = WebServer.IpAddrToString(ipaddress);
	i = InStr(serverIp, ":");
	if (i > INDEX_NONE)
	{
		serverIp = left(serverIp, i);
	}

	`if(`isdefined(COOKIE_PREFIX))
	cookiePrefix = "_"$worldinfo.Game.GetServerPort()$"_";
	`endif

	initQueryHandlers();
}

function loadWebAdminSkins()
{
//FIXME
/*	local int i;
	local array<ROUIResourceDataProvider> ProviderList;

	class'ROUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'WebAdminSkin', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		Skins[i] = WebAdminSkin(ProviderList[i]);
	}*/
}

function CreateChatLog()
{
	if (bChatLog)
	{
		WorldInfo.Spawn(class'ChatLog');
	}
}

function CleanupMsgSpecs()
{
	WorldInfo.Spawn(class'PCCleanUp');
}

/**
 * Clean up the webapplication and everything associated with it.
 */
function CleanupApp()
{
	local IQueryHandler handler;
	foreach handlers(handler)
	{
		handler.cleanup();
	}
	handlers.Remove(0, handlers.Length);
	menu.menu.Remove(0, menu.menu.length);
	menu = none;
	auth.cleanup();
	auth = none;
	sessions.destroyAll();
	sessions = none;
	dataStoreCache.cleanup();
	dataStoreCache = none;
	super.CleanupApp();
}

/**
 * Load the registered query handlers
 */
protected function initQueryHandlers()
{
	local IQueryHandler qh;
	local string entry;
	local class/*<IQueryHandler>*/ qhc;
	local class<Actor> aclass;

	foreach QueryHandlers(entry)
	{
		qhc = class(DynamicLoadObject(entry, class'class'));
		if (qhc == none)
		{
			`Log("Unable to find query handler class: "$entry,,'WebAdmin');
			continue;
		}
		qh = none;
		if (!ClassIsChildOf(qhc, class'Actor'))
		{
			qh = new(self) qhc;
		}
		else {
			aclass = class<Actor>(DynamicLoadObject(""$qhc, class'Class'));
			qh = Worldinfo.spawn(aclass);
		}
		if (qh == none)
		{
			`Log("Unable to create query handler: "$entry,,'WebAdmin');
		}
		else {
			addQueryHandler(qh);
		}
	}
}

/**
 * Add a query handler to the list. This will also call init() and
 * registerMenuItems() on the query handler.
 */
function addQueryHandler(IQueryHandler qh)
{
	if (handlers.find(qh) != INDEX_NONE)
	{
		return;
	}
	qh.init(self);
	qh.registerMenuItems(menu);
	handlers.addItem(qh);
}

/**
 * return the authentication URL string used in the user privileged system.
 */
function string getAuthURL(string forpath)
{
	if (Left(forpath, 1) != "/") forpath = "/"$forpath;
	return "webadmin://"$ serverIp $":"$ WebServer.CurrentListenPort $ forpath;
}

/**
 * Main entry point for the webadmin
 */
function Query(WebRequest Request, WebResponse Response)
{
	local WebAdminQuery currentQuery;
	local WebAdminMenu wamenu;
	local IQueryHandler handler;
	local string title, description;
	local bool acceptsXhtmlXml;
	local int i;

	response.Subst("webadmin.path", path);
	response.Subst("page.uri", Request.URI);
	response.Subst("page.fulluri", Path$Request.URI);
	response.Subst("random", Rand(MaxInt));

	if (len(SkinData) == 0)
	{
		if (skins.length == 0)
		{
			loadWebAdminSkins();
		}
		for (i = 0; i < Skins.length; i++)
		{
			response.Subst("webadminskin.name", `HTMLEscape(Skins[i].name));
			response.Subst("webadminskin.friendlyname", `HTMLEscape(Skins[i].FriendlyName));
			response.Subst("webadminskin.cssfile", `HTMLEscape(Skins[i].cssfile));
			SkinData $= response.LoadParsedUHTM(Path $ "/webadminskin_meta.inc");
		}
		if (skins.length == 0)
		{
			SkinData $= " ";
		}
	}
	response.Subst("webadminskins.meta", SkinData);

	if (InStr(Request.GetHeader("accept-encoding")$",", "gzip,") != INDEX_NONE)
	{
		if (InStr(Request.GetHeader("user-agent"), "Safari/") != INDEX_NONE)
		{
			// Safari lies, it doesn't support gzip encoded files
			response.Subst("client.gzip", "");
		}
		else if (InStr(Request.GetHeader("user-agent"), "MSIE 6.") != INDEX_NONE)
		{
			// MSIE 6. has issues with gzip
			response.Subst("client.gzip", "");
		}
		else {
			response.Subst("client.gzip", ".gz");
		}
	}
	else {
		response.Subst("client.gzip", "");
	}

	if (InStr(Request.GetHeader("accept"), "application/xhtml+xml") != INDEX_NONE)
	{
		acceptsXhtmlXml = bUseStrictContentType;
	}

	if (WorldInfo.IsInSeamlessTravel())
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		response.HTTPResponse("HTTP/1.1 503 Service Unavailable");
		response.subst("html.headers", "<meta http-equiv=\"refresh\" content=\"10\"/>");
		response.IncludeUHTM(Path $ "/servertravel.html");
		response.ClearSubst();
		return;
	}

	currentQuery.request = Request;
	currentQuery.response = Response;
	parseCookies(Request.GetHeader("cookie", ""), currentQuery.cookies);

	if (!getSession(currentQuery))
	{
		return;
	}

	if (len(pageAboutTitle) == 0)
	{
		addMessage(currentQuery, "No localization data. Please make sure the file Localization/INT/WebAdmin.int is up to date.", MT_Error);
	}

	if (!getWebAdminUser(currentQuery))
	{
		return;
	}
	response.Subst("admin.name", currentQuery.user.getUsername());

	wamenu = WebAdminMenu(currentQuery.session.getObject("WebAdminMenu"));
	if (wamenu == none)
	{
		wamenu = menu.getUserMenu(currentQuery.user);
		if (wamenu != none)
		{
			currentQuery.session.putObject("WebAdminMenu", wamenu);
			currentQuery.session.putString("WebAdminMenu.rendered", wamenu.render());
		}
	}
	if (wamenu == none)
	{
		Response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(currentQuery, msgNoPrivs, AccessDenied);
		return;
	}
	response.Subst("navigation.menu", currentQuery.session.getString("WebAdminMenu.rendered"));

	currentQuery.user.clearCheckedPrivileges();

	if (request.URI == "/")
	{
		if (len(startpage) != 0)
		{
			Response.Redirect(path$startpage);
			return;
		}
		pageGenericError(currentQuery, msgNoStartPage);
		return;
	}
	else if (request.URI == "/logout")
	{
		if (auth.logout(currentQuery.user))
		{
			sessions.destroy(currentQuery.session);
			//response.headers[response.headers.length] = "Set-Cookie: sessionid=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "sessionid", "", path, 0);
			//response.headers[response.headers.length] = "Set-Cookie: authcred=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "authcred", "", path, 0);
			//response.headers[response.headers.length] = "Set-Cookie: authtimeout=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "authtimeout", "", path, 0);
			if (bHttpAuth)
			{
				response.Subst("navigation.menu", "");
				//response.headers[response.headers.length] = "Set-Cookie: forceAuthentication=1; Path="$path$"/";
				sendCookie(currentQuery, "forceAuthentication", "1", path);
				addMessage(currentQuery, msgLogoutNotice, MT_Warning);
				pageGenericInfo(currentQuery, "");
				return;
			}
			Response.Redirect(path$"/");
			return;
		}
		pageGenericError(currentQuery, msgUnableToLogout);
		return;
	}
	else if (request.URI == "/about")
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		pageAbout(currentQuery);
		return;
	}
	else if (request.URI == "/data")
	{
		pageData(currentQuery);
		return;
	}

	// get proper handler
	handler = wamenu.getHandlerFor(request.URI, title, description);
	if (handler != none)
	{
		if (acceptsXhtmlXml && handler.producesXhtml()) response.AddHeader("Content-Type: application/xhtml+xml");
		response.Subst("page.title", title);
		response.Subst("page.description", description);
		if (handler.handleQuery(currentQuery))
		{
			return;
		}
	}

	if (currentQuery.user.canPerform(getAuthURL(request.URI))) {
		// try other way
		foreach handlers(handler)
		{
			if (handler.unhandledQuery(currentQuery))
			{
				return;
			}
		}
	}

	// check with the overal menu, if the handler is null the page doesn't exist
	if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
	if (menu.getHandlerFor(request.URI, title, description) == none)
	{
		Response.HTTPResponse("HTTP/1.1 404 Not Found");
		pageGenericError(currentQuery, msgNotFound, error404);
	}
	else {
		Response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(currentQuery, msgNoPrivs, AccessDenied);
	}
}

/**
 * Parse the cookie HTTP header
 */
protected function parseCookies(String cookiehdr, out array<KeyValuePair> cookies)
{
	local array<string> cookieParts;
	local string entry;
	local int pos;
	local KeyValuePair kvp;

	`if(`isdefined(COOKIE_PREFIX))
	local string prefix;
	local int pfpos;
	`endif

	ParseStringIntoArray(cookiehdr, cookieParts, ";", true);
	foreach cookieParts(entry)
	{
		pos = InStr(entry, "=");
		if (pos > INDEX_NONE)
		{
			kvp.key = Left(entry, pos);
			kvp.key -= " ";
			`if(`isdefined(COOKIE_PREFIX))
			if (left(kvp.key, 1) == "%")
			{
				// check prefix
				pfpos = InStr(kvp.key, "_");
				if (pfpos != INDEX_NONE)
				{
					prefix = mid(kvp.key, 1, pfpos-1);
					if (prefix == string(int(prefix)))
					{
						if (left(kvp.key, len(cookiePrefix)) != cookiePrefix)
						{
							continue;
						}
						kvp.key = mid(kvp.key, len(cookiePrefix));
						pfpos = cookies.Find('key', kvp.key);
						if (pfpos != INDEX_NONE)
						{
							cookies.remove(pfpos, 1);
						}
					}
				}
			}
			`endif
			kvp.value = Mid(entry, pos+1);
			if (left(kvp.value, 1) == "\"")
            {
                // unquote
                kvp.value = repl(mid(kvp.value, 1, len(kvp.value) - 2), "\\\"", "\"");
            }
			//`Log("Received cookie with name="$kvp.key$" ; value="$kvp.value,,'WebAdmin');
			cookies.AddItem(kvp);
		}
	}
}

/**
 * Send a cookie to the client. Returns true when the cookie was included in
 * the output. If the headers where already send false will be returned.
 */
function bool sendCookie(out WebAdminQuery q, string key, coerce string value,
	optional string cpath = "", optional int maxage = -1, optional string domain = "")
{
	local string cookie;
	if (q.response.SentText()) return false;
	key = `trim(key);
	if (len(key) == 0) return false;
	`if(`isdefined(COOKIE_PREFIX))
	key = cookiePrefix$key; // add prefix
	`endif
	cookie = "Set-Cookie: "$key$"=\""$repl(value, "\"", "\\\"")$"\"";
	if (len(cpath) > 0)
	{
		if (right(cpath, 1) != "/") cpath $= "/";
		cookie $= "; path="$cpath;
	}
	if (len(domain) > 0)
	{
		cookie $= "; domain="$domain;
	}
	if (maxage > -1)
	{
		cookie $= "; expires=\""$class'WebAdminUtils'.static.convertToRfc2109Date(q.response.GetHTTPExpiration(maxage))$"\"";
		cookie $= "; max-age="$maxage;
	}
	q.response.headers[q.response.headers.length] = cookie;
	//`log(cookie,,'WebAdmin');
	return true;
}

/**
 * Adds the ISession instance to query
 */
protected function bool getSession(out WebAdminQuery q)
{
	local string sessionId;
	local int idx;

	idx = q.cookies.Find('key', "sessionid");
	if (idx > INDEX_NONE)
	{
		sessionId = q.cookies[idx].value;
	}
	if (len(sessionId) == 0)
	{
		sessionId = q.request.GetVariable("sessionid");
	}
	if (len(sessionId) > 0)
	{
		q.session = sessions.get(sessionId);
		if (q.session != none && sessionOctetValidation > 0)
		{
			validateSessionOctet(q);
		}
	}
	if (q.session == none)
	{
		q.session = sessions.create();
		idx = inStr(q.request.RemoteAddr, ":");
		if (idx == INDEX_NONE) idx = len(q.request.RemoteAddr);
		q.session.putString("AuthIP", Left(q.request.RemoteAddr, idx));
		//q.response.headers[q.response.headers.length] = "Set-Cookie: sessionid="$q.session.getId()$"; Path="$path$"/";
		sendCookie(q, "sessionid", q.session.getId(), path);
	}
	if (q.session == none)
	{
		pageGenericError(q, msgSessionCreateFail);
		return false;
	}
	q.response.Subst("sessionid", q.session.getId());
	return true;
}

protected function validateSessionOctet(out WebAdminQuery q)
{
	local array<string> ip1, ip2;
	local int i;
	i = inStr(q.request.RemoteAddr, ":");
	if (i == INDEX_NONE) i = len(q.request.RemoteAddr);
	ParseStringIntoArray(Left(q.request.RemoteAddr, i), ip1, ".", false);
	ParseStringIntoArray(q.session.getString("AuthIP", "0.0.0.0"), ip2, ".", false);
	ip1.length = sessionOctetValidation;
	ip2.length = sessionOctetValidation;
	for (i = 0; i < ip1.length; ++i)
	{
		if (int(ip1[i]) != int(ip2[i]))
		{
			q.session = none;
			break;
		}
	}
}

/**
 * Retreives the webadmin user. Creates a new one when needed.
 */
protected function bool getWebAdminUser(out WebAdminQuery q)
{
	local string username, password, token, errorMsg, rememberCookie, hashAlgName;
	local int idx;
	local bool checkToken;

	local string realm;
	if (bHttpAuth)
	{
		realm = "RO2 WebAdmin - "$worldinfo.Game.GameReplicationInfo.ServerName;
		q.response.AddHeader("WWW-authenticate: basic realm=\""$realm$"\"");
		q.session.putString("UsedHttpAuth", "1");
	}

	q.user = q.session.getObject("IWebAdminUser");
	// 1: find existing user
	if (q.user != none)
	{
		if (q.session.getString("UsedHttpAuth") == "1")
		{
			// not really needed
			if (!auth.validate(q.request.Username, q.request.Password, "", errorMsg))
			{
				addMessage(q, errorMsg, MT_Error);
				pageAuthentication(q);
				return false;
			}
		}
		else {
			if (q.session.getString("AuthTimeout") == "1")
			{
				if (q.cookies.Find('key', "authcred") == INDEX_NONE)
				{
					q.session.removeString("AuthTimeout");
					q.session.removeObject("IWebAdminUser");
					auth.logout(q.user);
					q.user = none;
					addMessage(q, "Session timeout.", MT_Error);
					pageAuthentication(q);
					return false;
				}
			}
			setAuthCredCookie(q, "", -2);
		}
		return true;
	}

	idx = q.cookies.Find('key', "authcred");
	if (idx != INDEX_NONE)
	{
		rememberCookie = q.cookies[idx].value;
	}
	else {
		rememberCookie = "";
	}

	checkToken = false;

	// 2: try to authenticate
	if (len(q.request.Username) > 0 && len(q.request.Password) > 0)
	{
		username = q.request.Username;
		password = q.request.Password;
		if (bHttpAuth)
		{
			idx = q.cookies.Find('key', "forceAuthentication");
			if (idx != INDEX_NONE && q.cookies[idx].value == "1")
			{
				//q.response.headers[q.response.headers.length] = "Set-Cookie: forceAuthentication=; Path="$path$"/; Max-Age=0";
				sendCookie(q, "forceAuthentication", "", path, 0);
				pageAuthentication(q);
				return false;
			}
		}
	}
	else if (len(rememberCookie) > 0)
	{
		username = q.request.DecodeBase64(rememberCookie);
		idx = InStr(username, Chr(10));
		if (idx != INDEX_NONE)
		{
			password = Mid(username, idx+1);
			username = Left(username, idx);
		}
		else {
			username = "";
		}
	}

	// not set, check request variables
	if (len(username) == 0 || len(password) == 0)
	{
		username = q.request.GetVariable("username");
		password = q.request.GetVariable("password_hash");
		if (len(password) == 0) password = q.request.GetVariable("password");
		token = q.request.GetVariable("token");
		checkToken = true;
	}

	// request authentication
	if (len(username) == 0 || len(password) == 0)
	{
		pageAuthentication(q);
		return false;
	}

	// check data
	if (checkToken && (len(token) == 0 || token != q.session.getString("AuthFormToken")))
	{
		addMessage(q, msgInvalidToken, MT_Error);
		pageAuthentication(q);
		return false;
	}

	if (Left(password, 1) == "$")
	{
		idx = InStr(password, "$",,, 1);
		if (idx != INDEX_NONE)
		{
			hashAlgName = mid(password, 1, idx-1);
			password = mid(password, idx+1);
		}
	}

	if (exceededAuthFail(q, username))
	{
		q.response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(q, msgMaxLoginTries);
		return false;
	}

	q.user = auth.authenticate(username, password, hashAlgName, errorMsg);

	if (q.user == none)
	{
		recordAuthFail(q, username);

		addMessage(q, errorMsg, MT_Error);
		if (len(rememberCookie) > 0)
		{
			// unset cookie
			//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred=; Path="$path$"/; Max-Age=0";
			sendCookie(q, "authcred", "", path, 0);
			//q.response.headers[q.response.headers.length] = "Set-Cookie: authtimeout=; Path="$path$"/; Max-Age=0";
			sendCookie(q, "authtimeout", "", path, 0);
			addMessage(q, msgWrongAuthCookie, MT_Error);
			rememberCookie = "";
		}
		pageAuthentication(q);
		return false;
	}
	q.session.putObject("IWebAdminUser", q.user);
	resetAuthFail(q, username);

	if (q.request.GetVariable("remember") != "")
	{
		if (hashLib != none)
		{
			if (hashAlgName == "")
			{
				// received password wasn't hashed
				password = hashLib.getHash(password$username);
			}
			password = "$"$hashLib.getAlgName()$"$"$password;
			rememberCookie = q.request.EncodeBase64(username$chr(10)$password);
		}
		else {
			rememberCookie = q.request.EncodeBase64(username$chr(10)$password);
		}
		setAuthCredCookie(q, rememberCookie, int(q.request.GetVariable("remember")));
	}

	return true;
}

function bool exceededAuthFail(out WebAdminQuery q, string username)
{
	local int idx;
	idx = authFails.find('ip', q.request.RemoteAddr);
	if (idx != INDEX_NONE)
	{
		if (authFails[idx].count > MaxAuthFails)
		{
			return true;
		}
	}
	return false;
}

function recordAuthFail(out WebAdminQuery q, string username)
{
	local int idx;
	idx = authFails.find('ip', q.request.RemoteAddr);
	if (idx == INDEX_NONE)
	{
		idx = authFails.length;
		authFails.length = idx+1;
		authFails[idx].count = 0;
		authFails[idx].ip = q.request.RemoteAddr;
	}
	authFails[idx].count = authFails[idx].count + 1;
	authFails[idx].lastUpdate = timestamp();
}

function resetAuthFail(out WebAdminQuery q, string username)
{
	local int idx;
	idx = authFails.find('ip', q.request.RemoteAddr);
	if (idx != INDEX_NONE)
	{
		authFails.remove(idx, 1);
	}
}

/**
 * Set the cookie data to remember the current authetication attempt
 */
function setAuthCredCookie(out WebAdminQuery q, string creddata, int timeout)
{
	local int idx;
	if (timeout == -2)
	{
		idx = q.cookies.Find('key', "authtimeout");
		if (idx != INDEX_NONE)
		{
			timeout = int(q.cookies[idx].value);
		}
		else {
			timeout = 0;
		}
	}
	if (len(creddata) == 0)
	{
		idx = q.cookies.Find('key', "authcred");
		if (idx != INDEX_NONE)
		{
			creddata = q.cookies[idx].value;
		}
	}
	if (len(creddata) == 0)
	{
		return;
	}
	if (timeout > 0)
	{
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred="$creddata$"; Path="$path$"/; Max-Age="$timeout;
		sendCookie(q, "authcred", creddata, path, timeout);
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authtimeout="$timeout$"; Path="$path$"/; Max-Age="$timeout;
		sendCookie(q, "authtimeout", timeout, path, timeout);
		q.session.putString("AuthTimeout", "1");
	}
	else if (timeout == -1)
	{
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred="$creddata$"; Path="$path$"/";
		sendCookie(q, "authcred", creddata, path);
	}
	// else don't remember
}

/**
 * Get the messages stored for the current user.
 */
function WebAdminMessages getMessagesObject(WebAdminQuery q)
{
	local WebAdminMessages msgs;
	msgs = WebAdminMessages(q.session.getObject("WebAdmin.Messages"));
	if (msgs == none)
	{
		msgs = new class'WebAdminMessages';
		q.session.putObject("WebAdmin.Messages", msgs);
	}
	return msgs;
}

/**
 * Add a certain message. These messages will be processed at a later stage.
 */
function addMessage(WebAdminQuery q, string msg, optional EMessageType type = MT_Information)
{
	local WebAdminMessages msgs;
	if (len(msg) == 0) return;
	msgs = getMessagesObject(q);
	msgs.addMessage(msg, type);
}

/**
 * Render the message structure to HTML.
 */
function string renderMessages(WebAdminQuery q)
{
	local WebAdminMessages msgs;
	msgs = WebAdminMessages(q.session.getObject("WebAdmin.Messages"));
	if (msgs == none) return "";
	return msgs.renderMessages(self, q);
}

function string renderPrivilegeLog(WebAdminQuery q)
{
	local array<string> privs;
	local int i, j;
	local string tmp, entry;

	privs = q.user.getCheckedPrivileges();
	tmp = "";
	privs.InsertItem(0, getAuthURL(q.request.uri));
	for (i = 0; i < privs.length; ++i)
	{
		entry = privs[i];
		if (left(entry, 11) != "webadmin://")
		{
			continue;
		}
		j = InStr(entry, "/",,,11);
		if (j == INDEX_NONE)
		{
			continue;
		}
		entry = Mid(entry, j);
		q.response.Subst("privilege.log.entry", entry);
		tmp $= include(q, "privilege_log_entry.inc");
	}
	q.response.Subst("privilege.log", tmp);
	return include(q, "privilege_log.inc");
}

/**
 * Include the specified file.
 */
function string include(WebAdminQuery q, string file)
{
	if ((len(HTMLSubDirectory) > 0) && q.response.FileExists(Path $ "/" $ HTMLSubDirectory $ "/" $ file))
	{
		return q.response.LoadParsedUHTM(Path $ "/" $ HTMLSubDirectory $ "/" $ file);
	}
	return q.response.LoadParsedUHTM(Path $ "/" $ file);
}

function bool hasIncludeFile(WebAdminQuery q, string file)
{
	if ((len(HTMLSubDirectory) > 0) && q.response.FileExists(Path $ "/" $ HTMLSubDirectory $ "/" $ file))
	{
		return true;
	}
	return q.response.FileExists(Path $ "/" $ file);
}

/**
 * Load the given file and send it to the client.
 */
function sendPage(WebAdminQuery q, string file)
{
	local IQueryHandler handler;
	foreach handlers(handler)
	{
		handler.decoratePage(q);
	}
	q.response.Subst("messages", renderMessages(q));
	if (q.session.getString("privilege.log") != "")
	{
		q.response.Subst("privilege.log", renderPrivilegeLog(q));
	}

	if ((len(HTMLSubDirectory) > 0) && q.response.FileExists(Path $ "/" $ HTMLSubDirectory $ "/" $ file))
	{
		q.response.IncludeUHTM(Path $ "/" $ HTMLSubDirectory $ "/" $ file);
	}
	else {
		q.response.IncludeUHTM(Path $ "/" $ file);
	}
	q.response.ClearSubst();
}

/**
 * Create a generic error message.
 */
function pageGenericError(WebAdminQuery q, coerce string errorMsg, optional string title = "Error")
{
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	q.response.Subst("page.title", title);
	q.response.Subst("page.description", "");
	addMessage(q, errorMsg, MT_Error);
	sendPage(q, "message.html");
}

/**
 * Create a generic information message.
 */
function pageGenericInfo(WebAdminQuery q, coerce string msg, optional string title = "Information")
{
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	q.response.Subst("page.title", title);
	q.response.Subst("page.description", "");
	addMessage(q, msg);
	sendPage(q, "message.html");
}

/**
 * Produces the authentication page.
 */
function pageAuthentication(WebAdminQuery q)
{
	local string token;
	if (q.request.getVariable("ajax") == "1")
	{
		q.response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(q, msgNoPrivs, error403);
		return;
	}
	if (bHttpAuth)
	{
		q.response.HTTPResponse("HTTP/1.1 401 Unauthorized");
		pageGenericError(q, msgNoPrivs, error401);
		return;
	}
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	token = Right(ToHex(Rand(0xFFFF)), 4)$Right(ToHex(Rand(0xFFFF)), 4);
	q.session.putString("AuthFormToken", token);
	q.response.Subst("page.title", pageLogin);
	q.response.Subst("page.description", pageLoginDesc);
	q.response.Subst("token", token);
	if (hashLib == none)
	{
		q.response.Subst("hashalg", "");
	}
	else {
		q.response.Subst("hashalg", hashLib.getAlgName());
	}
	sendPage(q, "login.html");
}

/**
 * Show the about page
 */
function pageAbout(WebAdminQuery q)
{
	local OnlineGameSettings ogs;
	local OnlineSubsystem steamworks;

	q.response.Subst("page.title", pageAboutTitle);
	q.response.Subst("page.description", pageAboutDesc);
	q.response.Subst("engine.version", worldinfo.EngineVersion);
	q.response.Subst("engine.netversion", worldinfo.MinNetVersion);
	q.response.Subst("client.address", q.request.RemoteAddr);
	q.response.Subst("webadmin.address", serverIp$":"$WebServer.CurrentListenPort);
	if (bHttpAuth) q.response.Subst("webadmin.authmethod", "HTTP Authentication");
	else q.response.Subst("webadmin.authmethod", "Login form");
	if (q.cookies.Find('key', "authcred") > INDEX_NONE) q.response.Subst("client.remember", "True");
	else q.response.Subst("client.remember", "False");
	q.response.Subst("client.sessionid", q.session.getId());
	q.response.Subst("client.authip", q.session.getString("AuthIP"));
	q.response.Subst("client.useragent", q.request.GetHeader("user-agent"));


	if (worldinfo.game.GameInterface != none)
	{
		ogs = worldinfo.game.GameInterface.GetGameSettings(worldinfo.game.PlayerReplicationInfoClass.default.SessionName);
	}

	steamworks = class'GameEngine'.static.GetOnlineSubsystem();

	if (ogs != none)
	{
		q.response.subst("player.uniqueid", class'WebAdminUtils'.static.UniqueNetIdToString(ogs.OwningPlayerId));
		if (steamworks != none)
		{
			q.response.subst("player.steamid", `HTMLEscape(steamworks.UniqueNetIdToPlayerName(ogs.OwningPlayerId)));
		}
		else {
			q.response.subst("player.steamid", "");
		}
	}
	else {
		q.response.subst("player.uniqueid", "");
		q.response.subst("player.steamid", "");
	}

	if (steamworks != none)
	{
		q.response.subst("player.status", steamworks.GetLoginStatus(0));
		q.response.subst("engine.nattype", steamworks.GetNATType());
	}
	else {
		q.response.subst("player.status", "");
		q.response.subst("engine.nattype", "");
	}

	sendPage(q, "about.html");
}

/**
 * Generic XML data provider, could be used by AJAX calls.
 */
function pageData(WebAdminQuery q)
{
	local string tmp;
	local int i, j;

	local DCEGameInfo gametype;
	local array<DCEMapInfo> maps;
	local array<MutatorGroup> mutators;

	q.response.AddHeader("Content-Type: text/xml");
	q.response.SendText("<request>");

	tmp = q.request.getVariable("type");
	if (tmp == "gametypes") {
		dataStoreCache.loadGameTypes();
		q.response.SendText("<gametypes>");
		foreach dataStoreCache.gametypes(gametype)
	 	{
	 		q.response.SendText("<gametype>");
	 		q.response.SendText("<class>"$`HTMLEscape(gametype.data.ClassName)$"</class>");
	 		q.response.SendText("<friendlyname>"$`HTMLEscape(gametype.FriendlyName)$"</friendlyname>");
 			q.response.SendText("</gametype>");
	 	}
		q.response.SendText("</gametypes>");
	}
	else if (tmp == "maps") {
		q.response.SendText("<maps>");
		maps = dataStoreCache.getMaps(q.request.getVariable("gametype"));
 		for (i = 0; i < maps.length; i++)
 		{
 			q.response.SendText("<map>");
 			q.response.SendText("<name>"$`HTMLEscape(maps[i].MapName)$"</name>");
 			q.response.SendText("<friendlyname>"$`HTMLEscape(maps[i].FriendlyName)$"</friendlyname>");
 			q.response.SendText("</map>");
 		}
 		q.response.SendText("</maps>");
	}
	else if (tmp == "mutators") {
		mutators = dataStoreCache.getMutators(q.request.getVariable("gametype"));
 		for (i = 0; i < mutators.length; i++)
 		{
 			q.response.SendText("<mutatorGroup>");
			q.response.SendText("<name>"$`HTMLEscape(mutators[i].GroupName)$"</name>");
			q.response.SendText("<mutators>");
			for (j = 0; j < mutators[i].mutators.length; j++)
	 		{
	 			q.response.SendText("<mutator>");
	 			q.response.SendText("<class>"$`HTMLEscape(mutators[i].mutators[j].ClassName)$"</class>");
	 			q.response.SendText("<friendlyname>"$`HTMLEscape(mutators[i].mutators[j].FriendlyName)$"</friendlyname>");
	 			q.response.SendText("</mutator>");
	 		}
			q.response.SendText("</mutators>");
 			q.response.SendText("</mutatorGroup>");
 		}
	}
	else {
		addMessage(q, msgUnknownDataType@tmp, MT_Error);
	}

	q.response.SendText("<messages><![CDATA[");
	q.response.SendText(renderMessages(q));
	q.response.SendText("]]></messages>");
	q.response.SendText("</request>");
}

defaultproperties
{
	defaultAuthClass=class'BasicWebAdminAuth'
	defaultSessClass=class'SessionHandler'
	defaultDataStoreCacheClass=class'DataStoreCacheKF'
}
