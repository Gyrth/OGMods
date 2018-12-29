class DrikaCheckCharacterState : DrikaElement{
	array<string> target_choices = {"Check ID", "Check Reference", "Check Team"};
	array<string> state_choices = {"Awake", "Unconscious", "Dead"};
	int state_check;
	bool equals = true;

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_check = GetJSONInt(params, "state_check", 0);
		equals = GetJSONBool(params, "equals", true);
		InterpIdentifier(params);
		show_team_option = true;

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

	string GetDisplayString(){
		string trigger_message = "";
		if(identifier_type == id){
			trigger_message = "" + object_id;
		}else if(identifier_type == reference){
			trigger_message = reference_string;
		}else if(identifier_type == team){
			trigger_message = character_team;
		}
		return "CheckCharacterState" + " " + trigger_message + (equals?" ":" not ") + state_choices[state_check];
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_Checkbox("Equals", equals);
		ImGui_Combo("Check for", state_check, state_choices, state_choices.size());
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool Trigger(){
		if(identifier_type == id){
			if(MovementObjectExists(object_id)){
				MovementObject@ char = ReadCharacterID(object_id);
				if(char.HasVar("knocked_out")){
					if((char.GetIntVar("knocked_out") == state_check) == equals){
						return true;
					}
				}
			}
		}else if(identifier_type == team){
			int num_characters = GetNumCharacters();
			bool all_in_state = true;
			for(int i = 0; i < num_characters; i++){
				MovementObject@ char = ReadCharacter(i);
				Object@ obj = ReadObjectFromID(char.GetID());
				ScriptParams@ char_params = obj.GetScriptParams();
				if(char.HasVar("knocked_out")){
					if(char_params.HasParam("Teams")){
						//Removed all the spaces.
						string no_spaces_param = join(char_params.GetString("Teams").split(" "), "");
						//Teams are , seperated.
						array<string> teams = no_spaces_param.split(",");
						if(teams.find(character_team) != -1){
							if((char.GetIntVar("knocked_out") != state_check) == equals){
								all_in_state = false;
							}
						}
					}
				}
			}
			return all_in_state;
		}else if(identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				Log(warning, "MovementObject does not exist with reference " + reference_string);
				return false;
			}
			if(MovementObjectExists(registered_object_id)){
				MovementObject@ char = ReadCharacterID(registered_object_id);
				if(char.HasVar("knocked_out")){
					if((char.GetIntVar("knocked_out") == state_check) == equals){
						return true;
					}
				}
			}else{
				Log(warning, "Object with reference " + reference_string + " is not a MovementObject!");
			}
		}
		return false;
	}
}
