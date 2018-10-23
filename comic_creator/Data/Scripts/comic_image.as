class ComicImage : ComicElement{
	IMImage@ image;
	ComicGrabber@ grabber_top_left;
	ComicGrabber@ grabber_top_right;
	ComicGrabber@ grabber_bottom_left;
	ComicGrabber@ grabber_bottom_right;
	ComicGrabber@ grabber_center;
	string path;
	vec2 location;
	vec2 size;
	string image_name;

	ComicImage(string _path, vec2 _location, vec2 _size, int _index){
		comic_element_type = comic_image;
		has_settings = true;
		display_color = HexColor("#6e5eb4");

		path = _path;
		index = _index;
		location = _location;
		size = _size;

		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);

		@grabber_top_left = ComicGrabber("top_left", -1, -1, scaler, index);
		@grabber_top_right = ComicGrabber("top_right", 1, -1, scaler, index);
		@grabber_bottom_left = ComicGrabber("bottom_left", -1, 1, scaler, index);
		@grabber_bottom_right = ComicGrabber("bottom_right", 1, 1, scaler, index);
		@grabber_center = ComicGrabber("center", 1, 1, mover, index);

		new_image.setSize(size);
		Log(info, "adding image " + index);

		image_name = "image" + element_counter;
		element_counter += 1;

		image_container.addFloatingElement(new_image, image_name, location, index);
		UpdateContent();
	}

	void SetNewImage(){
		vec2 old_size = image.getSize();
		image.setImageFile(path);
		image.setSize(old_size);
	}

	void UpdateContent(){
		image.showBorder(edit_mode);
		grabber_top_left.SetVisible(edit_mode);
		grabber_top_right.SetVisible(edit_mode);
		grabber_bottom_left.SetVisible(edit_mode);
		grabber_bottom_right.SetVisible(edit_mode);
		grabber_center.SetVisible(edit_mode);

		image.setVisible(visible);

		vec2 location = image_container.getElementPosition(image_name);
		vec2 size = image.getSize();

		grabber_container.moveElement(grabber_top_left.grabber_name, location - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_top_right.grabber_name, location + vec2(size.x, 0) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_bottom_left.grabber_name, location + vec2(0, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_bottom_right.grabber_name, location + vec2(size.x, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_center.grabber_name, location + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
			size.x += added_size.x;
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			size.x -= added_size.x;
			image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
			location.x += added_size.x;
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
			size.y += added_size.y;
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			size.y -= added_size.y;
			image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
			location.y += added_size.y;
		}
		UpdateContent();
	}

	void AddPosition(vec2 added_positon){
		image_container.moveElementRelative(image_name, added_positon);
		location += added_positon;
		UpdateContent();
	}

	ComicGrabber@ GetGrabber(string grabber_name){
		if(grabber_name == "top_left"){
			return grabber_top_left;
		}else if(grabber_name == "top_right"){
			return grabber_top_right;
		}else if(grabber_name == "bottom_left"){
			return grabber_bottom_left;
		}else if(grabber_name == "bottom_right"){
			return grabber_bottom_right;
		}else if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	string GetSaveString(){
		return "add_image " + path + " " + location.x + " " + location.y + " " + size.x + " " + size.y;
	}

	string GetDisplayString(){
		return "AddImage " + path;
	}

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		image.addUpdateBehavior(behavior, name);
	}

	void RemoveUpdateBehavior(string name){
	}

	void SetVisible(bool _visible){
		visible = _visible;
		UpdateContent();
	}

	void AddSettings(){
		ImGui_Text("Current Image : ");
		ImGui_Text(path);
		if(ImGui_Button("Set Image")){
			string new_path = GetUserPickedReadPath("png", "Data/Textures");
			if(new_path != ""){
				array<string> split_path = new_path.split("/");
				split_path.removeAt(0);
				path = join(split_path, "/");
				SetNewImage();
			}
		}
	}

	void SetEdit(bool editing){
		edit_mode = editing;
		UpdateContent();
	}
}
