enum dialogue_functions	{
							say = 0,
							set_actor_color = 1,
							set_actor_voice = 2,
							set_actor_position = 3,
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
	bool dialogue_done = false;
	int voice = 0;
	vec3 target_actor_position;
	float target_actor_rotation;
	Object@ character_placeholder = null;

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
		}else if(dialogue_function == set_actor_voice){
			voice = GetJSONInt(params, "voice", 0);
			connection_types = {_movement_object};
		}else if(dialogue_function == set_actor_position){
			target_actor_position = GetJSONVec3(params, "target_actor_position", vec3(0.0));
			target_actor_rotation = GetJSONFloat(params, "target_actor_rotation", 0.0);
			connection_types = {_movement_object};
		}

		LoadIdentifier(params);
		UpdateActorName();

		drika_element_type = drika_dialogue;
		has_settings = true;
	}

	void PostInit(){
		if(dialogue_function == set_actor_position){
			//If this is a new set character position then use the hotspot as the default position.
			if(target_actor_position == vec3(0.0)){
				target_actor_position = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
			}
		}
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
		}else if(dialogue_function == set_actor_voice){
			data["voice"] = JSONValue(voice);
		}else if(dialogue_function == set_actor_position){
			data["target_actor_position"] = JSONValue(JSONarrayValue);
			data["target_actor_position"].append(target_actor_position.x);
			data["target_actor_position"].append(target_actor_position.y);
			data["target_actor_position"].append(target_actor_position.z);
			data["target_actor_rotation"] = JSONValue(target_actor_rotation);
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
		}else if(dialogue_function == set_actor_voice){
			display_string += actor_name;
		}else if(dialogue_function == set_actor_position){
			display_string += actor_name;
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

		if(dialogue_function == set_actor_position){
			CharacterPlaceholderCheck();
			if(character_placeholder.IsSelected()){
				vec3 new_position = character_placeholder.GetTranslation();
				vec4 v = character_placeholder.GetRotationVec4();
				quaternion quat(v.x,v.y,v.z,v.a);
				vec3 facing = Mult(quat, vec3(0,0,1));
				float rot = atan2(facing.x, facing.z) * 180.0f / PI;

				float new_rotation = floor(rot + 0.5f);

				if(target_actor_position != new_position || target_actor_rotation != new_rotation){
					target_actor_position = new_position;
					target_actor_rotation = new_rotation;
					SetActorPosition();
				}
			}
		}
	}

	void StartEdit(){
		if(dialogue_function == set_actor_position){
			SetActorPosition();
		}else if(dialogue_function == set_actor_voice){
			SetActorVoice();
		}else if(dialogue_function == set_actor_color){
			SetActorColor();
		}
	}

	void EditDone(){
		if(dialogue_function == set_actor_position){
			DeleteCharacterPlaceholder();
		}else if(dialogue_function == say){
			if(say_started){
				Reset();
			}
		}
	}

	void DeleteCharacterPlaceholder(){
		if(@character_placeholder != null){
			int character_placeholder_id = character_placeholder.GetID();
			DeleteObjectID(character_placeholder_id);
			@character_placeholder = null;
		}
	}

	void CharacterPlaceholderCheck(){
		if(@character_placeholder == null){
			int character_placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml");
			@character_placeholder = ReadObjectFromID(character_placeholder_id);
			character_placeholder.SetSelectable(true);
			character_placeholder.SetTranslatable(true);
			character_placeholder.SetScalable(true);
			character_placeholder.SetRotatable(true);

			character_placeholder.SetTranslation(target_actor_position);
			character_placeholder.SetRotation(quaternion(vec4(0,1,0, target_actor_rotation * PI / 180.0f)));


			PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(character_placeholder);
			placeholder_object.SetSpecialType(kSpawn);
			placeholder_object.SetPreview("Data/Objects/drika_spawn_placeholder.xml");
			placeholder_object.SetEditorDisplayName("Set Actor Position Helper");
		}
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			dialogue_function = dialogue_functions(current_dialogue_function);
			if(dialogue_function == say || dialogue_function == set_actor_color){
				connection_types = {_movement_object};
			}else{
				connection_types = {};
			}

			if(dialogue_function != set_actor_position){
				DeleteCharacterPlaceholder();
			}
		}

		if(dialogue_function == say){
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
			}
		}else if(dialogue_function == set_actor_color){
			if(ImGui_Combo("Actor", current_reference, available_references, available_references.size())){
				reference_string = available_references[current_reference];
			}
			ImGui_ColorEdit4("Dialogue Color", dialogue_color);
		}else if(dialogue_function == set_actor_voice){
			if(ImGui_SliderInt("Voice", voice, 0, 18, "%.0f")){
				level.SendMessage("drika_dialogue_test_voice " + voice);
			}
		}
	}

	void Reset(){
		dialogue_done = false;
		if(dialogue_function == say){
			if(say_started){
				level.SendMessage("drika_dialogue_hide");
			}
			say_started = false;
			say_timer = 0.0;
		}else if(dialogue_function == set_actor_position){
			if(triggered){
				array<MovementObject@> targets = GetTargetMovementObjects();

				for(uint i = 0; i < targets.size(); i++){
					targets[i].ReceiveScriptMessage("set_dialogue_control false");
				}
				triggered = false;
			}
		}
	}

	void Update(){
		if(dialogue_function == say){
			UpdateSayDialogue();
		}
	}

	bool Trigger(){
		if(dialogue_function == say){
			return UpdateSayDialogue();
		}else if(dialogue_function == set_actor_color){
			SetActorColor();
			return true;
		}else if(dialogue_function == set_actor_voice){
			SetActorVoice();
			return true;
		}else if(dialogue_function == set_actor_position){
			SetActorPosition();
			return true;
		}

		return false;
	}

	void SetActorColor(){
		string msg = "drika_dialogue_set_color ";
		msg += "\"" + actor_name + "\"";
		msg += dialogue_color.x + " " + dialogue_color.y + " " + dialogue_color.z + " " + dialogue_color.a;
		level.SendMessage(msg);
	}

	void SetActorVoice(){
		string msg = "drika_dialogue_set_voice ";
		msg += "\"" + actor_name + "\"";
		msg += voice;
		level.SendMessage(msg);
	}

	bool UpdateSayDialogue(){
		//Some setup operations that only need to be done once.
		if(say_started == false){
			say_started = true;
			say_text_split = say_text.split(" ");
			level.SendMessage("drika_dialogue_clear_say");
		}

		if(dialogue_done){
			if(GetInputPressed(0, "attack")){
				level.SendMessage("drika_dialogue_skip");
				return true;
			}
		}else if(wait_timer > 0.0){
			wait_timer -= time_step;
			if(GetInputPressed(0, "attack")){
				level.SendMessage("drika_dialogue_skip");
				wait_timer = 0.0;
			}
		}else if(say_timer > 0.15){
			say_timer = 0.0;
			string nametag = "\"" + actor_name + "\"";

			if(say_text_split[0] == "[wait"){
				say_text_split.removeAt(0);
				wait_timer = atof(say_text_split[0].substr(0, 2));
				say_text_split.removeAt(0);
				return false;
			}else if(say_text_split[0].findFirst("\n") != -1){
				array<string> new_line_split = say_text_split[0].split("\n");
				level.SendMessage("drika_dialogue_add_say " + nametag + " " + new_line_split[0]);
				level.SendMessage("drika_dialogue_add_say " + nametag + " \n");

				new_line_split.removeAt(0);
				say_text_split[0] = join(new_line_split, "\n");
				return false;
			}
			string msg = "drika_dialogue_add_say ";
			msg += nametag + " ";
			msg += say_text_split[0];
			level.SendMessage(msg);

			say_text_split.removeAt(0);

			if(say_text_split.size() == 0){
				dialogue_done = true;
			}
		}
		say_timer += time_step;
		return false;
	}

	void SetActorPosition(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			if(!triggered){
				targets[i].ReceiveScriptMessage("set_dialogue_control true");
			}
			targets[i].ReceiveScriptMessage("set_rotation " + target_actor_rotation);
			targets[i].ReceiveScriptMessage("set_dialogue_position " + target_actor_position.x + " " + target_actor_position.y + " " + target_actor_position.z);
		}
		triggered = true;
	}

}
