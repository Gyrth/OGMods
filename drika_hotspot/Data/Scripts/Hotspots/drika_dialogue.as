#include "dialogue_layouts.as";

enum dialogue_functions	{
							say = 0,
							actor_settings = 1,
							set_actor_position = 2,
							set_actor_animation = 3,
							set_actor_eye_direction = 4,
							set_actor_torso_direction = 5,
							set_actor_head_direction = 6,
							set_actor_omniscient = 7,
							set_camera_position = 8,
							fade_to_black = 9,
							settings = 10,
							start = 11,
							end = 12,
							set_actor_dialogue_control = 13,
							choice = 14
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
	vec3 target_camera_position;
	vec3 target_camera_rotation;
	float target_camera_zoom;
	float target_fade_to_black;
	float fade_to_black_duration;

	int dialogue_layout;
	string dialogue_text_font;
	int dialogue_text_size;
	vec4 dialogue_text_color;
	bool dialogue_text_shadow;
	bool use_voice_sounds;
	bool show_names;

	string default_avatar_path = "Data/Textures/ui/menus/main/white_square.png";
	TextureAssetRef avatar = LoadTexture(default_avatar_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
	string avatar_path;
	bool anim_mirrored;
	bool anim_mobile;
	bool anim_super_mobile;
	bool anim_swap;
	bool anim_from_start;
	bool use_ik;
	float transition_speed;
	bool wait_anim_end;
	bool dialogue_control;
	int current_choice;
	int nr_choices;
	string choice_1;
	string choice_2;
	string choice_3;
	string choice_4;
	string choice_5;
	int choice_1_go_to_line;
	int choice_2_go_to_line;
	int choice_3_go_to_line;
	int choice_4_go_to_line;
	int choice_5_go_to_line;
	bool choice_ui_added = false;
	DrikaElement@ choice_1_element;
	DrikaElement@ choice_2_element;
	DrikaElement@ choice_3_element;
	DrikaElement@ choice_4_element;
	DrikaElement@ choice_5_element;

	array<string> dialogue_function_names =	{
												"Say",
												"Actor Settings",
												"Set Actor Position",
												"Set Actor Animation",
												"Set Actor Eye Direction",
												"Set Actor Torso Direction",
												"Set Actor Head Direction",
												"Set Actor Omniscient",
												"Set Camera Position",
												"Fade To Black",
												"Settings",
												"Start",
												"End",
												"Set Actor Dialogue Control",
												"Choice"
											};

	DrikaDialogue(JSONValue params = JSONValue()){
		dialogue_function = dialogue_functions(GetJSONInt(params, "dialogue_function", start));
		current_dialogue_function = dialogue_function;

		say_text = GetJSONString(params, "say_text", "Drika Hotspot Dialogue");
		dialogue_color = GetJSONVec4(params, "dialogue_color", vec4(1));
		voice = GetJSONInt(params, "voice", 0);
		avatar_path = GetJSONString(params, "avatar_path", "None");
		if(avatar_path != "None"){
			avatar = LoadTexture(avatar_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}
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
		target_camera_position = GetJSONVec3(params, "target_camera_position", vec3(0.0));
		target_camera_rotation = GetJSONVec3(params, "target_camera_rotation", vec3(0.0));
		target_camera_zoom = GetJSONFloat(params, "target_camera_zoom", 90.0);
		target_fade_to_black = GetJSONFloat(params, "target_fade_to_black", 1.0);
		fade_to_black_duration = GetJSONFloat(params, "fade_to_black_duration", 1.0);

		dialogue_layout = GetJSONInt(params, "dialogue_layout", 0);
		dialogue_text_font = GetJSONString(params, "dialogue_text_font", "Data/Fonts/arial.ttf");
		dialogue_text_size = GetJSONInt(params, "dialogue_text_size", 50);
		dialogue_text_color = GetJSONVec4(params, "dialogue_text_color", vec4(1));
		dialogue_text_shadow = GetJSONBool(params, "dialogue_text_shadow", true);
		use_voice_sounds = GetJSONBool(params, "use_voice_sounds", true);
		show_names = GetJSONBool(params, "show_names", true);

		anim_mirrored = GetJSONBool(params, "anim_mirrored", false);
		anim_mobile = GetJSONBool(params, "anim_mobile", false);
		anim_super_mobile = GetJSONBool(params, "anim_super_mobile", false);
		anim_swap = GetJSONBool(params, "anim_swap", false);
		anim_from_start = GetJSONBool(params, "anim_from_start", true);
		use_ik = GetJSONBool(params, "use_ik", true);
		transition_speed = GetJSONFloat(params, "transition_speed", 3.0);
		wait_anim_end = GetJSONBool(params, "wait_anim_end", false);
		dialogue_control = GetJSONBool(params, "dialogue_control", true);
		nr_choices = GetJSONInt(params, "nr_choices", 5);
		choice_1 = GetJSONString(params, "choice_1", "Pick choice nr 1");
		choice_2 = GetJSONString(params, "choice_2", "Pick choice nr 2");
		choice_3 = GetJSONString(params, "choice_3", "Pick choice nr 3");
		choice_4 = GetJSONString(params, "choice_4", "Pick choice nr 4");
		choice_5 = GetJSONString(params, "choice_5", "Pick choice nr 5");
		choice_1_go_to_line = GetJSONInt(params, "choice_1_go_to_line", 0);
		choice_2_go_to_line = GetJSONInt(params, "choice_2_go_to_line", 0);
		choice_3_go_to_line = GetJSONInt(params, "choice_3_go_to_line", 0);
		choice_4_go_to_line = GetJSONInt(params, "choice_4_go_to_line", 0);
		choice_5_go_to_line = GetJSONInt(params, "choice_5_go_to_line", 0);

		if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
			connection_types = {_movement_object};
			LoadIdentifier(params);
		}

		show_character_option = true;
		show_team_option = true;
		show_name_option = true;
		show_reference_option = true;

		drika_element_type = drika_dialogue;
		has_settings = true;
	}

	void PostInit(){
		UpdateActorName();
		@choice_1_element = drika_elements[drika_indexes[choice_1_go_to_line]];
		@choice_2_element = drika_elements[drika_indexes[choice_2_go_to_line]];
		@choice_3_element = drika_elements[drika_indexes[choice_3_go_to_line]];
		@choice_4_element = drika_elements[drika_indexes[choice_4_go_to_line]];
		@choice_5_element = drika_elements[drika_indexes[choice_5_go_to_line]];
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["dialogue_function"] = JSONValue(dialogue_function);

		if(dialogue_function == say){
			data["say_text"] = JSONValue(say_text);
		}else if(dialogue_function == actor_settings){
			data["dialogue_color"] = JSONValue(JSONarrayValue);
			data["dialogue_color"].append(dialogue_color.x);
			data["dialogue_color"].append(dialogue_color.y);
			data["dialogue_color"].append(dialogue_color.z);
			data["dialogue_color"].append(dialogue_color.a);
			data["voice"] = JSONValue(voice);
			data["avatar_path"] = JSONValue(avatar_path);
		}else if(dialogue_function == set_actor_position){
			data["target_actor_position"] = JSONValue(JSONarrayValue);
			data["target_actor_position"].append(target_actor_position.x);
			data["target_actor_position"].append(target_actor_position.y);
			data["target_actor_position"].append(target_actor_position.z);
			data["target_actor_rotation"] = JSONValue(target_actor_rotation);
		}else if(dialogue_function == set_actor_animation){
			data["target_actor_animation"] = JSONValue(target_actor_animation);
			data["anim_mirrored"] = JSONValue(anim_mirrored);
			data["anim_mobile"] = JSONValue(anim_mobile);
			data["anim_super_mobile"] = JSONValue(anim_super_mobile);
			data["anim_swap"] = JSONValue(anim_swap);
			data["anim_from_start"] = JSONValue(anim_from_start);
			data["use_ik"] = JSONValue(use_ik);
			data["transition_speed"] = JSONValue(transition_speed);
			data["wait_anim_end"] = JSONValue(wait_anim_end);
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
		}else if(dialogue_function == set_camera_position){
			data["target_camera_position"] = JSONValue(JSONarrayValue);
			data["target_camera_position"].append(target_camera_position.x);
			data["target_camera_position"].append(target_camera_position.y);
			data["target_camera_position"].append(target_camera_position.z);
			data["target_camera_rotation"] = JSONValue(JSONarrayValue);
			data["target_camera_rotation"].append(target_camera_rotation.x);
			data["target_camera_rotation"].append(target_camera_rotation.y);
			data["target_camera_rotation"].append(target_camera_rotation.z);
			data["target_camera_zoom"] = JSONValue(target_camera_zoom);
		}else if(dialogue_function == fade_to_black){
			data["target_fade_to_black"] = JSONValue(target_fade_to_black);
			data["fade_to_black_duration"] = JSONValue(fade_to_black_duration);
		}else if(dialogue_function == settings){
			data["dialogue_layout"] = JSONValue(dialogue_layout);
			data["dialogue_text_font"] = JSONValue(dialogue_text_font);
			data["dialogue_text_size"] = JSONValue(dialogue_text_size);
			data["dialogue_text_shadow"] = JSONValue(dialogue_text_shadow);
			data["use_voice_sounds"] = JSONValue(use_voice_sounds);
			data["show_names"] = JSONValue(show_names);

			data["dialogue_text_color"] = JSONValue(JSONarrayValue);
			data["dialogue_text_color"].append(dialogue_text_color.x);
			data["dialogue_text_color"].append(dialogue_text_color.y);
			data["dialogue_text_color"].append(dialogue_text_color.z);
			data["dialogue_text_color"].append(dialogue_text_color.a);
		}else if(dialogue_function == set_actor_dialogue_control){
			data["dialogue_control"] = JSONValue(dialogue_control);
		}else if(dialogue_function == choice){
			data["nr_choices"] = JSONValue(nr_choices);
			if(nr_choices >= 1){
				data["choice_1"] = JSONValue(choice_1);
				if(@choice_1_element != null){
					data["choice_1_go_to_line"] = JSONValue(choice_1_element.index);
				}
			}
			if(nr_choices >= 2){
				data["choice_2"] = JSONValue(choice_2);
				if(@choice_2_element != null){
					data["choice_2_go_to_line"] = JSONValue(choice_2_element.index);
				}
			}
			if(nr_choices >= 3){
				data["choice_3"] = JSONValue(choice_3);
				if(@choice_3_element != null){
					data["choice_3_go_to_line"] = JSONValue(choice_3_element.index);
				}
			}
			if(nr_choices >= 4){
				data["choice_4"] = JSONValue(choice_4);
				if(@choice_4_element != null){
					data["choice_4_go_to_line"] = JSONValue(choice_4_element.index);
				}
			}
			if(nr_choices >= 5){
				data["choice_5"] = JSONValue(choice_5);
				if(@choice_5_element != null){
					data["choice_5_go_to_line"] = JSONValue(choice_5_element.index);
				}
			}
		}

		if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
			SaveIdentifier(data);
		}

		return data;
	}

