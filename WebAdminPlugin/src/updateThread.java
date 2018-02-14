import java.util.TimerTask;

import javafx.application.Platform;

public class updateThread extends TimerTask implements Runnable {
	private long updateFreq = 5000; //in milliseconds
	private GUIHandler gh;
	
	updateThread(GUIHandler g){
		gh = g;
	}
	
	@Override
	public void run() {
		while(true){
			Platform.runLater(() -> gh.updateGUI());
			try { 
				Thread.sleep(updateFreq);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
	
}
