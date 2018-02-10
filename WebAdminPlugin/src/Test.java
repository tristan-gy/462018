import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.*;

import javafx.application.Application;

public class Test {

	private static double versionNumber = 0.01;
	private static String baseURL;
	
	public static void main(String[] args)  throws Exception {
		if(login()){
			System.out.println("Base URL: " + baseURL);
		}

	}
	
	private static boolean login(){
		Application.launch(LoginGUI.class, "");
		LoginHandler.getSessionCookies();
		return LoginHandler.loginSuccessful();
	}
	
	public static void setBaseURL(String url){
		baseURL = url;
	}
	
	public static double getVersion(){
		return versionNumber;
	}
}
