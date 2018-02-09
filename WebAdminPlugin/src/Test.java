import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.*;

import org.jsoup.*;
import org.jsoup.Connection.Response;
import org.jsoup.nodes.Document;
import org.jsoup.select.Elements;

public class Test {

	public static void main(String[] args) throws Exception {
		LoginHandler lh = new LoginHandler();
		AdminGUI gui = new AdminGUI();
		gui.initializeLoginGUI(lh);
		
		
		
	}
}
