enum character_trigger_types {	check_id,
								check_team};

class DrikaOnCharacterEnter : DrikaElement{
	string character_team;
	int character_id;
	int current_item = 0;
	character_trigger_types trigger_type;
	bool triggered = false;

	DrikaOnCharacterEnter(int _character_id = 0, string _character_team = ""){
		character_id = _character_id;
		character_team = _character_team;
		drika_element_type = drika_on_character_enter;
		display_color = vec4(110, 94, 180, 255);
		has_settings = true;
		if(character_team == ""){
			trigger_type = check_id;
		}else{
			trigger_type = check_team;
		}
	}

	string GetSaveString(){
		return "on_character_enter " + character_id + " " + character_team;
	}

	string GetDisplayString(){
		if(trigger_type == check_id){
			return "OnCharacterEnter " + character_id;
		}else{
			return "OnCharacterEnter " + character_team;
		}
	}

	void AddSettings(){
		if(ImGui_Combo("Check for", current_item, {"Check ID", "Check Team"})){
			if(current_item == 0){
				trigger_type = check_id;
			}else{
				trigger_type = check_team;
			}
		}
		if(trigger_type == check_id){
			ImGui_InputInt("ID", character_id);
		}else{
			ImGui_InputText("Team", character_team, 64);
		}
	}

	void ReceiveMessage(string message, int param){
		if(trigger_type == check_id && message == "CharacterEnter"){
			if(param == character_id){
				triggered = true;
			}
		}
	}

	void ReceiveMessage(string message, string param){
		if(trigger_type == check_team && message == "CharacterEnter"){
			if(param == character_team){
				triggered = true;
			}
		}
	}

	bool Trigger(){
		if(triggered){
			triggered = false;
			return true;
		}else{
			return false;
		}
	}

}
