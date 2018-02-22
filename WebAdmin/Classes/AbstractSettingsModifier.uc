/**
 * A base implementation of the ISettingsModifier interface
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class AbstractSettingsModifier extends Object implements(ISettingsModifier);

/**
 * Current setting instance being augemented. Only set when augmentation will be
 * done.
 */
var WebAdminSettings curSettings;

var class<WebAdminSettings> selectedClass;

struct ClassEntry
{
	/**
	 * The WebAdminSettings class
	 */
	var class<WebAdminSettings> settingsClass;
	/**
	 * If true it applies to the subclasses as well.
	 */
	var bool bIncludeSubclasses;
};

/**
 * Defines which classes this modifier will affecr
 */
var array<ClassEntry> modifiesClasses;


/**
 * Some meta data for settings to check
 */
struct SettingValue
{
	/**
	 * True if the value is fixed. If false, it is ranged.
	 */
	var bool bFixed;

	// the values. if bFixed=false, the first value is the minimum
	var int intVal, intValMax;
	var float floatVal, floatValMax;
	var string stringVal;

	structdefaultproperties
	{
		bFixed=true
	}
};

function bool modifierAppliesTo(WebAdminSettings settings)
{
	selectedClass = getSelectedClass(settings);
	if (selectedClass != none)
	{
		curSettings = settings;
		return true;
	}
	return false;
}

function class<WebAdminSettings> getSelectedClass(WebAdminSettings settings)
{
	local ClassEntry entry;
	local bool augmentEnabled;

	if (settings == none) return none;

	foreach modifiesClasses(entry)
	{
		if (entry.bIncludeSubclasses)
		{
			augmentEnabled = ClassIsChildOf(settings.class, entry.settingsClass);
		}
		else {
			augmentEnabled = settings.class == entry.settingsClass;
		}
		if (augmentEnabled)
		{
			return entry.settingsClass;
		}
	}
	return none;
}

function string finalizeAugmentation(WebResponse response, String path)
{
	curSettings = none;
	selectedClass = none;
	return "";
}

function augmentSetting(SettingRendererState renderState, optional int index = -1, optional bool inContainer);

function ensureSettingValues(WebAdminSettings settings);

defaultProperties
{
}
