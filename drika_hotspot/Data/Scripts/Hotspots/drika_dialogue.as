enum dialogue_functions	{
							say = 0,
							set_dialogue_color = 1,
							set_dialogue_voice = 2,
							set_character_pos = 3,
							set_animation = 4
						}

class DrikaDialogue : DrikaElement{
	dialogue_functions dialogue_function;
	int current_dialogue_function;
	string say_text;
	array<string> say_text_split;
	bool say_started = false;
	float say_timer = 0.0;
	float wait_timer = 0.0;

	array<string> dialogue_function_names =	{
												"Say",
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
		}

		return data;
	}

	string GetDisplayString(){
		string display_string = "Dialogue ";
		display_string += dialogue_function_names[current_dialogue_function] + " ";

		if(dialogue_function == say){
			if(say_text.length() < 35){
				display_string += "\"" + say_text + "\"";
			}else{
				display_string += "\"" + say_text.substr(0, 35) + "..." + "\"";
			}
		}

		return display_string;
	}

	void StartSettings(){
		if(dialogue_function == say){
			ImGui_SetTextBuf(say_text);
		}
	}

	void DrawSettings(){
		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			dialogue_function = dialogue_functions(current_dialogue_function);
		}

		if(dialogue_function == say){
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
			}
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

				if(say_text_split[0] == "[wait"){
					say_text_split.removeAt(0);
					wait_timer = atof(say_text_split[0].substr(0, 2));
					say_text_split.removeAt(0);
					return triggered;
				}else if(say_text_split[0].findFirst("\n") != -1){
					array<string> new_line_split = say_text_split[0].split("\n");
					level.SendMessage("drika_dialogue_add_say " + new_line_split[0]);
					level.SendMessage("drika_dialogue_add_say \n");

					new_line_split.removeAt(0);
					say_text_split[0] = join(new_line_split, "\n");
					return triggered;
				}

				string msg = "drika_dialogue_add_say ";
				msg += say_text_split[0];
				level.SendMessage(msg);

				say_text_split.removeAt(0);

				if(say_text_split.size() == 0){
					triggered = true;
				}
			}
			say_timer += time_step;
		}
		return triggered;
	}
}
