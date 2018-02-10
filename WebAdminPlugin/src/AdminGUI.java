import java.util.ArrayList;

import javafx.application.Application;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.layout.GridPane;
import javafx.stage.Stage;

public class AdminGUI extends LoginGUI {

	public void showAdminGUI() {
		Stage primaryStage = new Stage();
		GridPane grid = new GridPane();
		
		grid.setAlignment(Pos.CENTER);
		grid.setHgap(10);
		grid.setVgap(10);
		grid.setPadding(new Insets(25, 25, 25, 25));
		
		Label lbl_error = new Label();
		Label lbl_errorMsg = new Label();
		grid.add(lbl_error, 0, 6);
		grid.add(lbl_errorMsg, 1, 6);
		
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

		Button btn = new Button();
		grid.add(btn, 1, 5);
		btn.setText("Submit Credentials");
		
		tf_username.setText("admin");
		tf_password.setText("cody_test_pass");
		tf_url.setText("http://deliveryboys.game.nfoservers.com:8080/ServerAdmin/");
		
		btn.setOnAction(new EventHandler<ActionEvent>() {
			@Override
			public void handle(ActionEvent event){}
		});

		Scene scene = new Scene(grid, 600, 400);
		primaryStage.setTitle("KF2 WebAdmin Plugin " + Test.getVersion());
		primaryStage.setScene(scene);
		primaryStage.show();
	}
	
}
