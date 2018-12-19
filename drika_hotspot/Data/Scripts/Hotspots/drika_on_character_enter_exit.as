enum character_trigger_types {	check_id = 0,
								check_team = 1,
								any_character = 2,
								any_player = 3,
								any_npc = 4
							};

enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	string character_team;
	int new_character_trigger_type;
	int new_hotspot_trigger_type;

	character_trigger_types character_trigger_type;
	hotspot_trigger_types hotspot_trigger_type;

	DrikaOnCharacterEnterExit(string _character_trigger_type = "0", string _param = "-1", string _hotspot_trigger_type = "0"){
		character_trigger_type = character_trigger_types(atoi(_character_trigger_type));
		hotspot_trigger_type = hotspot_trigger_types(atoi(_hotspot_trigger_type));
		new_hotspot_trigger_type = hotspot_trigger_type;
		new_character_trigger_type = character_trigger_type;

		drika_element_type = drika_on_character_enter_exit;
		connection_types = {_movement_object};

		if(character_trigger_type == check_id){
			object_id = atoi(_param);
		}else if(character_trigger_type == check_team){
			character_team = _param;
		}
		has_settings = true;
	}

	string GetSaveString(){
		if(character_trigger_type == check_id){
			return "on_character_enter_exit" + param_delimiter + int(character_trigger_type) + param_delimiter + object_id + param_delimiter + int(hotspot_trigger_type);
		}else if(character_trigger_type == check_team){
			return "on_character_enter_exit" + param_delimiter + int(character_trigger_type) + param_delimiter + character_team + param_delimiter + int(hotspot_trigger_type);
		}else{
			return "on_character_enter_exit" + param_delimiter + int(character_trigger_type) + param_delimiter + "" + param_delimiter + int(hotspot_trigger_type);
		}
	}

	string GetDisplayString(){
		string trigger_message = "";
		if(character_trigger_type == check_id){
			trigger_message = "" + object_id;
		}else if(character_trigger_type == check_team){
			trigger_message = character_team;
		}else if(character_trigger_type == any_character){
			trigger_message = "Any Character";
		}else if(character_trigger_type == any_player){
			trigger_message = "Any Player";
		}else if(character_trigger_type == any_npc){
			trigger_message = "Any NPC";
		}
		return "OnCharacter" + ((hotspot_trigger_type == on_enter)?"Enter":"Exit") + " " + trigger_message;
	}

	void DrawSettings(){
		array<string> character_trigger_choices = {"Check ID", "Check Team", "Any Character", "Any Player", "Any NPC"};
		if(ImGui_Combo("Check for", new_character_trigger_type, character_trigger_choices, character_trigger_choices.size())){
			character_trigger_type = character_trigger_types(new_character_trigger_type);
		}
		array<string> hotspot_trigger_choices = {"On Enter", "On Exit"};
		if(ImGui_Combo("Trigger when", new_hotspot_trigger_type, hotspot_trigger_choices, hotspot_trigger_choices.size())){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
		}
		if(character_trigger_type == check_id){
			ImGui_InputInt("ID", object_id);
		}else if(character_trigger_type == check_team){
			ImGui_InputText("Team", character_team, 64);
		}
	}

	void DrawEditing(){
		if(character_trigger_type == check_id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void ReceiveMessage(string message, int param){
		if((hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(hotspot_trigger_type == on_exit && message == "CharacterExit")){
			if(MovementObjectExists(param)){
				MovementObject@ character = ReadCharacterID(param);
				if(	character_trigger_type == check_id && object_id == param ||
					character_trigger_type == any_character ||
					character_trigger_type == any_player && character.controlled ||
					character_trigger_type == any_npc && !character.controlled){
					Log(info, "OnEnterExit triggered");
					triggered = true;
				}
			}
		}
	}

	void ReceiveMessage(string message, string param){
		if((character_trigger_type == check_team && hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(character_trigger_type == check_team && hotspot_trigger_type == on_exit && message == "CharacterExit")){
			//Removed all the spaces.
			string no_spaces_param = join(param.split(" "), "");
			//Teams are , seperated.
			array<string> teams = no_spaces_param.split(",");
			if(teams.find(character_team) != -1){
				Log(info, "OnEnterExit triggered");
				triggered = true;
			}
		}
	}

	void Reset(){
		triggered = false;
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
