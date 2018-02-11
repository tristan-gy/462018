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
import javafx.stage.WindowEvent;

public class GUIHandler extends Application {
	private LoginGUI loginGUI;
	private AdminGUI adminGUI;
	private Scene loginScene;
	private Scene adminScene;
	
	@Override
	public void start(Stage stage) throws Exception {
		stage.setTitle("KF2 WebAdmin Plugin " + Test.getVersion());
		loginGUI = new LoginGUI(stage);
		loginScene = loginGUI.getScene();
		stage.setScene(loginScene);
		stage.show();

	}
	
}
