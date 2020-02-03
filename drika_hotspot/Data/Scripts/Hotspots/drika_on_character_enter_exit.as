enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1,
								while_inside = 2,
								while_outside = 3};

enum target_character_types {	check_id = 0,
								check_team = 1,
								any_character = 2,
								any_player = 3,
								any_npc = 4
							};

class DrikaOnCharacterEnterExit : DrikaElement{
	int new_target_character_type;
	int new_hotspot_trigger_type;
	bool external_hotspot;
	int external_hotspot_id;
	Object@ external_hotspot_obj = null;
	bool reset_when_false;

	target_character_types target_character_type;
	hotspot_trigger_types hotspot_trigger_type;

	array<string> character_trigger_choices = {"Check ID", "Check Team", "Any Character", "Any Player", "Any NPC"};
	array<string> hotspot_trigger_choices = {"On Enter", "On Exit", "While Inside", "While Outside"};

	DrikaOnCharacterEnterExit(JSONValue params = JSONValue()){
		target_character_type = target_character_types(GetJSONInt(params, "target_character_type", 0));
		new_target_character_type = target_character_type;

		hotspot_trigger_type = hotspot_trigger_types(GetJSONInt(params, "hotspot_trigger_type", 0));
		new_hotspot_trigger_type = hotspot_trigger_type;
		reference_string = GetJSONString(params, "reference_string", "");
		character_team = GetJSONString(params, "character_team", "");
		object_id = GetJSONInt(params, "object_id", -1);
		external_hotspot = GetJSONBool(params, "external_hotspot", false);
		external_hotspot_id = GetJSONInt(params, "external_hotspot_id", -1);
		reset_when_false = GetJSONBool(params, "reset_when_false", false);

		connection_types = {_movement_object};
		drika_element_type = drika_on_character_enter_exit;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["target_character_type"] = JSONValue(target_character_type);
		data["hotspot_trigger_type"] = JSONValue(hotspot_trigger_type);
		data["reference_string"] = JSONValue(reference_string);
		data["object_id"] = JSONValue(object_id);
		data["character_team"] = JSONValue(character_team);
		data["external_hotspot"] = JSONValue(external_hotspot);
		if(external_hotspot){
			data["external_hotspot_id"] = JSONValue(external_hotspot_id);
		}
		if(hotspot_trigger_type == while_inside || hotspot_trigger_type == while_outside){
			data["reset_when_false"] = JSONValue(reset_when_false);
		}
		return data;
	}

	void PostInit(){
		if(external_hotspot){
			if(duplicating){
				if(ObjectExists(external_hotspot_id)){
					//Use the same transform as the original external hotspot.
					Object@ old_hotspot = ReadObjectFromID(external_hotspot_id);
					CreateExternalHotspot();
					external_hotspot_obj.SetScale(old_hotspot.GetScale());
					external_hotspot_obj.SetTranslation(old_hotspot.GetTranslation());
					external_hotspot_obj.SetRotation(old_hotspot.GetRotation());
				}else{
					external_hotspot_id = -1;
				}
			}else{
				if(ObjectExists(external_hotspot_id)){
					@external_hotspot_obj = ReadObjectFromID(external_hotspot_id);
					external_hotspot_obj.SetName("Drika External Hotspot");
				}else{
					CreateExternalHotspot();
				}
			}
		}
	}

	void Update(){
		if(duplicate_external_hotspot){
			duplicate_external_hotspot = false;
			if(ObjectExists(external_hotspot_id)){
				//Use the same transform as the original external hotspot.
				Object@ old_hotspot = ReadObjectFromID(external_hotspot_id);
				CreateExternalHotspot();
				external_hotspot_obj.SetScale(old_hotspot.GetScale());
				external_hotspot_obj.SetTranslation(old_hotspot.GetTranslation());
				external_hotspot_obj.SetRotation(old_hotspot.GetRotation());
			}else{
				external_hotspot_id = -1;
			}
			return;
		}

		if(external_hotspot_id == -1 && external_hotspot){
			CreateExternalHotspot();
		}else if(external_hotspot_id != -1 && !external_hotspot){
			QueueDeleteObjectID(external_hotspot_id);
			@external_hotspot_obj = null;
			external_hotspot_id = -1;
		}
	}

	void Delete(){
		if(external_hotspot && ObjectExists(external_hotspot_id)){
			QueueDeleteObjectID(external_hotspot_id);
			@external_hotspot_obj = null;
		}
	}

