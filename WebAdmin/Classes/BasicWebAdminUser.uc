/**
 * Basic webadmin user.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class BasicWebAdminUser extends Info implements(IWebAdminUser);

var class<MessagingSpectator> PCClass;

var MessagingSpectator PC;

var int maxHistory;
var int counter;
var array<MessageEntry> msgHistory;

var array<string> checkedPrivileges;

function ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type )
{
	local int idx;
	idx = msgHistory.length;
	msgHistory.Add(1);
	msgHistory[idx].counter = ++counter;
	msgHistory[idx].Sender = Sender;
	if (Sender != none)
	{
		msgHistory[idx].senderName = Sender.PlayerName;
	}
	else {
		msgHistory[idx].senderName = "";
	}
	msgHistory[idx].message = msg;
	msgHistory[idx].type = type;
	if (Sender.Team != none)
	{
		msgHistory[idx].teamName = class'WebAdminUtils'.static.getTeamNameEx(Sender.Team);
		msgHistory[idx].teamColor = Sender.Team.TeamColor;
		msgHistory[idx].teamId = Sender.Team.TeamIndex;
	}
	else {
		msgHistory[idx].teamId = INDEX_NONE;
	}

	idx = msgHistory.Length - maxHistory;
	if (idx > 0)
	{
		msgHistory.Remove(0, idx);
	}
}

function init()
{
	local TeamChatProxy tcp;
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.AddReceiver(ReceiveMessage);
	}
}

function logout()
{
	Destroy();
}

event Destroyed()
{
	local TeamChatProxy tcp;
	if (PC != none)
	{
		PC.ClearReceiver(ReceiveMessage);
		PC = none;
	}
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.ClearReceiver(ReceiveMessage);
	}
	super.Destroyed();
}

function setUsername(string username)
{
	linkPlayerController(username);
}

/**
 * Reuse an existing MessagingSpectator with the same name.
 */
protected function linkPlayerController(string username)
{
	if (PC != none)
	{
		if (PC.PlayerReplicationInfo.PlayerName == username)
		{
			return;
		}
		PC.ClearReceiver(ReceiveMessage);
		PC = none;
	}
	foreach WorldInfo.AllControllers(class'MessagingSpectator', PC)
	{
		if (PC.IsA(PCClass.name) && PC.PlayerReplicationInfo.PlayerName == username)
		{
			PC.AddReceiver(ReceiveMessage);
			return;
		}
	}

	//`Log("Creating new MessagingSpectator",,'WebAdmin');
	PC = WorldInfo.Spawn(PCClass);
	PC.PlayerReplicationInfo.PlayerName = username;
	PC.PlayerReplicationInfo.bAdmin = true;
	PC.AddReceiver(ReceiveMessage);
}

function string getUsername()
{
	if (PC == none || PC.PlayerReplicationInfo == none) return "";
	return PC.PlayerReplicationInfo.PlayerName;
}

function string getUserid()
{
	return getUsername();
}

function PlayerController getPC()
{
	return PC;
}

function bool canPerform(string uri)
{
	addCheckedPrivileges(uri);
	// only one admin type, can perform whatever (s)he wants
	return true;
}

function addCheckedPrivileges(string uri)
{
	if (checkedPrivileges.find(uri) == INDEX_NONE)
	{
		checkedPrivileges.AddItem(uri);
	}
}

function clearCheckedPrivileges()
{
	checkedPrivileges.length = 0;
}

function array<string> getCheckedPrivileges()
{
	return checkedPrivileges;
}

function messageHistory(out array<MessageEntry> history, optional int startingFrom)
{
	local int idx, i;
	idx = msgHistory.find('counter', startingFrom);
	for (i = idx+1; i < msgHistory.Length; i++)
	{
		history.addItem(msgHistory[i]);
	}
}

// not needed
function ISettingsPrivileges getSettingsPrivileges();

defaultproperties
{
	PCClass=class'MessagingSpectator'
	maxHistory = 50
}