	string GetDisplayString(){
		string display_string = "Dialogue ";
		display_string += dialogue_function_names[current_dialogue_function] + " ";
		UpdateActorName();

		if(dialogue_function == say){
			display_string += actor_name;
			string clean_say_text = say_text;
			clean_say_text = join(clean_say_text.split("\n"), "");
			if(clean_say_text.length() < 35){
				display_string += "\"" + clean_say_text + "\"";
			}else{
				display_string += "\"" + clean_say_text.substr(0, 35) + "..." + "\"";
			}
		}else if(dialogue_function == actor_settings){
			display_string += actor_name;
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
		}else if(dialogue_function == set_actor_omniscient){
			display_string += target_camera_zoom;
		}else if(dialogue_function == fade_to_black){
			display_string += target_fade_to_black + " ";
			display_string += fade_to_black_duration;
		}else if(dialogue_function == set_actor_dialogue_control){
			display_string += actor_name;
			display_string += dialogue_control;
		}else if(dialogue_function == choice){
			if(@choice_1_element == null || choice_1_element.deleted){
				@choice_1_element = drika_elements[0];
			}
			if(@choice_2_element == null || choice_2_element.deleted){
				@choice_2_element = drika_elements[0];
			}
			if(@choice_3_element == null || choice_3_element.deleted){
				@choice_3_element = drika_elements[0];
			}
			if(@choice_4_element == null || choice_4_element.deleted){
				@choice_4_element = drika_elements[0];
			}
			if(@choice_5_element == null || choice_5_element.deleted){
				@choice_5_element = drika_elements[0];
			}
		}

		return display_string;
	}

