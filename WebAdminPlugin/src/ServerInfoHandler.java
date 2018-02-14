import java.util.ArrayList;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class ServerInfoHandler extends PageHandler {

	ServerInfoHandler(String baseURL, String subDir) {
		super(baseURL, subDir);
	}

	/* current+gamesummary
	 * <response>
	 *  <gamesummary><![CDATA[
	 *   <div class="gs_mapimage"><img src="/images/maps/KF-INFERNALREALM.jpg" alt="KF-INFERNALREALM"/></div>
     *    <dl class="gs_details">
     *     <dt class="gs_map">Map</dt>
     *     <dd class="gs_map">Infernal Realm</dd>
     *     <dt class="gs_players">Players</dt>
     *     <dd class="gs_players">0/6</dd>
     *     <dt class="gs_wave">Wave 0</dt> WAVE NUMBER
     *     <dd class="gs_wave">0/0</dd> ZEDS KILLING/ZEDS TOTAL
     *    </dl>]]>
     *  </gamesummary>
     * </response>
Text: <div class="gs_mapimage"><img src="/images/maps/KF-ZEDLANDING.jpg" alt="KF-ZEDLANDING"/></div> <dl class="gs_details"> <dt class="gs_map">Map</dt> <dd class="gs_map">Zed Landing</dd> <dt class="gs_players">Players</dt> <dd class="gs_players">0/6</dd> <dt class="gs_wave">Wave 0</dt> <dd class="gs_wave">0/0</dd> </dl>
	 */
	public ArrayList<String> getInfo(){
		HashMap<String, String> params = new HashMap<>();
		params.put("ajax", "1");
		StringBuilder msg = new StringBuilder();
		Document info = super.post(params);
		ArrayList<String> data = new ArrayList<>();
		try {
			String map, players, wave_num, wave_remaining;
			//String regex = "([A-Z0-9])\\w*";
			//([A-Z0-9\/][^d>])\w*
			//String regex = "(?<=\\>)(.*?)(?=\\<)";
			String regex = "[^<>]+(?=[<])";
			Pattern pattern = Pattern.compile(regex);
			Matcher matcher = pattern.matcher(info.text());
		
			while(matcher.find()){
				if(matcher.group().length() == 1){
					continue;
				}
				if(matcher.group().length() == 2){
					continue;
				}
				if(matcher.group().equals("Map") || matcher.group().equals("Players")){
					continue;
				} else {
					data.add(matcher.group());
				}
			}
			return data;
			
				//the format of messages sent via teamchat is different
		} catch (Exception e){
			return null;
		}
		
	}
	
}
