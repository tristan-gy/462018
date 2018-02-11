import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

public abstract class PageHandler {

	private String baseURL;
	private String subDir;

	PageHandler(String baseURL, String subDir){
		this.baseURL = baseURL;
		this.subDir = subDir;
	}
	
	public Document post(String params){
		String USER_AGENT = "Mozilla/5.0";
		HashMap<String, String> cookies = LoginHandler.getSessionCookies();
		HashMap<String, String> formData = new HashMap<>();
		formData.clear();
		formData.put(baseURL+subDir, params);
		
		try { 
			Connection.Response page = Jsoup.connect(baseURL + subDir)
					.cookies(cookies)
					.data(formData)
					.method(Connection.Method.POST)
					.userAgent(USER_AGENT)
					.execute();
				return page.parse();
			}
			catch(IOException e) { //if literally anything goes wrong
				System.out.println("POST failed: " + e.getMessage());
				return null;
			}
	}
	
}
