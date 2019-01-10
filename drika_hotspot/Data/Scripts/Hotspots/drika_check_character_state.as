class DrikaCheckCharacterState : DrikaElement{
	array<string> target_choices = {"Check ID", "Check Reference", "Check Team"};
	array<string> state_choices = {"Awake", "Unconscious", "Dead"};
	int state_check;
	bool equals = true;

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_check = GetJSONInt(params, "state_check", 0);
		equals = GetJSONBool(params, "equals", true);
		LoadIdentifier(params);
		show_team_option = true;
		show_name_option = true;

		drika_element_type = drika_check_character_state;
		connection_types = {_movement_object};

		has_settings = true;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("check_character_state");
		data["state_check"] = JSONValue(state_check);
		data["equals"] = JSONValue(equals);
		SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "CheckCharacterState" + " " + GetTargetDisplayText() + (equals?" ":" not ") + state_choices[state_check];
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_Checkbox("Equals", equals);
		ImGui_Combo("Check for", state_check, state_choices, state_choices.size());
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		bool all_in_state = true;
		for(uint i = 0; i < targets.size(); i++){
			if((targets[i].GetIntVar("knocked_out") != state_check) == equals){
				all_in_state = false;
			}
		}
		return all_in_state;
	}
}
