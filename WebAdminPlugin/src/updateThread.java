import java.util.HashMap;
import java.util.TimerTask;

import javafx.application.Platform;

public class updateThread extends TimerTask implements Runnable {
	private long updateFreq = 5000; //in milliseconds
	private long infoUpdateFreq = 10000;
	private GUIHandler gh;
	private boolean startup = true;
	
	updateThread(GUIHandler g){
		gh = g;
	}
	
	@Override
	public void run() {
		
		while(true){
			
			String chatData = gh.getChatHandler().getChat();
			HashMap<String, String> serverState = gh.getServerInfoHandler().getServerState();
			
			/* If we've just started our program or the map has changed */
			
			if(startup || !gh.getCurrentMap().equals(gh.getServerInfoHandler().getCurrentMap())){
				HashMap<String, String> gamesettings = gh.getInfoHandler().getGameSettings();
				Platform.runLater(() -> gh.updateGUI(chatData, gamesettings, serverState));
			} else {
				Platform.runLater(() -> gh.updateGUI(chatData, null, serverState));
			}

			startup = false;
			try { 

				Thread.sleep(updateFreq);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
	
}
