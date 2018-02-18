import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/* Creates a Player object
 * 
 * Contains information about the player
 * 
 * Some information about the player is not subject to change (name, IP, UID)
 * 
 * All other information (perk, dosh, health, kills, ping, admin status) is subject 
 * to change as game progresses
 */


public class Player {

	/* name, perk, dosh, health, kills, ping, admin, 
	 * ip, uid, steam id, community id, spectator */
	private String name;
	private String perk;
	private String steamid;
	private String commid;
	private String spectator;
	private String uid;
	private String ip;
	private int dosh;
	private int health;
	private int kills;
	private int ping;
	private boolean admin;
	private LocalDateTime loginTime;
	
	Player(String name, String perk, String steamid, String commid, String uid, String ip, String spectator, boolean admin){
		if(name.length() < 0 || perk.length() < 0 || uid.length() < 0 || ip.length() < 0){
			throw new IllegalArgumentException();
		}
		this.name = name;
		this.perk = perk;
		this.steamid = steamid;
		this.commid = commid;
		this.spectator = spectator;
		this.uid = uid;
		this.ip = ip;
		this.admin = admin;
		this.loginTime = LocalDateTime.now();
	}

	public String getName() {
		return name;
	}

	public String getPerk() {
		return perk;
	}

	public void setPerk(String perk) {
		this.perk = perk;
	}

	public String getUid() {
		return uid;
	}

	public String getIp() {
		return ip;
	}

	public int getDosh() {
		return dosh;
	}

	public void setDosh(int dosh) {
		if(dosh < 0){
			return;
		}
		this.dosh = dosh;
	}

	public int getHealth() {
		return health;
	}

	public void setHealth(int health) {
		this.health = health;
	}

	public int getKills() {
		return kills;
	}

	public void setKills(int kills) {
		this.kills = kills;
	}

	public int getPing() {
		return ping;
	}

	public boolean isAdmin() {
		return admin;
	}

	public void setAdmin(boolean admin) {
		this.admin = admin;
	}
	
	public String getLoginTime(){
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
		return this.loginTime.format(formatter);
	}
	
	
}
