class ComicImage : ComicElement{
	IMImage@ image;
	ComicGrabber@ grabber_top_left;
	ComicGrabber@ grabber_top_right;
	ComicGrabber@ grabber_bottom_left;
	ComicGrabber@ grabber_bottom_right;
	ComicGrabber@ grabber_center;
	string path;
	vec2 position;
	vec2 size;
	string image_name;

	ComicImage(JSONValue params = JSONValue()){
		comic_element_type = comic_image;
		display_color = HexColor("#6e5eb4");

		path = GetJSONString(params, "path", "Textures/ui/menus/credits/overgrowth.png");
		position = GetJSONVec2(params, "position", vec2(snap_scale, snap_scale));
		size = GetJSONVec2(params, "size", vec2(720 - (720 % snap_scale), 255 - (255 % snap_scale)));

		has_settings = true;
	}

	void PostInit(){
		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);
		new_image.setSize(size);
		new_image.setClip(false);
		image_name = "image" + index;

		@grabber_top_left = ComicGrabber("top_left", -1, -1, scaler, index);
		@grabber_top_right = ComicGrabber("top_right", 1, -1, scaler, index);
		@grabber_bottom_left = ComicGrabber("bottom_left", -1, 1, scaler, index);
		@grabber_bottom_right = ComicGrabber("bottom_right", 1, 1, scaler, index);
		@grabber_center = ComicGrabber("center", 1, 1, mover, index);

		image_container.addFloatingElement(new_image, image_name, position, index);
		UpdateContent();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("add_image");
		data["path"] = JSONValue(path);
		data["position"] = JSONValue(JSONarrayValue);
		data["position"].append(position.x);
		data["position"].append(position.y);
		data["size"] = JSONValue(JSONarrayValue);
		data["size"].append(size.x);
		data["size"].append(size.y);
		return data;
	}

	string GetDisplayString(){
		return "AddImage " + path;
	}

	void Delete(){
		image_container.removeElement(image_name);
		grabber_top_left.Delete();
		grabber_top_right.Delete();
		grabber_bottom_left.Delete();
		grabber_bottom_right.Delete();
		grabber_center.Delete();
	}

	void SetIndex(int _index){
		index = _index;
		image.setZOrdering(index);
	}

	void SetNewImage(){
		vec2 old_size = image.getSize();
		image.setImageFile(path);
		image.setSize(old_size);
	}

	void UpdateContent(){
		image.setVisible(visible);

		vec2 position = image_container.getElementPosition(image_name);
		vec2 size = image.getSize();

		grabber_container.moveElement(grabber_top_left.grabber_name, position - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_top_right.grabber_name, position + vec2(size.x, 0) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_bottom_left.grabber_name, position + vec2(0, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_bottom_right.grabber_name, position + vec2(size.x, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement(grabber_center.grabber_name, position + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void StartEdit(){
		image.showBorder(true);
		grabber_top_left.SetVisible(true);
		grabber_top_right.SetVisible(true);
		grabber_bottom_left.SetVisible(true);
		grabber_bottom_right.SetVisible(true);
		grabber_center.SetVisible(true);
	}

	void EditDone(){
		image.showBorder(false);
		grabber_top_left.SetVisible(false);
		grabber_top_right.SetVisible(false);
		grabber_bottom_left.SetVisible(false);
		grabber_bottom_right.SetVisible(false);
		grabber_center.SetVisible(false);
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
			size.x += added_size.x;
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			size.x -= added_size.x;
			image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
			position.x += added_size.x;
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
			size.y += added_size.y;
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			size.y -= added_size.y;
			image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
			position.y += added_size.y;
		}
		UpdateContent();
	}

	void AddPosition(vec2 added_positon){
		image_container.moveElementRelative(image_name, added_positon);
		position += added_positon;
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

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		image.addUpdateBehavior(behavior, name);
	}

	void RemoveUpdateBehavior(string name){
	}

	void SetVisible(bool _visible){
		visible = _visible;
		Log(warning, "IMage visible " + visible);
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
