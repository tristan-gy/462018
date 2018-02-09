# KF2WebAdminPlugin
The purpose of this plugin is to provide a simple GUI for extended server control (using WebAdmin) and functionality for server administrators.

Goals:
  Interact with WebAdmin
    * Automated chat messages
    * Chat polling for specific messages
      + Custom votes -- allow for admins to set up custom chat markers which can execute commands.
        - Allows users to vote for difficulty change on end of round
      + Banned words (racist terms, for example)?
    * Enhanced chat logs
      + Integrate user IP and unique ID into chat logs
    * Track general server data
      + Track which maps are played most often
      + Track where users typically play from (IP geolocation look up -- anonymize data on this scale: perform lookup on IP, record         
        location, discard IP)
  Interact with server files
    * Simple addition of maps to server (update relevant server files such that map shows in-game and in WebAdmin)
    * Read old chat logs
    * Change server settings from tool (much like the settings available in WebAdmin -- would require interacting with either WebAdmin  
      through the tool or through server files, depending on setting) 