	void LeftClick(){
		if(this_hotspot.IsSelected() && ObjectExists(external_hotspot_id)){
			this_hotspot.SetSelected(false);
			external_hotspot_obj.SetSelected(true);
		}else if(ObjectExists(external_hotspot_id) && external_hotspot_obj.IsSelected()){
			external_hotspot_obj.SetSelected(false);
			this_hotspot.SetSelected(false);
		}else{
			if(ObjectExists(external_hotspot_id)){
				external_hotspot_obj.SetSelected(false);
			}
			this_hotspot.SetSelected(true);
		}
	}

	void EditDone(){
		if(external_hotspot && ObjectExists(external_hotspot_id)){
			external_hotspot_obj.SetSelected(false);
			external_hotspot_obj.SetSelectable(false);
		}
	}

	void StartEdit(){
		if(external_hotspot && ObjectExists(external_hotspot_id)){
			external_hotspot_obj.SetSelectable(true);
		}
	}

	string GetReference(){
		return reference_string;
	}

	string GetDisplayString(){
		string display_string = "";

		if(hotspot_trigger_type == on_enter){
			display_string += "OnCharacterEnter ";
		}else if(hotspot_trigger_type == on_exit){
			display_string += "OnCharacterExit ";
		}else if(hotspot_trigger_type == while_inside){
			display_string += "WhileCharacterInside ";
		}else if(hotspot_trigger_type == while_outside){
			display_string += "WhileCharacterOutside ";
		}

		if(target_character_type == check_id){
			display_string += "" + object_id;
		}else if(target_character_type == check_team){
			display_string += character_team;
		}else if(target_character_type == any_character){
			display_string += "Any Character";
		}else if(target_character_type == any_player){
			display_string += "Any Player";
		}else if(target_character_type == any_npc){
			display_string += "Any NPC";
		}
		return display_string;
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

		if(hotspot_trigger_type == while_inside || hotspot_trigger_type == while_outside){
			ImGui_Checkbox("Reset When False", reset_when_false);
		}

		ImGui_Checkbox("External Hotspot", external_hotspot);

		DrawSetReferenceUI();
	}

