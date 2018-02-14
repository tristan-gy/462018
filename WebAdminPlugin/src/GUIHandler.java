import java.util.ArrayList;

import javafx.application.Application;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.Scene;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.scene.Group;
import javafx.scene.control.Label;
import javafx.scene.control.SingleSelectionModel;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TextArea;
import javafx.scene.layout.BorderPane;


public class GUIHandler extends Application {
	/* Set the size of our window to about 1/3 of the screen size */
	private final double relativeSizeX = .30;
	private final double relativeSizeY = .30;
	private final int prefX = (int)(Screen.getPrimary().getVisualBounds().getWidth()*relativeSizeX);
	private final int prefY = (int)(Screen.getPrimary().getVisualBounds().getHeight()*relativeSizeY);
	
	/* Verify we are logged in before attempting to request server data */
	private boolean loggedIn = false;
	
	/* Handles server get/send requests */
	private ChatHandler chatHandler;
	private ServerInfoHandler serverInfoHandler;
	
	/* Specific GUI elements (tabs in our case) */
	private LoginGUI loginGUI;
	private ChatGUI chatGUI;
	private ServerInfoGUI siGUI;
	
	/* JavaFX objects */
	private Scene scene;
	private TabPane tabPane;
	private BorderPane mainPane;
	private Group root;
	
	private Tab loginTab;
	private Tab chatTab;
	private Tab serverInfoTab;
	
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
					loggedIn = true;
					//System.out.println("W: " + stage.getWidth() + " H: " + stage.getHeight());
					/* Initialize our ChatHandler to pass to our ChatGUI */
					chatHandler = new ChatHandler(LoginHandler.getBaseURL(), "current/chat+frame+data");
					serverInfoHandler = new ServerInfoHandler(LoginHandler.getBaseURL(), "current+gamesummary");
					System.out.println(serverInfoHandler.getInfo());
					/* Initialize our other tabs with our login information */
					initTabs(stage);
					/* Close login tab -- we don't need it again */
					tabSelectionModel.select(chatTab);
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
		stage.setScene(scene);
		stage.show();
	}
	
	private GUIHandler instance() {
		return this;
	}

	public void updateGUI(){
		if(chatHandler.getSuccessState() && serverInfoHandler.getSuccessState()){
			TextArea chat = (TextArea) chatGUI.getNodes().get(0); //chatbox
			chat.appendText(chatHandler.getChat());
			
			ArrayList<String> serverInfo = serverInfoHandler.getInfo();
			for(int i = 0; i < siGUI.getNodes().size(); i++){
				/* map, players, wave, wave data */
				Label datapoint = (Label) siGUI.getNodes().get(i);
				datapoint.setText("\t" + serverInfo.get(i));
			}
		}
	}
	
	private void initTabs(Stage stage){
		/* Init chat tab */
		chatGUI = new ChatGUI(stage, chatHandler);
		chatTab = chatGUI.getTab();
		chatTab.setText("Chat");
		tabPane.getTabs().add(chatTab);
		
		/* Init server info tab */
		siGUI = new ServerInfoGUI();
		serverInfoTab = siGUI.getTab();
		serverInfoTab.setText("Server Info");
		tabPane.getTabs().add(serverInfoTab);
	}
	
}
