import java.io.IOException;
import java.util.HashMap;

import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.select.Elements;

public class LoginHandler {
	private static String baseURL = "none";
	private static String errorMsg = "";
	private static boolean loginSuccess;
	private static Document home;
	private static HashMap<String, String> sessionCookies;
	private static HashMap<String, String> userCredentials;
	
	public static boolean attemptLogin(HashMap<String, String> loginDetails, String URL) throws IOException {
		return login(loginDetails, URL);
	}
	
	/* http://joelmin.blogspot.com/2016/04/how-to-login-to-website-using-jsoup-java_4.html */
	public static boolean login(HashMap<String, String> loginDetails, String URL) throws IOException {
		String USER_AGENT = "Mozilla/5.0";
		HashMap<String, String> cookies = new HashMap<>();
		try { 
			Connection.Response loginForm = Jsoup.connect(URL)
					.method(Connection.Method.GET)
					.userAgent(USER_AGENT)
					.execute();
			cookies.putAll(loginForm.cookies());
	
			Document loginDoc = loginForm.parse();
			
			String token = extractToken(loginDoc);
			
			loginDetails.put("password_hash", "");
			loginDetails.put("remember", "-1");
			loginDetails.put("token", token);

			Connection.Response homePage = Jsoup.connect(URL)
					.cookies(cookies)
					.data(loginDetails)
					.method(Connection.Method.POST)
					.userAgent(USER_AGENT)
					.execute();
			
			Document homeDoc = homePage.parse();
			if(!loginDoc.title().equals(homeDoc.title())){//if we logged in successfully to our home page
				System.out.println("Home: " + homeDoc.title());
				baseURL = URL;
				sessionCookies = cookies;
				userCredentials = loginDetails;
				home = homeDoc;
				return true;
			}
		}
		catch(IOException e) { //if literally anything goes wrong
			System.out.println("Login failed.");
			errorMsg = "error : " + e.toString();
		}
		return false;
	}
	
	/* Returns the value of our token */
	private static String extractToken(Document page){
		Elements tokenFinder = page.select("[name='token']");
		String token = null;
		if(tokenFinder.isEmpty()){
			System.out.println("Could not find token -- cannot proceed!");
			return null;
		} else if(tokenFinder.size() == 1){
			token = tokenFinder.toString();
			int tokenBegin = token.indexOf("value=\"") + 7;
			int tokenEnd = token.indexOf("\">");
			token = token.substring(tokenBegin, tokenEnd);
		} else {
			System.out.println("Something went wrong with our token capture -- cannot proceed!");
			return null;
		}
		return token;
	}
	
	private static String choiceStringToValue(String s){
		/* 0 = Until next map load
		 * -1 = Browser session
		 * 1800 = 30 minutes
		 * 3600 = 1 hour
		 * 86400 = 1 day
		 * 604800 = 1 week
		 * 2678400 = 1 month */
		String value = "-1";
		switch (s){
			case "Browser session": 
				value = "-1";
				return value;
			case "Until next map load":
				value = "0";
				return value;
			case "30 minutes":
				value = "1800";
				return value;
			case "1 hour":
				value = "3600";
				return value;
			case "1 day":
				value = "86400";
				return value;
			case "1 week":
				value = "604800";
				return value;
			case "1 month":
				value = "2678400";
				return value;
			default:
				return "-1";
		}
	}
	
	/* Getters */ 
	public static boolean loginSuccessful(){return loginSuccess;}
	
	public static String getErrorMessage(){return errorMsg;}
	
	public static Document getHome(){return home;}
	
	public static String getBaseURL(){return baseURL;}
	
	public static HashMap<String, String> getSessionCookies(){return sessionCookies;}

	public static HashMap<String, String> getUserCredentials(){return userCredentials;}
}
