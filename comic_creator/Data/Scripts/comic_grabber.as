enum grabber_types { scaler, mover };

class Grabber{
	IMImage@ image;
	int direction_x;
	int direction_y;
	grabber_types grabber_type;
	string grabber_name;
	bool visible = false;
	int index = 0;

	Grabber(string name, int _direction_x, int _direction_y, grabber_types _grabber_type){
		grabber_type = _grabber_type;

		IMImage grabber_image("Textures/grabber.png");
		@image = grabber_image;

		direction_x = _direction_x;
		direction_y = _direction_y;

	    IMMessage on_enter("grabber_activate");
		on_enter.addString(name);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");

		grabber_name = imGUI.getUniqueName("grabber");

		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		grabber_container.addFloatingElement(grabber_image, grabber_name, vec2(grabber_size / 2.0), 0);
	}

	void SetIndex(int parent_index){
		Log(warning, "Index " + (parent_index + 1));
		index = parent_index + 1;
		image.setZOrdering(index);
	}

	vec2 GetPosition(){
		return grabber_container.getElementPosition(grabber_name) + vec2(grabber_size / 2.0);
	}

	void Delete(){
		grabber_container.removeElement(grabber_name);
	}

	void SetVisible(bool _visible){
		visible = _visible;
		image.setVisible(visible);
		image.setPauseBehaviors(!visible);
	}
}
