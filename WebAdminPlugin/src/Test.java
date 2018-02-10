import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.*;

import javafx.application.Application;

public class Test {

	private static double versionNumber = 0.01;
	
	public static void main(String[] args)  throws Exception {
		//LoginHandler lh = new LoginHandler();
		//AdminGUI gui = new AdminGUI();
		//gui.initializeLoginGUI(lh);
		//gui.launch(args);
		Application.launch(AdminGUI.class, "");
		
		//adminGUI.lh = lgh;
	}
	
	public static double getVersion(){
		return versionNumber;
	}
}
