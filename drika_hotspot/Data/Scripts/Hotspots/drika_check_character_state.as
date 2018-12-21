class DrikaCheckCharacterState : DrikaElement{
	string character_team;
	target_character_types target_character_type;
	int new_target_character_type;

	array<string> target_choices = {"Check ID", "Check Team"};
	array<string> state_choices = {"Awake", "Unconscious", "Dead"};
	int state_check;

	DrikaCheckCharacterState(string _target_character_type = "0", string _param = "-1", string _state_check = "1"){
		target_character_type = target_character_types(atoi(_target_character_type));
		new_target_character_type = target_character_type;

		state_check = atoi(_state_check);

		drika_element_type = drika_check_character_state;
		connection_types = {_movement_object};

		if(target_character_type == check_id){
			object_id = atoi(_param);
		}else if(target_character_type == check_team){
			character_team = _param;
		}
		has_settings = true;
	}

	string GetDisplayString(){
		string trigger_message = "";
		if(target_character_type == check_id){
			trigger_message = "" + object_id;
		}else if(target_character_type == check_team){
			trigger_message = character_team;
		}
		return "CheckCharacterState" + " " + trigger_message + " " + state_choices[state_check];
	}

	void DrawSettings(){
		if(ImGui_Combo("Target type", new_target_character_type, target_choices, target_choices.size())){
			target_character_type = target_character_types(new_target_character_type);
		}
		if(target_character_type == check_id){
			ImGui_InputInt("ID", object_id);
		}else if(target_character_type == check_team){
			ImGui_InputText("Team", character_team, 64);
		}
		ImGui_Combo("Check for", state_check, state_choices, state_choices.size());
	}

	void DrawEditing(){
		if(target_character_type == check_id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	string GetSaveString(){
		if(target_character_type == check_id){
			return "check_character_state" + param_delimiter + int(target_character_type) + param_delimiter + object_id + param_delimiter + state_check;
		}else{
			return "check_character_state" + param_delimiter + int(target_character_type) + param_delimiter + character_team + param_delimiter + state_check;
		}
	}

	bool Trigger(){
		if(target_character_type == check_id){
			if(MovementObjectExists(object_id)){
				MovementObject@ char = ReadCharacterID(object_id);
				if(char.HasVar("knocked_out")){
					if(char.GetIntVar("knocked_out") == state_check){
						return true;
					}
				}
			}
		}else if(target_character_type == check_team){
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
							if(char.GetIntVar("knocked_out") != state_check){
								all_in_state = false;
							}
						}
					}
				}
			}
			return all_in_state;
		}
		return false;
	}
}
