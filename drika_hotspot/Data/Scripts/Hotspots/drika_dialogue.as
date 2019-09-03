enum dialogue_functions	{
							say = 0,
							add_actor = 1,
							set_dialogue_color = 2,
							set_dialogue_voice = 3,
							set_character_pos = 4,
							set_animation = 5
						}

class DrikaDialogue : DrikaElement{
	dialogue_functions dialogue_function;
	int current_dialogue_function;
	string say_text;
	array<string> say_text_split;
	bool say_started = false;
	float say_timer = 0.0;
	float wait_timer = 0.0;
	int actor_id;
	string actor_name;
	vec3 dialogue_color;

	array<string> dialogue_function_names =	{
												"Say",
												"Add Actor",
												"Set Dialogue Color",
												"Set Dialogue Voice",
												"Set Character Position",
												"Set Animation"
											};

	DrikaDialogue(JSONValue params = JSONValue()){
		dialogue_function = dialogue_functions(GetJSONInt(params, "dialogue_function", 0));
		current_dialogue_function = dialogue_function;

		if(dialogue_function == say){
			say_text = GetJSONString(params, "say_text", "Drika Hotspot Dialogue");
			identifier_type = identifier_types(reference);
			reference_string = GetJSONString(params, "identifier", "drika_reference");
		}else if(dialogue_function == add_actor){
			connection_types = {_movement_object};
			actor_id = GetJSONInt(params, "actor_id", 0);
			object_id = actor_id;
			if(MovementObjectExists(actor_id)){
				Object@ actor_object = ReadObjectFromID(actor_id);
				actor_name = actor_object.GetName();
			}
		}else if(dialogue_function == set_dialogue_color){
			dialogue_color = GetJSONVec3(params, "dialogue_color", vec3(1));
			identifier_type = identifier_types(reference);
			reference_string = GetJSONString(params, "identifier", "drika_reference");
		}

		drika_element_type = drika_dialogue;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("dialogue");
		data["dialogue_function"] = JSONValue(dialogue_function);

		if(dialogue_function == say){
			data["say_text"] = JSONValue(say_text);
			data["identifier"] = JSONValue(reference_string);
		}else if(dialogue_function == add_actor){
			data["actor_id"] = JSONValue(actor_id);
		}else if(dialogue_function == set_dialogue_color){
			data["dialogue_color"] = JSONValue(JSONarrayValue);
			data["dialogue_color"].append(dialogue_color.x);
			data["dialogue_color"].append(dialogue_color.y);
			data["dialogue_color"].append(dialogue_color.z);
			data["identifier"] = JSONValue(reference_string);
		}

		return data;
	}

	string GetDisplayString(){
		string display_string = "Dialogue ";
		display_string += dialogue_function_names[current_dialogue_function] + " ";

		if(dialogue_function == say){
			display_string += reference_string + " ";
			if(say_text.length() < 35){
				display_string += "\"" + say_text + "\"";
			}else{
				display_string += "\"" + say_text.substr(0, 35) + "..." + "\"";
			}
		}else if(dialogue_function == add_actor){
			if(actor_name == ""){
				display_string += actor_id;
			}else{
				display_string += actor_name;
			}
		}else if(dialogue_function == set_dialogue_color){
			display_string += reference_string + " ";
			display_string += Vec3ToString(dialogue_color);
		}

		return display_string;
	}

	void StartSettings(){
		CheckReferenceAvailable();
		if(dialogue_function == say){
			ImGui_SetTextBuf(say_text);
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void ConnectedChanged(){
		if(dialogue_function == add_actor){
			actor_id = object_id;
			if(MovementObjectExists(actor_id)){
				Object@ actor_object = ReadObjectFromID(actor_id);
				actor_name = actor_object.GetName();
			}
		}
	}

	void DrawSettings(){
		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			dialogue_function = dialogue_functions(current_dialogue_function);
			if(dialogue_function == add_actor){
				connection_types = {_movement_object};
			}else{
				connection_types = {};
			}
		}

		if(dialogue_function == say){
			if(ImGui_Combo("Actor", current_reference, available_references, available_references.size())){
				reference_string = available_references[current_reference];
			}
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
			}
		}else if(dialogue_function == set_dialogue_color){
			if(ImGui_Combo("Actor", current_reference, available_references, available_references.size())){
				reference_string = available_references[current_reference];
			}
			ImGui_ColorEdit3("Dialogue Color", dialogue_color);
		}
	}

	string GetReference(){
		if(dialogue_function == add_actor){
			return actor_name;
		}else{
			return "";
		}
	}

	void Reset(){
		triggered = false;
		if(dialogue_function == say){
			say_started = false;
			say_timer = 0.0;
		}
	}

	bool Trigger(){
		if(dialogue_function == say){
			//Some setup operations that only need to be done once.
			if(say_started == false){
				say_started = true;
				say_text_split = say_text.split(" ");
				level.SendMessage("drika_dialogue_clear_say");
			}

			if(wait_timer > 0.0){
				wait_timer -= time_step;
			}else if(say_timer > 0.15){
				say_timer = 0.0;
				string nametag = "\"" + reference_string + "\"";

				if(say_text_split[0] == "[wait"){
					say_text_split.removeAt(0);
					wait_timer = atof(say_text_split[0].substr(0, 2));
					say_text_split.removeAt(0);
					return triggered;
				}else if(say_text_split[0].findFirst("\n") != -1){
					array<string> new_line_split = say_text_split[0].split("\n");
					level.SendMessage("drika_dialogue_add_say " + nametag + " " + new_line_split[0]);
					level.SendMessage("drika_dialogue_add_say " + nametag + " \n");

					new_line_split.removeAt(0);
					say_text_split[0] = join(new_line_split, "\n");
					return triggered;
				}
				string msg = "drika_dialogue_add_say ";
				msg += nametag + " ";
				msg += say_text_split[0];
				level.SendMessage(msg);

				say_text_split.removeAt(0);

				if(say_text_split.size() == 0){
					triggered = true;
				}
			}
			say_timer += time_step;
		}else if(dialogue_function == add_actor){
			RegisterObject(actor_id, actor_name);
			triggered = true;
		}else if(dialogue_function == set_dialogue_color){
			string msg = "drika_dialogue_set_color ";
			msg += reference_string;
			msg += dialogue_color.x + " " + dialogue_color.y + " " + dialogue_color.z;
			level.SendMessage(msg);
			triggered = true;
		}

		return triggered;
	}
}
