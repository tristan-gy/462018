import java.util.ArrayList;
import java.util.HashMap;

import javafx.geometry.Insets;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.Tab;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.GridPane;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;

public class ServerInfoGUI extends GUIHandler implements InterfaceGUI {

	/* serverInfoNodes is called about once every 10 seconds -- it contains data about 
	 * the current map, number of players, and wave data */
	//private ArrayList<Node> serverInfoNodes = new ArrayList<>();
	
	/* infoNodes is called every time we log in OR on map change -- it contains data
	 * about various server settings such as server name, mutators, difficulty, etc. */
	private HashMap<String, Node> serverState = new HashMap<>();
	private HashMap<String, Node> gameSettings = new HashMap<>();
	private ArrayList<Label> labels = new ArrayList<>();
	
	private Font header = Font.font("Open Sans", FontWeight.SEMI_BOLD, 14);
	private Insets dataInsets = new Insets(0, 0, 0, 5);
	
	@Override
	public Tab getTab() {
		Tab t = new Tab();
		t.setClosable(false);
		GridPane grid = new GridPane();
		
		//grid.setAlignment(Pos.CENTER);
		grid.setHgap(10);
		grid.setVgap(5);
		grid.setPadding(new Insets(25, 25, 25, 25));
		ColumnConstraints col1 = new ColumnConstraints();
		col1.setPercentWidth(40);
		ColumnConstraints col2 = new ColumnConstraints();
		col2.setPercentWidth(30);
		ColumnConstraints col3 = new ColumnConstraints();
		col3.setPercentWidth(30);
		grid.getColumnConstraints().addAll(col1, col2, col3);
		//grid.setGridLinesVisible(true);

		/* First column */
		Label serverName = new Label("Server Name");
		serverName.setFont(header);
		
		Label serverName_data = new Label();
		serverName_data.setWrapText(true);
		serverName_data.setPadding(dataInsets);
		
		labels.add(serverName);
		labels.add(serverName_data);
		
		/* Cheat protection */
		Label cheatProtection = new Label("Cheat Protection");
		cheatProtection.setFont(header);
		
		Label cheatProtection_data = new Label();
		cheatProtection_data.setPadding(dataInsets);
		
		labels.add(cheatProtection);
		labels.add(cheatProtection_data);
		
		/* Game type */
		Label gameType = new Label("Game Type");
		gameType.setFont(header);
		
		Label gameType_data = new Label();
		gameType_data.setPadding(dataInsets);
		
		labels.add(gameType);
		labels.add(gameType_data);
		
		/* Map */
		Label map = new Label("Map");
		map.setFont(header);
		
		Label map_data = new Label();
		map_data.setWrapText(true);
		map_data.setPadding(dataInsets);
		
		labels.add(map);
		labels.add(map_data);
		
		/* Mutators */
		Label mutators = new Label("Mutators");
		mutators.setFont(header);
		
		Label mutators_data = new Label();
		mutators_data.setWrapText(true);
		mutators_data.setPadding(dataInsets);
			
		labels.add(mutators);
		labels.add(mutators_data);
		
		/* Second column */
		/* Wave (wave = wave that we're currently on, wave_data is the #
		 * of Zeds killed/# Zeds that will spawn */
		Label wave = new Label("Wave");
		wave.setFont(header);
		
		Label wave_data = new Label();
		wave_data.setWrapText(true);
		wave_data.setPadding(dataInsets);
			
		labels.add(wave);
		labels.add(wave_data);
		
		/* Difficulty */
		Label difficulty = new Label("Difficulty");
		difficulty.setFont(header);
		
		Label difficulty_data = new Label();
		difficulty_data.setWrapText(true);
		difficulty_data.setPadding(dataInsets);
		
		labels.add(difficulty);
		labels.add(difficulty_data);
		
		/* Players */
		Label player = new Label("Players");
		player.setFont(header);
		
		Label player_data = new Label();
		player_data.setWrapText(true);
		player_data.setPadding(dataInsets);
		
		labels.add(player);
		labels.add(player_data);
		
		/* Minimum # players to start game */
		Label minToStart = new Label("Minimum to Start");
		minToStart.setFont(header);
		
		Label minToStart_data = new Label();
		minToStart_data.setPadding(dataInsets);
		
		labels.add(minToStart);
		labels.add(minToStart_data);
		
		/* Spectators */
		Label spectators = new Label("Spectators");
		spectators.setFont(header);
		
		Label spectators_data = new Label();
		spectators_data.setPadding(dataInsets);
		
		labels.add(spectators);
		labels.add(spectators_data);
		
		/* Player Map Voting */
		Label mapVoting = new Label("Player Map Voting");
		mapVoting.setFont(header);
		
		Label mapVoting_data = new Label();
		mapVoting_data.setPadding(dataInsets);
		
		labels.add(mapVoting);
		labels.add(mapVoting_data);
		
		/* Player Kick Voting */
		Label kickVoting = new Label("Player Kick Voting");
		kickVoting.setFont(header);
		
		Label kickVoting_data = new Label();
		kickVoting_data.setPadding(dataInsets);
		
		labels.add(kickVoting);
		labels.add(kickVoting_data);
		
		serverState.put("gs_map_dd", map_data);
		serverState.put("gs_players_dd", player_data);
		serverState.put("gs_wave_dt", wave);
		serverState.put("gs_wave_dd", wave_data);
		
		gameSettings.put("Server Name", serverName_data);
		gameSettings.put("Cheat Protection", cheatProtection_data);
		gameSettings.put("Game type", gameType_data);
		gameSettings.put("Mutators", mutators_data);
		gameSettings.put("Difficulty", difficulty_data);
		gameSettings.put("Minimum to Start", minToStart_data);
		gameSettings.put("Spectators", spectators_data);
		gameSettings.put("Player Map Voting", mapVoting_data);
		gameSettings.put("Player Kick voting", kickVoting_data);
		
		for(int i = 0; i < labels.size(); i++){
			int col = i / 8;
			int row = i % 8;
			grid.add(labels.get(i), col, row);
		}
		
		t.setContent(grid);
		return t;
	}
	
	public void updateLabels(HashMap<String, String> gameSettingsData, HashMap<String, String> serverStateData){
		/* For game settings information who only change when the 
		 * map changes or server restarts (server name, cheat protection,
		 * game type, mutators, difficulty, min to start, spectators, 
		 * player map voting, and player kick voting */
		if(gameSettingsData != null){
			for(String key : gameSettings.keySet()){
				if(gameSettingsData.containsKey(key)){
					if(gameSettingsData.get(key).isEmpty()){
						Label l = (Label) gameSettings.get(key);
						l.setText("None");
					} else { 
						Label l = (Label) gameSettings.get(key);
						l.setText(gameSettingsData.get(key));
					}
				}
			}
		}
		
		if(serverStateData != null){
			Label map = (Label) serverState.get("gs_map_dd");
			map.setText(serverStateData.get("gs_map_dd"));
			Label players = (Label) serverState.get("gs_players_dd");
			players.setText(serverStateData.get("gs_players_dd"));
			Label curWave = (Label) serverState.get("gs_wave_dt");
			curWave.setText(serverStateData.get("gs_wave_dt"));
			Label numZeds = (Label) serverState.get("gs_wave_dd");
			numZeds.setText(serverStateData.get("gs_wave_dd"));
		}
	}

	@Override
	public ArrayList<Node> getNodes() {
		// TODO Auto-generated method stub
		return null;
	}

}
