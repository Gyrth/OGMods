enum character_message_types {
								character_message,
								character_script_message,
								character_queue_script_message
							};

class DrikaSendCharacterMessage : DrikaElement{
	string message;
	string display_message;
	character_message_types character_message_type;
	int current_message_type;
	array<string> message_type_choices = {"Message", "Script Message", "Queue Script Message"};

	DrikaSendCharacterMessage(JSONValue params = JSONValue()){
		message = GetJSONString(params, "message", "restore_health");
		character_message_type = character_message_types(GetJSONInt(params, "character_message_type", character_message));
		current_message_type = character_message_type;
		InterpIdentifier(params);

		connection_types = {_movement_object};
		drika_element_type = drika_send_character_message;
		has_settings = true;
		SetDisplayMessage();
	}

	void PostInit(){
		if(!MovementObjectExists(object_id)){
			Log(warning, "Character does not exist with id " + object_id);
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("send_character_message");
		data["character_message_type"] = JSONValue(character_message_type);
		data["message"] = JSONValue(message);
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
		return "SendCharacterMessage " + display_message;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Message Type", current_message_type, message_type_choices, message_type_choices.size())){
			character_message_type = character_message_types(current_message_type);
		}
		if(ImGui_InputText("Message", message, 64)){
			SetDisplayMessage();
		}
	}

	void SetDisplayMessage(){
		display_message = join(message.split("\n"), "");
		if(display_message.length() > 30){
			display_message = display_message.substr(0, 30);
		}
	}

	void DrawEditing(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return;
		}
		DebugDrawLine(target_character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
	}

	bool Trigger(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return false;
		}
		if(character_message_type == character_message){
			target_character.ReceiveMessage(message);
		}else if(character_message_type == character_script_message){
			target_character.ReceiveScriptMessage(message);
		}else if(character_message_type == character_queue_script_message){
			target_character.QueueScriptMessage(message);
		}
		return true;
	}
}
