#include "drika_shared.as";

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
							choice = 14,
							clear_dialogue = 15
						}

enum camera_transitions	{
							no_transition = 0,
							move_transition = 1,
							fade_transition = 2
						}

class DrikaDialogue : DrikaElement{

	dialogue_functions dialogue_function;
	int current_dialogue_function;
	string say_text;
	array<string> say_text_split;
	bool say_started = false;
	float say_timer = 0.0;
	bool auto_continue;
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
	bool wait_for_fade = false;
	bool skip_move_transition = false;

	int dialogue_layout;
	string dialogue_text_font;
	int dialogue_text_size;
	vec4 dialogue_text_color;
	bool dialogue_text_shadow;
	bool use_voice_sounds;
	bool show_names;
	bool show_avatar;
	bool use_fade;
	int dialogue_location;
	float dialogue_text_speed;

	string default_avatar_path = "Data/Textures/ui/menus/main/white_square.png";
	TextureAssetRef avatar = LoadTexture(default_avatar_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
	string avatar_path;
	bool anim_mirrored;
	bool anim_mobile;
	bool anim_super_mobile;
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
	DrikaGoToLineSelect@ choice_1_element;
	DrikaGoToLineSelect@ choice_2_element;
	DrikaGoToLineSelect@ choice_3_element;
	DrikaGoToLineSelect@ choice_4_element;
	DrikaGoToLineSelect@ choice_5_element;
	array<float> dof_settings;
	bool update_dof = false;
	bool enable_look_at_target;
	bool enable_move_with_target;
	DrikaTargetSelect@ track_target;
	camera_transitions camera_transition;
	int current_camera_transition;
	vec3 camera_translation_from;
	vec3 camera_rotation_from;
	float camera_transition_timer = 0.0;
	array<DialogueScriptEntry@> dialogue_script;

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
												"Choice",
												"Clear Dialogue"
											};

	array<string> camera_transition_names =	{
												"None",
												"Move Transition",
												"Fade Transition"
											};

	DrikaDialogue(JSONValue params = JSONValue()){
		dialogue_function = dialogue_functions(GetJSONInt(params, "dialogue_function", start));
		current_dialogue_function = dialogue_function;

		placeholder.default_scale = vec3(1.0);

		say_text = GetJSONString(params, "say_text", "Drika Hotspot Dialogue");
		dialogue_color = GetJSONVec4(params, "dialogue_color", vec4(1));
		voice = GetJSONInt(params, "voice", 0);
		avatar_path = GetJSONString(params, "avatar_path", "None");
		auto_continue = GetJSONBool(params, "auto_continue", false);
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
		camera_transition = camera_transitions(GetJSONInt(params, "camera_transition", no_transition));
		current_camera_transition = camera_transition;

		dialogue_layout = GetJSONInt(params, "dialogue_layout", 0);
		dialogue_text_font = GetJSONString(params, "dialogue_text_font", "Data/Fonts/arial.ttf");
		dialogue_text_size = GetJSONInt(params, "dialogue_text_size", 50);
		dialogue_text_color = GetJSONVec4(params, "dialogue_text_color", vec4(1));
		dialogue_text_shadow = GetJSONBool(params, "dialogue_text_shadow", true);
		use_voice_sounds = GetJSONBool(params, "use_voice_sounds", true);
		show_names = GetJSONBool(params, "show_names", true);
		show_avatar = GetJSONBool(params, "show_avatar", true);
		use_fade = GetJSONBool(params, "use_fade", true);
		dialogue_location = GetJSONInt(params, "dialogue_location", dialogue_bottom);
		dialogue_text_speed = GetJSONFloat(params, "dialogue_text_speed", 50.0);

		anim_mirrored = GetJSONBool(params, "anim_mirrored", false);
		anim_mobile = GetJSONBool(params, "anim_mobile", false);
		anim_super_mobile = GetJSONBool(params, "anim_super_mobile", false);
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

		@choice_1_element = DrikaGoToLineSelect("choice_1_go_to_line", params);
		@choice_2_element = DrikaGoToLineSelect("choice_2_go_to_line", params);
		@choice_3_element = DrikaGoToLineSelect("choice_3_go_to_line", params);
		@choice_4_element = DrikaGoToLineSelect("choice_4_go_to_line", params);
		@choice_5_element = DrikaGoToLineSelect("choice_5_go_to_line", params);

		dof_settings = GetJSONFloatArray(params, "dof_settings", {0.0, 0.0, 0.0, 0.0, 0.0, 0.0});
		enable_look_at_target = GetJSONBool(params, "enable_look_at_target", false);
		enable_move_with_target = GetJSONBool(params, "enable_move_with_target", false);
		@track_target = DrikaTargetSelect(this, params, "track_target");
		track_target.target_option = character_option | item_option;

		drika_element_type = drika_dialogue;
		has_settings = true;

		if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
			connection_types = {_movement_object};
		}
		@target_select = DrikaTargetSelect(this, params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;
	}

