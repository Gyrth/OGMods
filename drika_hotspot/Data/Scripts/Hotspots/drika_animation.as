enum animation_types {
						looping_forwards = 0,
						looping_backwards = 1,
						looping_forwards_and_backwards = 2,
						forward = 3,
						backward = 4
					}

enum animation_methods 	{
							timeline_method = 0,
							placeholder_method = 1
						}

enum duration_methods 	{
							constant_speed = 0,
							divide_between_keys = 1
						}

class AnimationKey{
	vec3 translation;
	quaternion rotation;
	vec3 scale;
	float time;
	bool moving = false;
	float moving_time;
}

class DrikaAnimation : DrikaElement{
	array<AnimationKey@> key_data;
	array<int> key_ids;
	animation_types animation_type;
	int current_animation_type;
	int current_duration_method;
	int current_animation_method;
	duration_methods duration_method;
	animation_methods animation_method;
	bool interpolate_rotation;
	bool interpolate_translation;
	bool animate_camera;
	bool animate_scale;
	float duration;
	float extra_yaw;

	int key_index = 0;
	Object@ current_key;
	Object@ next_key;
	float pi = 3.14159265f;
	float animation_timer = 0.0;
	int loop_direction = 1;
	bool animation_finished = false;
	float timeline_position = 1.0;
	float timeline_duration = 1.0;
	bool timeline_snap = true;
	float alpha = 0.0;
	bool moving_animation_key = false;
	AnimationKey@ target_key;
	float margin = 20.0;
	float timeline_width;
	float timeline_height;
	Object@ camera_placeholder = null;
	bool draw_debug_lines = false;
	vec3 previous_translation = vec3();
	bool animation_started = false;
	vec3 new_translation;
	quaternion new_rotation;
	vec3 new_scale;
	bool done = false;

	array<string> animation_type_names = 	{
												"Looping Forwards",
												"Looping Backwards",
												"Looping Forwards and Backwards",
												"Forward",
												"Backward"
											};

	array<string> duration_method_names = 	{
												"Constant Speed",
												"Divide Between Keys"
											};

	array<string> animation_method_names = 	{
												"Timeline",
												"Placeholder"
											};

	DrikaAnimation(JSONValue params = JSONValue()){
		drika_element_type = drika_animation;
		connection_types = {_movement_object, _env_object, _decal_object, _item_object, _hotspot_object};
		key_ids = GetJSONIntArray(params, "key_ids", {});
		key_data = InterpAnimationData(GetJSONValueArray(params, "key_data", {}));
		animation_type = animation_types(GetJSONInt(params, "animation_type", 3));
		current_animation_type = animation_type;
		duration_method = duration_methods(GetJSONInt(params, "duration_method", 0));
		current_duration_method = duration_method;
		animation_method = animation_methods(GetJSONInt(params, "animation_method", 1));
		current_animation_method  = animation_method;
		interpolate_rotation = GetJSONBool(params, "interpolate_rotation", false);
		interpolate_translation = GetJSONBool(params, "interpolate_translation", false);
		animate_camera = GetJSONBool(params, "animate_camera", false);
		animate_scale = GetJSONBool(params, "animate_scale", false);
		duration = GetJSONFloat(params, "duration", 5.0);
		extra_yaw = GetJSONFloat(params, "extra_yaw", 0.0);

		LoadIdentifier(params);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("animation");
		data["animation_type"] = JSONValue(animation_type);
		data["duration_method"] = JSONValue(duration_method);
		data["animation_method"] = JSONValue(animation_method);
		data["interpolate_rotation"] = JSONValue(interpolate_rotation);
		data["interpolate_translation"] = JSONValue(interpolate_translation);
		data["animate_camera"] = JSONValue(animate_camera);
		data["animate_scale"] = JSONValue(animate_scale);
		data["duration"] = JSONValue(duration);
		data["extra_yaw"] = JSONValue(extra_yaw);

		data["key_ids"] = JSONValue(JSONarrayValue);
		for(uint i = 0; i < key_ids.size(); i++){
			data["key_ids"].append(key_ids[i]);
		}

		data["key_data"] = JSONValue(JSONarrayValue);
		for(uint i = 0; i < key_data.size(); i++){
			JSONValue current_key_data;
			current_key_data["time"] = JSONValue(key_data[i].time);

			current_key_data["translation"] = JSONValue(JSONarrayValue);
			current_key_data["translation"].append(key_data[i].translation.x);
			current_key_data["translation"].append(key_data[i].translation.y);
			current_key_data["translation"].append(key_data[i].translation.z);

			current_key_data["rotation"] = JSONValue(JSONarrayValue);
			current_key_data["rotation"].append(key_data[i].rotation.x);
			current_key_data["rotation"].append(key_data[i].rotation.y);
			current_key_data["rotation"].append(key_data[i].rotation.z);
			current_key_data["rotation"].append(key_data[i].rotation.w);

			current_key_data["scale"] = JSONValue(JSONarrayValue);
			current_key_data["scale"].append(key_data[i].scale.x);
			current_key_data["scale"].append(key_data[i].scale.y);
			current_key_data["scale"].append(key_data[i].scale.z);

			data["key_data"].append(current_key_data);

		}
		SaveIdentifier(data);
		return data;
	}

