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
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			Log(warning, "MovementObject does not exist with id " + target_object.GetID());
			return;
		}
	}

	void Delete(){
		if(triggered){
			SetMorphTarget(true);
		}
	}

	string GetDisplayString(){
		return "SetMorphTarget " + label + " " + weight + " " + weight_weight;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void ApplySettings(){
		//Reset the morph value set by the preview.
		SetMorphTarget(true);
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_InputText("Label", label, 64)){
			SetMorphTarget(false);
		}
		if(ImGui_SliderFloat("Weight", weight, 0.0f, 1.0f, "%.2f")){
			SetMorphTarget(false);
		}
		if(ImGui_SliderFloat("Weight weight", weight_weight, 0.0f, 1.0f, "%.2f")){
			SetMorphTarget(false);
		}
	}

	bool Trigger(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return false;
		}
		triggered = true;
		SetMorphTarget(false);
		return true;
	}

	void DrawEditing(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return;
		}
		DebugDrawLine(target_character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
	}

	void SetMorphTarget(bool reset){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return;
		}
		target_character.rigged_object().SetMorphTargetWeight(label, reset?0.0f:weight, reset?0.0f:weight_weight);
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetMorphTarget(true);
		}
	}
}
