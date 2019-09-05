enum dialogue_functions	{
							say = 0,
							set_actor_color = 1,
							set_actor_voice = 2,
							set_actor_position = 3,
							set_actor_animation = 4,
							set_actor_eye_direction = 5,
							set_actor_torso_direction = 6,
							set_actor_head_direction = 7,
							set_actor_omniscient = 8
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
	vec4 dialogue_color;
	bool dialogue_done = false;
	int voice;
	vec3 target_actor_position;
	float target_actor_rotation;
	string target_actor_animation;
	string search_buffer = "";
	vec3 target_actor_eye_direction;
	float target_blink_multiplier;
	vec3 target_actor_torso_direction;
	float target_actor_torso_direction_weight;
	vec3 target_actor_head_direction;
	float target_actor_head_direction_weight;
	bool omniscient;

	array<string> dialogue_function_names =	{
												"Say",
												"Set Actor Color",
												"Set Actor Voice",
												"Set Actor Position",
												"Set Actor Animation",
												"Set Actor Eye Direction",
												"Set Actor Torso Direction",
												"Set Actor Head Direction",
												"Set Actor Omniscient"
											};

	DrikaDialogue(JSONValue params = JSONValue()){
		dialogue_function = dialogue_functions(GetJSONInt(params, "dialogue_function", 0));
		current_dialogue_function = dialogue_function;

		if(dialogue_function == say || dialogue_function == set_actor_color || dialogue_function == set_actor_voice || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient){
			connection_types = {_movement_object};
		}

		say_text = GetJSONString(params, "say_text", "Drika Hotspot Dialogue");
		dialogue_color = GetJSONVec4(params, "dialogue_color", vec4(1));
		voice = GetJSONInt(params, "voice", 0);
		target_actor_position = GetJSONVec3(params, "target_actor_position", vec3(0.0));
		target_actor_rotation = GetJSONFloat(params, "target_actor_rotation", 0.0);
		target_actor_animation = GetJSONString(params, "target_actor_animation", "Data/Animations/r_dialogue_2handneck.anm");
		target_actor_eye_direction = GetJSONVec3(params, "target_actor_eye_direction", vec3(0.0));
		target_blink_multiplier = GetJSONFloat(params, "target_blink_multiplier", 1.0);
		target_actor_torso_direction = GetJSONVec3(params, "target_actor_torso_direction", vec3(0.0));
		target_actor_torso_direction_weight = GetJSONFloat(params, "target_actor_torso_direction_weight", 1.0);
		target_actor_head_direction = GetJSONVec3(params, "target_actor_head_direction", vec3(0.0));
		target_actor_head_direction_weight = GetJSONFloat(params, "target_actor_head_direction_weight", 1.0);
		omniscient = GetJSONBool(params, "omniscient", true);

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
		}else if(dialogue_function == set_actor_voice){
			data["voice"] = JSONValue(voice);
		}else if(dialogue_function == set_actor_position){
			data["target_actor_position"] = JSONValue(JSONarrayValue);
			data["target_actor_position"].append(target_actor_position.x);
			data["target_actor_position"].append(target_actor_position.y);
			data["target_actor_position"].append(target_actor_position.z);
			data["target_actor_rotation"] = JSONValue(target_actor_rotation);
		}else if(dialogue_function == set_actor_animation){
			data["target_actor_animation"] = JSONValue(target_actor_animation);
		}else if(dialogue_function == set_actor_eye_direction){
			data["target_actor_eye_direction"] = JSONValue(JSONarrayValue);
			data["target_actor_eye_direction"].append(target_actor_eye_direction.x);
			data["target_actor_eye_direction"].append(target_actor_eye_direction.y);
			data["target_actor_eye_direction"].append(target_actor_eye_direction.z);
			data["target_blink_multiplier"] = JSONValue(target_blink_multiplier);
		}else if(dialogue_function == set_actor_torso_direction){
			data["target_actor_torso_direction"] = JSONValue(JSONarrayValue);
			data["target_actor_torso_direction"].append(target_actor_torso_direction.x);
			data["target_actor_torso_direction"].append(target_actor_torso_direction.y);
			data["target_actor_torso_direction"].append(target_actor_torso_direction.z);
			data["target_actor_torso_direction_weight"] = JSONValue(target_actor_torso_direction_weight);
		}else if(dialogue_function == set_actor_head_direction){
			data["target_actor_head_direction"] = JSONValue(JSONarrayValue);
			data["target_actor_head_direction"].append(target_actor_head_direction.x);
			data["target_actor_head_direction"].append(target_actor_head_direction.y);
			data["target_actor_head_direction"].append(target_actor_head_direction.z);
			data["target_actor_head_direction_weight"] = JSONValue(target_actor_head_direction_weight);
		}else if(dialogue_function == set_actor_omniscient){
			data["omniscient"] = JSONValue(omniscient);
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
			display_string += voice;
		}else if(dialogue_function == set_actor_position){
			display_string += actor_name;
		}else if(dialogue_function == set_actor_animation){
			display_string += actor_name;
			display_string += target_actor_animation;
		}else if(dialogue_function == set_actor_eye_direction){
			display_string += actor_name;
			display_string += target_blink_multiplier;
		}else if(dialogue_function == set_actor_torso_direction){
			display_string += actor_name;
			display_string += target_actor_torso_direction_weight;
		}else if(dialogue_function == set_actor_head_direction){
			display_string += actor_name;
			display_string += target_actor_head_direction_weight;
		}else if(dialogue_function == set_actor_omniscient){
			display_string += actor_name;
			display_string += omniscient;
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
		}else if(dialogue_function == set_actor_animation){
			if(all_animations.size() == 0){
				level.SendMessage("drika_dialogue_get_animations " + hotspot.GetID());
			}
			QueryAnimation(search_buffer);
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}

		if(dialogue_function == set_actor_position){
			PlaceholderCheck();
			if(placeholder.IsSelected()){
				vec3 new_position = placeholder.GetTranslation();
				vec4 v = placeholder.GetRotationVec4();
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
		}else if(dialogue_function == set_actor_eye_direction){
			PlaceholderCheck();
			DebugDrawBillboard("Data/Textures/ui/eye_widget.tga", placeholder.GetTranslation(), 0.1, vec4(1.0), _delete_on_draw);

			for(uint i = 0; i < targets.size(); i++){
				vec3 head_pos = targets[i].rigged_object().GetAvgIKChainPos("head");
				DebugDrawLine(head_pos, placeholder.GetTranslation(), vec4(1.0), vec4(1.0), _delete_on_update);
			}

			if(placeholder.IsSelected()){
				float scale = placeholder.GetScale().x;
				if(scale < 0.05f){
					placeholder.SetScale(vec3(0.05f));
				}
				if(scale > 0.1f){
					placeholder.SetScale(vec3(0.1f));
				}

				vec3 new_direction = placeholder.GetTranslation();
				float new_blink_mult = (placeholder.GetScale().x - 0.05f) / 0.05f;

				if(target_actor_eye_direction != new_direction || target_blink_multiplier != new_blink_mult){
					target_blink_multiplier = new_blink_mult;
					target_actor_eye_direction = new_direction;
					SetActorEyeDirection();
				}
			}
		}else if(dialogue_function == set_actor_torso_direction){
			PlaceholderCheck();
			DebugDrawBillboard("Data/Textures/ui/torso_widget.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_draw);

			for(uint i = 0; i < targets.size(); i++){
				vec3 torso_pos = targets[i].rigged_object().GetAvgIKChainPos("torso");
				DebugDrawLine(torso_pos, placeholder.GetTranslation(), vec4(1.0), vec4(1.0), _delete_on_update);
			}

			if(placeholder.IsSelected()){
				float scale = placeholder.GetScale().x;
				if(scale < 0.1f){
					placeholder.SetScale(vec3(0.1f));
				}
				if(scale > 0.35f){
					placeholder.SetScale(vec3(0.35f));
				}

				float new_weight = (placeholder.GetScale().x - 0.1f) * 4.0f;
				vec3 new_direction = placeholder.GetTranslation();

				if(target_actor_torso_direction != new_direction || target_actor_torso_direction_weight != new_weight){
					target_actor_torso_direction_weight = new_weight;
					target_actor_torso_direction = new_direction;
					SetActorTorsoDirection();
				}
			}
		}else if(dialogue_function == set_actor_head_direction){
			PlaceholderCheck();
			DebugDrawBillboard("Data/Textures/ui/head_widget.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_draw);

			for(uint i = 0; i < targets.size(); i++){
				vec3 head_pos = targets[i].rigged_object().GetAvgIKChainPos("head");
				DebugDrawLine(head_pos, placeholder.GetTranslation(), vec4(1.0), vec4(1.0), _delete_on_update);
			}

			if(placeholder.IsSelected()){
				float scale = placeholder.GetScale().x;
				if(scale < 0.1f){
					placeholder.SetScale(vec3(0.1f));
				}
				if(scale > 0.35f){
					placeholder.SetScale(vec3(0.35f));
				}

				float new_weight = (placeholder.GetScale().x - 0.1f) * 4.0f;
				vec3 new_direction = placeholder.GetTranslation();

				if(target_actor_head_direction != new_direction || target_actor_head_direction_weight != new_weight){
					target_actor_head_direction_weight = new_weight;
					target_actor_head_direction = new_direction;
					SetActorHeadDirection();
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
		}else if(dialogue_function == set_actor_animation){
			SetActorAnimation();
		}else if(dialogue_function == set_actor_eye_direction){
			SetActorEyeDirection();
		}else if(dialogue_function == set_actor_torso_direction){
			SetActorTorsoDirection();
		}else if(dialogue_function == set_actor_head_direction){
			SetActorHeadDirection();
		}else if(dialogue_function == set_actor_omniscient){
			SetActorOmniscient();
		}
	}

	void EditDone(){
		if(dialogue_function == set_actor_position || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction){
			DeletePlaceholder();
		}else if(dialogue_function == say){
			if(say_started){
				Reset();
			}
		}
	}

	void DeletePlaceholder(){
		if(@placeholder != null){
			int placeholder_id = placeholder.GetID();
			DeleteObjectID(placeholder_id);
			@placeholder = null;
		}
	}

	void PlaceholderCheck(){
		if(@placeholder == null){
			int placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml");
			@placeholder = ReadObjectFromID(placeholder_id);
			placeholder.SetSelectable(true);
			placeholder.SetTranslatable(true);
			placeholder.SetScalable(true);
			placeholder.SetRotatable(true);

			PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder);
			if(dialogue_function == set_actor_eye_direction){
				if(target_actor_eye_direction == vec3(0.0)){
					target_actor_eye_direction = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				placeholder.SetTranslation(target_actor_eye_direction);
				placeholder.SetScale(0.05f + 0.05f * target_blink_multiplier);
				placeholder_object.SetEditorDisplayName("Set Actor Eye Direction Helper");
			}else if(dialogue_function == set_actor_position){
				if(target_actor_position == vec3(0.0)){
					target_actor_position = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				//If this is a new set character position then use the hotspot as the default position.
				placeholder.SetTranslation(target_actor_position);
				placeholder.SetRotation(quaternion(vec4(0,1,0, target_actor_rotation * PI / 180.0f)));
				placeholder_object.SetPreview("Data/Objects/drika_spawn_placeholder.xml");
				placeholder_object.SetEditorDisplayName("Set Actor Position Helper");
			}else if(dialogue_function == set_actor_torso_direction){
				if(target_actor_torso_direction == vec3(0.0)){
					target_actor_torso_direction = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				placeholder.SetScale(target_actor_torso_direction_weight / 4.0f + 0.1f);
				placeholder.SetTranslation(target_actor_torso_direction);
				placeholder_object.SetEditorDisplayName("Set Actor Torso Direction Helper");
			}else if(dialogue_function == set_actor_head_direction){
				if(target_actor_head_direction == vec3(0.0)){
					target_actor_head_direction = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				placeholder.SetScale(target_actor_head_direction_weight / 4.0f + 0.1f);
				placeholder.SetTranslation(target_actor_head_direction);
				placeholder_object.SetEditorDisplayName("Set Actor Head Direction Helper");
			}

			placeholder_object.SetSpecialType(kSpawn);
		}
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			if(dialogue_function == set_actor_position || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction ||dialogue_function == set_actor_head_direction){
				DeletePlaceholder();
			}

			dialogue_function = dialogue_functions(current_dialogue_function);
			if(dialogue_function == say || dialogue_function == set_actor_color){
				connection_types = {_movement_object};
			}else{
				connection_types = {};
			}
		}

		if(dialogue_function == say){
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
			}
		}else if(dialogue_function == set_actor_color){
			if(ImGui_ColorEdit4("Dialogue Color", dialogue_color)){
				SetActorColor();
			}
		}else if(dialogue_function == set_actor_voice){
			if(ImGui_SliderInt("Voice", voice, 0, 18, "%.0f")){
				level.SendMessage("drika_dialogue_test_voice " + voice);
			}
		}else if(dialogue_function == set_actor_animation){
			ImGui_SetTextBuf(search_buffer);
			ImGui_Text("Search");
			ImGui_SameLine();
			ImGui_PushItemWidth(ImGui_GetWindowWidth() - 85);
			if(ImGui_InputText("", ImGuiInputTextFlags_AutoSelectAll)){
				search_buffer = ImGui_GetTextBuf();
				QueryAnimation(ImGui_GetTextBuf());
			}
			ImGui_PopItemWidth();

			if(ImGui_BeginChildFrame(55, vec2(-1, -1), ImGuiWindowFlags_AlwaysAutoResize)){
				for(uint i = 0; i < current_animations.size(); i++){
					AddCategory(current_animations[i].name, current_animations[i].animations);
				}
				ImGui_EndChildFrame();
			}
		}else if(dialogue_function == set_actor_omniscient){
			ImGui_Text("Set Omnicient to : ");
			ImGui_SameLine();
			ImGui_Checkbox("", omniscient);
		}
	}

	void AddCategory(string category, array<string> items){
		if(current_animations.size() < 1){
			return;
		}
		if(ImGui_TreeNodeEx(category, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
			ImGui_Unindent(22.0f);
			for(uint i = 0; i < items.size(); i++){
				AddItem(items[i]);
			}
			ImGui_Indent(22.0f);
			ImGui_TreePop();
		}
	}

	void AddItem(string name){
		bool is_selected = name == target_actor_animation;
		if(ImGui_Selectable(name, is_selected)){
			target_actor_animation = name;
			SetActorAnimation();
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
			wait_timer = 0.0;
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
		}else if(dialogue_function == set_actor_animation){
			SetActorAnimation();
			return true;
		}else if(dialogue_function == set_actor_eye_direction){
			SetActorEyeDirection();
			return true;
		}else if(dialogue_function == set_actor_torso_direction){
			SetActorTorsoDirection();
			return true;
		}else if(dialogue_function == set_actor_head_direction){
			SetActorHeadDirection();
			return true;
		}else if(dialogue_function == set_actor_omniscient){
			SetActorOmniscient();
			return true;
		}

		return false;
	}

	void SetActorOmniscient(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_omniscient " + omniscient);
		}
		triggered = true;
	}

	void SetActorHeadDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_head_target " + target_actor_head_direction.x + " " + target_actor_head_direction.y + " " + target_actor_head_direction.z + " " + target_actor_head_direction_weight);
		}
		triggered = true;
	}

	void SetActorTorsoDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_torso_target " + target_actor_torso_direction.x + " " + target_actor_torso_direction.y + " " + target_actor_torso_direction.z + " " + target_actor_torso_direction_weight);
		}
		triggered = true;
	}

	void SetActorEyeDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_eye_dir " + target_actor_eye_direction.x + " " + target_actor_eye_direction.y + " " + target_actor_eye_direction.z + " " + target_blink_multiplier);
		}
		triggered = true;
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

	void SetActorAnimation(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_animation \"" + target_actor_animation + "\"");
		}
		triggered = true;
	}
}
