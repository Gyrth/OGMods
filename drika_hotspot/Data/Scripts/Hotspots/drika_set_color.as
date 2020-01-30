enum color_types{ 	object_tint = 0,
					object_palette_color = 1
				};

class DrikaSetColor : DrikaElement{
	int num_palette_colors = 0;
	array<string> palette_names;
	int palette_slot;
	int current_palette_slot;
	vec3 before_color;
	vec3 after_color;
	int current_color_type;
	color_types color_type;
	array<string> palette_indexes;
	array<string> color_type_choices = {"Tint", "Palette Color"};

	DrikaSetColor(JSONValue params = JSONValue()){
		color_type = color_types(GetJSONInt(params, "color_type", 0));
		current_color_type = color_type;
		palette_slot = GetJSONInt(params, "palette_slot", 0);
		current_palette_slot = palette_slot;
		after_color = GetJSONVec3(params, "after_color", vec3(1));

		LoadIdentifier(params);
		connection_types = {_movement_object, _env_object, _item_object};
		drika_element_type = drika_set_color;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["color_type"] = JSONValue(color_type);
		data["palette_slot"] = JSONValue(palette_slot);
		data["after_color"] = JSONValue(JSONarrayValue);
		data["after_color"].append(after_color.x);
		data["after_color"].append(after_color.y);
		data["after_color"].append(after_color.z);
		SaveIdentifier(data);
		return data;
	}

	void Delete(){
		SetColor(true);
    }

	string GetDisplayString(){
		return "SetColor " + GetTargetDisplayText() + " " + Vec3ToString(after_color);
	}

	void StartEdit(){
		GetNumPaletteColors();
		/* DrikaElement::StartEdit(); */
		SetColor(false);
	}

	void EditDone(){
		SetColor(true);
	}

	void GetNumPaletteColors(){
		if(color_type == object_palette_color){
			array<Object@> targets = GetTargetObjects();
			for(uint i = 0; i < targets.size(); i++){
				palette_indexes.resize(0);
				num_palette_colors = 0;
				if(targets[i].GetType() == _movement_object){
					num_palette_colors = targets[i].GetNumPaletteColors();

					MovementObject@ char = ReadCharacterID(targets[i].GetID());
					level.SendMessage("drika_read_file " + hotspot.GetID() + " " + char.char_path + " " + "character_file" + " " + char.GetID());

					for(int j = 0; j < num_palette_colors; j++){
						palette_indexes.insertLast("" + j);
					}
				}
			}

			while(num_palette_colors != 0 && palette_slot >= num_palette_colors){
				palette_slot -= 1;
				current_palette_slot = palette_slot;
			}
		}
	}

	void ReceiveMessage(string message, string identifier, int id){
		if(identifier == "character_file"){
			string obj_path = GetStringBetween(message, "obj_path = \"", "\"");
			level.SendMessage("drika_read_file " + hotspot.GetID() + " " + obj_path + " " + "object_file" + " " + id);
		}else if(identifier == "object_file"){
			palette_names.resize(0);
			string red = GetStringBetween(message, "label_red=\"", "\"");
			string green = GetStringBetween(message, "label_green=\"", "\"");
			string blue = GetStringBetween(message, "label_blue=\"", "\"");
			string alpha = GetStringBetween(message, "label_alpha=\"", "\"");

			if(red != "") palette_names.insertLast(red);
			if(green != "") palette_names.insertLast(green);
			if(blue != "") palette_names.insertLast(blue);
			if(alpha != "") palette_names.insertLast(alpha);
		}
	}

	string GetStringBetween(string source, string first, string second){
		array<string> first_cut = source.split(first);
		if(first_cut.size() <= 1){
			return "";
		}
		array<string> second_cut = first_cut[1].split(second);

		if(second_cut.size() <= 1){
			return "";
		}
		return second_cut[0];
	}

	void PreTargetChanged(){
		SetColor(true);
	}

	void TargetChanged(){
		GetNumPaletteColors();
		GetBeforeColor();
		SetColor(false);
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Color Type", current_color_type, color_type_choices, color_type_choices.size())){
			SetColor(true);
			color_type = color_types(current_color_type);
			GetNumPaletteColors();
			GetBeforeColor();
			SetColor(false);
		}

		if(color_type == object_palette_color){
			if(num_palette_colors == 0){
				return;
			}
			if(ImGui_Combo("Palette Slot", current_palette_slot, palette_names, palette_names.size())){
				SetColor(true);
				palette_slot = current_palette_slot;
				GetBeforeColor();
				SetColor(false);
			}
		}

		if(ImGui_ColorEdit3("Color", after_color)){
			SetColor(false);
		}
	}

	void DrawEditing(){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(targets[i].GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(targets[i].GetID());
				DebugDrawLine(char.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}else{
				DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
		}
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeColor();
		}
		triggered = true;
		return SetColor(false);
	}

	void GetBeforeColor(){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(color_type == object_palette_color){
				if(targets[i].GetType() == _movement_object && targets[i].GetNumPaletteColors() > palette_slot){
					before_color = targets[i].GetPaletteColor(palette_slot);
				}
			}else if(color_type == object_tint){
				before_color = targets[i].GetTint();
			}
		}
	}

	bool SetColor(bool reset){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(color_type == object_palette_color){
				if(targets[i].GetType() == _movement_object && targets[i].GetNumPaletteColors() > palette_slot){
					targets[i].SetPaletteColor(palette_slot, reset?before_color:after_color);
				}
			}else if(color_type == object_tint){
				targets[i].SetTint(reset?before_color:after_color);
			}
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetColor(true);
		}
	}
}
