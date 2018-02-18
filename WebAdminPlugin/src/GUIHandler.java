import java.util.HashMap;

import javafx.application.Application;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.Scene;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.scene.Group;
import javafx.scene.control.SingleSelectionModel;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TextArea;
import javafx.scene.layout.BorderPane;


public class GUIHandler extends Application {
	/* Set the size of our window to about 1/3 of the screen size */
	private final double screenX = Screen.getPrimary().getVisualBounds().getWidth();
	private final double screenY = Screen.getPrimary().getVisualBounds().getHeight();
	private final double scaleX = .30;
	private final double scaleY = .30;
	private final double prefX = screenX*scaleX;
	private final double prefY = screenY*scaleY;
	
	/* Used to keep track of current map -- used to know what type of data we need to request */
	private String currentMap = "";
	
	/* Handles server get/send requests */
	private ChatHandler chatHandler;
	private ServerInfoHandler serverInfoHandler; //should be used on map changes
	private InfoHandler infoHandler;
	
	/* Specific GUI elements (tabs in our case) */
	private LoginGUI loginGUI;
	private ChatGUI chatGUI;
	private ServerInfoGUI siGUI;
	private PlayerGUI playerGUI;
	
	/* JavaFX objects */
	private Scene scene;
	private Group root;
	private BorderPane mainPane;
	private TabPane tabPane;
	
	private Tab loginTab;
	private Tab chatTab;
	private Tab serverInfoTab;
	private Tab playerTab;
	
	/* Thread which requests periodic updates from server */
	private Thread updateThread; 
	
	
	@Override
	public void start(Stage stage) throws Exception {
		stage.setTitle("KF2 WebAdmin Plugin " + Test.getVersion());

		root = new Group();
		tabPane = new TabPane();

		SingleSelectionModel<Tab> tabSelectionModel = tabPane.getSelectionModel();
		mainPane = new BorderPane();
		scene = new Scene(root, prefX, prefY);
		
		loginGUI = new LoginGUI(stage, prefX, prefY);

		loginTab = loginGUI.getTab();
		loginTab.setText("Login");
		tabPane.getTabs().add(loginTab);
		
		updateThread = new Thread(new updateThread(instance()));
		updateThread.setDaemon(true); //links thread to application and when we close our application, the thread shuts down as well
		loginGUI.getProperty().addListener(new ChangeListener<Boolean>() {
			@Override
			public void changed(ObservableValue<? extends Boolean> observable, Boolean oldValue, Boolean newValue){
				if(newValue){ //if we have logged in (as reported by LoginGUI)
					/* Initialize our ChatHandler to pass to our ChatGUI */
					chatHandler = new ChatHandler(LoginHandler.getBaseURL(), "current/chat+frame+data");
					infoHandler = new InfoHandler(LoginHandler.getBaseURL(), "current/info"); //this should be called every time the map changes
					serverInfoHandler = new ServerInfoHandler(LoginHandler.getBaseURL(), "current+gamesummary");

					/* Initialize our other tabs with our login information */
					initTabs(stage);
					
					/* Select new tab and close login tab -- we don't need it again */
					tabSelectionModel.select(serverInfoTab);
					tabPane.getTabs().remove(loginTab);
					
					/* Start watching for updates from server */
					updateThread.start();
				}
			}
		});
		
		mainPane.setCenter(tabPane);
		mainPane.prefHeightProperty().bind(scene.heightProperty());
		mainPane.prefWidthProperty().bind(scene.widthProperty());
		
		root.getChildren().add(mainPane);
		stage.setMinWidth(prefX);
		stage.setMinHeight(prefY);
		stage.setScene(scene);
		stage.show();
	}
	
	private GUIHandler instance() {
		return this;
	}

	//second arg: ArrayList<String> serverData
	public void updateGUI(String chatData, HashMap<String, String> serverInfo, HashMap<String, String> serverStateData){	
		if(serverStateData != null){
			siGUI.updateLabels(null, serverStateData);
			
			/* If we've changed maps, we need to update our current map and infohandler */
			if(!this.currentMap.equals(serverInfoHandler.getCurrentMap())){
				this.currentMap = serverInfoHandler.getCurrentMap();
			}
		}

		/* If we've changed maps */
		if(serverInfo != null){
			siGUI.updateLabels(serverInfo, serverStateData);
		}
		
		if(chatData != null){
			TextArea chat = (TextArea) chatGUI.getNodes().get(0); //chatbox
			chat.appendText(chatData);
		}
	}
	
	private void initTabs(Stage stage){
		/* Init server info tab */
		siGUI = new ServerInfoGUI();
		serverInfoTab = siGUI.getTab();
		serverInfoTab.setText("Server Info");
		tabPane.getTabs().add(serverInfoTab);
		
		/* Init chat tab */
		chatGUI = new ChatGUI(stage, chatHandler);
		chatTab = chatGUI.getTab();
		chatTab.setText("Chat");
		tabPane.getTabs().add(chatTab);
		
		/* Init player tab */
		playerGUI = new PlayerGUI();
		playerTab = playerGUI.getTab();
		playerTab.setText("Players");
		tabPane.getTabs().add(playerTab);
	}
	
	public ChatHandler getChatHandler(){
		return chatHandler;
	}
	
	public ServerInfoHandler getServerInfoHandler(){
		return serverInfoHandler;
	}
	
	public InfoHandler getInfoHandler(){
		return infoHandler;
	}
	
	public String getCurrentMap(){
		return currentMap;
	}
}
