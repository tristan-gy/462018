/**
 * This class provides the functionality to render a HTML page of a Settings
 * instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingsRenderer extends Object dependsOn(WebAdminSettings);

`include(WebAdmin.uci)

/**
 * Prefix of all include files.
 */
var protected string prefix;

/**
 * Prefix for variable names
 */
var protected string namePrefix;

/**
 * The base path to load the include files from
 */
var protected string path;

/**
 * Minimum number of options in a idMapped setting before switching to a listbox
 */
var int minOptionListSize;

struct SortedSetting
{
	var string txt;
	/** index of this item in one of the whole lists */
	var int idx;
	/** if true it's a localized setting rather than a property */
	var bool isLocalized;
};

/**
 * Settings group containg a sort list of settings.
 */
struct SettingsGroup
{
	var WebAdminSettings.SettingsGroupSpec spec;
	var array<SortedSetting> settings;
};

var array<SettingsGroup> groups;

var protected WebAdminSettings curSettings;
var protected WebResponse curResponse;

/**
 * Modifiers that will be polled to augment the settings
 */
var array<ISettingsModifier> modifiers;

/**
 * Currently active modifiers, only filled during rendering
 */
var protected array<ISettingsModifier> activeModifiers;

/**
 * Initialization when the instance is created.
 */
function init(string basePath, optional string namePre="settings_", optional string filePrefix="settings_")
{
	prefix = filePrefix;
	path = basePath;
	namePrefix = namePre;
	minOptionListSize=4;
}

function string getPath()
{
	return path;
}

function string getFilePrefix()
{
	return prefix;
}

function string getNamePrefix()
{
	return namePrefix;
}

function cleanup()
{
	curSettings = none;
	curResponse = none;
}

/**
 * Used to initialize the rendered for an IAdvWebAdminSettings instance
 */
function initEx(WebAdminSettings settings, WebResponse response)
{
	curSettings = settings;
	curResponse = response;
}

/**
 * Called after processing submitted values. Should be used to ensure some
 * settings have the correct values. This function is called stand-alone.
 */
function ensureSettingValues(WebAdminSettings settings)
{
	local int i;
	for (i = 0; i < modifiers.Length; ++i)
	{
		modifiers[i].ensureSettingValues(settings);
	}
}

/**
 * Sort all settings based on their name
 */
function sortSettings(int groupId)
{
	local int i, j;
	local SortedSetting sortset;

	groups[groupId].settings.length = 0; // clear old
	for (i = 0; i < curSettings.LocalizedSettingsMappings.length; i++)
	{
		if (curSettings.LocalizedSettingsMappings[i].Id < groups[groupId].spec.lMin) continue;
		if (curSettings.LocalizedSettingsMappings[i].Id >= groups[groupId].spec.lMax) continue;
		if (curSettings.LocalizedSettingsMappings[i].Name == '') continue;
		sortset.idx = i;
		sortset.isLocalized = true;
		sortset.txt = getLocalizedSettingText(curSettings.LocalizedSettingsMappings[i].Id);
		for (j = 0; j < groups[groupId].settings.length; j++)
		{
			if (Caps(groups[groupId].settings[j].txt) > Caps(sortset.txt))
			{
				groups[groupId].settings.Insert(j, 1);
				groups[groupId].settings[j] = sortset;
				break;
			}
		}
		if (j == groups[groupId].settings.length)
		{
			groups[groupId].settings[j] = sortset;
		}
	}
	for (i = 0; i < curSettings.PropertyMappings.length; i++)
	{
		if (curSettings.PropertyMappings[i].Id < groups[groupId].spec.pMin) continue;
		if (curSettings.PropertyMappings[i].Id >= groups[groupId].spec.pMax) continue;
		if (curSettings.PropertyMappings[i].Name == '') continue;
		sortset.idx = i;
		sortset.isLocalized = false;
		sortset.txt = getSettingText(curSettings.PropertyMappings[i].Id);
		for (j = 0; j < groups[groupId].settings.length; j++)
		{
			if (Caps(groups[groupId].settings[j].txt) > Caps(sortset.txt))
			{
				groups[groupId].settings.Insert(j, 1);
				groups[groupId].settings[j] = sortset;
				break;
			}
		}
		if (j == groups[groupId].settings.length)
		{
			groups[groupId].settings[j] = sortset;
		}
	}
}

