/**
 * A SettingModifier provides the means to augment the settings as they are
 * rendered for output. This can be used to disable certain settings are provide
 * additional information.
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface ISettingsModifier;

/**
 * Called before rendering the settings. Return false if this modifier does not
 * intent to augment any settings for the given instance.
 *
 * @return true if this modifier is going to augement the output.
 */
function bool modifierAppliesTo(WebAdminSettings settings);

/**
 * Called at the end of processing the settings. Can be used to clean up local
 * state. Any returned content is added to the  rendered content.
 */
function string finalizeAugmentation(WebResponse response, String path);

/**
 * Called when a setting is being rendered.
 * @param renderState
 *		The rendering state
 * @param index
 *		The index of rendering subelements. This is higher than -1 when the setting
 *		has multiple render phases for subitems (i.e. a selection list). Note that
 *		during rendering of the subelements the renderState is not reset.
 * @param inContainer
 *		True when the subelements are within a container, which means that is an
 *		additional step (with index = -1) for rendering the container.
 */
function augmentSetting(SettingRendererState renderState, optional int index = -1, optional bool inContainer);

/**
 * Called after processing submitted values. Should be used to ensure some
 * settings have the correct values. This function is called stand-alone.
 */
function ensureSettingValues(WebAdminSettings settings);
