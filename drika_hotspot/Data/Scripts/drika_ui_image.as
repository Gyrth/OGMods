class DrikaUIImage : DrikaUIElement{
	IMImage@ image;
	DrikaUIGrabber@ grabber_top_left;
	DrikaUIGrabber@ grabber_top_right;
	DrikaUIGrabber@ grabber_bottom_left;
	DrikaUIGrabber@ grabber_bottom_right;
	DrikaUIGrabber@ grabber_center;
	string image_path;
	ivec2 position;
	ivec2 size;
	float rotation;
	string image_name;
	vec4 color;
	bool keep_aspect;
	ivec2 position_offset;
	ivec2 size_offset;

	ivec2 max_offset(0, 0);

	DrikaUIImage(JSONValue params = JSONValue()){
		drika_ui_element_type = drika_ui_image;

		image_path = GetJSONString(params, "image_path", "");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		position = GetJSONIVec2(params, "position", ivec2());
		color = GetJSONVec4(params, "color", vec4());
		keep_aspect = GetJSONBool(params, "keep_aspect", false);
		size = GetJSONIVec2(params, "size", ivec2());
		index = GetJSONInt(params, "index", 0);

		position_offset = GetJSONIVec2(params, "position_offset", ivec2());
		size_offset = GetJSONIVec2(params, "size_offset", ivec2());

		ui_element_identifier = GetJSONString(params, "ui_element_identifier", "");
		PostInit();
	}

	void PostInit(){
		IMImage new_image(image_path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);
		ReadMaxOffsets();
		if(size_offset.x == 0.0 || size_offset.y == 0.0){
			size_offset = max_offset;
		}
		SetOffset();
		new_image.setSize(vec2(size.x, size.y));
		new_image.setZOrdering(index);
		new_image.setClip(false);
		image_name = imGUI.getUniqueName("image");

		Log(warning, "Create image");

		@grabber_top_left = DrikaUIGrabber("top_left", -1, -1, scaler);
		@grabber_top_right = DrikaUIGrabber("top_right", 1, -1, scaler);
		@grabber_bottom_left = DrikaUIGrabber("bottom_left", -1, 1, scaler);
		@grabber_bottom_right = DrikaUIGrabber("bottom_right", 1, 1, scaler);
		@grabber_center = DrikaUIGrabber("center", 1, 1, mover);

		image_container.addFloatingElement(new_image, image_name, vec2(position.x, position.y), 0);
		new_image.setRotation(rotation);
		new_image.setColor(color);
		UpdateContent();
	}

	void ReadUIInstruction(array<string> instruction){
		Log(warning, "Got instruction " + instruction[0]);
		if(instruction[0] == "set_position"){
			position.x = atoi(instruction[1]);
			position.y = atoi(instruction[2]);
			SetPosition();
		}else if(instruction[0] == "set_size"){
			size.x = atoi(instruction[1]);
			size.y = atoi(instruction[2]);
			SetSize();
		}else if(instruction[0] == "set_position_offset"){
			position_offset.x = atoi(instruction[1]);
			position_offset.y = atoi(instruction[2]);
			SetOffset();
		}else if(instruction[0] == "set_size_offset"){
			size_offset.x = atoi(instruction[1]);
			size_offset.y = atoi(instruction[2]);
			SetOffset();
		}else if(instruction[0] == "set_rotation"){
			rotation = atof(instruction[1]);
			SetRotation();
		}else if(instruction[0] == "set_color"){
			color.x = atof(instruction[1]);
			color.y = atof(instruction[2]);
			color.z = atof(instruction[3]);
			color.a = atof(instruction[4]);
			SetColor();
		}else if(instruction[0] == "set_aspect_ratio"){
			keep_aspect = instruction[1] == "true";
			SetSize();
		}else if(instruction[0] == "set_image_path"){
			image_path = instruction[1];
			SetNewImage();
		}else if(instruction[0] == "set_z_order"){
			index = atoi(instruction[1]);
			SetZOrder();
		}else if(instruction[0] == "add_update_behaviour"){
			if(instruction[1] == "fade_in"){
				int duration = atoi(instruction[2]);
				int tween_type = atoi(instruction[3]);
				string name = instruction[4];

				IMFadeIn new_fade(duration, IMTweenType(tween_type));
				image.addUpdateBehavior(new_fade, name);
			}else if(instruction[1] == "move_in"){
				int duration = atoi(instruction[2]);
				vec2 offset(atoi(instruction[3]), atoi(instruction[4]));
				int tween_type = atoi(instruction[5]);
				string name = instruction[6];

				IMMoveIn new_move(duration, offset, IMTweenType(tween_type));
				image.addUpdateBehavior(new_move, name);
			}
		}else if(instruction[0] == "remove_update_behaviour"){
			string name = instruction[1];
			if(image.hasUpdateBehavior(name)){
				image.removeUpdateBehavior(name);
			}
		}
		UpdateContent();
	}

	void Delete(){
		image_container.removeElement(image_name);
		grabber_top_left.Delete();
		grabber_top_right.Delete();
		grabber_bottom_left.Delete();
		grabber_bottom_right.Delete();
		grabber_center.Delete();
	}

	void SetZOrder(){
		image.setZOrdering(index);
	}

	void SetNewImage(){
		vec2 old_size = image.getSize();
		image.setImageFile(image_path);
		ReadMaxOffsets();
		image.setSize(old_size);
	}

	void UpdateContent(){
		vec2 position = image_container.getElementPosition(image_name);
		vec2 size = image.getSize();

		grabber_top_left.SetPosition(position);
		grabber_top_right.SetPosition(position + vec2(size.x, 0));
		grabber_bottom_left.SetPosition(position + vec2(0, size.y));
		grabber_bottom_right.SetPosition(position + vec2(size.x, size.y));
		grabber_center.SetPosition(position);
		grabber_center.SetSize(size);

		grabber_top_left.SetVisible(editing);
		grabber_top_right.SetVisible(editing);
		grabber_bottom_left.SetVisible(editing);
		grabber_bottom_right.SetVisible(editing);
		grabber_center.SetVisible(editing);

		image.showBorder(editing);
	}

	void AddSize(ivec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			if(keep_aspect){
				if(direction_y != -1){
					image.scaleToSizeX(image.getSizeX() + added_size.x);
					size.x += added_size.x;
					size.y = int(image.getSizeY());
				}
			}else{
				image.setSizeX(image.getSizeX() + added_size.x);
				size.x += added_size.x;
			}
		}else{
			if(keep_aspect){
				if(direction_y != -1){
					image.scaleToSizeX(image.getSizeX() - added_size.x);
					size.x -= added_size.x;
					image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
					position.x += added_size.x;
					size.y = int(image.getSizeY());
				}
			}else{
				image.setSizeX(image.getSizeX() - added_size.x);
				size.x -= added_size.x;
				image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
				position.x += added_size.x;
			}
		}
		if(direction_y == 1){
			if(!keep_aspect){
				image.setSizeY(image.getSizeY() + added_size.y);
				size.y += added_size.y;
			}
		}else{
			if(keep_aspect){
				if(direction_x == 1){
					image.scaleToSizeY(image.getSizeY() - added_size.y);
					size.y -= added_size.y;
					image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
					position.y += added_size.y;
					size.x = int(image.getSizeX());
				}else{
					float size_x_before = image.getSizeX();
					image.scaleToSizeY(image.getSizeY() - added_size.y);
					size.y -= added_size.y;
					float moved_x = size_x_before - image.getSizeX();
					image_container.moveElementRelative(image_name, vec2(moved_x, added_size.y));
					position.y += added_size.y;
					size.x = int(image.getSizeX());
				}
			}else{
				image.setSizeY(image.getSizeY() - added_size.y);
				size.y -= added_size.y;
				image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
				position.y += added_size.y;
			}
		}
		UpdateContent();
		SendUIInstruction("set_size", {size.x, size.y});
	}

	void SetPosition(){
		image_container.moveElement(image_name, vec2(position.x, position.y));
	}

	void SetSize(){
		image.setSize(vec2(size.x, size.y));
	}

	void AddPosition(ivec2 added_positon){
		image_container.moveElementRelative(image_name, vec2(added_positon.x, added_positon.y));
		position += added_positon;
		UpdateContent();
		SendUIInstruction("set_position", {position.x, position.y});
	}

	DrikaUIGrabber@ GetGrabber(string grabber_name){
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

	void ReadMaxOffsets(){
		max_offset = ivec2(int(image.getSizeX()),int(image.getSizeY()));
	}

	void SetOffset(){
		image.setImageOffset(vec2(position_offset.x, position_offset.y), vec2(size_offset.x, size_offset.y));
	}

	void SetRotation(){
		image.setRotation(rotation);
	}

	void SetColor(){
		image.setColor(color);
	}

	void SetEditing(bool _editing){
		editing = _editing;
		UpdateContent();
	}
}
