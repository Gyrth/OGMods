class ComicImage : ComicElement{
	IMImage@ image;
	Grabber@ grabber_top_left;
	Grabber@ grabber_top_right;
	Grabber@ grabber_bottom_left;
	Grabber@ grabber_bottom_right;
	Grabber@ grabber_center;
	string path;
	float position_x;
	float position_y;
	float size_x;
	float size_y;
	float rotation;
	string image_name;
	vec4 color;

	ComicImage(JSONValue params = JSONValue()){
		comic_element_type = comic_image;

		path = GetJSONString(params, "path", "Textures/ui/menus/credits/overgrowth.png");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		vec2 position = GetJSONVec2(params, "position", vec2(snap_scale, snap_scale));
		color = GetJSONVec4(params, "color", vec4(1.0, 1.0, 1.0, 1.0));
		position_x = position.x;
		position_y = position.y;
		vec2 size = GetJSONVec2(params, "size", vec2(720 - (720 % snap_scale), 255 - (255 % snap_scale)));
		size_x = size.x;
		size_y = size.y;

		has_settings = true;
	}

	void PostInit(){
		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);
		new_image.setSize(vec2(size_x, size_y));
		new_image.setClip(false);
		image_name = imGUI.getUniqueName("image");

		@grabber_top_left = Grabber("top_left", -1, -1, scaler);
		@grabber_top_right = Grabber("top_right", 1, -1, scaler);
		@grabber_bottom_left = Grabber("bottom_left", -1, 1, scaler);
		@grabber_bottom_right = Grabber("bottom_right", 1, 1, scaler);
		@grabber_center = Grabber("center", 1, 1, mover);

		image_container.addFloatingElement(new_image, image_name, vec2(position_x, position_y), 0);
		new_image.setRotation(rotation);
		new_image.setColor(color);
		UpdateContent();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("add_image");
		data["path"] = JSONValue(path);
		data["rotation"] = JSONValue(rotation);
		data["position"] = JSONValue(JSONarrayValue);
		data["position"].append(position_x);
		data["position"].append(position_y);
		data["color"] = JSONValue(JSONarrayValue);
		data["color"].append(color.x);
		data["color"].append(color.y);
		data["color"].append(color.z);
		data["color"].append(color.a);
		data["size"] = JSONValue(JSONarrayValue);
		data["size"].append(size_x);
		data["size"].append(size_y);
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

		grabber_top_left.SetPosition(position);
		grabber_top_right.SetPosition(position + vec2(size.x, 0));
		grabber_bottom_left.SetPosition(position + vec2(0, size.y));
		grabber_bottom_right.SetPosition(position + vec2(size.x, size.y));
		grabber_center.SetPosition(position);
		grabber_center.SetSize(vec2(size_x, size_y));

		image.showBorder(edit_mode);
		grabber_top_left.SetVisible(edit_mode);
		grabber_top_right.SetVisible(edit_mode);
		grabber_bottom_left.SetVisible(edit_mode);
		grabber_bottom_right.SetVisible(edit_mode);
		grabber_center.SetVisible(edit_mode);

		image.setZOrdering(index);
		grabber_top_left.SetIndex(index);
		grabber_top_right.SetIndex(index);
		grabber_bottom_left.SetIndex(index);
		grabber_bottom_right.SetIndex(index);
		grabber_center.SetIndex(index);
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
			size_x += added_size.x;
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			size_x -= added_size.x;
			image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
			position_x += added_size.x;
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
			size_y += added_size.y;
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			size_y -= added_size.y;
			image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
			position_y += added_size.y;
		}
		UpdateContent();
	}

	void AddPosition(vec2 added_positon){
		image_container.moveElementRelative(image_name, added_positon);
		position_x += added_positon.x;
		position_y += added_positon.y;
		UpdateContent();
	}

	Grabber@ GetGrabber(string grabber_name){
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
		image.removeUpdateBehavior(name);
	}

	bool SetVisible(bool _visible){
		visible = _visible;
		UpdateContent();
		return visible;
	}

	void DrawSettings(){
		ImGui_Text("Current Image : ");
		ImGui_SameLine();
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

		ImGui_Spacing();

		ImGui_Text("Position :");
		float slider_width = ImGui_GetWindowWidth() / 2.0 - 20.0;
		ImGui_PushItemWidth(slider_width);

		ImGui_Text("X");
		ImGui_SameLine();
		if(ImGui_SliderFloat("###position_x", position_x, 0.0, 2560, "%.0f")){
			image_container.moveElement(image_name, vec2(position_x, position_y));
			UpdateContent();
		}
		ImGui_SameLine();
		ImGui_Text("Y");
		ImGui_SameLine();
		if(ImGui_SliderFloat("###position_y", position_y, 0.0, 1440, "%.0f")){
			image_container.moveElement(image_name, vec2(position_x, position_y));
			UpdateContent();
		}

		ImGui_Spacing();

		ImGui_Text("Size :");
		ImGui_Text("X");
		ImGui_SameLine();
		if(ImGui_SliderFloat("###size_x", size_x, 0.0, 1000, "%.0f")){
			image.setSize(vec2(size_x, size_y));
			UpdateContent();
		}
		ImGui_SameLine();
		ImGui_Text("Y");
		ImGui_SameLine();
		if(ImGui_SliderFloat("###size_y", size_y, 0.0, 1000, "%.0f")){
			image.setSize(vec2(size_x, size_y));
			UpdateContent();
		}

		ImGui_PopItemWidth();

		slider_width = ImGui_GetWindowWidth() - 80.0;
		ImGui_PushItemWidth(slider_width);

		ImGui_Spacing();

		ImGui_Text("Rotation :");
		ImGui_SameLine();
		if(ImGui_SliderFloat("###rotation", rotation, -360, 360, "%.0f")){
			image.setRotation(rotation);
			UpdateContent();
		}

		ImGui_PopItemWidth();

		ImGui_Spacing();

		slider_width = ImGui_GetWindowWidth() - 61.0;
		ImGui_PushItemWidth(slider_width);

		ImGui_Text("Color :");
		ImGui_SameLine();
		if(ImGui_ColorEdit4("###Color", color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
			image.setColor(color);
			UpdateContent();
		}
		ImGui_PopItemWidth();
	}

	void SetEdit(bool editing){
		edit_mode = editing;
		UpdateContent();
	}
}
