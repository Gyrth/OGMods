class DrikaSetMorphTarget : DrikaElement{
	string morph_1;
	string morph_2;
	float weight;
	float smoothing_duration;
	bool two_way_morph;
	array<string> available_morphs;
	int morph_1_index;
	int morph_2_index;
	float timer = 0.0;

	DrikaSetMorphTarget(JSONValue params = JSONValue()){
		morph_1 = GetJSONString(params, "morph_1", "mouth_open");
		morph_2 = GetJSONString(params, "morph_2", "mouth_open");
		weight = GetJSONFloat(params, "weight", 1.0);
		smoothing_duration = GetJSONFloat(params, "smoothing_duration", 0.0);
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
		data["morph_1"] = JSONValue(morph_1);
		data["morph_2"] = JSONValue(morph_2);
		data["weight"] = JSONValue(weight);
		data["smoothing_duration"] = JSONValue(smoothing_duration);
		data["two_way_morph"] = JSONValue(two_way_morph);
		SaveIdentifier(data);
		return data;
	}

	void Delete(){
		SetMorphTarget(true);
	}

	string GetDisplayString(){
		return "SetMorphTarget " + GetTargetDisplayText() + " " + morph_1 + (two_way_morph?"+" + morph_2:"") + " " + weight;
	}

	void StartSettings(){
		if(available_morphs.size() == 0){
			GetAvailableMorphs();
		}
		CheckReferenceAvailable();
		SetMorphTarget(false);
	}

	void StartEdit(){
		SetMorphTarget(false);
	}

	void EditDone(){
		SetMorphTarget(true);
	}

	void PreTargetChanged(){
		SetMorphTarget(true);
	}

	void TargetChanged(){
		SetMorphTarget(false);
	}

	void GetMorphIndex(){
		morph_1_index = 0;
		morph_2_index = 0;
		for(uint i = 0; i < available_morphs.size(); i++){
			if(available_morphs[i] == morph_1){
				morph_1_index = i;
			}
			if(available_morphs[i] == morph_2){
				morph_2_index = i;
			}
		}
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

		float extra_space = 8.0f;

		if(two_way_morph){
			ImGui_PushItemWidth(ImGui_GetWindowContentRegionWidth() * 0.25);
			if(ImGui_Combo("###Morph 1", morph_1_index, available_morphs, available_morphs.size())){
				morph_1 = available_morphs[morph_1_index];
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			ImGui_PopItemWidth();

			ImGui_SameLine();

			ImGui_PushItemWidth(ImGui_GetWindowContentRegionWidth() * 0.5 - extra_space);
			if(ImGui_SliderFloat("###Weight", weight, -1.0f, 1.0f, "%.2f")){
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			ImGui_PopItemWidth();

			ImGui_SameLine();

			ImGui_PushItemWidth(ImGui_GetWindowContentRegionWidth() * 0.25 - extra_space);
			if(ImGui_Combo("###Morph 2", morph_2_index, available_morphs, available_morphs.size())){
				morph_2 = available_morphs[morph_2_index];
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			ImGui_PopItemWidth();
		}else{
			ImGui_PushItemWidth(ImGui_GetWindowContentRegionWidth() * 0.25 - extra_space);
			if(ImGui_Combo("###Morph 1", morph_1_index, available_morphs, available_morphs.size())){
				morph_1 = available_morphs[morph_1_index];
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			ImGui_PopItemWidth();

			ImGui_SameLine();

			ImGui_PushItemWidth(-1);
			if(ImGui_SliderFloat("###Weight", weight, 0.0f, 1.0f, "%.2f")){
				SetMorphTarget(true);
				SetMorphTarget(false);
			}
			ImGui_PopItemWidth();
		}
		ImGui_SliderFloat("Smoothing Duration", smoothing_duration, 0.0f, 10.0f, "%.2f");
	}

	bool Trigger(){
		if(UpdateSmoothing()){
			SetMorphTarget(false);
			triggered = false;
			timer = 0.0;
			return true;
		}else{
			return false;
		}
	}

	bool UpdateSmoothing(){
		if(timer >= smoothing_duration){
			return true;
		}else{
			SetMorphTarget(false);
			timer += time_step;
		}
		return false;
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
		UpdateSmoothing();
	}

	bool SetMorphTarget(bool reset){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		if(reset){
			triggered = false;
			timer = 0.0;
		}

		float weight_weight = smoothing_duration == 0.0f?1.0:min(1.0, max(0.0, timer / smoothing_duration));
		for(uint i = 0; i < targets.size(); i++){
			if(reset){
				targets[i].rigged_object().SetMorphTargetWeight(morph_1, 0.0f, 1.0);
				targets[i].rigged_object().SetMorphTargetWeight(morph_2, 0.0f, 1.0);
			}else{
				if(two_way_morph){
					if(weight < 0.0){
						targets[i].rigged_object().SetMorphTargetWeight(morph_1, abs(weight), weight_weight);
						targets[i].rigged_object().SetMorphTargetWeight(morph_2, 0.0f, weight_weight);
					}else{
						targets[i].rigged_object().SetMorphTargetWeight(morph_1, 0.0f, weight_weight);
						targets[i].rigged_object().SetMorphTargetWeight(morph_2, weight, weight_weight);
					}
				}else{
					targets[i].rigged_object().SetMorphTargetWeight(morph_1, weight, weight_weight);
				}
			}
		}
		return true;
	}

	void ReceiveMessage(string message){
		array<string> file_lines = message.split("\n");
		bool inside_morph = false;

		for(uint i = 0; i < file_lines.size(); i++){
			string line = file_lines[i];
			//Remove any tabs.
			line = join(line.split("\t"), "");
			if(line.findFirst("<morphs>") != -1){
				//Find the content within the <morphs> tags.
				inside_morph = true;
			}else if(line.findFirst("</morphs>") != -1){
				//Found the end of the morphs tag.
				break;
			}else if(inside_morph){
				//This line has a morph in it because it starts with a <.
				int tag_start = line.findFirst("<") + 1;
				if(tag_start != 0){
					int tag_end = line.findFirst(" ", tag_start);
					if(tag_end != -1){
						string new_morph_name = line.substr(tag_start, tag_end - tag_start);
						//Check if the morph is already added.
						if(available_morphs.find(new_morph_name) == -1){
							available_morphs.insertLast(new_morph_name);
						}
					}
				}
			}
		}
		GetMorphIndex();
	}

	void GetAvailableMorphs(){
		available_morphs.resize(0);

		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			level.SendMessage("drika_read_file " + hotspot.GetID() + " " + targets[i].char_path);
		}
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetMorphTarget(true);
		}
	}
}
