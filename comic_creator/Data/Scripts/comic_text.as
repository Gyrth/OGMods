class ComicText : ComicElement{
	IMDivider@ holder;
	array<IMText@> text_elements;
	string content;
	vec2 location;
	int index;
	ComicGrabber@ grabber_center;
	ComicText(string _content, ComicFont@ _comic_font, vec2 _location, int _index){
		comic_element_type = comic_text;

		content = _content;
		location = _location;
		index = _index;

		Log(info, content);

		IMDivider text_holder("textholder" + index, DOVertical);
		text_holder.showBorder();
		text_holder.setBorderColor(edit_outline_color);
		text_holder.setAlignment(CALeft, CATop);
		text_holder.setClip(false);
		array<string> lines = _content.split("\\n");
		for(uint i = 0; i < lines.size(); i++){
			IMText@ new_text;
			if(_comic_font is null){
				@new_text = IMText(lines[i], default_font);
			}else{
				@new_text = IMText(lines[i], _comic_font.font);
			}
			text_elements.insertLast(@new_text);
			text_holder.append(new_text);
			new_text.setZOrdering(index);
		}
		@grabber_center = ComicGrabber(index, "center", 1, 1, mover);
		@holder = text_holder;
		text_container.addFloatingElement(text_holder, "text" + index, location, index);
		Update();
	}

	void Update(){
		holder.showBorder(edit_mode);
		Log(info, visible + content);
		holder.setVisible(visible);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setVisible(visible);
		}
		grabber_center.SetVisible(edit_mode);

		vec2 location = text_container.getElementPosition("text" + index);
		vec2 size = holder.getSize();

		grabber_container.moveElement("grabber" + index + "center", location + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void SetVisible(bool _visible){
		visible = _visible;
		Update();
	}

	void SetEdit(bool editing){
		edit_mode = editing;
		Update();
	}

	ComicGrabber@ GetGrabber(string grabber_name){
		if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	void AddPosition(vec2 added_positon){
		text_container.moveElementRelative("text" + index, added_positon);
		location += added_positon;
		Update();
	}

	string GetSaveString(){
		return "add_text " + location.x + " " + location.y + " " + content;
	}

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		holder.addUpdateBehavior(behavior, name);
	}

	void RemoveUpdateBehavior(string name){
		holder.removeUpdateBehavior(name);
	}
}