	void PostInit(){
		UpdateActorName();
		choice_1_element.PostInit();
		choice_2_element.PostInit();
		choice_3_element.PostInit();
		choice_4_element.PostInit();
		choice_5_element.PostInit();
		target_select.PostInit();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["dialogue_function"] = JSONValue(dialogue_function);

		if(dialogue_function == say){
			data["say_text"] = JSONValue(say_text);
			data["auto_continue"] = JSONValue(auto_continue);
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
			data["dof_settings"] = JSONValue(JSONarrayValue);
			for(uint i = 0; i < dof_settings.size(); i++){
				data["dof_settings"].append(dof_settings[i]);
			}
			data["enable_look_at_target"] = JSONValue(enable_look_at_target);
			data["enable_move_with_target"] = JSONValue(enable_move_with_target);
			if(enable_look_at_target || enable_move_with_target){
				track_target.SaveIdentifier(data);
			}
			data["camera_transition"] = JSONValue(camera_transition);
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
			data["show_avatar"] = JSONValue(show_avatar);
			data["dialogue_location"] = JSONValue(dialogue_location);
			data["dialogue_text_speed"] = JSONValue(dialogue_text_speed);

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
				choice_1_element.SaveGoToLine(data);
			}
			if(nr_choices >= 2){
				data["choice_2"] = JSONValue(choice_2);
				choice_2_element.SaveGoToLine(data);
			}
			if(nr_choices >= 3){
				data["choice_3"] = JSONValue(choice_3);
				choice_3_element.SaveGoToLine(data);
			}
			if(nr_choices >= 4){
				data["choice_4"] = JSONValue(choice_4);
				choice_4_element.SaveGoToLine(data);
			}
			if(nr_choices >= 5){
				data["choice_5"] = JSONValue(choice_5);
				choice_5_element.SaveGoToLine(data);
			}
		}else if(dialogue_function == start){
			data["use_fade"] = JSONValue(use_fade);
		}else if(dialogue_function == end){
			data["use_fade"] = JSONValue(use_fade);
		}

		if(dialogue_function == say || dialogue_function == actor_settings || dialogue_function == set_actor_position || dialogue_function == set_actor_animation || dialogue_function == set_actor_eye_direction || dialogue_function == set_actor_torso_direction || dialogue_function == set_actor_head_direction || dialogue_function == set_actor_omniscient || dialogue_function == set_actor_dialogue_control){
			target_select.SaveIdentifier(data);
		}

