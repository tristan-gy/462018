/**
 * Interface to provide more granural privileges on settings pages.
 *
 * Copyright (C) 2011 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface ISettingsPrivileges;

/**
 * Sets the base uri to check privileges against. This is called by QHDefault
 * before settings will be rendered.
 */
function setBasePrivilegeUri(String uri);

/**
 * Check if
 */
function bool hasSettingsGroupAccess(class<WebAdminSettings> settings, string groupId);
