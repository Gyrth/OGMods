enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	int new_target_character_type;
	int new_hotspot_trigger_type;

	target_character_types target_character_type;
	hotspot_trigger_types hotspot_trigger_type;

	array<string> character_trigger_choices = {"Check ID", "Check Team", "Any Character", "Any Player", "Any NPC"};
	array<string> hotspot_trigger_choices = {"On Enter", "On Exit"};

	DrikaOnCharacterEnterExit(JSONValue params = JSONValue()){
		target_character_type = target_character_types(GetJSONInt(params, "target_character_type", 0));
		new_target_character_type = target_character_type;

		hotspot_trigger_type = hotspot_trigger_types(GetJSONInt(params, "hotspot_trigger_type", 0));
		new_hotspot_trigger_type = hotspot_trigger_type;
		reference_string = GetJSONString(params, "reference_string", "");
		character_team = GetJSONString(params, "character_team", "");
		object_id = GetJSONInt(params, "object_id", -1);

		connection_types = {_movement_object};
		drika_element_type = drika_on_character_enter_exit;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("on_character_enter_exit");
		data["target_character_type"] = JSONValue(target_character_type);
		data["hotspot_trigger_type"] = JSONValue(hotspot_trigger_type);
		data["reference_string"] = JSONValue(reference_string);
		data["object_id"] = JSONValue(object_id);
		data["character_team"] = JSONValue(character_team);
		return data;
	}

	string GetReference(){
		return reference_string;
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
		if(target_character_type == check_id){
			ImGui_InputInt("ID", object_id);
		}else if(target_character_type == check_team){
			ImGui_InputText("Team", character_team, 64);
		}
		if(ImGui_Combo("Trigger when", new_hotspot_trigger_type, hotspot_trigger_choices, hotspot_trigger_choices.size())){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
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
					triggered = true;
					RegisterObject(param, reference_string);
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
				triggered = true;
				RegisterObject(id_param, reference_string);
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
