import java.util.ArrayList;
import java.util.HashMap;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.Node;
import javafx.scene.control.Tab;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.cell.PropertyValueFactory;

public class PlayerGUI implements InterfaceGUI {

	private TableView<Player> table = new TableView<>();
	
	@Override
	public Tab getTab() {
		Tab t = new Tab();
	
		/* name, perk, dosh, health, kills, ping, admin, 
		 * ip, uid, steam id, community id, spectator */
		TableColumn<Player, String> name = new TableColumn<Player, String>("Name");
		name.setCellValueFactory(new PropertyValueFactory<>("name"));
		TableColumn<Player, String> perk = new TableColumn<Player, String>("Perk");
		perk.setCellValueFactory(new PropertyValueFactory<>("perk"));
		TableColumn<Player, String> dosh = new TableColumn<Player, String>("Dosh");
		dosh.setCellValueFactory(new PropertyValueFactory<>("dosh"));
		TableColumn<Player, String> health = new TableColumn<Player, String>("Health");
		health.setCellValueFactory(new PropertyValueFactory<>("health"));
		TableColumn<Player, String> kills = new TableColumn<Player, String>("Kills");
		kills.setCellValueFactory(new PropertyValueFactory<>("kills"));
		TableColumn<Player, String> ping = new TableColumn<Player, String>("Ping");
		ping.setCellValueFactory(new PropertyValueFactory<>("ping"));
		TableColumn<Player, String> admin = new TableColumn<Player, String>("Admin");
		admin.setCellValueFactory(new PropertyValueFactory<>("admin"));
		TableColumn<Player, String> ip = new TableColumn<Player, String>("IP");
		ip.setCellValueFactory(new PropertyValueFactory<>("ip"));
		TableColumn<Player, String> uid = new TableColumn<Player, String>("Unique ID");
		uid.setCellValueFactory(new PropertyValueFactory<>("uid"));
		TableColumn<Player, String> steamid = new TableColumn<Player, String>("Steam ID");
		steamid.setCellValueFactory(new PropertyValueFactory<>("steamid"));
		TableColumn<Player, String> commid = new TableColumn<Player, String>("Community ID");
		commid.setCellValueFactory(new PropertyValueFactory<>("commid"));
		TableColumn<Player, String> spec = new TableColumn<Player, String>("Spectator");
		spec.setCellValueFactory(new PropertyValueFactory<>("spectator"));
		TableColumn<Player, String> action = new TableColumn<Player, String>("Action");
		
		table.getColumns().addAll(name, perk, dosh, health, kills,
				ping, admin, ip, uid, steamid, commid, spec, action);
		table.setEditable(false);
		table.setItems(updateTab());
		t.setContent(table);
		return t;
	}

	@Override
	public ArrayList<Node> getNodes() {
		// TODO Auto-generated method stub
		return null;
	}
	
	public ObservableList<Player> updateTab(){
		//String name, String perk, String steamid, String commid, String uid, String ip, String spectator, boolean admin
		Player ply1 = new Player("Deliverance", "Gunslinger", "76561197997972041", "", "0x01100001023F5A49", "142.68.151.238", "No", false);
		ObservableList<Player> list = FXCollections.observableArrayList(ply1);
		return list;
	}

}
