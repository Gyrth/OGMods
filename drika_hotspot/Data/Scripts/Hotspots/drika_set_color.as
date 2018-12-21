enum color_types{ 	object_tint = 0,
					object_palette_color = 1
				};

class DrikaSetColor : DrikaElement{
	int num_palette_colors = 0;
	int palette_slot;
	vec3 before_color;
	vec3 after_color;
	int current_color_type;
	color_types color_type;
	array<string> palette_indexes;
	array<string> color_type_choices = {"Tint", "Palette Color"};

	DrikaSetColor(string _identifier_type = "0", string _identifier = "-1", string _color_type = "0", string _palette_slot = "0", string _color = "1,1,1"){
		color_type = color_types(atoi(_color_type));
		current_color_type = color_type;
		palette_slot = atoi(_palette_slot);
		connection_types = {_movement_object, _env_object, _decal_object, _item_object};
		InterpIdentifier(_identifier_type, _identifier);
		drika_element_type = drika_set_color;
		after_color = StringToVec3(_color);
		has_settings = true;
	}

	void Delete(){
		Reset();
    }

	array<string> GetSaveParameters(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		return {"set_color", identifier_type, save_identifier, color_type, palette_slot, Vec3ToString(after_color)};
	}

	string GetDisplayString(){
		string identifier;
		if(identifier_type == id){
			identifier = "" + object_id;
		}else if(identifier_type == reference){
			identifier = "" + reference_string;
		}
		return "SetColor " + identifier + " " + Vec3ToString(after_color);
	}

	void StartEdit(){
		GetNumPaletteColors();
		DrikaElement::StartEdit();
	}

	void GetNumPaletteColors(){
		if(color_type == object_palette_color){
			Object@ target_object = GetTargetObject();
			if(target_object is null){
				return;
			}
			palette_indexes.resize(0);
			num_palette_colors = 0;
			if(target_object.GetType() == _movement_object){
				num_palette_colors = target_object.GetNumPaletteColors();
				for(int i = 0; i < num_palette_colors; i++){
					palette_indexes.insertLast("" + i);
				}
			}
		}
	}

	void TargetChanged(){
		GetNumPaletteColors();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Color Type", current_color_type, color_type_choices, color_type_choices.size())){
			color_type = color_types(current_color_type);
			GetNumPaletteColors();
		}
		if(color_type == object_palette_color){
			if(num_palette_colors == 0){
				return;
			}
			ImGui_Combo("Palette Slot", palette_slot, palette_indexes, palette_indexes.size());
		}
		ImGui_ColorPicker3("Color", after_color, 0);
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
			Object@ target_object = ReadObjectFromID(object_id);
			DebugDrawLine(target_object.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
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
