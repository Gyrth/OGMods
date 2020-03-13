class DrikaUIText : DrikaUIElement{
	IMDivider@ holder;
	array<IMText@> text_elements;
	array<string> split_content;
	string text_content;
	ivec2 position;
	float rotation;
	DrikaUIGrabber@ grabber_center;
	string holder_name;
	DrikaUIFont@ font_element = null;

	DrikaUIText(JSONValue params = JSONValue()){
		drika_ui_element_type = drika_ui_text;

		text_content = GetJSONString(params, "text_content", "");
		split_content = text_content.split("\n");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		position = GetJSONIVec2(params, "position", ivec2());
		index = GetJSONInt(params, "index", 0);

		@font_element = cast<DrikaUIFont@>(GetUIElement(GetJSONString(params, "font_id", "")));

		ui_element_identifier = GetJSONString(params, "ui_element_identifier", "");
		PostInit();
	}

	void PostInit(){
		IMDivider text_holder(ui_element_identifier + "textholder", DOVertical);
		@holder = text_holder;
		text_holder.setBorderColor(edit_outline_color);
		text_holder.setAlignment(CALeft, CATop);
		text_holder.setClip(false);
		text_holder.setZOrdering(index);

		@grabber_center = DrikaUIGrabber("center", 1, 1, mover);
		grabber_center.margin = 0.0;
		holder_name = imGUI.getUniqueName("text");
		text_container.addFloatingElement(text_holder, holder_name, vec2(position.x, position.y), 0);
		SetNewText();
	}

	void ReadUIInstruction(array<string> instruction){
		Log(warning, "Got instruction " + instruction[0]);
		if(instruction[0] == "set_position"){
			position.x = atoi(instruction[1]);
			position.y = atoi(instruction[2]);
			SetPosition();
		}else if(instruction[0] == "set_rotation"){
			rotation = atof(instruction[1]);
			SetNewText();
		}else if(instruction[0] == "set_content"){
			text_content = instruction[1];
			split_content = text_content.split("\n");
			SetNewText();
		}else if(instruction[0] == "font_changed"){
			@font_element = cast<DrikaUIFont@>(GetUIElement(instruction[1]));
			SetNewText();
		}else if(instruction[0] == "set_z_order"){
			index = atoi(instruction[1]);
			SetZOrder();
		}else if(instruction[0] == "add_update_behaviour"){
			if(instruction[1] == "fade_in"){
				int duration = atoi(instruction[2]);
				int tween_type = atoi(instruction[3]);
				string name = instruction[4];

				for(uint i = 0; i < text_elements.size(); i++){
					IMFadeIn new_fade(duration, IMTweenType(tween_type));
					text_elements[i].addUpdateBehavior(new_fade, name + "2");
				}
			}else if(instruction[1] == "move_in"){
				int duration = atoi(instruction[2]);
				vec2 offset(atoi(instruction[3]), atoi(instruction[4]));
				int tween_type = atoi(instruction[5]);
				string name = instruction[6];

				IMMoveIn new_move(duration, offset, IMTweenType(tween_type));
				holder.addUpdateBehavior(new_move, name);
			}
		}else if(instruction[0] == "remove_update_behaviour"){
			string name = instruction[1];
			if(holder.hasUpdateBehavior(name)){
				holder.removeUpdateBehavior(name);
			}
			for(uint i = 0; i < text_elements.size(); i++){
				if(text_elements[i].hasUpdateBehavior(name)){
					text_elements[i].removeUpdateBehavior(name);
				}
			}
		}
		UpdateContent();
	}

	void Delete(){
		text_container.removeElement(holder_name);
		grabber_center.Delete();
	}

	void SetZOrder(){
		holder.setZOrdering(index);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setZOrdering(index);
		}
	}

	void SetNewText(){
		text_elements.resize(0);
		holder.clear();
		holder.setSize(vec2(-1,-1));
		for(uint i = 0; i < split_content.size(); i++){
			IMText@ new_text;
			DisposeTextAtlases();
			if(font_element is null){
				@new_text = IMText(split_content[i], default_font);
			}else{
				@new_text = IMText(split_content[i], font_element.font);
			}
			text_elements.insertLast(@new_text);
			holder.append(new_text);
			new_text.setRotation(rotation);
		}

		// imgui needs to update once or else the position of the grabber isn't calculated correctly.
		imGUI.update();
		UpdateContent();
	}

	void UpdateContent(){
		holder.showBorder(editing);
		grabber_center.SetVisible(editing);

		vec2 position = text_container.getElementPosition(holder_name);
		grabber_center.SetPosition(position);
		vec2 size = holder.getSize();
		if(size.x + size.y > 0.0){
			grabber_center.SetSize(vec2(size.x, size.y));
		}
	}

	void SetEditing(bool _editing){
		editing = _editing;
		UpdateContent();
	}

	DrikaUIGrabber@ GetGrabber(string grabber_name){
		if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	void AddPosition(ivec2 added_positon){
		text_container.moveElementRelative(holder_name, vec2(added_positon.x, added_positon.y));
		position += added_positon;
		UpdateContent();
		SendUIInstruction("set_position", {position.x, position.y});
	}

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].addUpdateBehavior(behavior, name);
		}
	}

	void RemoveUpdateBehavior(string name){
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].removeUpdateBehavior(name);
		}
	}

	void SetPosition(){
		text_container.moveElement(holder_name, vec2(position.x, position.y));
	}
}
