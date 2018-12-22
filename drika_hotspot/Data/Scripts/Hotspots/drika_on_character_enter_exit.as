enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	string character_team;
	int new_target_character_type;
	int new_hotspot_trigger_type;

	target_character_types target_character_type;
	hotspot_trigger_types hotspot_trigger_type;

	array<string> character_trigger_choices = {"Check ID", "Check Team", "Any Character", "Any Player", "Any NPC"};
	array<string> hotspot_trigger_choices = {"On Enter", "On Exit"};

	DrikaOnCharacterEnterExit(string _target_character_type = "0", string _param = "-1", string _hotspot_trigger_type = "0", string _reference_string = ""){
		target_character_type = target_character_types(atoi(_target_character_type));
		new_target_character_type = target_character_type;
		hotspot_trigger_type = hotspot_trigger_types(atoi(_hotspot_trigger_type));
		new_hotspot_trigger_type = hotspot_trigger_type;
		reference_string = _reference_string;

		drika_element_type = drika_on_character_enter_exit;
		connection_types = {_movement_object};

		if(target_character_type == check_id){
			object_id = atoi(_param);
		}else if(target_character_type == check_team){
			character_team = _param;
		}
		has_settings = true;
	}

	string GetReference(){
		return reference_string;
	}

	array<string> GetSaveParameters(){
		if(target_character_type == check_id){
			return {"on_character_enter_exit", target_character_type, object_id, hotspot_trigger_type, reference_string};
		}else if(target_character_type == check_team){
			return {"on_character_enter_exit", target_character_type, character_team, hotspot_trigger_type, reference_string};
		}else{
			return {"on_character_enter_exit", target_character_type, "", hotspot_trigger_type, reference_string};
		}
	}

	string GetDisplayString(){
		string trigger_message = "";
		if(target_character_type == check_id){
			trigger_message = "" + object_id;
		}else if(target_character_type == check_team){
			trigger_message = character_team;
		}else if(target_character_type == any_character){
			trigger_message = "Any Character";
		}else if(target_character_type == any_player){
			trigger_message = "Any Player";
		}else if(target_character_type == any_npc){
			trigger_message = "Any NPC";
		}
		return "OnCharacter" + ((hotspot_trigger_type == on_enter)?"Enter":"Exit") + " " + trigger_message;
	}

	void DrawSettings(){
		if(ImGui_Combo("Check for", new_target_character_type, character_trigger_choices, character_trigger_choices.size())){
			target_character_type = target_character_types(new_target_character_type);
		}
		if(ImGui_Combo("Trigger when", new_hotspot_trigger_type, hotspot_trigger_choices, hotspot_trigger_choices.size())){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
		}
		if(target_character_type == check_id){
			ImGui_InputInt("ID", object_id);
		}else if(target_character_type == check_team){
			ImGui_InputText("Team", character_team, 64);
		}
		DrawSetReferenceUI();
	}

	void DrawEditing(){
		if(target_character_type == check_id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void ReceiveMessage(string message, int param){
		if((hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(hotspot_trigger_type == on_exit && message == "CharacterExit")){
			if(MovementObjectExists(param)){
				MovementObject@ character = ReadCharacterID(param);
				if(	target_character_type == check_id && object_id == param ||
					target_character_type == any_character ||
					target_character_type == any_player && character.controlled ||
					target_character_type == any_npc && !character.controlled){
					Log(info, "OnEnterExit triggered");
					triggered = true;
					//If the reference already exists then a new one is assigned by the hotspot.
					reference_string = RegisterObject(param, reference_string);
				}
			}
		}
	}

	void ReceiveMessage(string message, string param, int id_param){
		if((target_character_type == check_team && hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(target_character_type == check_team && hotspot_trigger_type == on_exit && message == "CharacterExit")){
			//Removed all the spaces.
			string no_spaces_param = join(param.split(" "), "");
			//Teams are , seperated.
			array<string> teams = no_spaces_param.split(",");
			if(teams.find(character_team) != -1){
				Log(info, "OnEnterExit triggered");
				triggered = true;
				//If the reference already exists then a new one is assigned by the hotspot.
				reference_string = RegisterObject(id_param, reference_string);
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
