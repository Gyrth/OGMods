enum character_trigger_types {	check_id = 0,
								check_team = 1};

class DrikaOnCharacterEnter : DrikaElement{
	string character_team;
	int character_id;
	int current_item;
	character_trigger_types trigger_type;
	bool triggered = false;

	DrikaOnCharacterEnter(int _trigger_type = 0, int _character_id = -1, string _character_team = ""){
		character_id = _character_id;
		character_team = _character_team;
		trigger_type = character_trigger_types(_trigger_type);
		current_item = _trigger_type;

		drika_element_type = drika_on_character_enter;

		display_color = vec4(110, 94, 180, 255);
		has_settings = true;
	}

	string GetSaveString(){
		return "on_character_enter " + int(trigger_type) + " " + character_id + " " + character_team;
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
			trigger_type = character_trigger_types(current_item);
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
