import java.util.ArrayList;
import javafx.event.EventHandler;
//import javafx.geometry.HPos;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
//import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.Tab;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.GridPane;
//import javafx.scene.layout.RowConstraints;
import javafx.stage.Stage;

public class ChatGUI extends GUIHandler implements InterfaceGUI {

	private ChatHandler chatHandler;
	private ArrayList<Node> chatNodes;
	
	public ChatGUI(Stage primaryStage, ChatHandler ch){
		chatNodes = new ArrayList<>();
		this.chatHandler = ch;
	}
	
	public Tab getTab() {
		Tab t = new Tab();
		t.setClosable(false);
		GridPane grid = new GridPane();
		
		grid.setAlignment(Pos.CENTER);
		grid.setHgap(15);
		grid.setVgap(15);
		grid.setPadding(new Insets(25, 25, 25, 25));
		ColumnConstraints col1 = new ColumnConstraints();
		col1.setPercentWidth(20);
		ColumnConstraints col2 = new ColumnConstraints();
		col2.setPercentWidth(80);
		grid.getColumnConstraints().addAll(col1, col2);
		//grid.setGridLinesVisible(true);

		TextArea tf_chat = new TextArea();
		tf_chat.setEditable(false);
		tf_chat.setWrapText(true);
		grid.add(tf_chat, 1, 1);
		
		TextField tf_sendChat = new TextField();
		grid.add(tf_sendChat, 1, 2);
		Label sendChat = new Label("Send message:");
		sendChat.setWrapText(true);
		grid.add(sendChat, 0, 2);
		
		//grid.addRow(0, chat);
		
		tf_sendChat.setOnKeyPressed(new EventHandler<KeyEvent>() {
			@Override
			public void handle(KeyEvent event){
				if(event.getCode().equals(KeyCode.ENTER)) {
					String sentMessage = chatHandler.sendChat(tf_sendChat.getText());
					if(!sentMessage.equals("")){
						tf_chat.appendText(sentMessage);
						tf_sendChat.clear();
					}
				}
			}
		});
		t.setContent(grid);
		chatNodes.add(tf_chat);
		chatNodes.add(tf_sendChat);
		return t;
	}

	@Override
	public ArrayList<Node> getNodes() {
		return chatNodes;
	}
	
}
