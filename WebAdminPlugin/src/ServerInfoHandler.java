import java.util.HashMap;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class ServerInfoHandler extends PageHandler {

	private String currentMap;
	
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

	public HashMap<String, String> getServerState(){
		HashMap<String, String> ret = new HashMap<>();
		HashMap<String, String> params = new HashMap<>();
		params.put("ajax", "1");
		Document unparsed = super.post(params);
		if(unparsed == null){
			return null;
		}
		//System.out.println("updating from serverinfohandler " + System.currentTimeMillis());
		//html = html.replace("<!--// <![CDATA[", "");
		//html = html.replace("// ]]> -->", "");
		String html = unparsed.toString();
		html = Jsoup.parse(html).html();
		Document info = Jsoup.parse(html);

		for (Element e : info.select("gamesummary")) {
			String unescapedHTML = e.text();
			Document parsed = Jsoup.parse(unescapedHTML);

			Elements dts = parsed.getElementsByTag("dt");
			Elements dds = parsed.getElementsByTag("dd");
			for (int i = 0; i < dts.size(); i++) {
				ret.put(dts.get(i).className() + "_dt", dts.get(i).text());
				ret.put(dds.get(i).className() + "_dd", dds.get(i).text());
			}
		}
		currentMap = ret.get("gs_map_dt");
		return ret;
	}
	
	public String getCurrentMap(){
		return currentMap;
	}
	
}
