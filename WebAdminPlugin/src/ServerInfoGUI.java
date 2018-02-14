import java.util.ArrayList;

import javafx.event.EventHandler;
import javafx.geometry.Insets;
import javafx.geometry.Orientation;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.Tab;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.GridPane;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;

public class ServerInfoGUI extends GUIHandler implements InterfaceGUI {

	private ArrayList<Node> infoNodes = new ArrayList<Node>();
	
	@Override
	public Tab getTab() {
		Tab t = new Tab();
		GridPane grid = new GridPane();
		
		//grid.setAlignment(Pos.CENTER);
		grid.setHgap(15);
		grid.setVgap(5);
		grid.setPadding(new Insets(25, 25, 25, 25));
		ColumnConstraints col1 = new ColumnConstraints();
		col1.setPercentWidth(20);
		ColumnConstraints col2 = new ColumnConstraints();
		col2.setPercentWidth(80);
		grid.getColumnConstraints().addAll(col1, col2);
		//grid.setGridLinesVisible(true);
		
		Label map = new Label("Map: ");
		map.setFont(Font.font("Open Sans", FontWeight.SEMI_BOLD, 14));
		Label map_data = new Label();
		grid.add(map, 0, 0);
		grid.add(map_data, 0, 1);
		
		Label player = new Label("Players: ");
		player.setFont(Font.font("Open Sans", FontWeight.SEMI_BOLD, 14));
		Label player_data = new Label();
		grid.add(player, 0, 2);
		grid.add(player_data, 0, 3);
		
		Label waveTop = new Label("Wave:");
		waveTop.setFont(Font.font("Open Sans", FontWeight.SEMI_BOLD, 14));
		Label wave = new Label();
		Label wave_data = new Label();
		grid.add(waveTop, 0, 4);
		grid.add(wave, 0, 5);
		grid.add(wave_data, 0, 6);
		
		infoNodes.add(map_data);
		infoNodes.add(player_data);
		infoNodes.add(wave);
		infoNodes.add(wave_data);
		t.setContent(grid);
		return t;
	}

	@Override
	public ArrayList<Node> getNodes() {
		return infoNodes;
	}

}
