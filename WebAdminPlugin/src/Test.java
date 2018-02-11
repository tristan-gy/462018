import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.jsoup.nodes.Document;

import java.util.*;

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
