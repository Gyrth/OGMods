enum state_choices { 	awake = 0,
						unconscious = 1,
						dead = 2,
						knows_about = 3
					}

class DrikaCheckCharacterState : DrikaElement{
	array<string> state_choice_names = {"Awake", "Unconscious", "Dead", "Knows About"};
	state_choices state_choice;
	int current_state_choice;
	bool equals = true;
	int known_character_id;

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_choice = state_choices(GetJSONInt(params, "state_check", awake));
		current_state_choice = state_choice;
		equals = GetJSONBool(params, "equals", true);
		known_character_id = GetJSONInt(params, "known_character_id", 0);

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
		data["state_check"] = JSONValue(state_choice);
		data["equals"] = JSONValue(equals);
		if(state_choice == knows_about){
			data["known_character_id"] = JSONValue(known_character_id);
		}
		SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "CheckCharacterState" + " " + GetTargetDisplayText() + (equals?" ":" not ") + state_choice_names[state_choice] + ((state_choice == knows_about)?" " +  known_character_id:"");
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_Checkbox("Equals", equals);
		if(ImGui_Combo("Check for", current_state_choice, state_choice_names, state_choice_names.size())){
			state_choice = state_choices(current_state_choice);
		}

		if(state_choice == knows_about){
			ImGui_InputInt("Known Character ID", known_character_id);
		}
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
			if(state_choice == knows_about){
				string command = "self_id = situation.KnownID(" + known_character_id + ");";
				targets[i].Execute(command);
				bool known = (targets[i].GetIntVar("self_id") != -1);
				if(known != equals){
					all_in_state = false;
				}
			}else{
				if((targets[i].GetIntVar("knocked_out") != state_choice) == equals){
					all_in_state = false;
				}
			}
		}
		return all_in_state;
	}
}
