/**
 * Adds Killing Floor 2 specific information to current defaults handler.
 *
 * Copyright (C) 2015 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHDefaultsKF extends QHDefaults;

`include(WebAdmin.uci)

function string rewriteSettingsClassname(string pkgName, string clsName)
{
	// rewrite standard game classes to WebAdmin
	if (pkgName ~= "KFGame") pkgName = string(class.getPackageName());
	else if (pkgName ~= "KFGameContent") pkgName = string(class.getPackageName());
	return super.rewriteSettingsClassname(pkgName, clsName);
}