	void DrawEditing(){
		if(target_character_type == check_id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}

		if(@external_hotspot_obj != null){
			DebugDrawLine(external_hotspot_obj.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void CreateExternalHotspot(){
		external_hotspot_id = CreateObject("Data/Objects/Hotspots/drika_external_hotspot.xml", false);
		@external_hotspot_obj = ReadObjectFromID(external_hotspot_id);
		external_hotspot_obj.SetName("Drika External Hotspot");
		external_hotspot_obj.SetSelectable(true);
		external_hotspot_obj.SetTranslatable(true);
		external_hotspot_obj.SetScalable(true);
		external_hotspot_obj.SetRotatable(true);
		external_hotspot_obj.SetScale(vec3(0.25));
		external_hotspot_obj.SetTranslation(this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0));
		ScriptParams@ external_params = external_hotspot_obj.GetScriptParams();
		external_params.SetInt("Target Drika Hotspot", this_hotspot.GetID());
	}

	void ReceiveMessage(string message, int param){
		//This is triggered by characters entering/exiting the current hotspot.
		if(!external_hotspot){
			CheckEvent(message, param);
		}
	}

	void ReceiveMessage(string message, int param_1, int param_2){
		//This function is triggered when a character enters/exits an external hotspot.
		//Check if the enter/exit signal is from the external hotspot.
		if(param_2 == external_hotspot_id){
			CheckEvent(message, param_1);
		}
	}

	void CheckEvent(string event, int char_id){
		if(hotspot_trigger_type == while_inside || hotspot_trigger_type == while_outside){
			return;
		}
		if(!MovementObjectExists(char_id)){
			return;
		}

		MovementObject@ char = ReadCharacterID(char_id);
		ScriptParams@ char_params = ReadObjectFromID(char_id).GetScriptParams();

		if(char_params.HasParam("Teams")) {
			string team = char_params.GetString("Teams");

			if((target_character_type == check_team && hotspot_trigger_type == on_enter && event == "enter") ||
				(target_character_type == check_team && hotspot_trigger_type == on_exit && event == "exit")){
				//Removed all the spaces.
				string no_spaces_param = join(team.split(" "), "");
				//Teams are , seperated.
				array<string> teams = no_spaces_param.split(",");
				if(teams.find(character_team) != -1){
					triggered = true;
					RegisterObject(char_id, reference_string);
					return;
				}
			}
		}

		if((hotspot_trigger_type == on_enter && event == "enter") ||
			(hotspot_trigger_type == on_exit && event == "exit")){
			if(target_character_type == check_id && object_id == char_id ||
				target_character_type == any_character ||
				target_character_type == any_player && char.controlled ||
				target_character_type == any_npc && !char.controlled){
				triggered = true;
				RegisterObject(char_id, reference_string);
				return;
			}
		}
	}

	void Reset(){
		triggered = false;
	}

	bool Trigger(){
		if(hotspot_trigger_type == while_inside || hotspot_trigger_type == while_outside){
			if(hotspot_trigger_type == while_inside && InsideCheck() || hotspot_trigger_type == while_outside && !InsideCheck()){
				triggered = true;
				//If this is the last element then just return true to finish the script.
				if(current_line == int(drika_indexes.size() - 1)){
					return true;
				}
				DrikaElement@ next_element = drika_elements[drika_indexes[current_line + 1]];
				if(next_element.Trigger()){
					//The next element has finished so go to the next element.
					current_line += 1;
					return true;
				}
			}else{
				if(triggered && reset_when_false){
					if(current_line == int(drika_indexes.size() - 1)){
						return true;
					}
					triggered = false;
					DrikaElement@ next_element = drika_elements[drika_indexes[current_line + 1]];
					next_element.Reset();
				}
			}
			return false;
		}else{
			if(triggered){
				triggered = false;
				return true;
			}else{
				return false;
			}
		}
	}

	bool InsideCheck(){
		Object@ target_hotspot = external_hotspot?external_hotspot_obj:this_hotspot;

		if(target_character_type == check_id){
			if(object_id != -1 && MovementObjectExists(object_id)){
				MovementObject@ char = ReadCharacterID(object_id);
				RegisterObject(char.GetID(), reference_string);
				return CharacterInside(char, target_hotspot);
			}
		}else if(target_character_type == any_character){
			for(int i = 0; i < GetNumCharacters(); i++){
				MovementObject@ char = ReadCharacter(i);
				if(CharacterInside(char, target_hotspot)){
					RegisterObject(char.GetID(), reference_string);
					return true;
				}
			}
		}else if(target_character_type == any_player){
			for(int i = 0; i < GetNumCharacters(); i++){
				MovementObject@ char = ReadCharacter(i);
				if(char.controlled && CharacterInside(ReadCharacter(i), target_hotspot)){
					RegisterObject(char.GetID(), reference_string);
					return true;
				}
			}
		}else if(target_character_type == any_npc){
			for(int i = 0; i < GetNumCharacters(); i++){
				MovementObject@ char = ReadCharacter(i);
				if(!char.controlled && CharacterInside(ReadCharacter(i), target_hotspot)){
					RegisterObject(char.GetID(), reference_string);
					return true;
				}
			}
		}else if(target_character_type == check_team){
			for(int i = 0; i < GetNumCharacters(); i++){
				MovementObject@ char = ReadCharacter(i);
				ScriptParams@ char_params = ReadObjectFromID(char.GetID()).GetScriptParams();
				if(char_params.HasParam("Teams")){
					string team = char_params.GetString("Teams");
					//Removed all the spaces.
					string no_spaces_param = join(team.split(" "), "");
					//Teams are , seperated.
					array<string> teams = no_spaces_param.split(",");
					if(teams.find(character_team) != -1){
						RegisterObject(char.GetID(), reference_string);
						//Every character in the team needs to be inside.
						if(!CharacterInside(char, target_hotspot)){
							return false;
						}
					}
				}else{
					//This character does not have a Teams parameter so we can't finish this check.
					return false;
				}
			}
			return true;
		}

		return false;
	}

	bool CharacterInside(MovementObject@ char, Object@ hotspot_obj){
		vec3 pos = hotspot_obj.GetTranslation();
		vec3 scale = hotspot_obj.GetScale();

		vec3 char_pos = char.position;
		bool is_inside =	char_pos.x > pos.x-scale.x*2.0f
							&& char_pos.x < pos.x+scale.x*2.0f
							&& char_pos.y > pos.y-scale.y*2.0f
							&& char_pos.y < pos.y+scale.y*2.0f
							&& char_pos.z > pos.z-scale.z*2.0f
							&& char_pos.z < pos.z+scale.z*2.0f;

		return is_inside;
	}
}
