## KF2 Server Tool Description
This tool is designed to extend the base functionality of the server management tool, "WebAdmin", provided by TripWire Interactive. It provides a simple GUI with which to interact or monitor the server with great control and flexibility.

WebAdmin lacks many basic features which make server management complicated and inflexible, and attempting to implement the changes listed below without an external program requires modding core game files. Modifying core games files requires TripWire to view the mod and whitelist the files. This tool does not modify core game files and thus does not need to be whitelisted.

The tool performs all of the functions that WebAdmin does:
 - View basic server information such as server name, map, gamemode, player information, wave, difficulty, etc.
 - Change map, set server parameters such as difficulty, mutators, number of players, etc. 
 
 As previously stated, the intention of this tool is to extend the functionality greatly. These functions are listed below.

## Roadmap

 - Includes all base WebAdmin functionality
	 - Kick, ban
	 - View players and their information
	 - View map, wave #, length, difficulty
	 - Change map, length, difficulty
	 - Change number of players, add/remove mutators, allow/disallow spectators
	 - Server passwords

 - Provide server administrators with an ability to set up voting on certain server parameters using chat commands (these changes will only take affect after the server changes levels). The ability to revert to "normal" settings (as defined by the administrator) after all players leave will be available. For example, if your server typically runs on Suicidal/Survival/Medium, the server will be automatically reset to these parameters after all players leave.
	 - Vote on difficulty (Normal, Hard, Suicidal, Hell on Earth)
	 - Gamemode (Survival, Weekly, Endless, Versus)
	 - Match length (Short, Medium, Long)
 - Automated chat messages (rules, how to vote for specific settings, etc.)
 - Chat monitoring. Primary use would be for counting votes. Another use case could be banned words. 
 - All functionality regarding chat will be genericized so as to allow administrators maximum functionality and customization. This means that admins can set up specific messages to watch chat for (i.e. "!vote length long"), the percentage required to pass votes, and exactly what commands to pass to server should a vote succeed. 

 - Log server data
	- Track data about users
		- Times played on server
		- Time spent on server
		- IP geolocation
	- What maps are played, gamemodes, difficulty, etc.
	 - Extend information stored in chat logs
		 - Integrate user IP

 - Read server logs
 - Add/remove maps from server

