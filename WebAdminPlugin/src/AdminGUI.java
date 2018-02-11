import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.HPos;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.RowConstraints;
import javafx.stage.Stage;
import javafx.util.Duration;

public class AdminGUI extends GUIHandler {

	private ChatHandler chatHandler;
	private Stage primaryStage;
	private Scene myScene;
	
	public AdminGUI(Stage primaryStage){
		chatHandler = new ChatHandler(LoginHandler.getBaseURL(), "current/chat+frame+data");
		this.primaryStage = primaryStage;
		getScene();
	}
	
	public Scene getScene() {
		//Stage primaryStage = new Stage();
		GridPane grid = new GridPane();
		
		grid.setAlignment(Pos.CENTER);
		grid.setHgap(15);
		grid.setVgap(15);
		grid.setPadding(new Insets(25, 25, 25, 25));
		ColumnConstraints col1 = new ColumnConstraints();
		col1.setPercentWidth(25);
		ColumnConstraints col2 = new ColumnConstraints();
		col2.setPercentWidth(75);
		grid.getColumnConstraints().addAll(col1, col2);
		grid.setGridLinesVisible(true);
		
		
		Label chat = new Label("Chat:");

		TextArea tf_chat = new TextArea();
		tf_chat.setEditable(false);
		tf_chat.setWrapText(true);
		grid.add(tf_chat, 1, 1);
		
		TextField tf_sendChat = new TextField();
		grid.add(tf_sendChat, 1, 2);
		Label sendChat = new Label("Send message:");
		grid.add(sendChat, 0, 2);
		
		Button btn = new Button();
		//grid.add(btn, 1, 0);
		btn.setText("Update Chat");
		grid.addRow(0, chat, btn);
		btn.setOnAction(new EventHandler<ActionEvent>() {
			@Override
			public void handle(ActionEvent event){
				tf_chat.appendText(chatHandler.getChat());
			}
		});
		
		tf_sendChat.setOnKeyPressed(new EventHandler<KeyEvent>() {
			@Override
			public void handle(KeyEvent event){
				if(event.getCode().equals(KeyCode.ENTER)) {
					System.out.println(tf_sendChat.getText());
					chatHandler.sendChat(tf_sendChat.getText());
				}
			}
		});
		
		
/*		Timeline chatUpdate = new Timeline(
			new KeyFrame(Duration.seconds(5), e -> {
					System.out.println("updating chat...");
					tf_chat.appendText(chatHandler.getChat());
			})
		);
		chatUpdate.setCycleCount(-1);
		chatUpdate.play();
*/
		myScene = new Scene(grid, 600, 400);
		return myScene;
		//primaryStage.setTitle("KF2 WebAdmin Plugin " + Test.getVersion());
		//primaryStage.setScene(scene);
		//primaryStage.show();
	}
	
}
