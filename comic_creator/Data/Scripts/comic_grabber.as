class ComicGrabber : ComicElement{
	IMImage@ image;
	int direction_x;
	int direction_y;
	grabber_types grabber_type;
	ComicGrabber(int image_index, string name, int _direction_x, int _direction_y, grabber_types _grabber_type){
		IMImage grabber_image("Textures/ui/eclipse.tga");
		@image = grabber_image;
		grabber_type = _grabber_type;

		comic_element_type = grabber;

		direction_x = _direction_x;
		direction_y = _direction_y;

	    IMMessage on_enter("grabber_activate");
		on_enter.addInt(image_index);
		on_enter.addString(name);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");

		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		grabber_container.addFloatingElement(grabber_image, "grabber" + image_index + name, vec2(grabber_size / 2.0), image_index);
	}
	void SetVisible(bool _visible){
		visible = _visible;
		image.setVisible(visible);
		image.setPauseBehaviors(!visible);
	}
}
