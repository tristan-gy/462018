/**
 * Base class for entries in the data store cache. Used to make certain usage
 * easier and to work around some data transformation entires. It encapsulates
 * specific ROUIResourceDataProvider subclasses.
 *
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DataStoreCacheEntry extends Object abstract;

/**
 * Localized/fixed values
 */
var string FriendlyName, Description;

final static function string ensureFriendlyName(string currentValue, string className, string fallback)
{
	if (len(currentValue) != 0)
	{
		// might be a <String:...> value
		currentValue = class'WebAdminUtils'.static.getLocalized(currentValue);
	}
	// check if localized
	if (len(currentValue) != 0)
	{
		return currentValue;
	}
	currentValue = constructFriendlyName(className);
	if (len(currentValue) != 0)
	{
		return currentValue;
	}
	return fallback;
}

/**
 * Helper function to create a friendly name from a classname
 */
final static function string constructFriendlyName(String className)
{
	local int i;
	local string pkg, cls, res;

	if (len(className) == 0) return "";
	i = InStr(className, ".");
	if (i > 0)
	{
		pkg = left(className, i);
		cls = mid(className, i+1);
	}
	else {
		pkg = "";
		cls = className;
	}

	res = Localize(cls, "DisplayName", pkg);
	if (InStr(res, className$".DisplayName?") == INDEX_NONE)
	{
		if (len(res) > 0) return res;
	}

	return "";

	// FooBarQuux -> Foo Bar Quux
	/*
 	for (i = 0; i < len(cls); i++) {
 		pkg = Mid(cls, i, 1);
 		if (pkg == "_" || pkg == "-")
 		{
 			pkg = " ";
		}
		else if (Caps(pkg) == pkg && string(int(pkg)) != pkg)
		{
			pkg = " "$pkg;
 		}
 		res = res$pkg;
 	}
 	return res;
 	*/
}
