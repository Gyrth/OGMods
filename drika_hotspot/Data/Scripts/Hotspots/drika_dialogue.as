enum dialogue_functions	{
							say = 0,
							set_actor_color = 1,
							set_actor_voice = 2,
							set_actor_pos = 3,
							set_actor_animation = 4
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
	vec4 dialogue_color = vec4(1.0);

	array<string> dialogue_function_names =	{
												"Say",
												"Set Actor Color",
												"Set Actor Voice",
												"Set Actor Position",
												"Set Actor Animation"
											};

	DrikaDialogue(JSONValue params = JSONValue()){
		dialogue_function = dialogue_functions(GetJSONInt(params, "dialogue_function", 0));
		current_dialogue_function = dialogue_function;

		if(dialogue_function == say){
			say_text = GetJSONString(params, "say_text", "Drika Hotspot Dialogue");
			connection_types = {_movement_object};
		}else if(dialogue_function == set_actor_color){
			dialogue_color = GetJSONVec4(params, "dialogue_color", vec4(1));
			connection_types = {_movement_object};
		}

		LoadIdentifier(params);
		UpdateActorName();

		drika_element_type = drika_dialogue;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("dialogue");
		data["dialogue_function"] = JSONValue(dialogue_function);

		if(dialogue_function == say){
			data["say_text"] = JSONValue(say_text);
		}else if(dialogue_function == set_actor_color){
			data["dialogue_color"] = JSONValue(JSONarrayValue);
			data["dialogue_color"].append(dialogue_color.x);
			data["dialogue_color"].append(dialogue_color.y);
			data["dialogue_color"].append(dialogue_color.z);
			data["dialogue_color"].append(dialogue_color.a);
		}
		SaveIdentifier(data);

		return data;
	}

	string GetDisplayString(){
		string display_string = "Dialogue ";
		display_string += dialogue_function_names[current_dialogue_function] + " ";
		UpdateActorName();

		if(dialogue_function == say){
			display_string += actor_name;
			if(say_text.length() < 35){
				display_string += "\"" + say_text + "\"";
			}else{
				display_string += "\"" + say_text.substr(0, 35) + "..." + "\"";
			}
		}else if(dialogue_function == set_actor_color){
			display_string += actor_name;
			display_string += Vec4ToString(dialogue_color);
		}

		return display_string;
	}

	void UpdateActorName(){
		array<Object@> targets = GetTargetObjects();
		actor_name = "";

		if(identifier_type == id && targets.size() != 0){
			for(uint i = 0; i < targets.size(); i++){
				if(targets[i].GetName() != ""){
					actor_name += targets[i].GetName() + " ";
				}else{
					actor_name += targets[i].GetID() + " ";
				}
			}
		}else{
			actor_name = GetTargetDisplayText() + " ";
		}
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

	void DrawSettings(){
		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			dialogue_function = dialogue_functions(current_dialogue_function);
			if(dialogue_function == say || dialogue_function == set_actor_color){
				connection_types = {_movement_object};
			}else{
				connection_types = {};
			}
		}

		DrawSelectTargetUI();

		if(dialogue_function == say){
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
			}
		}else if(dialogue_function == set_actor_color){
			if(ImGui_Combo("Actor", current_reference, available_references, available_references.size())){
				reference_string = available_references[current_reference];
			}
			ImGui_ColorEdit4("Dialogue Color", dialogue_color);
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
				string nametag = "\"" + actor_name + "\"";

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
		}else if(dialogue_function == set_actor_color){
			string msg = "drika_dialogue_set_color ";
			msg += "\"" + actor_name + "\"";
			msg += dialogue_color.x + " " + dialogue_color.y + " " + dialogue_color.z + " " + dialogue_color.a;
			level.SendMessage(msg);
			triggered = true;
		}

		return triggered;
	}
}
