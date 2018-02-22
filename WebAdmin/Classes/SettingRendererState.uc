/**
 * Keeps the state of a setting being rendered until it is rendered
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingRendererState extends object;

/**
 * The ID of the setting. Should not be changed.
 */
var int settingId;

/**
 * The setting name. Should not be changed.
 */
var name settingName;

/**
 * Setting type. Set by the renderer as an indication. Changing it has no effect.
 */
var string settingType;

/**
 * The mapping type of the value
 */
var EPropertyValueMappingType mappingType;

/**
 * The setting's data type
 */
var ESettingsDataType dataType;

/**
 * The name (and id) of the HTML form element. Should not be changed.
 */
var string formName;

/**
 * CSS class names used in the setting container
 */
var string cssClass;

/**
 * The description/label of the setting
 */
var string label;

/**
 * Tooltip for the setting
 */
var string tooltip;

/**
 * If false, the setting's form element is rendered disabled
 */
var bool bEnabled;

/**
 * If false, the setting will not be rendered at all.
 */
var bool bVisible;

struct KeyValue
{
	var string Key;
	var string Value;
};

/**
 * Substitution variables used for rendering the settings.
 */
var array<KeyValue> substitutions;

/**
 * Extra HTML to add after the setting. ISettingsModifier can add their
 * custom data here.
 */
var string extra;

/**
 * The current webresponse instance;
 */
var WebResponse WebResponse;

/**
 * The base path to load files from (for the WebResponse)
 */
var string path;

/**
 * Reset to the base values
 */
function reset()
{
	settingId = 0;
	settingName = '';
	settingType = "";
	formName = "";
	cssClass = "";
	label = "";
	tooltip = "";
	bEnabled = true;
	bVisible = true;
	substitutions.length = 0;
	extra = "";
	dataType = SDT_Empty;
	mappingType = PVMT_RawValue;
}

function subst(string key, coerce string value)
{
	local int idx;
	idx = substitutions.find('Key', key);
	if (idx == INDEX_NONE)
	{
		idx = substitutions.length;
		substitutions.length = idx+1;
		substitutions[idx].Key = key;
	}
	substitutions[idx].Value = value;
}

function string getSubst(string key)
{
	local int idx;
	idx = substitutions.find('Key', key);
	if (idx == INDEX_NONE)
	{
		return "";
	}
	return substitutions[idx].Value;
}
