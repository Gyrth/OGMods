enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	int new_target_character_type;
	int new_hotspot_trigger_type;
	bool external_hotspot;
	int external_hotspot_id;
	Object@ external_hotspot_obj;

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
		external_hotspot = GetJSONBool(params, "external_hotspot", false);
		external_hotspot_id = GetJSONInt(params, "external_hotspot_id", -1);

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

	void Delete(){
		if(external_hotspot && ObjectExists(external_hotspot_id)){
			QueueDeleteObjectID(external_hotspot_id);
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
		if(ObjectExists(external_hotspot_id)){
			external_hotspot_obj.SetSelected(false);
		}
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

		ImGui_Checkbox("External Hotspot", external_hotspot);

		DrawSetReferenceUI();
	}

	void DrawEditing(){
		if(target_character_type == check_id && object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}

		if(external_hotspot_id == -1 && external_hotspot){
			CreateExternalHotspot();
		}else if(external_hotspot_id != -1 && !external_hotspot){
			QueueDeleteObjectID(external_hotspot_id);
			external_hotspot_id = -1;
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
		Log(warning, "received " + message + " " + param_1 + " " + param_2);
		//Check if the enter/exit signal is from the external hotspot.
		if(param_2 == external_hotspot_id){
			CheckEvent(message, param_1);
		}
	}

	void CheckEvent(string event, int char_id){
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
		if(triggered){
			triggered = false;
			return true;
		}else{
			return false;
		}
	}
}
