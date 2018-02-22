/**
 * A administrator record
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class MultiAdminData extends Object perobjectconfig config(MultiAdmin);

`include(WebAdmin.uci)

/**
 * The name to show. It does not have to be the same as the login name.
 */
var config string DisplayName;

/**
 * The password for this user
 */
var private config string Password;

/**
 * Which list to process first
 */
enum EAccessOrder
{
	DenyAllow,
	AllowDeny,
};

/**
 * Sets the order in which the allow and deny options should be processed
 */
var config EAccessOrder Order;

/**
 * URL segments to allow or deny. An empty list means "all".
 */
var config array<string> Allow, Deny;

/**
 * if true this account is enabled
 */
var config bool bEnabled;

var array<string> cacheDenied;
var array<string> cacheAllowed;

/**
 * return the display name
 */
function string getDisplayName()
{
	if (len(DisplayName) == 0)
	{
		return string(name);
	}
	return DisplayName;
}

function setPassword(string pw)
{
	if (len(pw) > 0)
	{
		Password = pw;
	}
}

/**
 * return true when the password matches
 */
function bool matchesPassword(string pw)
{
	if (!bEnabled) return false;
	if (len(password) == 40) // sha1 hash
	{
		return (Caps(Password) == Caps(pw));
	}
	return (Password == pw) && (len(pw) > 0);
}

/**
 * Return true if this user can access this location. This is just the path part
 * not the full uri as the IWebAdminUser gets.
 */
function bool canAccess(string loc)
{
	local bool retval;
	if (!bEnabled) return false;
	if (cacheAllowed.find(loc) != INDEX_NONE) {
		return true;
	}
	if (cacheDenied.find(loc) != INDEX_NONE) {
		return false;
	}
	retval = internalCanAccess(loc);
	if (retval) {
		cacheAllowed.addItem(loc);
	}
	else {
		cacheDenied.addItem(loc);
	}
	return retval;
}

protected function bool internalCanAccess(string loc)
{
	if (Order == DenyAllow)
	{
		if (matchDenied(loc))
		{
			if (!matchAllowed(loc)) return false;
		}
		return true;
	}
	else if (Order == AllowDeny)
	{
		if (matchAllowed(loc)) return true;
		if (matchDenied(loc)) return false;
		return false;
	}
	return true;
}

/**
 * True if the uri matches any entry
 */
function bool matchAllowed(string loc)
{
	local string m;
	foreach Allow(m)
	{
		if (class'WebAdminUtils'.static.maskedCompare(loc, m, true))
		{
			return true;
		}
	}
	return false;
}

/**
 * True if the uri matches any denied entry
 */
function bool matchDenied(string loc)
{
	local string m;
	foreach Deny(m)
	{
		if (class'WebAdminUtils'.static.maskedCompare(loc, m, true))
		{
			return true;
		}
	}
	return false;
}

function clearAuthCache()
{
    cacheDenied.length = 0;
    cacheAllowed.length = 0;
}

defaultproperties
{
}
