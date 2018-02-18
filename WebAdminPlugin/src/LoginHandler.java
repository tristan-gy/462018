import java.io.IOException;
import java.util.HashMap;

import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class LoginHandler {
	private static String baseURL = "none";
	private static String errorMsg = "";
	private static boolean loginSuccess;
	private static Document home;
	private static HashMap<String, String> sessionCookies;
	private static HashMap<String, String> userCredentials;
	private static HashMap<String, String> basicServerInformation;
	
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
				baseURL = URL;
				sessionCookies = cookies;
				userCredentials = loginDetails;
				home = homeDoc;
				basicServerInformation = parseHomePage(homeDoc);
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
	
	private static HashMap<String, String> parseHomePage(Document info){
		HashMap<String, String> ret = new HashMap<>();
		
		/* We want the information provided by two elements (class names are "section")
		 *
		 * This div will give us our server name, cheat protection, game type
		 * and mutators
		 * div class = "section"
		 * 	dl id = "currentGame"
		 *   dt Server Name
		 *    dd Delivery Boys - Long/Suicidal/HoE
		 *   dt Cheat Protection
		 *    dd On
		 *   dt Game type
		 *    dd Survival
		 *   dt Mutators
		 *    dd</dd> (none in this case)
		 *    
		 * This div will give us our difficulty and spectators
		 */
		Elements divSections = info.getElementsByClass("section");
		
		for(Element e : divSections){
			Elements dts = e.getElementsByTag("dt");
			Elements dds = e.getElementsByTag("dd");
			for(int i = 0; i < dts.size(); i++){
				ret.put(dts.get(i).text(), dds.get(i).text());
			}
		}
		return ret;
		
	}
	
	/* Getters */ 
	public static boolean loginSuccessful(){return loginSuccess;}
	
	public static String getErrorMessage(){return errorMsg;}
	
	public static Document getHome(){return home;}
	
	public static String getBaseURL(){return baseURL;}
	
	public static HashMap<String, String> getSessionCookies(){return sessionCookies;}

	public static HashMap<String, String> getUserCredentials(){return userCredentials;}
	
	public static HashMap<String, String> getBasicServerInfo(){return basicServerInformation;}
}
