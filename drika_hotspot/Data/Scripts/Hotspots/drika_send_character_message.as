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
	string message_list = "restore_health\nfull_revive\nfall_death\nignite\nactivate\nentered_fire\nextinguish\nstart_talking\nstop_talking\nset_dialogue_control\nset_omniscient\nset_animation\nset_eye_dir\nset_rotation\nequip_item\nempty_hands\nset_dialogue_position\nset_torso_target\nmake_saved_corpse\nrevive_and_unsave_corpse\n";

	DrikaSendCharacterMessage(JSONValue params = JSONValue()){
		message = GetJSONString(params, "message", "restore_health");
		character_message_type = character_message_types(GetJSONInt(params, "character_message_type", character_message));
		current_message_type = character_message_type;
		LoadIdentifier(params);

		connection_types = {_movement_object};
		drika_element_type = drika_send_character_message;
		has_settings = true;
		SetDisplayMessage();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("send_character_message");
		data["character_message_type"] = JSONValue(character_message_type);
		data["message"] = JSONValue(message);
		SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "SendCharacterMessage " + GetTargetDisplayText() + " " + display_message;
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
		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip(message_list);
			ImGui_PopStyleColor();
		}
	}

	void SetDisplayMessage(){
		display_message = join(message.split("\n"), "");
		if(display_message.length() > 30){
			display_message = display_message.substr(0, 30);
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			if(character_message_type == character_message){
				targets[i].ReceiveMessage(message);
			}else if(character_message_type == character_script_message){
				targets[i].ReceiveScriptMessage(message);
			}else if(character_message_type == character_queue_script_message){
				targets[i].QueueScriptMessage(message);
			}
		}
		return true;
	}
}