	array<AnimationKey@> InterpAnimationData(array<JSONValue> data){
		array<AnimationKey@> new_data;
		for(uint i = 0; i < data.size(); i++){
			JSONValue current_key_data = data[i];
			AnimationKey new_key;
			new_key.translation = vec3(current_key_data["translation"][0].asFloat(), current_key_data["translation"][1].asFloat(), current_key_data["translation"][2].asFloat());
			new_key.rotation = quaternion(current_key_data["rotation"][0].asFloat(), current_key_data["rotation"][1].asFloat(), current_key_data["rotation"][2].asFloat(), current_key_data["rotation"][3].asFloat());
			new_key.scale = vec3(current_key_data["scale"][0].asFloat(), current_key_data["scale"][1].asFloat(), current_key_data["scale"][2].asFloat());
			new_key.time = current_key_data["time"].asFloat();
			new_data.insertLast(new_key);
		}
		return new_data;
	}

	void PostInit(){
		Reset();
	}

	void Delete(){
		for(uint i = 0; i < key_ids.size(); i++){
			QueueDeleteObjectID(key_ids[i]);
		}
	}

	string GetDisplayString(){
		if(animate_camera){
			return "Animation Camera";
		}else{
			return "Animation " + GetTargetDisplayText();
		}
	}

	void StartSettings(){
		CheckReferenceAvailable();
		WriteAnimationKeyParams();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Animation Method", current_animation_method, animation_method_names, animation_method_names.size())){
			animation_method = animation_methods(current_animation_method);
			//Remove all the old data when switching between methods.
			if(animation_method == placeholder_method){
				key_data.resize(0);
			}else{
				for(uint i = 0; i < key_ids.size(); i++){
					QueueDeleteObjectID(key_ids[i]);
				}
				key_ids.resize(0);
			}
		}
		if(animation_method == placeholder_method){
			if(ImGui_Combo("Duration Method", current_duration_method, duration_method_names, duration_method_names.size())){
				duration_method = duration_methods(current_duration_method);
			}
		}
		if(ImGui_Combo("Animation Type", current_animation_type, animation_type_names, animation_type_names.size())){
			animation_type = animation_types(current_animation_type);
		}
		if(ImGui_SliderFloat("Duration", duration, 0.0f, 10.0f, "%.2f")){
			SetCurrentTransform();
		}
		if(ImGui_SliderFloat("Extra Yaw", extra_yaw, 0.0f, 360.0f, "%.1f")){
			SetCurrentTransform();
		}
		if(ImGui_Checkbox("Interpolation Rotation", interpolate_rotation)){
			SetCurrentTransform();
		}
		if(ImGui_Checkbox("Interpolation Translation", interpolate_translation)){
			SetCurrentTransform();
		}
		if(ImGui_Checkbox("Animate Camera", animate_camera)){
			SetCurrentTransform();
		}
		if(ImGui_Checkbox("Animate Scale", animate_scale)){
			SetCurrentTransform();
		}
	}

	void SetCurrentTransform(){
		CameraPlaceholderCheck();
		array<Object@> targets = GetTargetObjects();
		if(targets.size() == 0){
			return;
		}
		if(animation_method == timeline_method){
			TimelineSetTransform(animation_timer);
		}else if(animation_method == placeholder_method){
			PlaceholderSetTransform();
		}
	}

	void ReceiveEditorMessage(array<string> messages){
		if(animation_method == placeholder_method){
			if(messages[0] == "added_object"){
				int obj_id = atoi(messages[1]);
				if(!ObjectExists(obj_id)){
					return;
				}
				Object@ obj = ReadObjectFromID(obj_id);
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Owner")){
					if(obj_params.GetInt("Owner") == this_hotspot.GetID()){
						//The new object is a duplicated animation key of this animation.
						key_ids.insertAt(obj_params.GetInt("Index") + 1, obj_id);
						WriteAnimationKeyParams();
					}
				}
			}
		}
	}

	void TargetChanged(){
		animate_camera = false;
	}

	void ConnectedChanged(){
		animate_camera = false;
	}

	bool Trigger(){
		array<Object@> targets = GetTargetObjects();
		// Don't do anything if the target object does not exist.
		if(targets.size() == 0){
			return false;
		}

		if(!animation_started){
			animation_started = true;
			if(animate_camera){
				level.SendMessage("animating_camera true " + hotspot.GetID());
			}
		}

		//When the animation is done, and the trigger is called again, then start the animation over.
		if(done){
			Reset();
			return false;
		}

		UpdateAnimation();
		if(animation_finished){
			done = true;
			if(animate_camera){
				level.SendMessage("animating_camera false " + hotspot.GetID());
			}
			return true;
		}else{
			return false;
		}
	}

	void UpdateAnimationKeys(){
		//Make sure there is always at least two animation key available.
		while(key_ids.size() < 2){
			CreateKey();
			WriteAnimationKeyParams();
		}
	}

	void WriteAnimationKeyParams(){
		for(uint i = 0; i < key_ids.size(); i++){
			if(!ObjectExists(key_ids[i])){
				return;
			}
			Object@ key = ReadObjectFromID(key_ids[i]);
			ScriptParams@ key_params = key.GetScriptParams();
			key_params.SetInt("Index", i);
			key_params.SetInt("Owner", this_hotspot.GetID());
		}
	}

	void UpdateAnimation(){
		if(animation_method == timeline_method){
			TimelineUpdateAnimation();
		}else if(animation_method == placeholder_method){
			UpdateAnimationKeys();
			animation_timer += time_step;
			PlaceholderUpdateAnimation();
		}
		SetCurrentTransform();
	}

	float CalculateWholeDistance(){
		float whole_distance = 0.0f;
		for(uint i = 1; i < key_ids.size(); i++){
			whole_distance += distance(ReadObjectFromID(key_ids[i - 1]).GetTranslation(), ReadObjectFromID(key_ids[i]).GetTranslation());
		}
		//Add the distance between the fist and last node as well.
		whole_distance += distance(ReadObjectFromID(key_ids[0]).GetTranslation(), ReadObjectFromID(key_ids[(key_ids.size() - 1)]).GetTranslation());
		return whole_distance;
	}

	void NextAnimationKey(){
		if(animation_type == looping_forwards){
			if(key_index + 2 >= int(key_ids.size())){
				key_index = 0;
			}else{
				key_index += 1;
			}
			@current_key = ReadObjectFromID(key_ids[key_index]);
			@next_key = ReadObjectFromID(key_ids[key_index + 1]);
		}else if(animation_type == looping_backwards){
			if(key_index - 2 < 0){
				key_index = key_ids.size() - 1;
			}else{
				key_index -= 1;
			}
			@current_key = ReadObjectFromID(key_ids[key_index]);
			@next_key = ReadObjectFromID(key_ids[key_index - 1]);
		}else if(animation_type == looping_forwards_and_backwards){
			if(loop_direction == 1){
				if(key_index + 2 >= int(key_ids.size())){
					loop_direction = -1;
					key_index += 1;
				}else{
					key_index += 1;
				}
			}else{
				if(key_index - 2 < 0){
					loop_direction = 1;
					key_index -= 1;
				}else{
					key_index -= 1;
				}
			}

			if(loop_direction == 1){
				@current_key = ReadObjectFromID(key_ids[key_index]);
				@next_key = ReadObjectFromID(key_ids[key_index + 1]);
			}else{
				@current_key = ReadObjectFromID(key_ids[key_index]);
				@next_key = ReadObjectFromID(key_ids[key_index - 1]);
			}
		}else if(animation_type == forward){
			if(key_index + 2 >= int(key_ids.size())){
				animation_finished = true;
			}else{
				key_index += 1;
			}
		}else if(animation_type == backward){
			if(key_index - 2 < 0){
				animation_finished = true;
			}else{
				key_index -= 1;
			}
		}
	}

	void CameraPlaceholderCheck(){
		if(animate_camera){
			if(@camera_placeholder == null){
				int camera_placeholder_id = CreateObject("Data/Objects/placeholder/camera_placeholder.xml");
				@camera_placeholder = ReadObjectFromID(camera_placeholder_id);
				camera_placeholder.SetSelectable(true);
				camera_placeholder.SetTranslatable(true);
				camera_placeholder.SetScalable(true);
				camera_placeholder.SetRotatable(true);
			}

			PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(camera_placeholder);
			if(show_editor){
				placeholder_object.SetSpecialType(kCamPreview);
			}else{
				placeholder_object.SetSpecialType(kSpawn);
			}
		}else{
			if(@camera_placeholder != null){
				QueueDeleteObjectID(camera_placeholder.GetID());
				@camera_placeholder = null;
			}
		}
	}

	void ApplyTransform(vec3 translation, quaternion rotation, vec3 scale){
		Object@ target;
		if(animate_camera){
			@target = camera_placeholder;

			vec3 direction;
			vec3 position = target.GetTranslation();

			// Set camera euler angles from rotation matrix
			vec3 front = Mult(rotation, vec3(0,0,1));
			float y_rot = atan2(front.x, front.z)*180.0f/pi;
			float x_rot = asin(front[1])*-180.0f/pi;
			vec3 up = Mult(rotation, vec3(0,1,0));
			vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
			vec3 expected_up = normalize(cross(expected_right, front));
			float z_rot = atan2(dot(up,expected_right), dot(up, expected_up))*180.0f/pi;
			direction.x = floor(x_rot*100.0f+0.5f)/100.0f;
			direction.y = floor(y_rot*100.0f+0.5f)/100.0f;
			direction.z = floor(z_rot*100.0f+0.5f)/100.0f;

			if(!EditorModeActive()){
				camera.SetPos(translation);
				camera.SetXRotation(direction.x);
				camera.SetYRotation(direction.y);
				camera.SetZRotation(direction.z);
				camera.SetDistance(0.0f);
	            UpdateListener(translation, vec3(0.0f), camera.GetFacing(), camera.GetUpVector());
			}

			if(animate_scale){
				const float zoom_sensitivity = 3.5f;
				float zoom = min(150.0f, 90.0f / max(0.001f,(1.0f+(scale.x-1.0f) * zoom_sensitivity)));
				level.Execute("dialogue.cam_zoom = " + zoom + ";");
				camera.SetFOV(zoom);
			}

			level.Execute("dialogue.cam_pos = vec3(" + translation.x + ", " + translation.y + ", " + translation.z + ");");
			level.Execute("dialogue.cam_rot = vec3(" + direction.x + "," + direction.y + "," + direction.z + ");");
		}else{
			array<Object@> targets = GetTargetObjects();
			@target = targets[0];
		}

		target.SetTranslation(translation);
		target.SetRotation(rotation);
		if(animate_scale){
			target.SetScale(scale);
		}

		RefreshChildren(target);
	}

	void RefreshChildren(Object@ obj){
		if(obj.GetType() == _group){
			array<int> children = obj.GetChildren();
			for(uint i = 0; i < children.size(); i++){
				Object@ child = ReadObjectFromID(children[i]);
				child.SetTranslation(child.GetTranslation());
				child.SetRotation(child.GetRotation());
				if(animate_scale){
					child.SetScale(child.GetScale());
				}
				RefreshChildren(child);
			}
		}
	}

	void TimelineUpdateAnimation(){
		if(animation_type == forward){
			animation_timer += time_step;
			if(animation_timer >= duration){
				animation_finished = true;
			}
		}else if(animation_type == backward){
			animation_timer -= time_step;
			if(animation_timer <= 0.0){
				animation_finished = true;
			}
		}else if(animation_type == looping_forwards){
			animation_timer += time_step;
			if(animation_timer >= duration){
				animation_timer = 0.0;
			}
		}else if(animation_type == looping_backwards){
			animation_timer -= time_step;
			if(animation_timer <= 0.0){
				animation_timer = duration;
			}
		}else if(animation_type == looping_forwards_and_backwards){
			if(loop_direction == 1){
				animation_timer += time_step;
				if(animation_timer >= duration){
					loop_direction = -1;
				}
			}else if(loop_direction == -1){
				animation_timer -= time_step;
				if(animation_timer <= 0.0){
					loop_direction = 1;
				}
			}
		}
	}

	void TimelineSetTransform(float current_time){
		bool on_keyframe = false;

		for(uint i = 0; i < key_data.size(); i++){
			if(key_data[i].time == current_time){
				//If the timeline position is exactly on a keyframe then just apply that transform.
				on_keyframe = true;
				new_translation = key_data[i].translation;
				new_rotation = key_data[i].rotation;
				new_scale = key_data[i].scale;
			}
		}

		if(!on_keyframe){
			AnimationKey@ right_key = GetClosestAnimationFrame(current_time, 1, {});
			AnimationKey@ left_key = GetClosestAnimationFrame(current_time, -1, {});
			AnimationKey@ right2_key = GetClosestAnimationFrame(current_time, 1, {right_key});
			AnimationKey@ left2_key = GetClosestAnimationFrame(current_time, -1, {left_key});

			if(@left_key != null && @right_key != null){
				float whole_length = right_key.time - left_key.time;
				float current_length = right_key.time - current_time;
				alpha = (current_length / whole_length);

				if(!on_keyframe){
					new_scale = mix(right_key.scale, left_key.scale, alpha);
				}

				if(interpolate_translation || interpolate_rotation){
					if(@left2_key != null && @right2_key != null){
						if(interpolate_translation){
							new_translation = Bezier3(right_key.translation, left_key.translation, right2_key.translation, left2_key.translation, alpha);
						}
						if(interpolate_rotation){
							previous_translation = Bezier3(right_key.translation, left_key.translation, right2_key.translation, left2_key.translation, max(0.0, alpha - time_step));
						}
					}else if(@left2_key != null){
						if(interpolate_translation){
							new_translation = Bezier2Left(right_key.translation, left_key.translation, left2_key.translation, alpha);
						}
						if(interpolate_rotation){
							previous_translation = Bezier2Left(right_key.translation, left_key.translation, left2_key.translation, max(0.0, alpha - time_step));
						}
					}else if(@right2_key != null){
						if(interpolate_translation){
							new_translation = Bezier2Right(right_key.translation, left_key.translation, right2_key.translation, alpha);
						}
						if(interpolate_rotation){
							previous_translation = Bezier2Right(right_key.translation, left_key.translation, right2_key.translation, max(0.0, alpha - time_step));
						}
					}
				}

				if(!interpolate_translation){
					new_translation = mix(right_key.translation, left_key.translation, alpha);
				}

				if(!interpolate_rotation){
					new_rotation = mix(right_key.rotation, left_key.rotation, alpha);
					float extra_y_rot = (extra_yaw / 180.0f * pi);
					new_rotation = new_rotation.opMul(quaternion(vec4(0,1,0,extra_y_rot)));
				}else{
					vec3 path_direction = normalize(previous_translation - new_translation);
					vec3 up_direction = normalize(mix(right_key.rotation, left_key.rotation, alpha) * vec3(0.0f, 1.0f, 0.0f));

					float yaw = atan2(-path_direction.x, -path_direction.z) + (extra_yaw / 180.0f * pi);
					float pitch = asin(-path_direction.y);
					vec3 right_roll_direction = normalize(right_key.rotation * vec3(1.0f, 0.0f, 0.0f));
					vec3 left_roll_direction = normalize(left_key.rotation * vec3(1.0f, 0.0f, 0.0f));
					vec3 mixed_roll_direction = mix(right_roll_direction, left_roll_direction, alpha);
					float roll = asin(mixed_roll_direction.y);

					new_rotation = quaternion(vec4(0,1,0,yaw)) * quaternion(vec4(1,0,0,pitch)) * quaternion(vec4(0,0,1,roll));
				}
			}else if(@right_key != null){
				new_translation = right_key.translation;
				new_rotation = right_key.rotation;
				new_scale = right_key.scale;
			}else if(@left_key != null){
				new_translation = left_key.translation;
				new_rotation = left_key.rotation;
				new_scale = left_key.scale;
			}else{
				//No keys found.
				return;
			}
		}
		ApplyTransform(new_translation, new_rotation, new_scale);
	}

	vec3 Bezier3(vec3 right_position, vec3 left_position, vec3 second_right_position, vec3 second_left_position, float alpha){
		float target_distance = distance(left_position, right_position) / 2.0f;

		vec3 left_direction = normalize(right_position - second_left_position);
		vec3 left_target = left_position + (left_direction * target_distance);

		vec3 right_direction = normalize(left_position - second_right_position);
		vec3 right_target = right_position + (right_direction * target_distance);

		vec3 leg_1_position = mix(left_target, left_position, alpha);
		vec3 leg_2_position = mix(right_target, left_target, alpha);
		vec3 leg_3_position = mix(right_position, right_target, alpha);

		vec3 leg_1_2_average = mix(leg_2_position, leg_1_position, alpha);
		vec3 leg_2_3_average = mix(leg_3_position, leg_2_position, alpha);

		if(draw_debug_lines){
			DebugDrawWireBox(right_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawWireBox(left_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawWireBox(second_right_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawWireBox(second_left_position, vec3(0.5), vec3(1.0), _delete_on_update);

			DebugDrawLine(left_position, left_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawLine(right_position, right_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawWireBox(leg_1_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawWireBox(leg_2_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawLine(leg_1_position, leg_2_position, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawWireBox(leg_3_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawLine(leg_2_position, leg_3_position, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawLine(leg_1_2_average, leg_2_3_average, vec3(0.0, 1.0, 1.0), _delete_on_update);
		}

		return mix(leg_2_3_average, leg_1_2_average, alpha);
	}

	vec3 Bezier2Right(vec3 right_position, vec3 left_position, vec3 second_right_position, float alpha){
		float target_distance = distance(left_position, right_position) / 2.0f;

		vec3 right_direction = normalize(left_position - second_right_position);
		vec3 right_target = right_position + (right_direction * target_distance);

		vec3 leg_1_position = mix(right_target, left_position, alpha);
		vec3 leg_2_position = mix(right_position, right_target, alpha);

		if(draw_debug_lines){
			DebugDrawWireBox(right_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawWireBox(left_position, vec3(0.5), vec3(1.0), _delete_on_update);

			DebugDrawWireBox(second_right_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawLine(left_position, right_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawLine(right_position, right_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawWireBox(leg_1_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawWireBox(leg_2_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawLine(leg_1_position, leg_2_position, vec3(0.0, 0.0, 1.0), _delete_on_update);
		}

		return mix(leg_2_position, leg_1_position, alpha);
	}

	vec3 Bezier2Left(vec3 right_position, vec3 left_position, vec3 second_left_position, float alpha){
		float target_distance = distance(left_position, right_position) / 2.0f;

		vec3 left_direction = normalize(right_position - second_left_position);
		vec3 left_target = left_position + (left_direction * target_distance);

		vec3 leg_1_position = mix(left_target, left_position, alpha);
		vec3 leg_2_position = mix(right_position, left_target, alpha);

		if(draw_debug_lines){
			DebugDrawWireBox(right_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawWireBox(left_position, vec3(0.5), vec3(1.0), _delete_on_update);

			DebugDrawWireBox(second_left_position, vec3(0.5), vec3(1.0), _delete_on_update);
			DebugDrawLine(right_position, left_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawLine(left_position, left_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
			DebugDrawWireBox(leg_1_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawWireBox(leg_2_position, vec3(0.5), vec3(1.0, 0.0, 0.0), _delete_on_update);
			DebugDrawLine(leg_1_position, leg_2_position, vec3(0.0, 0.0, 1.0), _delete_on_update);
		}

		return mix(leg_2_position, leg_1_position, alpha);
	}

	AnimationKey@ GetClosestAnimationFrame(float current_time, int direction, array<AnimationKey@> exceptions){
		AnimationKey@ key = null;
		for(uint i = 0; i < key_data.size(); i++){
			bool hit_exception = false;
			for(uint j = 0; j < exceptions.size(); j++){
				if(exceptions[j] is key_data[i]){
					hit_exception = true;
					break;
				}
			}
			if(hit_exception){
				continue;
			}
			if(	(key_data[i].time > current_time && direction == 1 && (@key == null || key_data[i].time - current_time < key.time - current_time)) ||
				(key_data[i].time < current_time && direction == -1 && (@key == null || current_time - key_data[i].time < current_time - key.time))){
				@key = key_data[i];
			}
		}
		return key;
	}

	void PlaceholderUpdateAnimation(){
		if(duration_method == constant_speed){
			//The animation will have a constant speed.
			bool skip_node = false;
			float whole_distance = CalculateWholeDistance();
			//When the keys are all at the same location no animation can be performed.
			if(whole_distance == 0.0f){
				return;
			}else{
				float key_distance = distance(next_key.GetTranslation(), current_key.GetTranslation());
				//If the current and next keys are at the same location then just go to the next key.
				if(key_distance == 0.0f){
					animation_timer = 0.0f;
					NextAnimationKey();
				}else{
					//To make sure the time isn't 0, or else it will devide by zero.
					float duration_between_keys = max(0.0001f, duration * (key_distance / whole_distance));
					alpha = animation_timer / duration_between_keys;
					if(animation_timer > duration_between_keys){
						animation_timer = 0.0f;
						NextAnimationKey();
						return;
					}
				}
			}
		}else if(duration_method == divide_between_keys){
			//The animation will devide the time between the animation keys.
			float duration_between_keys = max(0.0001, duration / key_ids.size());
			alpha = animation_timer / duration_between_keys;
			float key_distance = distance(next_key.GetTranslation(), current_key.GetTranslation());
			if(animation_timer > duration_between_keys){
				animation_timer = 0.0f;
				NextAnimationKey();
				return;
			}
		}else{
			Log(error, "Unknown animation method! " + duration_method);
		}
	}

	void PlaceholderSetTransform(){
		quaternion new_rotation;
		vec3 new_position;

		array<Object@> targets = GetTargetObjects();

		if(interpolate_translation){
			float node_distance = distance(next_key.GetTranslation(), current_key.GetTranslation());
			//Current time, start value, change in value, duration
			float offset_alpha = sine_wave(alpha, 0.0f, 1.0f, 1.0f);
			vec3 previous_direction = normalize(current_key.GetRotation() * vec3(0.0f, 0.0f, 1.0f) * loop_direction) * node_distance * alpha;
			vec3 current_direction = normalize(next_key.GetRotation() * vec3(0.0f, 0.0f, 1.0f) * loop_direction) * (node_distance * (1.0f - alpha));
			new_position = mix(current_key.GetTranslation() + previous_direction, next_key.GetTranslation() + current_direction, offset_alpha);
		}else{
			new_position = mix(current_key.GetTranslation(), next_key.GetTranslation(), alpha);
		}

		if(interpolate_rotation){
			vec3 path_direction = normalize(new_position - targets[0].GetTranslation());
			vec3 up_direction = normalize(mix(current_key.GetRotation(), next_key.GetRotation(), alpha) * vec3(0.0f, 1.0f, 0.0f));

			float rotation_y = atan2(-path_direction.x, -path_direction.z) + (extra_yaw / 180.0f * pi);
			float rotation_x = asin(-path_direction.y);

			vec3 previous_direction = normalize(current_key.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
			vec3 current_direction = normalize(next_key.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
			vec3 roll = mix(previous_direction, current_direction, alpha);
			float rotation_z = asin(roll.y);
			new_rotation = quaternion(vec4(0,1,0,rotation_y)) * quaternion(vec4(1,0,0,rotation_x)) * quaternion(vec4(0,0,1,rotation_z));
		}else{
			new_rotation = mix(current_key.GetRotation(), next_key.GetRotation(), alpha);
			float extra_y_rot = (extra_yaw / 180.0f * pi);
			new_rotation = new_rotation.opMul(quaternion(vec4(0,1,0,extra_y_rot)));
		}

		vec3 new_scale = mix(current_key.GetScale(), next_key.GetScale(), alpha);

		ApplyTransform(new_position, new_rotation, new_scale);
	}

	//Current time, start value, change in value, duration
	float sine_wave(float t, float b, float c, float d) {
		return -c/2 * (cos(pi*t/d) - 1) + b;
	}

	void DrawDebugMesh(Object@ object){
		mat4 mesh_transform;
		mesh_transform.SetTranslationPart(object.GetTranslation());
		mat4 rotation = Mat4FromQuaternion(object.GetRotation());
		mesh_transform.SetRotationPart(rotation);

		mat4 scale_mat;
		scale_mat[0] = object.GetScale().x;
		scale_mat[5] = object.GetScale().y;
		scale_mat[10] = object.GetScale().z;
		scale_mat[15] = 1.0f;
		mesh_transform = mesh_transform * scale_mat;

		vec4 color = object.IsSelected()?vec4(0.0f, 0.85f, 0.0f, 0.75f):vec4(0.0f, 0.35f, 0.0f, 0.75f);
		DebugDrawWireMesh("Data/Models/drika_hotspot_cube.obj", mesh_transform, color, _delete_on_update);
	}

	void DrawEditing(){
		CameraPlaceholderCheck();
		if(animation_method == timeline_method){
			if(animate_camera){
				DebugDrawLine(camera_placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
			DrawTimeline();
		}else{
			UpdateAnimationKeys();
			int num_keys = max(0, key_ids.size() - 1);
			for(int i = 0; i < num_keys; i++){
				if(ObjectExists(key_ids[i]) && ObjectExists(key_ids[i+1])){
					Object@ current_key = ReadObjectFromID(key_ids[i]);
					Object@ next_key = ReadObjectFromID(key_ids[i+1]);
					if(i == 0){
						DrawDebugMesh(current_key);
					}
					DrawDebugMesh(next_key);
					DebugDrawLine(current_key.GetTranslation(), next_key.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				}else if(!ObjectExists(key_ids[i])){
					key_ids.removeAt(i);
					WriteAnimationKeyParams();
					return;
				}else if(!ObjectExists(key_ids[i+1])){
					key_ids.removeAt(i+1);
					WriteAnimationKeyParams();
					return;
				}
			}
			if(animate_camera){
				DebugDrawLine(camera_placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);

				for(uint i = 0; i < key_ids.size(); i++){
					Object@ key = ReadObjectFromID(key_ids[i]);
					if(key.IsSelected()){
						camera_placeholder.SetTranslation(key.GetTranslation());
						camera_placeholder.SetRotation(key.GetRotation());
						if(animate_scale){
							camera_placeholder.SetScale(key.GetScale());
						}
					}
				}

			}
		}
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void Update(){
		if(animation_method == timeline_method){
			if(moving_animation_key){
				MoveAnimationKey();
			}else{
				array<Object@> targets = GetTargetObjects();
				//Don't move/insert/delete keys when the modifier keys are pressed or no targets are present.
				if(GetInputDown(0, "lctrl") || GetInputDown(0, "lalt") || targets.size() == 0){
					return;
				}else{
					if(GetInputPressed(0, "i")){
						//Make sure to delete any key that's currently at this position before adding a new one.
						DeleteAnimationKey();
						InsertAnimationKey();
					}else if(GetInputPressed(0, "x")){
						DeleteAnimationKey();
					}else if(GetInputPressed(0, "g")){
						for(uint i = 0; i < key_data.size(); i++){
							if(key_data[i].time == timeline_position){
								@target_key = key_data[i];
								target_key.moving = true;
								target_key.moving_time = target_key.time;
								moving_animation_key = true;
							}
						}
					}
				}
			}
		}
	}

	void MoveAnimationKey(){
		target_key.moving_time = min(timeline_duration, max(0.0, ImGui_GetMousePos().x - margin / 2.0) * timeline_duration / timeline_width);
		if(timeline_snap){
			float lowest = floor(target_key.moving_time * 10.0) / 10.0;
			float highest = ceil(target_key.moving_time * 10.0) / 10.0;
			if(abs(target_key.moving_time - lowest) < abs(highest - target_key.moving_time)){
				target_key.moving_time = lowest;
			}else{
				target_key.moving_time = highest;
			}
		}
		//Apply the movement to the keyframe.
		if(ImGui_IsMouseClicked(0)){
			//Remove any keyframe that is currently at this position.
			for(uint i = 0; i < key_data.size(); i++){
				if(key_data[i].time == target_key.moving_time){
					key_data.removeAt(i);
					i--;
				}
			}
			target_key.moving = false;
			target_key.time = target_key.moving_time;
			moving_animation_key = false;
		//Cancel the movement to the keyframe.
		}else if(ImGui_IsMouseClicked(1)){
			target_key.moving = false;
			moving_animation_key = false;
		}
	}

	void EditDone(){
		for(uint i = 0; i < key_ids.size(); i++){
			if(key_ids[i] != -1 && ObjectExists(key_ids[i])){
				Object@ current_key = ReadObjectFromID(key_ids[i]);
				current_key.SetSelected(false);
				current_key.SetSelectable(false);
			}
		}
	}

	void ApplySettings(){
		Reset();
	}

	void StartEdit(){
		for(uint i = 0; i < key_ids.size(); i++){
			if(key_ids[i] != -1 && ObjectExists(key_ids[i])){
				Object@ current_key = ReadObjectFromID(key_ids[i]);
				current_key.SetSelectable(true);
			}
		}
	}

	void CreateKey(){
		int new_key_id = CreateObject("Data/Objects/drika_hotspot_cube.xml", false);
		key_ids.insertLast(new_key_id);
		Object@ new_key = ReadObjectFromID(new_key_id);
		new_key.SetName("Animation Key");
		new_key.SetDeletable(true);
		new_key.SetCopyable(true);
		new_key.SetSelectable(true);
		new_key.SetTranslatable(true);
		new_key.SetScalable(true);
		new_key.SetRotatable(true);
		new_key.SetScale(vec3(1.0));
		new_key.SetTranslation(this_hotspot.GetTranslation() + vec3(0, key_ids.size(), 0));
	}

	void InsertAnimationKey(){
		AnimationKey new_key;
		Object@ target;
		if(animate_camera){
			@target = camera_placeholder;
		}else{
			array<Object@> targets = GetTargetObjects();
			@target = targets[0];
		}
		new_key.time = timeline_position;
		new_key.translation = target.GetTranslation();
		new_key.rotation = target.GetRotation();
		new_key.scale = target.GetScale();
		key_data.insertLast(@new_key);
	}

	void DeleteAnimationKey(){
		for(uint i = 0; i < key_data.size(); i++){
			if(key_data[i].time == timeline_position){
				key_data.removeAt(i);
				i--;
			}
		}
	}

	void LeftClick(){
		int selected_index = -1;
		for(uint i = 0; i < key_ids.size(); i++){
			Object@ next_key = ReadObjectFromID(key_ids[i]);
			if(next_key.IsSelected()){
				selected_index = i;
				break;
			}
		}
		if(selected_index != -1){
			selected_index += 1;
			if(selected_index >= int(key_ids.size())){
				selected_index = 0;
			}
			for(uint i = 0; i < key_ids.size(); i++){
				Object@ next_key = ReadObjectFromID(key_ids[i]);
				if(selected_index == int(i)){
					next_key.SetSelected(true);
				}else{
					next_key.SetSelected(false);
				}
			}
		}
	}

	void DrawTimeline(){
		timeline_width = GetScreenWidth() - margin;
		timeline_height = GetScreenHeight() - margin;
		if(duration > 0.0){
			timeline_duration = duration;
		}

		if(ImGui_Begin("Animation Timeline", ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove)){
			vec2 current_position = ImGui_GetWindowPos() + vec2(margin / 2.0);
			float line_separation = timeline_width / (timeline_duration * 10.0);
			//Add one more line for the 0 keyframe.
			int nr_lines = int(timeline_duration * 10.0) + 1;
			for(int i = 0; i < nr_lines; i++){
				ImDrawList_AddLine(current_position + ((i%10==0?vec2():vec2(0.0, 20.0))), current_position + vec2(0, timeline_height), ImGui_GetColorU32(vec4(1.0, 1.0, 1.0, 1.0)), 1.0f);

				string frame_label = formatFloat((i / 10.0), '0l', 2, 1);
				if(line_separation > 30.0 || i%10==0){
					ImDrawList_AddText(current_position - vec2(10.0, 10.0), ImGui_GetColorU32(i%10==0?vec4(1.0, 1.0, 1.0, 0.5):vec4(1.0, 1.0, 1.0, 0.25)), frame_label);
				}

				current_position += vec2(line_separation, 0.0);
			}
			if(ImGui_IsWindowHovered() && ImGui_IsMouseDown(0)){
				timeline_position = min(timeline_duration, max(0.0, ImGui_GetMousePos().x - margin / 2.0) * timeline_duration / timeline_width);
				if(timeline_snap){
					float lowest = floor(timeline_position * 10.0) / 10.0;
					float highest = ceil(timeline_position * 10.0) / 10.0;
					if(abs(timeline_position - lowest) < abs(highest - timeline_position)){
						timeline_position = lowest;
					}else{
						timeline_position = highest;
					}
				}
				animation_timer = timeline_position;
				SetCurrentTransform();
			}
		}
		//Draw the current position on the timeline.
		vec2 cursor_position = ImGui_GetWindowPos() + vec2(margin / 2.0, 0.0);
		//Convert the time in msec to a x position on the timeline.
		cursor_position += vec2(timeline_position * timeline_width / timeline_duration, 0.0);
		ImDrawList_AddLine(cursor_position, cursor_position + vec2(0, timeline_height), ImGui_GetColorU32(vec4(0.0, 1.0, 0.0, 1.0)), 4.0f);

		for(uint i = 0; i < key_data.size(); i++){
			vec2 key_position = ImGui_GetWindowPos() + vec2(margin / 2.0, 0.0);
			//Convert the time in msec to a x position on the timeline.
			float keyframe_time = key_data[i].moving?key_data[i].moving_time:key_data[i].time;
			key_position += vec2(keyframe_time * timeline_width / timeline_duration, 0.0);
			ImDrawList_AddLine(key_position + vec2(0.0, 20.0), key_position + vec2(0, timeline_height), ImGui_GetColorU32(vec4(1.0, 0.75, 0.0, 0.85)), 4.0f);
		}

		ImGui_SetWindowSize("Animation Timeline", vec2(GetScreenWidth(), GetScreenHeight() / 8.0));
		ImGui_SetWindowPos("Animation Timeline", vec2(0.0f, GetScreenHeight() - (GetScreenHeight() / 8.0)));
		ImGui_End();
	}

	void Reset(){
		if(animation_type == forward){
			animation_timer = 0.0;
		}else if(animation_type == backward){
			animation_timer = duration;
		}else if(animation_type == looping_forwards){
			animation_timer = 0.0;
		}else if(animation_type == looping_backwards){
			animation_timer = duration;
		}else if(animation_type == looping_forwards_and_backwards){
			animation_timer = 0.0;
		}

		previous_translation = vec3();
		timeline_position = 0.0;
		animation_started = false;
		loop_direction = 1.0;
		done = false;
		animation_finished = false;

		if(animate_camera){
			level.SendMessage("animating_camera false " + hotspot.GetID());
		}

		if(animation_method == placeholder_method){
			UpdateAnimationKeys();
			if(animation_type == looping_forwards || animation_type == looping_forwards_and_backwards || animation_type == forward){
				key_index = 0;
				@current_key = ReadObjectFromID(key_ids[key_index]);
				@next_key = ReadObjectFromID(key_ids[key_index + 1]);
			}else{
				key_index = key_ids.size() - 1;
				@current_key = ReadObjectFromID(key_ids[key_index]);
				@next_key = ReadObjectFromID(key_ids[key_index - 1]);
			}
		}
		SetCurrentTransform();
	}
}
