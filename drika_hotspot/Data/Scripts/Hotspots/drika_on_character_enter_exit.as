enum character_trigger_types {	check_id = 0,
								check_team = 1};

enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	string character_team;
	int character_id;
	int new_character_trigger_type;
	int new_hotspot_trigger_type;

	character_trigger_types character_trigger_type;
	hotspot_trigger_types hotspot_trigger_type;

	bool triggered = false;

	DrikaOnCharacterEnterExit(int _character_trigger_type = 0, string _param = "-1", int _hotspot_trigger_type = int(on_enter)){
		character_trigger_type = character_trigger_types(_character_trigger_type);
		hotspot_trigger_type = hotspot_trigger_types(_hotspot_trigger_type);
		new_hotspot_trigger_type = hotspot_trigger_type;

		drika_element_type = drika_on_character_enter_exit;

		if(character_trigger_type == check_id){
			character_id = atoi(_param);
			new_character_trigger_type = character_trigger_type;
		}else{
			character_team = _param;
		}
		has_settings = true;
	}

	string GetSaveString(){
		if(character_trigger_type == check_id){
			return "on_character_enter_exit " + int(character_trigger_type) + " " + character_id + " " + int(hotspot_trigger_type);
		}else{
			return "on_character_enter_exit " + int(character_trigger_type) + " " + character_team + " " + int(hotspot_trigger_type);
		}
	}

	string GetDisplayString(){
		if(character_trigger_type == check_id){
			return "OnCharacterEnterExit " + character_id;
		}else{
			return "OnCharacterEnterExit " + character_team;
		}
	}

	void AddSettings(){
		if(ImGui_Combo("Check for", new_character_trigger_type, {"Check ID", "Check Team"})){
			character_trigger_type = character_trigger_types(new_character_trigger_type);
		}
		if(ImGui_Combo("Trigger when", new_hotspot_trigger_type, {"On Enter", "On Exit"})){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
		}
		if(character_trigger_type == check_id){
			ImGui_InputInt("ID", character_id);
		}else{
			ImGui_InputText("Team", character_team, 64);
		}
	}

	void ReceiveMessage(string message, int param){
		if((character_trigger_type == check_id && hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(character_trigger_type == check_id && hotspot_trigger_type == on_exit && message == "CharacterExit")){
			if(param == character_id){
				triggered = true;
			}
		}
	}

	void ReceiveMessage(string message, string param){
		if((character_trigger_type == check_team && hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(character_trigger_type == check_team && hotspot_trigger_type == on_exit && message == "CharacterExit")){
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
