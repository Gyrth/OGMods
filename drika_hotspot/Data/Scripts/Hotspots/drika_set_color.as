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

	DrikaSetColor(JSONValue params = JSONValue()){
		color_type = color_types(GetJSONInt(params, "color_type", 0));
		current_color_type = color_type;
		palette_slot = GetJSONInt(params, "palette_slot", 0);
		after_color = GetJSONVec3(params, "after_color", vec3(1));

		LoadIdentifier(params);
		connection_types = {_movement_object, _env_object, _decal_object, _item_object};
		drika_element_type = drika_set_color;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_color");
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
		Reset();
    }

	string GetDisplayString(){
		return "SetColor " + GetTargetDisplayText() + " " + Vec3ToString(after_color);
	}

	void StartEdit(){
		GetNumPaletteColors();
		DrikaElement::StartEdit();
	}

	void GetNumPaletteColors(){
		if(color_type == object_palette_color){
			array<Object@> targets = GetTargetObjects();
			for(uint i = 0; i < targets.size(); i++){
				palette_indexes.resize(0);
				num_palette_colors = 0;
				if(targets[i].GetType() == _movement_object){
					num_palette_colors = targets[i].GetNumPaletteColors();
					for(int j = 0; j < num_palette_colors; j++){
						palette_indexes.insertLast("" + j);
					}
				}
			}
		}
	}

	void TargetChanged(){
		GetNumPaletteColors();
	}

	void StartSettings(){
		CheckReferenceAvailable();
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
		ImGui_ColorEdit3("Color", after_color);
	}

	void DrawEditing(){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
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
				before_color = targets[i].GetPaletteColor(palette_slot);
			}else if(color_type == object_tint){
				before_color = targets[i].GetTint();
			}
		}
	}

	bool SetColor(bool reset){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(color_type == object_palette_color){
				targets[i].SetPaletteColor(palette_slot, reset?before_color:after_color);
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