/**
 * Creates the settings groups
 */
function createGroups()
{
	local SettingsGroup group;
	local array<SettingsGroupSpec> specs;
	local SettingsGroupSpec spec;

	groups.length = 0;
	specs = curSettings.settingGroups();
	// copy the spec to our format
	foreach specs(spec)
	{
		group.spec = spec;
		group.settings.Length = 0;
		groups.AddItem(group);
	}

	// add a dummy group
	if (groups.length == 0)
	{
		group.spec.groupId = "0";
		group.spec.pMin = 0;
		group.spec.pMax = curSettings.PropertyMappings.Length;
		group.spec.lMin = 0;
		group.spec.lMax = curSettings.LocalizedSettingsMappings.length;
		group.settings.Length = 0;
		groups.AddItem(group);
	}
}

/**
 * Render all properties of the given settings instance
 */
function render(WebAdminSettings settings, WebResponse response,
	optional string substName = "settings", optional ISettingsPrivileges privileges)
{
	local string result, entry;
	local int i;

	curSettings = settings;
	curResponse = response;

	activeModifiers.length = 0;
	for (i = 0; i < modifiers.Length; ++i)
	{
		if (modifiers[i].modifierAppliesTo(settings))
		{
			activeModifiers[activeModifiers.Length] = modifiers[i];
		}
	}

	createGroups();
	for (i = 0; i < groups.length; i++)
	{
		sortSettings(i);
	}

	if (groups.length == 1)
	{
		curResponse.Subst("settings", renderGroup(groups[0]));
		result = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "wrapper_single.inc");
	}
	else {
		result= "";
		for (i = 0; i < groups.length; i++)
		{
			if (groups[i].settings.length == 0) continue;
			if (string(int(groups[i].spec.groupId)) != groups[i].spec.groupId)
			{
				if (privileges != none)
				{
					if (!privileges.hasSettingsGroupAccess(settings.class, groups[i].spec.groupId))
					{
						continue;
					}
				}
			}
			curResponse.Subst("group.id", groups[i].spec.groupId);
			curResponse.Subst("group.title", `HTMLEscape(groups[i].spec.DisplayName));
			curResponse.Subst("group.settings", renderGroup(groups[i]));
			entry = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "group.inc");
			result $= entry;
		}
		curResponse.Subst("settings", result);
		result = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "wrapper_group.inc");
	}
	for (i = 0; i < activeModifiers.Length; ++i)
	{
		result $= activeModifiers[i].finalizeAugmentation(curResponse, path);
	}
	activeModifiers.length = 0;

	curResponse.subst(substName, result);
}

/**
 * Render a selection of settings
 */
function string renderGroup(SettingsGroup group)
{
	local string result, entry;
	local int i, j;
	local EPropertyValueMappingType mtype;
	local SettingRendererState renderState;

	renderState = new class'SettingRendererState';
	renderState.WebResponse = curResponse;
	renderState.path = path;

	for (i = 0; i < group.settings.length; i++)
	{
		renderState.reset();
		if (group.settings[i].isLocalized)
		{
			entry = renderLocalizedSetting(curSettings.LocalizedSettingsMappings[group.settings[i].idx].Id, renderState);
		}
		else {
			j = group.settings[i].idx;
			curSettings.GetPropertyMappingType(curSettings.PropertyMappings[j].Id, mtype);
			renderState.mappingType = mtype;
			defaultSubst(curSettings.PropertyMappings[j].Id, renderState);
			switch (mtype)
			{
				case PVMT_PredefinedValues:
					entry = renderPredefinedValues(curSettings.PropertyMappings[j].Id, j, renderState);
					break;
				case PVMT_Ranged:
					entry = renderRanged(curSettings.PropertyMappings[j].Id, renderState);
					break;
				case PVMT_IdMapped:
					entry = renderIdMapped(curSettings.PropertyMappings[j].Id, j, renderState);
					break;
				default:
					entry = renderRaw(curSettings.PropertyMappings[j].Id, j, renderState);
			}
		}
		if (len(entry) > 0 && renderState.bVisible)
		{
			curResponse.subst("setting.html", entry);
			result $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "entry.inc");
		}
	}
	return result;
}

/**
 * Get a readable name for the current localized property
 */
function string getLocalizedSettingText(int settingId)
{
	local string val, res, elm;
	local int i;

	val = curSettings.GetStringSettingColumnHeader(settingId);
	if (len(val) > 0) return val;

	val = string(curSettings.GetStringSettingName(settingId));
	// FooBarQuux -> Foo Bar Quux
	res = "";
 	for (i = 0; i < len(val); i++) {
 		elm = Mid(val, i, 1);
 		if (Caps(elm) == elm)
		{
			elm = " "$elm;
 		}
 		else if (i == 0 && Locs(elm) == elm && elm == "b") {
 			// skip the 'b' in 'bDoSomething'
 			continue;
 		}
 		res = res$elm;
 	}
 	return res;
}

/**
 * Render a localized property
 */
function string renderLocalizedSetting(int settingId, SettingRendererState renderState)
{
	local name propname;
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	propname = curSettings.GetStringSettingName(settingId);
	renderState.settingType = "localizedSetting";
	renderState.settingId = settingId;
	renderState.settingName = propname;
	renderState.formName = namePrefix$propname;
	renderState.label = getLocalizedSettingText(settingId);
	renderState.tooltip = Localize(string(curSettings.class.name)$" Tooltips", string(propname), string(curSettings.class.getPackageName()));

	curSettings.GetStringSettingValue(settingId, selectedValue);
	curSettings.GetStringSettingValueNames(settingId, values);
	options = "";
	if (values.length >= minOptionListSize)
	{
		for (i = 0; i < values.Length; i++)
		{
			renderState.subst("setting.option.value", values[i].id);
			renderState.subst("setting.option.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				renderState.subst("setting.option.selected", "selected=\"selected\"");
			}
			else {
				renderState.subst("setting.option.selected", "");
			}
			options $= renderSetting(renderState, "option.inc", i, true);
		}
		renderState.subst("setting.options", options);
		return renderSetting(renderState, "select.inc");
	}
	else {
		for (i = 0; i < values.Length; i++)
		{
			renderState.subst("setting.radio.index", i);
			renderState.subst("setting.radio.value", values[i].id);
			renderState.subst("setting.radio.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				renderState.subst("setting.radio.selected", "checked=\"checked\"");
			}
			else {
				renderState.subst("setting.radio.selected", "");
			}
			options $= renderSetting(renderState, "radio.inc", i);
		}
		return options;
	}
}

/**
 * Get a name for the current setting property.
 */
function string getSettingText(int settingId)
{
	local string val, res, elm;
	local int i;

	val = curSettings.GetPropertyColumnHeader(settingId);
	if (len(val) > 0) return val;
	val = string(curSettings.GetPropertyName(settingId));

	// FooBarQuux -> Foo Bar Quux
	res = "";
 	for (i = 0; i < len(val); i++) {
 		elm = Mid(val, i, 1);
 		if (Caps(elm) == elm && string(int(elm)) != elm)
		{
			elm = " "$elm;
 		}
 		else if (i == 0 && Locs(elm) == elm && elm == "b") {
 			// skip the 'b' in 'bDoSomething'
 			continue;
 		}
 		res = res$elm;
 	}
 	return res;
}

/**
 * Set the default substitution parts for the current property
 * @return true when the setting should be rendered
 */
function defaultSubst(int settingId, SettingRendererState renderState)
{
	local name propname;

	propname = curSettings.GetPropertyName(settingId);
	renderState.settingId = settingId;
	renderState.settingName = propname;
	renderState.formName = namePrefix$propname;
	renderState.label = getSettingText(settingId);
	renderState.tooltip = Localize(string(curSettings.class.name)$" Tooltips", string(propname), string(curSettings.class.getPackageName()));
	renderState.dataType = curSettings.GetPropertyType(settingId);
}

function string renderPredefinedValues(int settingId, int idx, SettingRendererState renderState)
{
	local string options, selectedValue, part1, part2, valDesc;
	local int i, j;
	local array<SettingsData> values;

	local bool usedPreDef, selected;
	local string svalue;
	local int ivalue;
	local float fvalue;

	renderState.settingType = "predefinedValues";

	selectedValue = curSettings.GetPropertyAsString(settingId);
	values = curSettings.PropertyMappings[idx].PredefinedValues;
	usedPreDef = false;

	for (i = 0; i < values.Length; i++)
	{
		valDesc = "";
		for (j = 0; j < curSettings.PropertyMappings[idx].ValueMappings.Length; j++) {
			if (curSettings.PropertyMappings[idx].ValueMappings[j].Id == i) {
				valDesc = string(curSettings.PropertyMappings[idx].ValueMappings[j].name);
			}
		}

		switch (values[i].Type)
		{
			case SDT_Int32:
			case SDT_Int64:
				ivalue = curSettings.GetSettingsDataInt(values[i]);
				renderState.subst("setting.option.value", string(ivalue));
				if (len(valDesc) == 0) {
					renderState.subst("setting.option.text", string(ivalue));
				}
				else {
					renderState.subst("setting.option.text", valDesc);
				}
				selected = (ivalue == int(selectedValue));
				break;
			case SDT_Double:
			case SDT_Float:
				fvalue = curSettings.GetFloatPredefinedValues(curSettings.PropertyMappings[idx].Id, i);
				renderState.subst("setting.option.value", string(fvalue));
				if (len(valDesc) == 0) {
					renderState.subst("setting.option.text", string(fvalue));
				}
				else {
					renderState.subst("setting.option.text", valDesc);
				}
				selected = (fvalue ~= float(selectedValue));
				break;
			case SDT_String:
				svalue = curSettings.GetStringPredefinedValues(curSettings.PropertyMappings[idx].Id, i);
				renderState.subst("setting.option.value", `HTMLEscape(svalue));
				if (len(valDesc) == 0) {
					renderState.subst("setting.option.text", `HTMLEscape(svalue));
				}
				else {
					renderState.subst("setting.option.text", valDesc);
				}
				selected = (svalue ~= selectedValue);
				break;
			default:
				`Log("Unsupported data type "$values[i].Type$" for setting id "$settingId,,'WebAdmin');
				return "";
		}
		if (selected)
		{
			usedPreDef = true;
			renderState.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			renderState.subst("setting.option.selected", "");
		}
		options $= renderSetting(renderState, "option.inc", i, true);
	}
	curResponse.subst("setting.options", options);

	if (!usedPreDef) {
		renderState.formName = namePrefix$curSettings.GetPropertyName(settingId)$"_pre";
	}
	part1 = renderSetting(renderState, "select.inc");
	if (usedPreDef) {
		renderState.formName = namePrefix$curSettings.GetPropertyName(settingId)$"_raw";
	}
	else {
		renderState.formName = namePrefix$curSettings.GetPropertyName(settingId);
	}
	part2 = renderRaw(settingId, idx, renderState);

	renderState.subst("multisetting.predef", part1);
	renderState.subst("multisetting.raw", part2);
	renderState.formName = namePrefix$curSettings.GetPropertyName(settingId);

	renderState.settingType = "predefinedValuesContainer";
	renderState.subst("multisetting.predef.class", usedPreDef?"":"settingsraw");
	renderState.subst("multisetting.rawval.class", usedPreDef?"settingsraw":"");
	return renderSetting(renderState, "multisetting.inc");
}

function string renderRanged(int settingId, SettingRendererState renderState)
{
	local float value, min, max, incr;
	local byte asInt;

	renderState.settingType = "ranged";

	curSettings.GetRangedPropertyValue(settingId, value);
	curSettings.GetPropertyRange(settingId, min, max, incr, asInt);

	if (asInt != 1)
	{
		renderState.subst("setting.value", string(value));
		renderState.subst("setting.minval", string(min));
		renderState.subst("setting.maxval", string(max));
		renderState.subst("setting.increment", string(incr));
		renderState.subst("setting.asint", "false");
	}
	else {
		renderState.subst("setting.value", string(int(value)));
		renderState.subst("setting.minval", string(int(min)));
		renderState.subst("setting.maxval", string(int(max)));
		renderState.subst("setting.increment", string(int(incr)));
		renderState.subst("setting.asint", "true");
	}

	return renderSetting(renderState, "ranged.inc");
}

function string renderIdMapped(int settingId, int idx, SettingRendererState renderState)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	renderState.settingType = "idMapped";

	curSettings.GetIntProperty(settingId, selectedValue);
	values = curSettings.PropertyMappings[idx].ValueMappings;
	if (values.length >= minOptionListSize)
	{
		for (i = 0; i < values.Length; i++)
		{
			renderState.subst("setting.option.value", values[i].id);
			renderState.subst("setting.option.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				renderState.subst("setting.option.selected", "selected=\"selected\"");
			}
			else {
				renderState.subst("setting.option.selected", "");
			}
			options $= renderSetting(renderState, "option.inc", i, true);
		}
		renderState.subst("setting.options", options);
		return renderSetting(renderState, "select.inc");
	}
	else {
		for (i = 0; i < values.Length; i++)
		{
			renderState.subst("setting.radio.index", i);
			renderState.subst("setting.radio.value", values[i].id);
			renderState.subst("setting.radio.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				renderState.subst("setting.radio.selected", "checked=\"checked\"");
			}
			else {
				renderState.subst("setting.radio.selected", "");
			}
			options $= renderSetting(renderState, "radio.inc", i);
		}
		return options;
	}
}

