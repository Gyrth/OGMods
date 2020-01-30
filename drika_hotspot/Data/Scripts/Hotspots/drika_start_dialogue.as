class DrikaStartDialogue : DrikaElement{
	string dialogue_name;
	array<string> available_dialogues;
	array<int> dialogue_ids;
	int current_index;
	Object@ dialogue_obj;

	DrikaStartDialogue(JSONValue params = JSONValue()){
		dialogue_name = GetJSONString(params, "dialogue_name", "drika_dialogue");

		drika_element_type = drika_start_dialogue;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["dialogue_name"] = JSONValue(dialogue_name);
		return data;
	}

	string GetDisplayString(){
		return "StartDialogue " + dialogue_name;
	}

	void StartEdit(){
		available_dialogues.resize(0);
		dialogue_ids.resize(0);
		current_index = 0;
		array<int> placeholders = GetObjectIDsType(_placeholder_object);
		for(uint i = 0; i < placeholders.size(); i++){
			Object@ placeholder = ReadObjectFromID(placeholders[i]);
			ScriptParams@ params = placeholder.GetScriptParams();
			if(params.HasParam("DisplayName")){
				available_dialogues.insertLast(params.GetString("DisplayName"));
				dialogue_ids.insertLast(placeholders[i]);
				if(params.GetString("DisplayName") == dialogue_name){
					current_index = int(available_dialogues.size()) - 1;
				}
			}
		}
		if(available_dialogues.size() > 0){
			dialogue_name = available_dialogues[current_index];
			@dialogue_obj = ReadObjectFromID(dialogue_ids[current_index]);
		}
	}

	void DrawEditing(){
		if(@dialogue_obj != null){
			DebugDrawLine(dialogue_obj.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void DrawSettings(){
		if(ImGui_Combo("Dialogue", current_index, available_dialogues)){
			@dialogue_obj = ReadObjectFromID(dialogue_ids[current_index]);
			dialogue_name = available_dialogues[current_index];
		}
	}

	bool Trigger(){
		level.SendMessage("start_dialogue \"" + dialogue_name + "\"");
		return true;
	}
}
