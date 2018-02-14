
/* This interface provides methods which should be generic across all GUI elements
 * Each GUI element will be considered a "tab" (much like the tabs in your web browser)
 * getTab is where we will actually construct a GUI (adding text boxes, buttons, etc.)
 * getNodes returns a list of specific nodes inside of the GUI, as defined by the implementation
 * 
 * The LoginGUI is only used at startup and performs special functions, so we don't need to 
 * implement our interface there.
 */

import java.util.ArrayList;
import javafx.scene.Node;
import javafx.scene.control.Tab;

public interface InterfaceGUI {
	
	public Tab getTab(); // Returns our tab
	public ArrayList<Node> getNodes(); // Returns GUI elements that we need access to for updating
	
}
