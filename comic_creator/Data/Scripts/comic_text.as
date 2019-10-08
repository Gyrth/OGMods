class ComicText : ComicElement{
	IMDivider@ holder;
	array<IMText@> text_elements;
	array<string> content;
	string joined_content;
	string display_content;
	int whole_length = 0;
	vec2 position;
	ComicFont@ comic_font = null;
	Grabber@ grabber_center;
	string holder_name;

	ComicText(JSONValue params = JSONValue()){
		comic_element_type = comic_text;

		string original_content = GetJSONString(params, "content", "Example Text");
		position = GetJSONVec2(params, "position", vec2(200, 200));
		content = original_content.split("\\n");
		joined_content = join(content, "\n");
		display_content = join(content, " ");

		has_settings = true;
	}

	void PostInit(){
		IMDivider text_holder("textholder" + index, DOVertical);
		@holder = text_holder;
		text_holder.setBorderColor(edit_outline_color);
		text_holder.setAlignment(CALeft, CATop);
		text_holder.setClip(false);

		@grabber_center = Grabber("center", 1, 1, mover, index);
		holder_name = imGUI.getUniqueName("text");
		text_container.addFloatingElement(text_holder, holder_name, position, index);
		SetNewText();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("add_text");
		data["position"] = JSONValue(JSONarrayValue);
		data["position"].append(position.x);
		data["position"].append(position.y);
		data["content"] = JSONValue(join(content, "\\n"));
		return data;
	}

	string GetDisplayString(){
		return "AddText " + display_content;
	}

	void Delete(){
		text_container.removeElement(holder_name);
		grabber_center.Delete();
	}

	void SetIndex(int _index){
		index = _index;
		holder.setZOrdering(index);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setZOrdering(index);
		}
	}

	void SetNewText(){
		text_elements.resize(0);
		holder.clear();
		holder.setSize(vec2(0,0));
		for(uint i = 0; i < content.size(); i++){
			IMText@ new_text;
			if(comic_font is null){
				@new_text = IMText(content[i], default_font);
			}else{
				@new_text = IMText(content[i], comic_font.font);
			}
			text_elements.insertLast(@new_text);
			holder.append(new_text);
			new_text.setZOrdering(index);
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
		holder.showBorder(edit_mode);
		holder.setVisible(visible);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setVisible(visible);
		}
		grabber_center.SetVisible(edit_mode);

		vec2 position = text_container.getElementPosition(holder_name);
		vec2 size = holder.getSize();
		if(size.x + size.y > 0.0){
			grabber_container.moveElement(grabber_center.grabber_name, position + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
		}
	}

	void SetVisible(bool _visible){
		visible = _visible;
		UpdateContent();
	}

	void StartEdit(){
		edit_mode = true;
		UpdateContent();
	}

	void SetEdit(bool editing){
		edit_mode = editing;
		SetNewText();
	}

	Grabber@ GetGrabber(string grabber_name){
		if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	void AddPosition(vec2 added_positon){
		text_container.moveElementRelative(holder_name, added_positon);
		position += added_positon;
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

	void AddSettings(){
		if(ImGui_InputTextMultiline("", joined_content, 512, vec2(-1, -1))){
		}
	}

	void EditDone(){
		content = joined_content.split("\n");
		display_content = join(content, " ");
		SetNewText();
	}
}