		return data;
	}

	string GetDisplayString(){
		string display_string = "Dialogue ";
		display_string += dialogue_function_names[current_dialogue_function] + " ";
		UpdateActorName();

		if(dialogue_function == say){
			display_string += actor_name + " ";
			display_string += "\"" + say_text + "\"";
		}else if(dialogue_function == actor_settings){
			display_string += actor_name + " ";
		}else if(dialogue_function == set_actor_position){
			display_string += actor_name + " ";
		}else if(dialogue_function == set_actor_animation){
			display_string += actor_name + " ";
			display_string += target_actor_animation;
		}else if(dialogue_function == set_actor_eye_direction){
			display_string += actor_name + " ";
			display_string += target_blink_multiplier;
		}else if(dialogue_function == set_actor_torso_direction){
			display_string += actor_name + " ";
			display_string += target_actor_torso_direction_weight;
		}else if(dialogue_function == set_actor_head_direction){
			display_string += actor_name + " ";
			display_string += target_actor_head_direction_weight;
		}else if(dialogue_function == set_actor_omniscient){
			display_string += actor_name + " ";
			display_string += omniscient;
		}else if(dialogue_function == set_camera_position){
			display_string += target_camera_zoom;
		}else if(dialogue_function == fade_to_black){
			display_string += target_fade_to_black + " ";
			display_string += fade_to_black_duration;
		}else if(dialogue_function == set_actor_dialogue_control){
			display_string += actor_name + " ";
			display_string += dialogue_control;
		}else if(dialogue_function == choice){
			choice_1_element.CheckLineAvailable();
			if(nr_choices >= 2)	choice_2_element.CheckLineAvailable();
			if(nr_choices >= 3)	choice_3_element.CheckLineAvailable();
			if(nr_choices >= 4)	choice_4_element.CheckLineAvailable();
			if(nr_choices >= 5)	choice_5_element.CheckLineAvailable();
		}

		return display_string;
	}

	void UpdateActorName(){
		actor_name = target_select.GetTargetDisplayText();
	}

	void Delete(){
		placeholder.Remove();
		target_select.Delete();
		track_target.Delete();
		Reset();
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
		track_target.CheckAvailableTargets();
		if(dialogue_function == say){

		}else if(dialogue_function == set_actor_animation){
			if(all_animations.size() == 0){
				level.SendMessage("drika_dialogue_get_animations " + hotspot.GetID());
			}
			QueryAnimation(search_buffer);
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
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

			if(enable_look_at_target || enable_move_with_target){
				array<Object@> track_targets = track_target.GetTargetObjects();

				for(uint j = 0; j < track_targets.size(); j++){
					vec3 target_location = track_targets[j].GetTranslation();

					if(track_targets[j].GetType() == _item_object){
						ItemObject@ item_obj = ReadItemID(track_targets[j].GetID());
						target_location = item_obj.GetPhysicsPosition();
					}else if(track_targets[j].GetType() == _movement_object){
						MovementObject@ char = ReadCharacterID(track_targets[j].GetID());
						target_location = char.position;
					}
					DebugDrawLine(placeholder.GetTranslation(), target_location, vec3(0.0, 1.0, 0.0), _delete_on_update);
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
		}else if(dialogue_function == set_camera_position){
			SetCameraTransform(target_camera_position, target_camera_rotation);
			SetDialogueDOF();
		}
	}

	void EditDone(){
		placeholder.Remove();
		if(dialogue_function != set_actor_dialogue_control){
			Reset();
		}
	}

	void ApplySettings(){
		Apply();
	}

	void PlaceholderCheck(){
		if(!placeholder.Exists()){
			placeholder.path = "Data/Objects/placeholder/empty_placeholder.xml";
			placeholder.Create();

			PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder.object);
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

		float option_name_width = 150.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Dialogue Function");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("###Dialogue Function", current_dialogue_function, dialogue_function_names, dialogue_function_names.size())){
			placeholder.Remove();
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
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(connection_types.find(_movement_object) != -1){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Target Character");
			ImGui_NextColumn();
			ImGui_NextColumn();

			target_select.DrawSelectTargetUI();
		}

		if(dialogue_function == say){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Auto Continue");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_Checkbox("", auto_continue);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text");
			ImGui_NextColumn();
			ImGui_SetTextBuf(say_text);

			if(ImGui_IsRootWindowOrAnyChildFocused() && !ImGui_IsAnyItemActive() && !ImGui_IsMouseClicked(0)){
				ImGui_SetKeyboardFocusHere(0);
			}

			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				say_text = ImGui_GetTextBuf();
				Reset();
			}

			ImGui_PopItemWidth();
		}else if(dialogue_function == actor_settings){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Color");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_ColorEdit4("##Dialogue Color", dialogue_color)){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Voice");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderInt("##Voice", voice, 0, 18, "%.0f")){
				level.SendMessage("drika_dialogue_test_voice " + voice);
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Avatar");
			ImGui_NextColumn();
			ImGui_BeginChild("avatar_select_ui", vec2(0, 50), false, ImGuiWindowFlags_AlwaysAutoResize);
			ImGui_Columns(2, false);
			ImGui_SetColumnWidth(0, 110);
			if(ImGui_Button("Pick Avatar")){
				string new_path = GetUserPickedReadPath("png", "Data/Textures");
				if(new_path != ""){
					new_path = new_path;
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
			ImGui_NextColumn();
			ImGui_Image(avatar, vec2(50, 50));
			ImGui_EndChild();
		}else if(dialogue_function == set_actor_animation){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Animation");
			ImGui_NextColumn();

			ImGui_Checkbox("From Start", anim_from_start);
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

			ImGui_BeginChild("animation_settings_ui", vec2(0, 20), false, ImGuiWindowFlags_AlwaysAutoResize);
			ImGui_Columns(2, false);
			ImGui_SetColumnWidth(0, 150);

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Transition Speed");
			ImGui_NextColumn();
			float second_settings_column_width = ImGui_GetContentRegionAvailWidth();
			ImGui_PushItemWidth(second_settings_column_width);
			ImGui_SliderFloat("##Transition Speed", transition_speed, 0.0, 10.0, "%.1f");
			ImGui_PopItemWidth();
			ImGui_EndChild();

			ImGui_AlignTextToFramePadding();
			ImGui_SetTextBuf(search_buffer);
			ImGui_Text("Search");
			ImGui_SameLine();
			ImGui_PushItemWidth(ImGui_GetContentRegionAvailWidth());
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
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Set Omnicient to");
			ImGui_NextColumn();
			ImGui_Checkbox("", omniscient);
		}else if(dialogue_function == fade_to_black){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Target Alpha");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderFloat("##Target Alpha", target_fade_to_black, 0.0, 1.0, "%.3f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Fade Duration");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
 			ImGui_SliderFloat("##Fade Duration", fade_to_black_duration, 0.0, 10.0, "%.3f");
			ImGui_PopItemWidth();
		}else if(dialogue_function == settings){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Layout");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_Combo("##Dialogue Layout", dialogue_layout, dialogue_layout_names, dialogue_layout_names.size());
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Font");
			ImGui_NextColumn();
			if(ImGui_Button("Set Font")){
				string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
				if(new_path != ""){
					array<string> path_split = new_path.split("/");
					string file_name = path_split[path_split.size() - 1];
					string file_extension = file_name.substr(file_name.length() - 3, 3);

					if(file_extension == "ttf" || file_extension == "TTF"){
						dialogue_text_font = new_path;
					}else{
						DisplayError("Font issue", "Only ttf font files are supported.");
					}
				}
			}
			ImGui_SameLine();
			ImGui_AlignTextToFramePadding();
			ImGui_Text(dialogue_text_font);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Text Size");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderInt("##Dialogue Text Size", dialogue_text_size, 1, 100, "%.0f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Text Color");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_ColorEdit4("##Dialogue Text Color", dialogue_text_color);
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Text Shadow");
			ImGui_NextColumn();
			ImGui_Checkbox("###Dialogue Text Shadow", dialogue_text_shadow);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Voice Sounds");
			ImGui_NextColumn();
			ImGui_Checkbox("###Use Voice Sounds", use_voice_sounds);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Show Name");
			ImGui_NextColumn();
			ImGui_Checkbox("###Show Name", show_names);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Show Avatar");
			ImGui_NextColumn();
			ImGui_Checkbox("###Show Avatar", show_avatar);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Dialogue Location");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_Combo("##Dialogue Location", dialogue_location, dialogue_location_names, dialogue_location_names.size());
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text Speed");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderFloat("##Text Speed", dialogue_text_speed, 1.0, 100.0, "%.0f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(dialogue_function == set_actor_dialogue_control){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Set dialogue control to");
			ImGui_NextColumn();
			ImGui_Checkbox("", dialogue_control);
		}else if(dialogue_function == choice){

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Number of choices");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderInt("###Number of choices", nr_choices, 1, 5, "%.0f")){
				Reset();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_Separator();
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Choice 1");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_InputText("##text1", choice_1, 64)){
				Reset();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
			choice_1_element.DrawGoToLineUI();

			if(nr_choices >= 2){
				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Choice 2");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_InputText("##text2", choice_2, 64)){
					Reset();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();
				choice_2_element.DrawGoToLineUI();
			}
			if(nr_choices >= 3){
				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Choice 3");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_InputText("##text3", choice_3, 64)){
					Reset();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();
				choice_3_element.DrawGoToLineUI();
			}
			if(nr_choices >= 4){
				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Choice 4");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_InputText("##text4", choice_4, 64)){
					Reset();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();
				choice_4_element.DrawGoToLineUI();
			}
			if(nr_choices >= 5){
				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Choice 5");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_InputText("##text5", choice_5, 64)){
					Reset();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();
				choice_5_element.DrawGoToLineUI();
			}

		}else if(dialogue_function == set_camera_position){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Near Blur");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Near Blur", dof_settings[0], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Near Dist");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Near Dist", dof_settings[1], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Near Transition");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Near Transition", dof_settings[2], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Far Blur");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Far Blur", dof_settings[3], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Far Dist");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Far Dist", dof_settings[4], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Far Transition");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("##Far Transition", dof_settings[5], 0.0f, 10.0f, "%.1f")){
				update_dof = true;
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Look At Target");
			ImGui_NextColumn();
			ImGui_Checkbox("###Look At Target", enable_look_at_target);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Move With Target");
			ImGui_NextColumn();
			ImGui_Checkbox("###Move With Target", enable_move_with_target);
			ImGui_NextColumn();

			if(enable_look_at_target || enable_move_with_target){
				ImGui_Separator();
				ImGui_Text("Target Character");
				ImGui_NextColumn();
				ImGui_NextColumn();
				track_target.DrawSelectTargetUI();
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Transition Method");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("###Transition Method", current_camera_transition, camera_transition_names, camera_transition_names.size())){
				camera_transition = camera_transitions(current_camera_transition);
			}

		}else if(dialogue_function == start){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Fade");
			ImGui_NextColumn();
			ImGui_Checkbox("###Use Fade", use_fade);
			ImGui_NextColumn();
		}else if(dialogue_function == end){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Fade");
			ImGui_NextColumn();
			ImGui_Checkbox("###Use Fade", use_fade);
			ImGui_NextColumn();
		}
	}

	void SetDialogueDOF(){
		level.SendMessage("drika_set_dof " + dof_settings[0] + " " + dof_settings[1] + " " + dof_settings[2] + " " + dof_settings[3] + " " + dof_settings[4] + " " + dof_settings[5]);
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

	void ReceiveMessage(array<string> messages){
		if(messages[0] == "fade_out_done"){
			wait_for_fade = false;
		}else if(messages[0] == "old_camera_transform"){
			camera_translation_from = vec3(atof(messages[1]), atof(messages[2]), atof(messages[3]));
			camera_rotation_from = vec3(atof(messages[4]), atof(messages[5]), atof(messages[6]));

			//Skip the move transition if the beginning and end transform is the same.
			if(distance(camera_rotation_from, target_camera_rotation) < 0.1 && distance(camera_translation_from, target_camera_position) < 0.1){
				skip_move_transition = true;
			}
		}
	}

	void Reset(){
		dialogue_done = false;
		wait_for_fade = false;
		skip_move_transition = false;
		camera_transition_timer = 0.0;
		if(dialogue_function == say){
			if(say_started){
				level.SendMessage("drika_dialogue_clear");
			}
			SetTargetTalking(false);
			say_started = false;
			say_timer = 0.0;
			wait_timer = 0.0;
		}else if(dialogue_function == fade_to_black){
			if(triggered){
				ResetFadeToBlack();
			}
		}else if(dialogue_function == set_actor_dialogue_control){
			array<MovementObject@> targets = target_select.GetTargetMovementObjects();

			for(uint i = 0; i < targets.size(); i++){
				RemoveDialogueActor(targets[i]);
			}
		}else if(dialogue_function == choice){
			if(choice_ui_added){
				level.SendMessage("drika_dialogue_clear");
			}
			choice_ui_added = false;
		}else if(dialogue_function == start){
			if(triggered){
				level.SendMessage("drika_dialogue_end");
			}
		}else if(dialogue_function == set_camera_position){
			level.SendMessage("drika_set_dof 0.0 0.0 0.0 0.0 0.0 0.0");
		}
		triggered = false;
	}

	void Update(){
		if(dialogue_function == say){
			UpdateSayDialogue(true);
		}else if(dialogue_function == choice){
			ShowChoiceDialogue(true);
		}else if(dialogue_function == set_camera_position){
			if(update_dof){
				update_dof = false;
				SetDialogueDOF();
			}
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
					array<MovementObject@> targets = target_select.GetTargetMovementObjects();
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
			if(camera_transition == move_transition){
				if(triggered == false){
					triggered = true;
					level.SendMessage("drika_get_old_camera_transform " + this_hotspot.GetID());
					return false;
				}

				if(skip_move_transition){
					SetCameraTransform(target_camera_position, target_camera_rotation);
					SetDialogueDOF();
					skip_move_transition = false;
					triggered = false;
					return true;
				}

				float transition_duration = 1.0;
				float alpha = ApplyEase(camera_transition_timer / transition_duration, easeInOutSine);
				alpha = max(0.0, min(1.0, alpha));

				// Convert the X Y Z rotations into quaternions.
				float deg2rad = PI / 180.0f;
	            quaternion rot_y(vec4(0, 1, 0, target_camera_rotation.y * deg2rad));
	            quaternion rot_x(vec4(1, 0, 0, target_camera_rotation.x * deg2rad));
	            quaternion rot_z(vec4(0, 0, 1, target_camera_rotation.z * deg2rad));
				quaternion target_rotation = rot_y * rot_x * rot_z;

	            quaternion rot2_y(vec4(0, 1, 0, camera_rotation_from.y * deg2rad));
	            quaternion rot2_x(vec4(1, 0, 0, camera_rotation_from.x * deg2rad));
	            quaternion rot2_z(vec4(0, 0, 1, camera_rotation_from.z * deg2rad));
				quaternion from_rotation = rot2_y * rot2_x * rot2_z;

				// Use the alpha to mix the two quaternions, making them blend.
				quaternion mixed_rotation = mix(from_rotation, target_rotation, alpha);

				// Convert the resulting quaternion back into X Y Z rotation.
				vec3 front = Mult(mixed_rotation, vec3(0,0,1));
				vec3 new_mixed_rotation;
				new_mixed_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
				new_mixed_rotation.x = asin(front[1]) * -180.0f / PI;
				vec3 up = Mult(mixed_rotation, vec3(0,1,0));
				vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
				vec3 expected_up = normalize(cross(expected_right, front));
				new_mixed_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

				vec3 mixed_translation = mix(camera_translation_from, target_camera_position, alpha);

				SetCameraTransform(mixed_translation, new_mixed_rotation);
				SetDialogueDOF();

				if(camera_transition_timer >= transition_duration){
					camera_transition_timer = 0.0;
					triggered = false;
					return true;
				}

				camera_transition_timer += time_step;
				return false;
			}else if(camera_transition == fade_transition){
				if(wait_for_fade){
					//Waiting for the fade to end.
					return false;
				}else if(!triggered){
					//Starting the fade.
					level.SendMessage("drika_dialogue_fade_out_in " + this_hotspot.GetID());
					wait_for_fade = true;
					triggered = true;
					return false;
				}else{
					SetCameraTransform(target_camera_position, target_camera_rotation);
					SetDialogueDOF();
					triggered = false;
					return true;
				}
			}else{
				SetCameraTransform(target_camera_position, target_camera_rotation);
				SetDialogueDOF();
				return true;
			}
		}else if(dialogue_function == fade_to_black){
			SetFadeToBlack();
			return true;
		}else if(dialogue_function == settings){
			SetDialogueSettings();
			return true;
		}else if(dialogue_function == start){
			return StartDialogue();
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
		}else if(dialogue_function == clear_dialogue){
			level.SendMessage("allow_dialogue_move_in");
			level.SendMessage("drika_dialogue_clear");
			return true;
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
				return PickChoice(choice_1_element.GetTargetLineIndex());
			}else if(GetInputPressed(0, "2") && nr_choices >= 2){
				return PickChoice(choice_2_element.GetTargetLineIndex());
			}else if(GetInputPressed(0, "3") && nr_choices >= 3){
				return PickChoice(choice_3_element.GetTargetLineIndex());
			}else if(GetInputPressed(0, "4") && nr_choices >= 4){
				return PickChoice(choice_4_element.GetTargetLineIndex());
			}else if(GetInputPressed(0, "5") && nr_choices >= 5){
				return PickChoice(choice_5_element.GetTargetLineIndex());
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
			new_target_line = choice_1_element.GetTargetLineIndex();
		}else if(current_choice + 1 == 2){
			new_target_line = choice_2_element.GetTargetLineIndex();
		}else if(current_choice + 1 == 3){
			new_target_line = choice_3_element.GetTargetLineIndex();
		}else if(current_choice + 1 == 4){
			new_target_line = choice_4_element.GetTargetLineIndex();
		}else if(current_choice + 1 == 5){
			new_target_line = choice_5_element.GetTargetLineIndex();
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

	bool StartDialogue(){
		if(wait_for_fade){
			//Waiting for the fade to end.
			return false;
		}else if(use_fade && !triggered){
			//Starting the fade.
			level.SendMessage("drika_dialogue_fade_out_in " + this_hotspot.GetID());
			wait_for_fade = true;
			triggered = true;
			return false;
		}else{
			//Fade is done, continue with the next function.
			in_dialogue_mode = true;
			triggered = false;
			level.SendMessage("drika_dialogue_start");
			return true;
		}
	}

	bool EndDialogue(){
		if(wait_for_fade){
			return false;
		}else if(level.DialogueCameraControl() && (use_fade && !triggered)){
			level.SendMessage("drika_dialogue_fade_out_in " + this_hotspot.GetID());
			wait_for_fade = true;
			triggered = true;
			return false;
		}else{
			in_dialogue_mode = false;
			triggered = false;
			ClearDialogueActors();
			level.SendMessage("drika_dialogue_end");
			return true;
		}
	}

	void SetDialogueSettings(){
		text_speed = 1.0f / dialogue_text_speed;
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
		msg += show_avatar + " ";
		msg += dialogue_location + " ";
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

	void SetCameraTransform(vec3 position, vec3 rotation){
		string msg = "drika_dialogue_set_camera_position ";
		msg += floor(rotation.x * 100.0f + 0.5f) / 100.0f + " ";
		msg += floor(rotation.y * 100.0f + 0.5f) / 100.0f + " ";
		msg += floor(rotation.z * 100.0f + 0.5f) / 100.0f + " ";
		msg += position.x + " ";
		msg += position.y + " ";
		msg += position.z + " ";
		msg += target_camera_zoom + " ";

		array<Object@> targets = track_target.GetTargetObjects();
		msg += enable_look_at_target + " ";
		msg += enable_move_with_target + " ";
		msg += ((targets.size() > 0)?targets[0].GetID():-1) + " ";
		level.SendMessage(msg);
	}

	void SetActorOmniscient(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_omniscient " + omniscient);
		}
	}

	void SetActorHeadDirection(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_head_target " + target_actor_head_direction.x + " " + target_actor_head_direction.y + " " + target_actor_head_direction.z + " " + target_actor_head_direction_weight);
		}
	}

	void SetActorTorsoDirection(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage("set_torso_target " + target_actor_torso_direction.x + " " + target_actor_torso_direction.y + " " + target_actor_torso_direction.z + " " + target_actor_torso_direction_weight);
		}
	}

	void SetActorEyeDirection(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

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

	int dialogue_progress = 0;
	float dialogue_timer = 0.0;

	bool UpdateSayDialogue(bool preview){
		//Some setup operations that only need to be done once.
		if(say_started == false){
			say_started = true;
			dialogue_progress = 0;
			dialogue_timer = 0.0;

			dialogue_script = InterpDialogueScript(say_text);

			level.SendMessage("drika_dialogue_clear_say");

			string nametag = "\"" + actor_name + "\"";
			level.SendMessage("drika_dialogue_add_say " + nametag + " " + "\"" + say_text + "\"");

			return false;
		}else if(say_started == true && (GetInputPressed(0, "skip_dialogue") && !preview)){
			SetTargetTalking(false);
			SkipWholeDialogue();
			return false;
		}else if(dialogue_done == true){
			if((GetInputPressed(0, "attack") || auto_continue) && !preview){
				level.SendMessage("drika_dialogue_skip");
				return true;
			}else{
				return false;
			}
		}else if(say_started == true){
			if(GetInputPressed(0, "attack") && !preview){
				level.SendMessage("drika_dialogue_skip");
				level.SendMessage("drika_dialogue_show_skip_message");
				SetTargetTalking(false);

				for(uint i = dialogue_progress; i < dialogue_script.size(); i++){
					DialogueScriptEntry@ entry = dialogue_script[i];
					dialogue_progress += 1;

					switch(entry.script_entry_type){
						case character_entry:
							level.SendMessage("drika_dialogue_next");
							break;
						case wait_entry:
							//Skip the wait entries.
							level.SendMessage("drika_dialogue_next");
							break;
						default:
							level.SendMessage("drika_dialogue_next");
							break;
					}
				}

				dialogue_done = true;
				return false;
			}else if(dialogue_timer <= 0.0){
				for(uint i = dialogue_progress; i < dialogue_script.size(); i++){
					DialogueScriptEntry@ entry = dialogue_script[i];
					dialogue_progress += 1;

					switch(entry.script_entry_type){
						case character_entry:
							level.SendMessage("drika_dialogue_next");
							dialogue_timer = text_speed;
							SetTargetTalking(true);
							return false;
						case wait_entry:
							level.SendMessage("drika_dialogue_next");
							dialogue_timer = entry.wait;
							SetTargetTalking(false);
							return false;
						default:
							level.SendMessage("drika_dialogue_next");
							break;
					}
				}

				//At the end of the dialogue.
				level.SendMessage("drika_dialogue_show_skip_message");
				dialogue_done = true;
				SetTargetTalking(false);
				return false;
			}

			dialogue_timer -= time_step;
			return false;
		}
		return false;
	}

	void SetTargetTalking(bool talking){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			targets[i].ReceiveScriptMessage(talking?"start_talking":"stop_talking");
		}
	}

	void SkipWholeDialogue(){
		Reset();
		while(true){
			//No end dialogue was found and the script has ended.
			if(current_line == int(drika_indexes.size() - 1)){
				script_finished = true;
				break;
			}else{
				current_line += 1;
				display_index = drika_indexes[current_line];
			}

			//When ending a dialogue just let it trigger.
			if(GetCurrentElement().drika_element_type == drika_dialogue){
				DrikaDialogue@ dialogue_function = cast<DrikaDialogue@>(GetCurrentElement());
				if(dialogue_function.dialogue_function == end){
					break;
				}else if(dialogue_function.dialogue_function == choice){
					//A dialogue choice can not be skipped.
					break;
				}
			}

			//Skip any dialogue say or sounds.
			if(GetCurrentElement().drika_element_type == drika_dialogue){
				DrikaDialogue@ dialogue_function = cast<DrikaDialogue@>(GetCurrentElement());
				if(dialogue_function.dialogue_function == say || dialogue_function.dialogue_function == fade_to_black){
					continue;
				}
			}else if(GetCurrentElement().drika_element_type == drika_go_to_line){
				continue;
			}else if(GetCurrentElement().drika_element_type == drika_play_sound){
				continue;
			}else if(GetCurrentElement().drika_element_type == drika_animation){
				DrikaAnimation@ animation_function = cast<DrikaAnimation@>(GetCurrentElement());
				animation_function.SkipAnimation();
				continue;
			}

			GetCurrentElement().Trigger();
		}
	}

	void SetActorPosition(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			/* targets[i].rigged_object().anim_client().Reset(); */
			/* targets[i].Execute("dialogue_anim = \"Data/Animations/r_actionidle.anm\";"); */

			if(targets[i].GetIntVar("state") == _ragdoll_state){
                targets[i].Execute("WakeUp(_wake_stand);" +
		                			"EndGetUp();" +
		                			"unragdoll_time = 0.0f;");
            }

			targets[i].ReceiveScriptMessage("set_rotation " + target_actor_rotation);
			targets[i].ReceiveScriptMessage("set_dialogue_position " + target_actor_position.x + " " + target_actor_position.y + " " + target_actor_position.z);
			targets[i].Execute("this_mo.velocity = vec3(0.0, 0.0, 0.0);");
			targets[i].Execute("FixDiscontinuity();");
		}
	}

	void SetActorAnimation(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			string flags = "0";
			if(anim_mirrored) flags += " | _ANM_MIRRORED";
			if(anim_mobile) flags += " | _ANM_MOBILE";
			if(anim_super_mobile) flags += " | _ANM_SUPER_MOBILE";
			if(anim_from_start) flags += " | _ANM_FROM_START";

			string roll_fade = use_ik ? "roll_ik_fade = 0.0f;" : "roll_ik_fade = 1.0f;";
			string callback = "";
			if(wait_anim_end) callback += "in_animation = true;this_mo.rigged_object().anim_client().SetAnimationCallback(\"void EndAnim()\");";

			if(targets[i].GetIntVar("state") == _ragdoll_state){
                targets[i].Execute("WakeUp(_wake_stand);" +
		                			"EndGetUp();" +
		                			"unragdoll_time = 0.0f;");
				targets[i].Execute("FixDiscontinuity();");
            }

			targets[i].rigged_object().anim_client().Reset();
			targets[i].Execute(roll_fade + "this_mo.SetAnimation(\"" + target_actor_animation + "\", " + transition_speed + ", " + flags + ");dialogue_anim = \"" + target_actor_animation + "\";" + callback);
		}
	}

	void SetActorDialogueControl(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();

		for(uint i = 0; i < targets.size(); i++){
			if(dialogue_control){
				AddDialogueActor(targets[i]);
			}else{
				RemoveDialogueActor(targets[i]);
			}
		}
	}
}
