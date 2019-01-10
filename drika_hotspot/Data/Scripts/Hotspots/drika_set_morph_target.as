class DrikaSetMorphTarget : DrikaElement{
	string label;
	string label2;
	float weight;
	bool two_way_morph;

	DrikaSetMorphTarget(JSONValue params = JSONValue()){
		label = GetJSONString(params, "label", "mouth_open");
		label2 = GetJSONString(params, "label2", "mouth_open");
		weight = GetJSONFloat(params, "weight", 1.0);
		two_way_morph = GetJSONBool(params, "two_way_morph", false);
		LoadIdentifier(params);
		show_team_option = true;
		show_name_option = true;

		connection_types = {_movement_object};
		drika_element_type = drika_set_morph_target;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_morph_target");
		data["label"] = JSONValue(label);
		data["label2"] = JSONValue(label2);
		data["weight"] = JSONValue(weight);
		data["two_way_morph"] = JSONValue(two_way_morph);
		SaveIdentifier(data);
		return data;
	}

	void Delete(){
		if(triggered){
			SetMorphTarget(true);
		}
	}

	string GetDisplayString(){
		return "SetMorphTarget " + GetTargetDisplayText() + " " + label + (two_way_morph?"+" + label2:"") + " " + weight;
	}

	void StartSettings(){
		CheckReferenceAvailable();
		SetMorphTarget(false);
	}

	void ApplySettings(){
		//Reset the morph value set by the preview.
		SetMorphTarget(true);
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		if(ImGui_Checkbox("Two Way Morph Target", two_way_morph)){
			//A single morph target cannot go under 0.
			if(!two_way_morph && weight < 0.0){
				weight = 0.0;
			}
			SetMorphTarget(true);
			SetMorphTarget(false);
		}

		if(ImGui_InputText("Label", label, 64)){
			SetMorphTarget(true);
			SetMorphTarget(false);
		}

		if(two_way_morph){
			if(ImGui_InputText("Label 2", label2, 64)){
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			if(ImGui_SliderFloat("Weight", weight, -2.0f, 2.0f, "%.2f")){
				SetMorphTarget(false);
			}
		}else{
			if(ImGui_SliderFloat("Weight", weight, 0.0f, 2.0f, "%.2f")){
				SetMorphTarget(false);
			}
		}
	}

	bool Trigger(){
		triggered = true;
		return SetMorphTarget(false);
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool SetMorphTarget(bool reset){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			if(reset){
				targets[i].rigged_object().SetMorphTargetWeight(label, 0.0f, 1.0);
				targets[i].rigged_object().SetMorphTargetWeight(label2, 0.0f, 1.0);
			}else{
				if(two_way_morph){
					if(weight < 0.0){
						targets[i].rigged_object().SetMorphTargetWeight(label, abs(weight), 1.0);
						targets[i].rigged_object().SetMorphTargetWeight(label2, 0.0f, 1.0f);
					}else{
						targets[i].rigged_object().SetMorphTargetWeight(label, 0.0f, 0.0f);
						targets[i].rigged_object().SetMorphTargetWeight(label2, weight, 1.0);
					}
				}else{
					targets[i].rigged_object().SetMorphTargetWeight(label, weight, 1.0);
				}
			}
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetMorphTarget(true);
		}
	}
}
