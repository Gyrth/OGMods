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
	TargetSelect known_target(this, "known_target");

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_choice = state_choices(GetJSONInt(params, "state_check", awake));
		current_state_choice = state_choice;
		equals = GetJSONBool(params, "equals", true);

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;

		known_target.LoadIdentifier(params);
		known_target.target_option = id_option | name_option | character_option | reference_option | team_option;

		drika_element_type = drika_check_character_state;
		connection_types = {_movement_object};

		has_settings = true;
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
		known_target.CheckAvailableTargets();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["state_check"] = JSONValue(state_choice);
		data["equals"] = JSONValue(equals);
		if(state_choice == knows_about){
			known_target.SaveIdentifier(data);
		}
		target_select.SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "CheckCharacterState" + " " + target_select.GetTargetDisplayText() + (equals?" ":" not ") + state_choice_names[state_choice] + ((state_choice == knows_about)?" " +  known_target.GetTargetDisplayText():"");
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();
		ImGui_Checkbox("Equals", equals);
		if(ImGui_Combo("Check for", current_state_choice, state_choice_names, state_choice_names.size())){
			state_choice = state_choices(current_state_choice);
		}

		if(state_choice == knows_about){
			ImGui_Separator();
			ImGui_Text("Known Character");
			known_target.DrawSelectTargetUI();
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		array<MovementObject@> known_targets = known_target.GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		bool all_in_state = true;

		for(uint i = 0; i < targets.size(); i++){
			if(state_choice == knows_about){
				for(uint j = 0; j < known_targets.size(); j++){
					string command = "self_id = situation.KnownID(" + known_targets[j].GetID() + ");";
					targets[i].Execute(command);
					bool known = (targets[i].GetIntVar("self_id") != -1);
					if(known != equals){
						all_in_state = false;
					}
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
