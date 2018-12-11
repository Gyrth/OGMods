enum color_types{ 	object_tint = 0,
					object_palette_color = 1
				};

class DrikaSetColor : DrikaElement{
	int num_palette_colors = 0;
	int palette_slot;
	vec3 before_color;
	vec3 after_color;
	int current_idenifier_type;
	int current_color_type;
	color_types color_type;
	array<string> palette_indexes;

	DrikaSetColor(string _identifier_type = "0", string _identifier = "-1", string _color_type = "0", string _palette_slot = "0", string _color = "1,1,1"){
		color_type = color_types(atoi(_color_type));
		current_color_type = color_type;
		palette_slot = atoi(_palette_slot);
		identifier_type = identifier_types(atoi(_identifier_type));
		current_idenifier_type = identifier_type;

		if(identifier_type == id){
			object_id = atoi(_identifier);
		}else if(identifier_type == reference){
			reference_string = _identifier;
		}

		drika_element_type = drika_set_color;
		after_color = StringToVec3(_color);
		has_settings = true;

		GetBeforeColor();
	}

	void Delete(){
		Reset();
    }

	string GetSaveString(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		return "set_color" + param_delimiter + identifier_type + param_delimiter + save_identifier + param_delimiter + color_type + param_delimiter + palette_slot + param_delimiter + Vec3ToString(after_color);
	}

	string GetDisplayString(){
		string identifier;
		if(identifier_type == id){
			identifier = "" + object_id;
		}else if(identifier_type == reference){
			identifier = "" + reference_string;
		}
		return "SetColor " + identifier;
	}

	void StartEdit(){
		GetNumPaletteColors();
	}

	void GetNumPaletteColors(){
		if(color_type == object_palette_color){
			Object@ target_object = GetTargetObject();
			if(target_object is null){
				return;
			}
			num_palette_colors = target_object.GetNumPaletteColors();
			palette_indexes.resize(0);
			for(int i = 0; i < num_palette_colors; i++){
				palette_indexes.insertLast("" + i);
			}
		}
	}

	void AddSettings(){
		if(ImGui_Combo("Identifier Type", current_idenifier_type, {"ID", "Reference"})){
			identifier_type = identifier_types(current_idenifier_type);
		}
		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", object_id)){
				GetNumPaletteColors();
			}
		}else if (identifier_type == reference){
			if(ImGui_InputText("Reference", reference_string, 64)){
				GetNumPaletteColors();
			}
		}
		if(ImGui_Combo("Color Type", current_color_type, {"Tint", "Palette Color"})){
			color_type = color_types(current_color_type);
			GetNumPaletteColors();
		}
		if(color_type == object_palette_color){
			if(num_palette_colors == 0){
				return;
			}
			ImGui_Combo("Palette Slot", palette_slot, palette_indexes);
		}
		ImGui_ColorPicker3("Color", after_color, 0);
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
			Object@ target_object = ReadObjectFromID(object_id);
			DebugDrawLine(target_object.GetTranslation(), this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
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
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		if(color_type == object_palette_color){
			before_color = target_object.GetPaletteColor(palette_slot);
		}else if(color_type == object_tint){
			before_color = target_object.GetTint();
		}
	}

	bool SetColor(bool reset){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return false;
		}
		if(color_type == object_palette_color){
			target_object.SetPaletteColor(palette_slot, reset?before_color:after_color);
		}else if(color_type == object_tint){
			target_object.SetTint(reset?before_color:after_color);
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
