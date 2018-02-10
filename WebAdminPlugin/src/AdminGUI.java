import java.util.ArrayList;

import javafx.application.Application;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.layout.GridPane;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.scene.text.Text;
import javafx.stage.Stage;

public class AdminGUI extends Application { 
	
	//private ArrayList<String> userData;
	private boolean loginSuccess;
	//private LoginHandler lh;
	//public static LoginData ld;
	
	public void start(Stage primaryStage){
		GridPane grid = new GridPane();
		grid.setAlignment(Pos.CENTER);
		grid.setHgap(10);
		grid.setVgap(10);
		grid.setPadding(new Insets(25, 25, 25, 25));
		
		Label lbl_error = new Label();
		Label lbl_errorMsg = new Label();
		grid.add(lbl_error, 0, 6);
		grid.add(lbl_errorMsg, 1, 6);
		
		Text sceneTitle = new Text("Enter Server Information");
		sceneTitle.setFont(Font.font("Tahoma", FontWeight.NORMAL, 20));
		grid.add(sceneTitle, 0, 0, 1, 1);
		
		Label server = new Label("Server Address:");
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
		
		ChoiceBox<String> choices = new ChoiceBox<String>();
		choices.getItems().add("Browser session");
		choices.getItems().add("Until next map load");
		choices.getItems().add("30 minutes");
		choices.getItems().add("1 hour");
		choices.getItems().add("1 day");
		choices.getItems().add("1 week");
		choices.getItems().add("1 month");
		choices.getSelectionModel().selectFirst();
		
		grid.add(choices, 1, 4);
		
		Button btn = new Button();
		grid.add(btn, 1, 5);
		btn.setText("Submit Credentials");
		
		tf_username.setText("admin");
		tf_password.setText("cody_test_pass");
		tf_url.setText("http://deliveryboys.game.nfoservers.com:8080/ServerAdmin/");
		btn.setOnAction(new EventHandler<ActionEvent>() {
			@Override
			public void handle(ActionEvent event){
				if(tf_username.getText().length() > 4 && tf_password.getText().length() > 4 && tf_url.getText().length() > 5){
					
					ArrayList<String> userInfo = new ArrayList<>();
					userInfo.add(tf_url.getText());
					userInfo.add(tf_username.getText());
					userInfo.add(tf_password.getText());
					userInfo.add(choices.getSelectionModel().getSelectedItem().toString());
					
					try {
						//ld.setLoginData(userInfo);
						//loginSuccess = ld.getLoginSuccess();
						LoginHandler lh = new LoginHandler();
						lh.attemptLogin(userInfo);
						loginSuccess = lh.loginSuccessful();
						if(loginSuccess){
							lbl_error.setTextFill(Color.GREEN);
							lbl_error.setText("Login successful!");
							lbl_errorMsg.setText(""); //remove any error messages we may have gotten
							//delay_closeGUI(primaryStage);
						} else {
							lbl_error.setTextFill(Color.RED);
							lbl_error.setText("Error:");
							lbl_errorMsg.setText(lh.getErrorMessage());
						}
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			}
		});
		
		Scene scene = new Scene(grid, 400, 275);
		
		primaryStage.setTitle("KF2 WebAdmin Plugin " + Test.getVersion());
		primaryStage.setScene(scene);

		primaryStage.show();
	}
	
	//private void setUserData(ArrayList<String> data){
	//	//userData = data;
	//}
	//public ArrayList<String> getUserData(){
	//	return userData;
	//}
	
	private void delay_closeGUI(Stage stage){
		try{
			Thread.sleep(2500);
			stage.close();
		} catch (InterruptedException ex) {
			Thread.currentThread().interrupt();
		}
	}
	
}
