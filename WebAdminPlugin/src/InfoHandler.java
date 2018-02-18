import java.util.ArrayList;
import java.util.HashMap;

import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

/* This class handles getting "info" (which is the name of the GET request that WebAdmin sends periodically)
 * "info" contains the following information:
 * header
 * gamesummary (already handled in server info handler)
 * notes
 * Current Game
 * 	server name, cheat protection, game type, map, mutators
 * Rules
 * 	wave # (0/10)
 *  difficulty (suicidal)
 *  num players (0/6)
 *  minimum players to start
 *  spectators (0/2)
 *  player map voting (on/off)
 *  player kick voting (on/off)
 * Table of players (JUST THE TABLE HEADERS -- doesn't contain actual list of players)
 *  Name
 *  Perk
 *  Dosh
 *  Health
 *  Kills
 *  Ping
 *  + Table Rows - contains the player data
 *   name
 *   perk
 *   dosh
 *   health
 *   kills
 *   ping
 *    
 * Menu
 * 	All of the sidebar links
 * 
 */


public class InfoHandler extends PageHandler {

	InfoHandler(String baseURL, String subDir) {
		super(baseURL, subDir);
	}

	
	/* Server name, cheat protection, game type, map, mutators, rules,
	 * wave number, difficulty, # players, # spectators, player map voting,
	 * player kick voting */
	public HashMap<String, String> getGameSettings(){
		Document info = super.get();
		if(info == null){
			return null;
		}
		HashMap<String, String> ret = new HashMap<>();
		Elements divSections = info.getElementsByClass("section");
		
		for(Element e : divSections){
			Elements dts = e.getElementsByTag("dt");
			Elements dds = e.getElementsByTag("dd");
			for(int i = 0; i < dts.size(); i++){
				ret.put(dts.get(i).text(), dds.get(i).text());
			}
		}
		updatePlayers(info);
		return ret;
	}
	
	private void updatePlayers(Document info) {
		HashMap<String, ArrayList<String>> ret = new HashMap<>();
		
		if(!info.hasText() || info.select("#players").size() == 0){
			//return null;
		}
		
		//Elements players = info.select("#players");
		//Elements tableHeaders = players.select("th");
		//Elements evenRows = players.select(".even");
		//Elements oddRows = players.select(".odd");
		
		//Elements evenTD;
		//Elements oddTD;
		//for(Element e : evenRows){
		//	Elements td = e.getElementsByTag("td");
		//	
		//}
		
		//return ret;
	}
}
