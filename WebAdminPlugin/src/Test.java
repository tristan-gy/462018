import javafx.application.Application;

public class Test {

	private static double versionNumber = 0.01;
	
	public static void main(String[] args)  throws Exception {
		Application.launch(GUIHandler.class, "");
	}

	public static double getVersion(){
		return versionNumber;
	}
}
