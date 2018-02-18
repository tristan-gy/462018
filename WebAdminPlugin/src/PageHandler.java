import java.io.IOException;
import java.util.HashMap;

import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

public abstract class PageHandler {

	private Document lastDocument;
	private String baseURL;
	private String subDir;
	private HashMap<String, String> sessionCookies;
	private HashMap<String, String> formData;
	private final int MAX_RETRIES = 10;
	
	PageHandler(String baseURL, String subDir){
		this.baseURL = baseURL;
		this.subDir = subDir;
		this.sessionCookies = LoginHandler.getSessionCookies();
	}
	
	public Document post(HashMap<String, String> formData){
		String USER_AGENT = "Mozilla/5.0";
		try { 
			Connection.Response page = Jsoup.connect(baseURL + subDir)
					.cookies(sessionCookies)
					.data(formData)
					.method(Connection.Method.POST)
					.userAgent(USER_AGENT)
					.execute();
			this.formData = formData;
			lastDocument = page.parse();
			return lastDocument;
		}
		catch(IOException e) { //if literally anything goes wrong
			System.out.println("POST failed: " + e.getMessage() + "...Attempting relogin.");
			relogin(formData);
			return null;
		}
	}
	
	public Document get(){
		try { 
			Connection.Response page = Jsoup.connect(baseURL + subDir)
					.cookies(sessionCookies)
					.method(Connection.Method.GET)
					.execute();
			lastDocument = page.parse();
			return lastDocument;
		}
		catch(IOException e) { //if literally anything goes wrong
			System.out.println("POST failed: " + e.getMessage() + "...Attempting relogin.");
			relogin(formData);
			return null;
		}
	}
	
	private void relogin(HashMap<String, String> formData){
		boolean loginSuccess = false;
		int retryCount = 0;
		while(!loginSuccess && retryCount < MAX_RETRIES){
			try {
				loginSuccess = LoginHandler.attemptLogin(LoginHandler.getUserCredentials(), baseURL);
				this.sessionCookies = LoginHandler.getSessionCookies();
				this.formData = formData;
			} catch (IOException e) {
				System.out.println("bad relogin");
				e.printStackTrace();
			}
		}
		if(loginSuccess){ 
			System.out.println("Reconnected to server!");
			this.post(formData);
		} else if (!loginSuccess){
			System.out.println("Failed to reconnect to server!");
		}
	}

}
