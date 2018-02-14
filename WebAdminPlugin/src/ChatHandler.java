import java.util.HashMap;

import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

public class ChatHandler extends PageHandler {

	ChatHandler(String baseURL, String subDir) {
		super(baseURL, subDir);
	}
	
	/* 
	 * Message format:
	 * div "chatmessage"
	 * span0 "teamcolor"
	 * span1 "username"
	 * span2 "message"
	 * </div>
	 * 
	 * Team Message format:
	 * div "chatmessage"
	 * span0 "teamcolor" &#160
	 * span1 "teamnotice" (Team)
	 * span2 "username" Deliverance (could by any username)
	 * span3 "message" message content
	 * </div>
	 */
	public String getChat(){
		HashMap<String, String> params = new HashMap<>();
		params.put("ajax", "1");
		StringBuilder msg = new StringBuilder();
		Document chat = super.post(params);

		try { 
			if(!chat.hasText() || chat.getElementsByClass("message").text().isEmpty()){
				return "";
			}
			for(Element e : chat.getElementsByClass("chatmessage")){
				String username, message;
				
				//the format of messages sent via teamchat is different
				if(e.getElementsByTag("span").get(1).text().equals("(Team)")){
					String team = e.getElementsByTag("span").get(1).text();
					username = e.getElementsByTag("span").get(2).text();
					message = e.getElementsByTag("span").get(3).text();
					msg.append(team + " ");
				} else {
					username = e.getElementsByTag("span").get(1).text();
					message = e.getElementsByTag("span").get(2).text();
				}
				msg.append(username + ": ");
				msg.append(message + "\n");
			}
			return msg.toString();
		} catch (Exception e){
			return "LOST CONNECTION TO SERVER. RETRYING.\n";
		}
		
	}
	
	public String sendChat(String msg){
		StringBuilder sb = new StringBuilder();
		String username, message;
		HashMap<String, String> params = new HashMap<>();
		params.put("ajax", "1");
		params.put("message", msg);
		params.put("teamsay", "-1");
		Document chat = super.post(params);
		try {
			if(!chat.hasText() || chat.getElementsByClass("message").text().isEmpty()){
				return "";
			}
			for(Element e : chat.getElementsByClass("chatmessage")){
				username = e.getElementsByTag("span").get(1).text();
				message = e.getElementsByTag("span").get(2).text();
				sb.append(username + ": ");
				sb.append(message + "\n");
			}
			return sb.toString();
		} catch (Exception e){
			return "LOST CONNECTION TO SERVER. RETRYING.\n";
		}
	}
	
	
	
}