	void UpdateActorName(){
		//Temporary converting identifier for backwards compatibility. Can be removed later on.
		if(identifier_type == id){
			identifier_type = character;
		}
		actor_name = GetTargetDisplayText() + " ";
	}

	void Delete(){
		DeletePlaceholder();
		Reset();
	}

	void StartSettings(){
		CheckReferenceAvailable();
		CheckCharactersAvailable();
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
		if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
			for(uint i = 0; i < targets.size(); i++){
				DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
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
		}else if(dialogue_function == set_camera_position){
			PlaceholderCheck();

			if(placeholder.IsSelected()){
				vec3 new_position = placeholder.GetTranslation();
				vec4 v = placeholder.GetRotationVec4();
				quaternion quat(v.x,v.y,v.z,v.a);
				vec3 front = Mult(quat, vec3(0,0,1));
				vec3 new_rotation;
				new_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
				new_rotation.x = asin(front[1]) * -180.0f / PI;
				vec3 up = Mult(quat, vec3(0,1,0));
				vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
				vec3 expected_up = normalize(cross(expected_right, front));
				new_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

				const float zoom_sensitivity = 3.5f;
				float new_zoom = min(150.0f, 90.0f / max(0.001f, (1.0f + (placeholder.GetScale().x - 1.0f) * zoom_sensitivity)));

				if(target_camera_position != new_position || target_camera_rotation != new_rotation || target_camera_zoom != new_zoom){
					target_camera_position = new_position;
					target_camera_rotation = new_rotation;
					target_camera_zoom = new_zoom;
				}
			}
		}
	}

	void StartEdit(){
		Apply();
	}

	void Apply(){
		if(dialogue_function == set_actor_position){
			SetActorPosition();
		}else if(dialogue_function == actor_settings){
			SetActorSettings();
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
		}else if(dialogue_function == fade_to_black){
			SetFadeToBlack();
		}else if(dialogue_function == settings){
			SetDialogueSettings();
		}else if(dialogue_function == set_actor_dialogue_control){
			SetActorDialogueControl();
		}else if(dialogue_function == choice){
			Reset();
		}
	}

