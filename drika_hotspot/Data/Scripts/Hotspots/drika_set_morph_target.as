class DrikaSetMorphTarget : DrikaElement{
	string label;
	float weight;
	float weight_weight;

	DrikaSetMorphTarget(JSONValue params = JSONValue()){
		label = GetJSONString(params, "label", "mouth_open");
		weight = GetJSONFloat(params, "weight", 1.0);
		weight_weight = GetJSONFloat(params, "weight_weight", 1.0);
		InterpIdentifier(params);

		connection_types = {_movement_object};
		drika_element_type = drika_set_morph_target;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_morph_target");
		data["label"] = JSONValue(label);
		data["weight"] = JSONValue(weight);
		data["weight_weight"] = JSONValue(weight_weight);
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}
		return data;
	}

	void PostInit(){
		if(!MovementObjectExists(object_id)){
			Log(warning, "Character does not exist with id " + object_id);
		}
	}

	string GetDisplayString(){
		return "SetMorphTarget " + label + " " + weight + " " + weight_weight;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_InputText("Label", label, 64);
		ImGui_SliderFloat("Weight", weight, 0.0f, 1.0f, "%.2f");
		ImGui_SliderFloat("Weight weight", weight_weight, 0.0f, 1.0f, "%.2f");
	}

	bool Trigger(){
		if(object_id == -1 || !MovementObjectExists(object_id)){
			return false;
		}
		triggered = true;
		SetMorphTarget(false);
		return true;
	}

	void DrawEditing(){
		if(object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void SetMorphTarget(bool reset){
		if(object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			character.rigged_object().SetMorphTargetWeight(label, reset?0.0f:weight, reset?0.0f:weight_weight);
		}
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetMorphTarget(true);
		}
	}
}
