class DrikaUIText : DrikaUIElement{
	IMDivider@ holder;
	array<IMText@> text_elements;
	array<string> content;
	string joined_content;
	string display_content;
	int whole_length = 0;
	float position_x;
	float position_y;
	float rotation;
	DrikaUIGrabber@ grabber_center;
	string holder_name;

	DrikaUIText(JSONValue params = JSONValue()){
		drika_ui_element_type = drika_ui_text;

		string original_content = GetJSONString(params, "text_content", "");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		vec2 position = GetJSONVec2(params, "position", vec2());
		position_x = position.x;
		position_y = position.y;
		content = original_content.split("\\n");
		joined_content = join(content, "\n");
		display_content = join(content, " ");

		ui_element_identifier = GetJSONString(params, "ui_element_identifier", "");
	}

	void PostInit(){
		IMDivider text_holder(ui_element_identifier + "textholder", DOVertical);
		@holder = text_holder;
		text_holder.setBorderColor(edit_outline_color);
		text_holder.setAlignment(CALeft, CATop);
		text_holder.setClip(false);

		@grabber_center = DrikaUIGrabber("center", 1, 1, mover);
		grabber_center.margin = 0.0;
		holder_name = imGUI.getUniqueName("text");
		text_container.addFloatingElement(text_holder, holder_name, vec2(position_x, position_y), 0);
		SetNewText();
	}

	void Delete(){
		text_container.removeElement(holder_name);
		grabber_center.Delete();
	}

	void SetZOrder(int index){
		holder.setZOrdering(index);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setZOrdering(index);
		}
	}

	void SetNewText(){
		text_elements.resize(0);
		holder.clear();
		holder.setSize(vec2(-1,-1));
		for(uint i = 0; i < content.size(); i++){
			IMText@ new_text;
			@new_text = IMText(content[i], default_font);
			text_elements.insertLast(@new_text);
			holder.append(new_text);
			new_text.setRotation(rotation);
		}
		whole_length = join(content, "").length();
		// imgui needs to update once or else the position of the grabber isn't calculated correctly.
		imGUI.update();
		UpdateContent();
	}

	void SetProgress(int progress){
		int shown_characters = progress * whole_length / 100;
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setText(content[i].substr(0, max(0, min(content[i].length(), shown_characters))));
			shown_characters -= content[i].length();
		}
	}

	void UpdateContent(){
		holder.showBorder(editing_ui);
		holder.setVisible(visible);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setVisible(visible);
		}
		grabber_center.SetVisible(editing_ui);

		vec2 position = text_container.getElementPosition(holder_name);
		grabber_center.SetPosition(position);
		vec2 size = holder.getSize();
		if(size.x + size.y > 0.0){
			grabber_center.SetSize(vec2(size.x, size.y));
		}
	}

	bool SetVisible(bool _visible){
		visible = _visible;
		UpdateContent();
		return visible;
	}

	void SetEditing(bool editing){
		SetNewText();
	}

	DrikaUIGrabber@ GetGrabber(string grabber_name){
		if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	void AddPosition(vec2 added_positon){
		text_container.moveElementRelative(holder_name, added_positon);
		position_x += added_positon.x;
		position_y += added_positon.y;
		UpdateContent();
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

	void EditDone(){
		display_content = join(content, " ");
	}
}
