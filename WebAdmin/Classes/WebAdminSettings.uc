/**
 * Base class for the pluggable settings mechanism for the WebAdmin.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminSettings extends Settings abstract;

/**
 * Specification of a settings group.
 */
struct SettingsGroupSpec
{
	/**
	 * An unique id for this group
	 */
	var string groupId;

	/**
	 * Name to show as title for the group.
	 */
	var localized string DisplayName;

	/**
	 * range in the properties that belongs to this group
	 */
	var int pMin, pMax;

	/**
	 * range in the localized properties that belongs to this group
	 */
	var int lMin, lMax;
};

struct FloatPredefinedValue
{
	var int PropertyId;
	var array<float> Values;
};

struct StringPredefinedValue
{
	var int PropertyId;
	var array<string> Values;
};

/**
 * Returned by default by the settingGroups function
 */
var protected array<SettingsGroupSpec> SettingsGroups;

var protected array<FloatPredefinedValue> FloatPredefinedValues;

var protected array<StringPredefinedValue> StringPredefinedValues;

/**
 * Called by the webadmin to intialize the values for the settings.
 */
function initSettings();

/**
 * Called to provide the current gameinfo instance. If you use this (i.e. store
 * it) make sure to set it to none in cleanupSettings().
 */
function setCurrentGameInfo(GameInfo instance);

/**
 * Called by the webadmin to save the settings.
 */
function saveSettings()
{
	saveInternal();
}

/**
 * Called by the webadmin when it is being destroyed. Implement this function
 * to clean references to objects and/or actors when needed.
 */
function cleanupSettings();

/**
 * Return the groups specification. When an empty array is returned settings are
 * not grouped in any way.
 */
function array<SettingsGroupSpec> settingGroups()
{
	return SettingsGroups;
}

/**
 * Get the predefined values for a given property which uses floats
 */
function float GetFloatPredefinedValues(int PropertyId, int Index, float DefValue = 0)
{
	local int idx;
	idx = FloatPredefinedValues.Find('PropertyId', PropertyId);
	if (idx == INDEX_NONE)
	{
		`warn("GetFloatPredefinedValues("$PropertyId$", "$Index$"): no property");
		return DefValue;
	}
	if (FloatPredefinedValues[idx].Values.Length <= Index || Index < 0)
	{
		`warn("GetFloatPredefinedValues("$PropertyId$", "$Index$"): index out of bounds");
		return DefValue;
	}
	return FloatPredefinedValues[idx].values[Index];
}

/**
 * Get the predefined values for a given property which uses strings
 */
function string GetStringPredefinedValues(int PropertyId, int Index, string DefValue = "")
{
	local int idx;
	idx = StringPredefinedValues.Find('PropertyId', PropertyId);
	if (idx == INDEX_NONE)
	{
		`warn("GetStringPredefinedValues("$PropertyId$", "$Index$"): no property");
		return DefValue;
	}
	if (StringPredefinedValues[idx].Values.Length <= Index || Index < 0)
	{
		`warn("GetStringPredefinedValues("$PropertyId$", "$Index$"): index out of bounds");
		return DefValue;
	}
	return StringPredefinedValues[idx].values[Index];
}

/**
 * Called by saveSettings. This function should perform the updating of the
 * configuration
 */
protected function saveInternal();

// helper functions

protected function bool SetFloatPropertyByName(name prop, float value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetFloatProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool SetIntPropertyByName(name prop, int value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetIntProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool SetStringPropertyByName(name prop, string value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetStringProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool SetStringArrayPropertyByName(name prop, array<string> value, optional string delim = ";")
{
	local int PropertyId;
	local string realval;
	local int i;

	if (GetPropertyId(prop, PropertyId))
	{
		for (i = 0; i < value.length; i++)
		{
			if (i > 0) realval $= delim;
			realval $= value[i];
		}
		SetStringProperty(PropertyId, realval);
		return true;
	}
	return false;
}

protected function bool GetFloatPropertyByName(name prop, out float value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetFloatProperty(PropertyId, value);
	}
	return false;
}

protected function bool GetIntPropertyByName(name prop, out int value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetIntProperty(PropertyId, value);
	}
	return false;
}

protected function bool GetStringPropertyByName(name prop, out string value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetStringProperty(PropertyId, value);
	}
	return false;
}

protected function bool GetStringArrayPropertyByName(name prop, out array<string> value, optional string delim = ";")
{
	local int PropertyId;
	local string realval;
	local int i;

	if (GetPropertyId(prop, PropertyId))
	{
		if (GetStringProperty(PropertyId, realval))
		{
			value.length = 0;
			ParseStringIntoArray(realval, value, delim, true);
			for (i = 0; i < value.length; i++)
			{
				value[i] -= chr(10);
				value[i] -= chr(13);
			}
			return true;
		}
	}
	return false;
}

defaultproperties
{
}
