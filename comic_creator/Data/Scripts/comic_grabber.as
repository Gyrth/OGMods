enum grabber_types { scaler, mover };

class ComicGrabber : ComicElement{
	IMImage@ image;
	int direction_x;
	int direction_y;
	grabber_types grabber_type;
	string grabber_name;

	ComicGrabber(string name, int _direction_x, int _direction_y, grabber_types _grabber_type, int parent_index){
		comic_element_type = comic_grabber;
		grabber_type = _grabber_type;

		IMImage grabber_image("Textures/ui/eclipse.tga");
		@image = grabber_image;

		direction_x = _direction_x;
		direction_y = _direction_y;

	    IMMessage on_enter("grabber_activate");
		on_enter.addInt(parent_index);
		on_enter.addString(name);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");

		grabber_name = "grabber" + element_counter + name;
		element_counter += 1;

		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		grabber_container.addFloatingElement(grabber_image, grabber_name, vec2(grabber_size / 2.0), parent_index + 1);
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
