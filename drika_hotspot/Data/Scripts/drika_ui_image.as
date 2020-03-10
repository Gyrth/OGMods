class DrikaUIImage : DrikaUIElement{
	IMImage@ image;
	DrikaUIGrabber@ grabber_top_left;
	DrikaUIGrabber@ grabber_top_right;
	DrikaUIGrabber@ grabber_bottom_left;
	DrikaUIGrabber@ grabber_bottom_right;
	DrikaUIGrabber@ grabber_center;
	string path;
	float position_x;
	float position_y;
	float size_x;
	float size_y;
	float rotation;
	string image_name;
	vec4 color;
	bool keep_aspect;
	float position_offset_x = 0.0;
	float position_offset_y = 0.0;
	float size_offset_x = 0.0;
	float size_offset_y = 0.0;

	float max_offset_x = 0.0;
	float max_offset_y = 0.0;

	DrikaUIImage(JSONValue params = JSONValue()){
		drika_ui_element_type = drika_ui_image;

		path = GetJSONString(params, "image_path", "");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		vec2 position = GetJSONVec2(params, "position", vec2());
		color = GetJSONVec4(params, "color", vec4());
		keep_aspect = GetJSONBool(params, "keep_aspect", false);
		position_x = position.x;
		position_y = position.y;
		vec2 size = GetJSONVec2(params, "size", vec2());
		size_x = size.x;
		size_y = size.y;

		vec2 position_offset = GetJSONVec2(params, "position_offset", vec2());
		position_offset_x = position_offset.x;
		position_offset_y = position_offset.y;

		vec2 size_offset = GetJSONVec2(params, "size_offset", vec2());
		size_offset_x = size_offset.x;
		size_offset_y = size_offset.y;

		ui_element_identifier = GetJSONString(params, "ui_element_identifier", "");
		PostInit();
	}

	void PostInit(){
		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);
		ReadMaxOffsets();
		if(size_offset_x == 0.0 || size_offset_y == 0.0){
			size_offset_x = max_offset_x;
			size_offset_y = max_offset_y;
		}
		SetOffset();
		new_image.setSize(vec2(size_x, size_y));
		new_image.setClip(false);
		image_name = imGUI.getUniqueName("image");

		Log(warning, "Create image");

		@grabber_top_left = DrikaUIGrabber("top_left", -1, -1, scaler);
		@grabber_top_right = DrikaUIGrabber("top_right", 1, -1, scaler);
		@grabber_bottom_left = DrikaUIGrabber("bottom_left", -1, 1, scaler);
		@grabber_bottom_right = DrikaUIGrabber("bottom_right", 1, 1, scaler);
		@grabber_center = DrikaUIGrabber("center", 1, 1, mover);

		image_container.addFloatingElement(new_image, image_name, vec2(position_x, position_y), 0);
		new_image.setRotation(rotation);
		new_image.setColor(color);
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

	void SetZOrder(int index){
		image.setZOrdering(index);
	}

	void SetNewImage(){
		vec2 old_size = image.getSize();
		image.setImageFile(path);
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
		grabber_center.SetSize(vec2(size_x, size_y));

		image.showBorder(editing_ui);
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			if(keep_aspect){
				if(direction_y != -1){
					image.scaleToSizeX(image.getSizeX() + added_size.x);
					size_x += added_size.x;
					size_y = image.getSizeY();
				}
			}else{
				image.setSizeX(image.getSizeX() + added_size.x);
				size_x += added_size.x;
			}
		}else{
			if(keep_aspect){
				if(direction_y != -1){
					image.scaleToSizeX(image.getSizeX() - added_size.x);
					size_x -= added_size.x;
					image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
					position_x += added_size.x;
					size_y = image.getSizeY();
				}
			}else{
				image.setSizeX(image.getSizeX() - added_size.x);
				size_x -= added_size.x;
				image_container.moveElementRelative(image_name, vec2(added_size.x, 0.0));
				position_x += added_size.x;
			}
		}
		if(direction_y == 1){
			if(!keep_aspect){
				image.setSizeY(image.getSizeY() + added_size.y);
				size_y += added_size.y;
			}
		}else{
			if(keep_aspect){
				if(direction_x == 1){
					image.scaleToSizeY(image.getSizeY() - added_size.y);
					size_y -= added_size.y;
					image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
					position_y += added_size.y;
					size_x = image.getSizeX();
				}else{
					float size_x_before = image.getSizeX();
					image.scaleToSizeY(image.getSizeY() - added_size.y);
					size_y -= added_size.y;
					float moved_x = size_x_before - image.getSizeX();
					image_container.moveElementRelative(image_name, vec2(moved_x, added_size.y));
					position_y += added_size.y;
					size_x = image.getSizeX();
				}
			}else{
				image.setSizeY(image.getSizeY() - added_size.y);
				size_y -= added_size.y;
				image_container.moveElementRelative(image_name, vec2(0.0, added_size.y));
				position_y += added_size.y;
			}
		}
		UpdateContent();
	}

	void AddPosition(vec2 added_positon){
		image_container.moveElementRelative(image_name, added_positon);
		position_x += added_positon.x;
		position_y += added_positon.y;
		UpdateContent();
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

	bool SetVisible(bool _visible){
		visible = _visible;
		UpdateContent();
		return visible;
	}

	void ReadMaxOffsets(){
		max_offset_x = image.getSizeX();
		max_offset_y = image.getSizeY();
	}

	void SetOffset(){
		image.setImageOffset(vec2(position_offset_x, position_offset_y), vec2(size_offset_x, size_offset_y));
	}


	void SetEditing(bool editing){
		UpdateContent();
	}
}
