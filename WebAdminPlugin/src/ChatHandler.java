import java.util.HashMap;

import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

public class ChatHandler extends PageHandler {

	ChatHandler(String baseURL, String subDir) {
		super(baseURL, subDir);
	}
	
	public String getChat(){
		StringBuilder msg = new StringBuilder();
		Document chat = super.post("ajax=1");
		if(!chat.hasText() || chat.getElementsByClass("message").text().isEmpty()){
			return "";
		}
		
		/* Message format:
		 * div "chatmessage"
		 * span0 "teamcolor"
		 * span1 "username"
		 * span2 "message"
		 * </div>
		 */
		for(Element e : chat.getElementsByClass("chatmessage")){
			String username = e.getElementsByTag("span").get(1).text();
			String message = e.getElementsByTag("span").get(2).text();
			msg.append(username + ": ");
			msg.append(message + "\n");
		}
		
		return msg.toString();
	}
	
	public void sendChat(String message){
		//message.replaceAll(" ", "+");
		super.post("ajax=1&message="+message+"&teamsay=-1");
	}
	
	
	
}
