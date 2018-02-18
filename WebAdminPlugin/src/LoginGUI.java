import java.io.IOException;
import java.util.HashMap;

import javafx.beans.property.BooleanProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.HPos;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Button;
//import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.Tab;
import javafx.scene.control.TextField;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.GridPane;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.scene.text.Text;
import javafx.stage.Stage;

public class LoginGUI extends GUIHandler { 
	
	private double prefX;
	private double prefY;
	
	private boolean loginSuccess = false;
	private HashMap<String, String> userInfo = new HashMap<>();
	
	private BooleanProperty loggedIn = new SimpleBooleanProperty();
	
	public LoginGUI(Stage primaryStage, double prefX, double prefY){
		this.prefX = prefX;
		this.prefY = prefY;
	}
	
	public Tab getTab(){
		Tab t = new Tab();
		GridPane grid = new GridPane();

		ColumnConstraints column1 = new ColumnConstraints();
		column1.setPercentWidth(25);
		ColumnConstraints column2 = new ColumnConstraints();
		column2.setPercentWidth(75);
		column2.setHalignment(HPos.LEFT);
		grid.getColumnConstraints().addAll(column1, column2);
		grid.setPrefSize(prefX, prefY);
		
		//grid.setGridLinesVisible(true);
		grid.setAlignment(Pos.CENTER);
		grid.setHgap(10);
		grid.setVgap(10);
		grid.setPadding(new Insets(25, 25, 25, 25));
		
		Label lbl_error = new Label();
		Label lbl_errorMsg = new Label();
		grid.add(lbl_error, 0, 6);
		grid.add(lbl_errorMsg, 1, 6);
		
		Text sceneTitle = new Text("Server Information");
		sceneTitle.setFont(Font.font("Tahoma", FontWeight.NORMAL, 14));
		grid.add(sceneTitle, 0, 0, 1, 1);
		
		Label server = new Label("Server URL:");
		grid.add(server, 0, 1);
		
		TextField tf_url = new TextField();
		grid.add(tf_url, 1, 1);
		
		Label username = new Label("Username:");
		grid.add(username, 0, 2);
		TextField tf_username = new TextField();
		grid.add(tf_username, 1, 2);
		
		Label password = new Label("Password:");
		grid.add(password, 0, 3);
		PasswordField tf_password = new PasswordField();
		grid.add(tf_password, 1, 3);

		Button btn = new Button();

		grid.add(btn, 1, 4);
		btn.setText("Submit Credentials");
		
		tf_username.setText("admin");
		tf_password.setText("cody_test_pass");
		tf_url.setText("http://deliveryboys.game.nfoservers.com:8080/ServerAdmin/");
		//http://deliveryboys.game.nfoservers.com:8080/ServerAdmin/
		
		btn.setOnAction(new EventHandler<ActionEvent>() {
			@Override
			public void handle(ActionEvent event){
				userInfo.clear(); //clear our userinfo every time so we don't keep adding user data if an attempt fails
				userInfo.put("username", tf_username.getText());
				userInfo.put("password", tf_password.getText());
				if(goodCredentials(userInfo)){	
					try {
						loginSuccess = LoginHandler.login(userInfo, tf_url.getText());
						if(loginSuccess){
							lbl_error.setTextFill(Color.GREEN);
							lbl_error.setText("Login successful!");
							lbl_errorMsg.setText(""); //remove any error messages we have gotten previously
							//System.out.println("Base URL: " + LoginHandler.getBaseURL());
							loggedIn.set(loginSuccess);
						} else {
							lbl_errorMsg.setText("");
							lbl_error.setTextFill(Color.RED);
							lbl_error.setText("Error:");
							lbl_errorMsg.setText(LoginHandler.getErrorMessage());
						}
					} catch (IOException e) {
						lbl_errorMsg.setText("");
						lbl_error.setTextFill(Color.RED);
						lbl_error.setText("Error:");
						lbl_errorMsg.setText(LoginHandler.getErrorMessage());
					}
				}
			}
		});

		t.setContent(grid);
		return t;
	}

	private boolean goodCredentials(HashMap<String, String> creds){
		/* username, pass */
		String username = creds.get("username");
		String password = creds.get("password");
		if(username.length() < 4){
			return false;
		}
		if(password.length() < 4){
			return false;
		}
		return true;
	}
	
	public boolean getLoginSuccess(){
		return loginSuccess;
	}
	
	public final BooleanProperty getProperty(){
		return loggedIn;
	}
	
}
