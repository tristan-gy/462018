import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

//import java.util.Map;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Attribute;
//import org.jsoup.Connection.Response;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public abstract class PageParser {

	private Document document;
	private Elements pageElements;
	private int numElements;
	
	private ArrayList<String> pages;
	
	//private Map<ArrayList<String>, ArrayList<String>>
	private Map<Element, ArrayList<String>> elementMap;
	
	PageParser(Document doc){
		this.document = doc;
		//this.pageElements = doc.getAllElements();
		//this.elementMap = new HashMap<Element, ArrayList<String>>();
	}
	
	public Elements getElements(){
		Elements e = document.getAllElements();
		this.numElements = e.size();
		return document.getAllElements();
	}
	
	public Document getPage(String page){
		return this.document;
	}
	
	private void elementParser(){
		ArrayList<String> properties = new ArrayList<>();
		
		for(Element e : this.getElements()){
			for(Attribute attr : e.attributes()){
				properties.add(attr.getKey());
			}
			this.elementMap.put(e, properties);
			properties.clear();
		}
	}
	
	
}
