import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;

public class AdminGUI extends Frame implements ActionListener, WindowListener {
	private static Frame LoginGUI;
//heeeeelo

	public void initializeLoginGUI(LoginHandler lh) {
		Label lbl_url;
		Label lbl_username;
		Label lbl_password;
		Label lbl_loginDuration;
		
		TextField tf_url;
		TextField tf_username;
		TextField tf_password;
		
		Choice c_loginDuration;
		
		Button loginSubmit;
		LoginGUI = new Frame("Connect to your server");
		LoginGUI.setSize(300, 300);
		LoginGUI.setLayout(new FlowLayout());
		LoginGUI.addWindowListener(new WindowListener() {
			public void windowClosing(WindowEvent e){
				System.exit(0);
			}
			public void windowActivated(WindowEvent arg0) {}
			public void windowClosed(WindowEvent arg0) {}
			public void windowDeactivated(WindowEvent arg0) {}
			public void windowDeiconified(WindowEvent arg0) {}
			public void windowIconified(WindowEvent arg0) {}
			public void windowOpened(WindowEvent arg0) {}
		});
		
		
		lbl_url = new Label("Server URL:");
		tf_url = new TextField(20);
		LoginGUI.add(lbl_url);
		LoginGUI.add(tf_url);
		
		lbl_username = new Label("Username:");
		tf_username = new TextField(20);
		LoginGUI.add(lbl_username);
		LoginGUI.add(tf_username);
		
		lbl_password = new Label("Password:");
		tf_password = new TextField(20);
		LoginGUI.add(lbl_password);
		LoginGUI.add(tf_password);
		
		lbl_loginDuration = new Label("Login Duration:");
		c_loginDuration = new Choice();
		c_loginDuration.add("Until next map load");
		c_loginDuration.add("Browser session");
		c_loginDuration.add("30 minutes");
		c_loginDuration.add("1 hour");
		c_loginDuration.add("1 day");
		c_loginDuration.add("1 week");
		c_loginDuration.add("1 month");
		LoginGUI.add(lbl_loginDuration);
		LoginGUI.add(c_loginDuration);
		
		loginSubmit = new Button("Submit");
		loginSubmit.addActionListener(new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent evt) {
				if(tf_username.getText().length() > 0 && 
						tf_password.getText().length() > 4 &&
						tf_url.getText().length() > 5) {
					
					ArrayList<String> userInfo = new ArrayList<>();
					userInfo.add(tf_url.getText());
					userInfo.add(tf_username.getText());
					userInfo.add(tf_password.getText());
					userInfo.add(c_loginDuration.getSelectedItem());
					try {
						lh.attemptLogin(userInfo);
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			}
		});
		
		LoginGUI.add(loginSubmit);
		LoginGUI.setVisible(true);
		
		
	}
	

	@Override
	public void windowActivated(WindowEvent arg0) {}

	@Override
	public void windowClosed(WindowEvent arg0) {}

	@Override
	public void windowDeactivated(WindowEvent arg0) {}

	@Override
	public void windowDeiconified(WindowEvent arg0) {}

	@Override
	public void windowIconified(WindowEvent arg0) {}

	@Override
	public void windowOpened(WindowEvent arg0) {}

	@Override
	public void actionPerformed(ActionEvent e) {}

	@Override
	public void windowClosing(WindowEvent e) {}

}