function string renderRaw(int settingId, int idx, SettingRendererState renderState)
{
	local float min, max, incr;
	renderState.settingType = "raw";
	renderState.subst("setting.value", `HTMLEscape(curSettings.GetPropertyAsString(settingId)));

	min = curSettings.PropertyMappings[idx].MinVal;
	max = curSettings.PropertyMappings[idx].MaxVal;
	incr = curSettings.PropertyMappings[idx].RangeIncrement;
	switch(curSettings.GetPropertyType(settingId))
	{
		case SDT_Empty:
			return  "";
		case SDT_Int32:
		case SDT_Int64:
			if (max != 0)
			{
				renderState.subst("setting.maxval", int(max));
				renderState.subst("setting.minval", int(min));
			}
			else {
				renderState.subst("setting.maxval", "Number.NaN");
				renderState.subst("setting.minval", "Number.NaN");
			}
			if (incr > 0)
			{
				renderState.subst("setting.increment", string(int(incr)));
			}
			renderState.subst("setting.asint", "true");
			return renderSetting(renderState, "int.inc");
		case SDT_Double:
		case SDT_Float:
			if (max != 0)
			{
				renderState.subst("setting.maxval", max);
				renderState.subst("setting.minval", min);
			}
			else {
				renderState.subst("setting.maxval", "Number.NaN");
				renderState.subst("setting.minval", "Number.NaN");
			}
			if (incr > 0)
			{
				renderState.subst("setting.increment", string(incr));
			}
			renderState.subst("setting.asint", "false");
			return renderSetting(renderState, "float.inc");
		default:
			if (max != 0)
			{
				renderState.subst("setting.maxval", max);
				renderState.subst("setting.minval", min);
			}
			else {
				renderState.subst("setting.maxval", "Number.NaN");
				renderState.subst("setting.minval", "Number.NaN");
			}
			if (max > 0 && max > min)
			{
				renderState.subst("setting.maxlength", int(max));
			}
			else {
				renderState.subst("setting.maxlength", "");
			}
			if (max > 256)
			{
				return renderSetting(renderState, "textarea.inc");
			}
			else {
				return renderSetting(renderState, "string.inc");
			}
	}
}

function string renderSetting(SettingRendererState renderState, string filename,
	optional int index = -1, optional bool inContainer)
{
	local int i;
	for (i = 0; i < activeModifiers.length; ++i)
	{
		activeModifiers[i].augmentSetting(renderState, index, inContainer);
	}

	for (i = 0; i < renderState.substitutions.length; ++i)
	{
		curResponse.subst(renderState.substitutions[i].Key, renderState.substitutions[i].Value);
	}

	curResponse.subst("setting.type", renderState.settingType);
	curResponse.subst("setting.id", string(renderState.settingId));
	curResponse.subst("setting.name", renderState.settingName);
	curResponse.subst("setting.formname", renderState.formName);
	curResponse.subst("setting.text", `HTMLEscape(renderState.label));
	curResponse.subst("setting.tooltip", `HTMLEscape(renderState.tooltip));
	curResponse.subst("setting.enabled", renderState.bEnabled?"":"disabled=\"disabled\"");
	curResponse.subst("setting.augmented", renderState.extra);
	curResponse.subst("setting.css", renderState.cssClass);

	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ filename);
}

defaultproperties
{
	minOptionListSize=4
}
