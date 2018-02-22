/**
 * Cache entry for KFMutatorSummary
 *
 * Copyright (C) 2011,2014 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DCEMutator extends DataStoreCacheEntry;

var string ClassName;

var KFMutatorSummary data;

function init(KFMutatorSummary source)
{
	data = source;
	if (data == none)
	{
		`warn("No UIMutatorSummary",,'WebAdmin');
		return;
	}
	friendlyName = ensureFriendlyName(data.FriendlyName, data.ClassName, string(data.name));
	description = class'WebAdminUtils'.static.getLocalized(data.Description);
	ClassName = data.ClassName;
}