	void EditDone(){
		DeletePlaceholder();
		if(dialogue_function != set_actor_dialogue_control){
			Reset();
		}
	}

	void ApplySettings(){
		Apply();
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
			placeholder.SetDeletable(false);
			placeholder.SetCopyable(false);

			PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder);
			if(dialogue_function == set_actor_eye_direction){
				if(target_actor_eye_direction == vec3(0.0)){
					target_actor_eye_direction = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				placeholder.SetTranslation(target_actor_eye_direction);
				placeholder.SetScale(0.05f + 0.05f * target_blink_multiplier);
				placeholder_object.SetEditorDisplayName("Set Actor Eye Direction Helper");
			}else if(dialogue_function == set_actor_position){
				//If this is a new set character position then use the hotspot as the default position.
				if(target_actor_position == vec3(0.0)){
					target_actor_position = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
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
			}else if(dialogue_function == set_camera_position){
				if(target_camera_position == vec3(0.0)){
					target_camera_position = this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0);
				}
				placeholder.SetTranslation(target_camera_position);

				const float zoom_sensitivity = 3.5f;
				float scale = (90.0f / target_camera_zoom - 1.0f) / zoom_sensitivity + 1.0f;
				placeholder.SetScale(vec3(scale));

				float deg2rad = PI / 180.0f;
	            quaternion rot_y(vec4(0, 1, 0, target_camera_rotation.y * deg2rad));
	            quaternion rot_x(vec4(1, 0, 0, target_camera_rotation.x * deg2rad));
	            quaternion rot_z(vec4(0, 0, 1, target_camera_rotation.z * deg2rad));
	            placeholder.SetRotation(rot_y * rot_x * rot_z);

				placeholder_object.SetPreview("Data/Objects/camera.xml");
				placeholder_object.SetEditorDisplayName("Set Camera Position Helper");
				placeholder_object.SetSpecialType(kCamPreview);
			}
		}
	}

	void DrawSettings(){
		if(connection_types.find(_movement_object) != -1){
			DrawSelectTargetUI();
		}

		if(ImGui_Combo("Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			DeletePlaceholder();
			Reset();
			dialogue_function = dialogue_functions(current_dialogue_function);

			if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
				connection_types = {_movement_object};
			}else{
				connection_types = {};
			}

			if(dialogue_function == set_actor_animation){
				if(all_animations.size() == 0){
					level.SendMessage("drika_dialogue_get_animations " + hotspot.GetID());
				}
				QueryAnimation(search_buffer);
			}
		}

		if(dialogue_function == say){
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
				Reset();
			}
		}else if(dialogue_function == actor_settings){
			if(ImGui_ColorEdit4("Dialogue Color", dialogue_color)){

			}
			if(ImGui_SliderInt("Voice", voice, 0, 18, "%.0f")){
				level.SendMessage("drika_dialogue_test_voice " + voice);
			}

			ImGui_Columns(2, false);
			ImGui_SetColumnWidth(0, 75);
			ImGui_Image(avatar, vec2(50, 50));
			ImGui_NextColumn();
			if(ImGui_Button("Set Avatar")){
				string new_path = GetUserPickedReadPath("png", "Data/Textures");
				if(new_path != ""){
					array<string> split_path = new_path.split(".");
					string extention = split_path[split_path.size() - 1];
					if(extention != "jpg" && extention != "png" && extention != "tga"){
						DisplayError("Load Avatar", "Only .png, .tga or .jpg files are allowed.");
					}else{
						avatar_path = new_path;
						avatar = LoadTexture(avatar_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
					}
				}
			}
			if(avatar_path != "None"){
				if(ImGui_Button("Clear Avatar")){
					avatar_path = "None";
					avatar = LoadTexture(default_avatar_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
				}
			}
		}else if(dialogue_function == set_actor_animation){
			ImGui_Checkbox("From Start", anim_from_start);
			ImGui_SameLine();
			ImGui_Checkbox("Swap", anim_swap);
			ImGui_SameLine();
			ImGui_Checkbox("Mirrored", anim_mirrored);
			ImGui_SameLine();
			ImGui_Checkbox("Mobile", anim_mobile);
			ImGui_SameLine();
			ImGui_Checkbox("Super Mobile", anim_super_mobile);
			ImGui_SameLine();
			ImGui_Checkbox("Use IK", use_ik);
			ImGui_SameLine();
			ImGui_Checkbox("Wait Animation End", wait_anim_end);

			ImGui_SliderFloat("Transition Speed", transition_speed, 0.0, 10.0, "%.1f");

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
		}else if(dialogue_function == fade_to_black){
			ImGui_SliderFloat("Target Alpha", target_fade_to_black, 0.0, 1.0, "%.3f");
 			ImGui_SliderFloat("Fade Duration", fade_to_black_duration, 0.0, 10.0, "%.3f");
		}else if(dialogue_function == settings){
			ImGui_Combo("Dialogue Layout", dialogue_layout, dialogue_layout_names, dialogue_layout_names.size());
			ImGui_Text("Font : " + dialogue_text_font);
			ImGui_SameLine();
			if(ImGui_Button("Set Font")){
				string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
				if(new_path != ""){
					dialogue_text_font = new_path;
				}
			}
			ImGui_SliderInt("Dialogue Text Size", dialogue_text_size, 1, 100, "%.0f");
			ImGui_ColorEdit4("Dialogue Text Color", dialogue_text_color);
			ImGui_Checkbox("Dialogue Text Shadow", dialogue_text_shadow);
			ImGui_Checkbox("Use Voice Sounds", use_voice_sounds);
			ImGui_Checkbox("Show Name", show_names);
		}else if(dialogue_function == set_actor_dialogue_control){
			ImGui_Text("Set to : ");
			ImGui_SameLine();
			ImGui_Checkbox("", dialogue_control);
		}else if(dialogue_function == choice){
			ImGui_PushItemWidth(-1.0);

			ImGui_SliderInt("Number of choices", nr_choices, 1, 5, "%.0f");
			if(nr_choices >= 1){
				ImGui_Separator();
				ImGui_Text("Choice 1 : ");
				ImGui_SameLine();
				ImGui_InputText("##text1", choice_1, 64);
				AddGoToLineCombo(choice_1_element, "choice_1");
			}
			if(nr_choices >= 2){
				ImGui_Separator();
				ImGui_Text("Choice 2 : ");
				ImGui_SameLine();
				ImGui_InputText("##text2", choice_2, 64);
				AddGoToLineCombo(choice_2_element, "choice_2");
			}
			if(nr_choices >= 3){
				ImGui_Separator();
				ImGui_Text("Choice 3 : ");
				ImGui_SameLine();
				ImGui_InputText("##text3", choice_3, 64);
				AddGoToLineCombo(choice_3_element, "choice_3");
			}
			if(nr_choices >= 4){
				ImGui_Separator();
				ImGui_Text("Choice 4 : ");
				ImGui_SameLine();
				ImGui_InputText("##text4", choice_4, 64);
				AddGoToLineCombo(choice_4_element, "choice_4");
			}
			if(nr_choices >= 5){
				ImGui_Separator();
				ImGui_Text("Choice 5 : ");
				ImGui_SameLine();
				ImGui_InputText("##text5", choice_5, 64);
				AddGoToLineCombo(choice_5_element, "choice_5");
			}

			ImGui_PopItemWidth();
		}
	}

	void AddGoToLineCombo(DrikaElement@ &inout target_element, string combo_name){
		string preview_value = target_element.line_number + target_element.GetDisplayString();
		ImGui_Text("Go to line : ");
		ImGui_SameLine();
		ImGui_PushStyleColor(ImGuiCol_Text, target_element.GetDisplayColor());
		if(ImGui_BeginCombo("###line" + combo_name, preview_value)){
			for(uint i = 0; i < drika_indexes.size(); i++){
				int item_no = drika_indexes[i];
				bool is_selected = (target_element.index == drika_indexes[i]);
				vec4 text_color = drika_elements[item_no].GetDisplayColor();

				ImGui_PushStyleColor(ImGuiCol_Text, text_color);
				if(ImGui_Selectable(drika_elements[item_no].line_number + drika_elements[item_no].GetDisplayString(), is_selected)){
					@target_element = drika_elements[item_no];
				}
				ImGui_PopStyleColor();
			}
			ImGui_EndCombo();
		}
		ImGui_PopStyleColor();
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

	void TargetChanged(){
		Apply();
	}

	void PreTargetChanged(){
		Reset();
	}

	void ReceiveMessage(string message, int param){
		if(message == "drika_dialogue_choice_select"){
			current_choice = param;
			level.SendMessage("drika_dialogue_choice_select " + current_choice);
		}else if(message == "drika_dialogue_choice_pick" && !editing){
			triggered = true;
			current_choice = param;
		}
	}

	void Reset(){
		dialogue_done = false;
		if(dialogue_function == say){
			if(say_started){
				level.SendMessage("drika_dialogue_hide");
			}
			array<MovementObject@> targets = GetTargetMovementObjects();

			for(uint i = 0; i < targets.size(); i++){
				targets[i].ReceiveScriptMessage("stop_talking");
			}
			say_started = false;
			say_timer = 0.0;
			wait_timer = 0.0;
		}else if(dialogue_function == fade_to_black){
			if(triggered){
				ResetFadeToBlack();
			}
			triggered = false;
		}else if(dialogue_function == set_actor_dialogue_control){
			array<MovementObject@> targets = GetTargetMovementObjects();

			for(uint i = 0; i < targets.size(); i++){
				RemoveDialogueActor(targets[i].GetID());
			}
		}else if(dialogue_function == choice){
			if(choice_ui_added){
				level.SendMessage("drika_dialogue_hide");
			}
			choice_ui_added = false;
			triggered = false;
		}
	}

	void Update(){
		if(dialogue_function == say){
			UpdateSayDialogue(true);
		}else if(dialogue_function == choice){
			ShowChoiceDialogue(true);
		}
	}

	bool Trigger(){
		if(dialogue_function == say){
			if(UpdateSayDialogue(false)){
				Reset();
				return true;
			}
		}else if(dialogue_function == actor_settings){
			SetActorSettings();
			return true;
		}else if(dialogue_function == set_actor_position){
			SetActorPosition();
			return true;
		}else if(dialogue_function == set_actor_animation){
			if(wait_anim_end){
				if(!triggered){
					SetActorAnimation();
					triggered = true;
				}else{
					array<MovementObject@> targets = GetTargetMovementObjects();
					for(uint i = 0; i < targets.size(); i++){
						if(targets[i].GetBoolVar("in_animation")){
							return false;
						}
						triggered = false;
						return true;
					}
				}
				return false;
			}else{
				SetActorAnimation();
				return true;
			}
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
		}else if(dialogue_function == set_camera_position){
			SetCameraPosition();
			return true;
		}else if(dialogue_function == fade_to_black){
			SetFadeToBlack();
			return true;
		}else if(dialogue_function == settings){
			SetDialogueSettings();
			return true;
		}else if(dialogue_function == start){
			StartDialogue();
			return true;
		}else if(dialogue_function == end){
			return EndDialogue();
		}else if(dialogue_function == set_actor_dialogue_control){
			SetActorDialogueControl();
			return true;
		}else if(dialogue_function == choice){
			if(ShowChoiceDialogue(false)){
				Reset();
				return false;
			}
			return false;
		}

		return false;
	}

	bool ShowChoiceDialogue(bool preview){
		if(!choice_ui_added){
			level.SendMessage("drika_dialogue_clear_say");
			current_choice = 0;
			choice_ui_added = true;
			string merged_choices;

			if(nr_choices >= 1){
				merged_choices += "\"" + choice_1 + "\"";
			}
			if(nr_choices >= 2){
				merged_choices += "\"" + choice_2 + "\"";
			}
			if(nr_choices >= 3){
				merged_choices += "\"" + choice_3 + "\"";
			}
			if(nr_choices >= 4){
				merged_choices += "\"" + choice_4 + "\"";
			}
			if(nr_choices >= 5){
				merged_choices += "\"" + choice_5 + "\"";
			}

			level.SendMessage("drika_dialogue_choice " + this_hotspot.GetID() + " " +  merged_choices);
		}


		if(!preview){
			if((GetInputPressed(0, "up") || GetInputPressed(0, "menu_up")) && current_choice > 0){
				current_choice -= 1;
				level.SendMessage("drika_dialogue_choice_select " + current_choice);
			}else if((GetInputPressed(0, "down") || GetInputPressed(0, "menu_down")) && current_choice < (nr_choices - 1)){
				current_choice += 1;
				level.SendMessage("drika_dialogue_choice_select " + current_choice);
			}else if(GetInputPressed(0, "jump") || GetInputPressed(0, "skip_dialogue")){
				return GoToCurrentChoice();
			}else if(GetInputPressed(0, "1") && nr_choices >= 1){
				return PickChoice(choice_1_element.index);
			}else if(GetInputPressed(0, "2") && nr_choices >= 2){
				return PickChoice(choice_2_element.index);
			}else if(GetInputPressed(0, "3") && nr_choices >= 3){
				return PickChoice(choice_3_element.index);
			}else if(GetInputPressed(0, "4") && nr_choices >= 4){
				return PickChoice(choice_4_element.index);
			}else if(GetInputPressed(0, "5") && nr_choices >= 5){
				return PickChoice(choice_5_element.index);
			}
		}

		if(triggered){
			return GoToCurrentChoice();
		}

		return false;
	}

	bool GoToCurrentChoice(){
		int new_target_line;
		if(current_choice + 1 == 1){
			new_target_line = choice_1_element.index;
		}else if(current_choice + 1 == 2){
			new_target_line = choice_2_element.index;
		}else if(current_choice + 1 == 3){
			new_target_line = choice_3_element.index;
		}else if(current_choice + 1 == 4){
			new_target_line = choice_4_element.index;
		}else if(current_choice + 1 == 5){
			new_target_line = choice_5_element.index;
		}

		return PickChoice(new_target_line);
	}

	bool PickChoice(int new_target_line){
		if(new_target_line < 0 || new_target_line >= int(drika_elements.size())){
			Log(warning, "The Go to line isn't valid in the dialogue choice " + new_target_line);
			return false;
		}

		current_line = new_target_line;
		display_index = drika_indexes[new_target_line];

		return true;
	}

	void StartDialogue(){
		level.SendMessage("drika_dialogue_fade_out_in " + this_hotspot.GetID());
		wait_for_fade = true;
	}

	bool EndDialogue(){
		if(level.DialogueCameraControl()){
			if(!triggered){
				level.SendMessage("drika_dialogue_fade_out_in " + this_hotspot.GetID());
				wait_for_fade = true;
				triggered = true;
				return false;
			}else{
				level.SendMessage("drika_dialogue_end");
				triggered = false;
				return true;
			}
		}else{
			return true;
		}
	}

	void SetDialogueSettings(){
		string msg = "drika_dialogue_set_settings ";
		msg += dialogue_layout + " ";
		msg += dialogue_text_font + " ";
		msg += dialogue_text_size + " ";
		msg += dialogue_text_color.x + " ";
		msg += dialogue_text_color.y + " ";
		msg += dialogue_text_color.z + " ";
		msg += dialogue_text_color.a + " ";
		msg += dialogue_text_shadow + " ";
		msg += use_voice_sounds + " ";
		msg += show_names + " ";
		level.SendMessage(msg);
	}

	void SetFadeToBlack(){
		string msg = "drika_dialogue_fade_to_black ";
		msg += target_fade_to_black + " ";
		msg += fade_to_black_duration;
		triggered = true;
		level.SendMessage(msg);
	}

	void ResetFadeToBlack(){
		string msg = "drika_dialogue_clear_fade_to_black ";
		msg += target_fade_to_black;
		level.SendMessage(msg);
	}

	void SetCameraPosition(){
		string msg = "drika_dialogue_set_camera_position ";
		msg += floor(target_camera_rotation.x * 100.0f + 0.5f) / 100.0f + " ";
		msg += floor(target_camera_rotation.y * 100.0f + 0.5f) / 100.0f + " ";
		msg += floor(target_camera_rotation.z * 100.0f + 0.5f) / 100.0f + " ";
		msg += target_camera_position.x + " ";
		msg += target_camera_position.y + " ";
		msg += target_camera_position.z + " ";
		msg += target_camera_zoom;
		level.SendMessage(msg);
	}

	void SetActorOmniscient(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_omniscient " + omniscient);
		}
	}

	void SetActorHeadDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_head_target " + target_actor_head_direction.x + " " + target_actor_head_direction.y + " " + target_actor_head_direction.z + " " + target_actor_head_direction_weight);
		}
	}

	void SetActorTorsoDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_torso_target " + target_actor_torso_direction.x + " " + target_actor_torso_direction.y + " " + target_actor_torso_direction.z + " " + target_actor_torso_direction_weight);
		}
	}

	void SetActorEyeDirection(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_eye_dir " + target_actor_eye_direction.x + " " + target_actor_eye_direction.y + " " + target_actor_eye_direction.z + " " + target_blink_multiplier);
		}
	}

	void SetActorSettings(){
		string msg = "drika_dialogue_set_actor_settings ";
		msg += "\"" + actor_name + "\" ";
		msg += dialogue_color.x + " " + dialogue_color.y + " " + dialogue_color.z + " " + dialogue_color.a + " ";
		msg += voice + " ";
		msg += avatar_path;
		level.SendMessage(msg);
	}

	bool UpdateSayDialogue(bool preview){
		//Some setup operations that only need to be done once.
		if(say_started == false){
			say_started = true;
			say_text_split = say_text.split(" ");
			level.SendMessage("drika_dialogue_clear_say");
		}

		if(GetInputPressed(0, "skip_dialogue") && !preview){
			SkipWholeDialogue();
			return false;
		}else if(dialogue_done){
			if(GetInputPressed(0, "attack") && !preview){
				level.SendMessage("drika_dialogue_skip");
				return true;
			}
		}else if(GetInputPressed(0, "attack")){
			array<MovementObject@> targets = GetTargetMovementObjects();
			string nametag = "\"" + actor_name + "\"";
			say_timer = 0.0;
			wait_timer = 0.0;
			string wait_removed = join(say_text_split, " ");

			while(wait_removed.findFirst("[wait") != -1){
				int start_index = wait_removed.findFirst("[wait");
				wait_removed.erase(start_index, 10);
			}

			array<string> new_line_split = wait_removed.split("\n");
			for(uint i = 0; i < new_line_split.size(); i++){
				level.SendMessage("drika_dialogue_add_say " + nametag + " " + "\"" + new_line_split[i] + "\"");
				level.SendMessage("drika_dialogue_add_say " + nametag + " \n");
			}

			level.SendMessage("drika_dialogue_skip");
			for(uint i = 0; i < targets.size(); i++){
				targets[i].ReceiveScriptMessage("stop_talking");
			}
			say_text_split.resize(0);
			dialogue_done = true;
			return false;
		}else if(wait_timer > 0.0){
			wait_timer -= time_step;
		}else if(say_timer > 0.15){
			say_timer = 0.0;
			string nametag = "\"" + actor_name + "\"";
			array<MovementObject@> targets = GetTargetMovementObjects();

			if(say_text_split[0].findFirst("[wait") != -1){
				int start_index = say_text_split[0].findFirst("[wait");
				//Check if there is text in front that needs to be displayed first.
				if(start_index != 0){
					level.SendMessage("drika_dialogue_add_say " + nametag + " " + say_text_split[0].substr(0, start_index - 1));
				}

				say_text_split.removeAt(0);
				wait_timer = atof(say_text_split[0].substr(0, 2));
				say_text_split[0].erase(0, 4);
				for(uint i = 0; i < targets.size(); i++){
					targets[i].ReceiveScriptMessage("stop_talking");
				}
				return false;
			}else if(say_text_split[0].findFirst("\n") != -1){
				for(uint i = 0; i < targets.size(); i++){
					targets[i].ReceiveScriptMessage("start_talking");
				}
				array<string> new_line_split = say_text_split[0].split("\n");
				level.SendMessage("drika_dialogue_add_say " + nametag + " " + new_line_split[0]);
				level.SendMessage("drika_dialogue_add_say " + nametag + " \n");

				new_line_split.removeAt(0);
				say_text_split[0] = join(new_line_split, "\n");

				return false;
			}

			for(uint i = 0; i < targets.size(); i++){
				targets[i].ReceiveScriptMessage("start_talking");
			}

			string msg = "drika_dialogue_add_say ";
			msg += nametag + " ";
			msg += say_text_split[0];
			level.SendMessage(msg);

			say_text_split.removeAt(0);

			if(say_text_split.size() == 0){
				for(uint i = 0; i < targets.size(); i++){
					targets[i].ReceiveScriptMessage("stop_talking");
				}
				dialogue_done = true;
			}

		}
		say_timer += time_step;
		return false;
	}

	void SkipWholeDialogue(){
		while(true){
			//When ending a dialogue just let it trigger.
			if(GetCurrentElement().drika_element_type == drika_dialogue){
				DrikaDialogue@ dialogue_function = cast<DrikaDialogue@>(GetCurrentElement());
				if(dialogue_function.dialogue_function == end){
					break;
				}
			}

			//No end dialogue was found and the script has ended.
			if(current_line == int(drika_indexes.size() - 1)){
				script_finished = true;
				break;
			}else{
				current_line += 1;
				display_index = drika_indexes[current_line];
			}

			//Skip any dialogue say or sounds.
			if(GetCurrentElement().drika_element_type == drika_dialogue){
				DrikaDialogue@ dialogue_function = cast<DrikaDialogue@>(GetCurrentElement());
				if(dialogue_function.dialogue_function == say || dialogue_function.dialogue_function == set_camera_position || dialogue_function.dialogue_function == fade_to_black){
					continue;
				}
			}else if(GetCurrentElement().drika_element_type == drika_play_sound){
				continue;
			}

			GetCurrentElement().Trigger();
		}
	}

	void SetActorPosition(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			/* targets[i].rigged_object().anim_client().Reset(); */
			targets[i].Execute("dialogue_anim = \"Data/Animations/r_actionidle.anm\";");
			targets[i].ReceiveScriptMessage("set_rotation " + target_actor_rotation);
			targets[i].ReceiveScriptMessage("set_dialogue_position " + target_actor_position.x + " " + target_actor_position.y + " " + target_actor_position.z);
			targets[i].Execute("this_mo.velocity = vec3(0.0, 0.0, 0.0);");
			targets[i].Execute("FixDiscontinuity();");
		}
	}

	void SetActorAnimation(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			string flags = "0";
			if(anim_mirrored) flags += " | _ANM_MIRRORED";
			if(anim_mobile) flags += " | _ANM_MOBILE";
			if(anim_super_mobile) flags += " | _ANM_SUPER_MOBILE";
			if(anim_swap) flags += " | _ANM_SWAP";
			if(anim_from_start) flags += " | _ANM_FROM_START";

			string roll_fade = use_ik ? "roll_ik_fade = 0.0f;" : "roll_ik_fade = 1.0f;";
			string callback = "";
			if(wait_anim_end) callback += "in_animation = true;this_mo.rigged_object().anim_client().SetAnimationCallback(\"void EndAnim()\");";

			targets[i].rigged_object().anim_client().Reset();
			targets[i].Execute(roll_fade + "this_mo.SetAnimation(\"" + target_actor_animation + "\", " + transition_speed + ", " + flags + ");dialogue_anim = \"" + target_actor_animation + "\";" + callback);
		}
	}

	void SetActorDialogueControl(){
		array<MovementObject@> targets = GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			if(dialogue_control){
				AddDialogueActor(targets[i].GetID());
			}else{
				RemoveDialogueActor(targets[i].GetID());
			}
		}
	}
}
