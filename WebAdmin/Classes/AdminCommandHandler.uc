/**
 * Simulates execution of certain admin commands
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 * Copyright (C) 2015 Tripwire Interactive LLC
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class AdminCommandHandler extends Info;

`include(WebAdmin.uci)

/**
 * Returns true when it was handled
 */
function bool execute(string cmd, out string result, PlayerController pc)
{
	local int i;
	local Admin adminuser;
	local string args;

	i = InStr(cmd, " ");
	if (i != INDEX_NONE)
	{
		args = Mid(cmd, i+1);
		cmd = Left(cmd, i);
	}

	if (cmd ~= "Admin")
	{
		i = InStr(args, " ");
		if (i != INDEX_NONE)
		{
			cmd = Left(args, i);
			args = Mid(args, i+1);
		}
		else {
			cmd = args;
			args = "";
		}
	}

	if (cmd ~= "AdminChangeMap" || cmd ~= "ChangeMap")
	{
		WorldInfo.ServerTravel(cmd);
		return true;
	}
	else if (cmd ~= "AdminChangeOption")
	{
		result = "AdminChangeOption is not available";
		return true;
	}
	`if(`WITH_TEXT_MUTE)
	else if (cmd ~= "AdminForceTextMute")
	{
		result = MutePlayer(args, true, false);
		return true;
	}
	else if (cmd ~= "AdminForceTextUnMute")
	{
		result = MutePlayer(args, false, false);
		return true;
	}
	`endif
	else if (cmd ~= "AdminForceVoiceMute")
	{
		result = MutePlayer(args, true, true);
		return true;
	}
	else if (cmd ~= "AdminForceVoiceUnMute")
	{
		result = MutePlayer(args, false, true);
		return true;
	}
	else if (cmd ~= "AdminKick" || cmd ~= "Kick")
	{
		WorldInfo.Game.AccessControl.Kick(args/*, "Engine.AccessControl.KickedMsg"*/);
		return true;
	}
	else if (cmd ~= "AdminKickBan" || cmd ~= "KickBan")
	{
		WorldInfo.Game.AccessControl.KickBan(args/*, "Engine.AccessControl.KickAndPermaBan"*/);
		return true;
	}
	`if(`WITH_SESSION_BAN)
	else if (cmd ~= "AdminSessionBan" || cmd ~= "SessionBan")
	{
		if (`{AccessControl} (WorldInfo.Game.AccessControl) != none)
		{
			result = SessionBan(args, "Engine.AccessControl.KickAndSessionBan");
		}
		else {
			result = "Session banning not available with the current access control";
		}
		return true;
	}
	`endif
	else if (cmd ~= "AdminLogin")
	{
		result = "AdminLogin is not available";
		return true;
	}
	else if (cmd ~= "AdminLogOut")
	{
		result = "AdminLogOut is not available";
		return true;
	}
	else if (cmd ~= "AdminPlayerList")
	{
		result = "AdminPlayerList is not available";
		return true;
	}
	else if (cmd ~= "PlayerList")
	{
		result = "PlayerList is not available";
		return true;
	}
	else if (cmd ~= "AdminPublishMapList")
	{
		result = "AdminPublishMapList is not available";
		return true;
	}
	else if (cmd ~= "AdminRestartMap" || cmd ~= "RestartMap")
	{
		WorldInfo.ServerTravel("?restart", false);
		return true;
	}

	adminuser = Admin(pc);
	if (adminuser != none)
	{
		if (cmd ~= "KickBan")
		{
			adminuser.KickBan(args/*, "Engine.AccessControl.KickAndPermaBan"*/);
			return true;
		}
		else if (cmd ~= "Kick")
		{
			adminuser.Kick(args/*, "Engine.AccessControl.KickedMsg"*/);
			return true;
		}
		else if (cmd ~= "PlayerList")
		{
			adminuser.PlayerList();
			return true;
		}
		else if (cmd ~= "RestartMap")
		{
			adminuser.RestartMap();
			return true;
		}
		else if (cmd ~= "switch")
		{
			adminuser.switch(args);
			return true;
		}
	}

	if (adminuser.CheatManager != none)
	{
		if (cmd ~= "SloMo")
		{
			adminuser.CheatManager.SloMo(float(args));
			return true;
		}
		else if (cmd ~= "SetJumpZ")
		{
			adminuser.CheatManager.SetJumpZ(float(args));
			return true;
		}
		else if (cmd ~= "SetGravity")
		{
			adminuser.CheatManager.SetGravity(float(args));
			return true;
		}
		else if (cmd ~= "SetSpeed")
		{
			adminuser.CheatManager.SetSpeed(float(args));
			return true;
		}
	}

	return false;
}

function string MutePlayer(String TargetPlayer, bool bMute, bool bVoice)
{
	local PlayerController PC;
	local `{PlayerController} TargetPlayerPC;

	TargetPlayer -= " ";
	TargetPlayerPC = `{PlayerController} (WorldInfo.Game.AccessControl.GetControllerFromString(TargetPlayer));
	if ( TargetPlayerPC != none )
	{
		if (bVoice)
		{
			foreach WorldInfo.AllControllers(class'PlayerController', PC)
			{
				if (bMute)
				{
					PC.ServerMutePlayer(TargetPlayerPC.PlayerReplicationInfo.UniqueId);
				}
				else {
					PC.ServerUnMutePlayer(TargetPlayerPC.PlayerReplicationInfo.UniqueId);
				}
			}
		}
		else {
			`if(`WITH_TEXT_MUTE)
			TargetPlayerPC.bServerMutedText = bMute;
			`endif
		}
		return "Mute player: "$TargetPlayerPC.PlayerReplicationInfo.PlayerName$" mute="$bMute$" voice="$bVoice;
	}
	return "";
}

function string SessionBan(string TargetPlayer, optional string reason)
{
	local PlayerController TargetPlayerPC;

	TargetPlayer -= " ";
	TargetPlayerPC = PlayerController(WorldInfo.Game.AccessControl.GetControllerFromString(TargetPlayer));
	if ( TargetPlayerPC != none )
	{
		`{AccessControl} (WorldInfo.Game.AccessControl).KickSessionBanPlayer(TargetPlayerPC, TargetPlayerPC.PlayerReplicationInfo.UniqueId, "Engine.AccessControl.KickAndSessionBan");
		return TargetPlayer$" banned for this session";
	}
	return "Player "$TargetPlayer$" not found";
}
