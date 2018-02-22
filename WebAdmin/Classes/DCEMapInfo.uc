/**
 * Cache entry for UIMapSummary
 *
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DCEMapInfo extends DataStoreCacheEntry;

var string MapName;

var UIMapSummary data;

function init(UIMapSummary source)
{
	data = source;
	if (data == none)
	{
		`warn("No UIMapSummary",,'WebAdmin');
		return;
	}
	friendlyName = ensureFriendlyName(data.DisplayName, data.MapName, string(data.name));
	description = class'WebAdminUtils'.static.getLocalized(data.Description);
	MapName = data.MapName;
}
