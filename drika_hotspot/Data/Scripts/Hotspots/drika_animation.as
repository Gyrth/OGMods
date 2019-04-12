enum animation_types {
						looping_forwards = 0,
						looping_backwards = 1,
						looping_forwards_and_backwards = 2,
						forward = 3,
						backward = 4
					}

enum animation_methods {
						constant_speed = 0,
						divide_between_keys = 1
					}

class DrikaAnimation : DrikaElement{
	array<int> key_ids;
	animation_types animation_type;
	int current_animation_type;
	animation_methods animation_method;
	bool interpolate_rotation;
	bool interpolate_translation;
	bool animate_camera;
	bool animate_scale;
	float duration;
	float forward_rotation;

	int key_index = 0;
	Object@ current_key;
	Object@ next_key;
	float pi = 3.14159265f;
	float animation_timer = 0.0;
	int loop_direction = 1;
	bool animation_finished = false;

	array<string> animation_type_names = {	"Looping Forwards",
											"Looping Backwards",
											"Looping Forwards and Backwards",
											"Forward",
											"Backward"
										};

	DrikaAnimation(JSONValue params = JSONValue()){
		drika_element_type = drika_animation;
		connection_types = {_movement_object, _env_object, _decal_object, _item_object, _hotspot_object};
		key_ids = GetJSONIntArray(params, "key_ids", {});
		animation_type = animation_types(GetJSONInt(params, "animation_type", 3));
		current_animation_type = animation_type;
		animation_method = animation_methods(GetJSONInt(params, "animation_method", 0));
		interpolate_rotation = GetJSONBool(params, "interpolate_rotation", false);
		interpolate_translation = GetJSONBool(params, "interpolate_translation", false);
		animate_camera = GetJSONBool(params, "animate_camera", false);
		animate_scale = GetJSONBool(params, "animate_scale", false);
		duration = GetJSONFloat(params, "duration", 5.0);
		forward_rotation = GetJSONFloat(params, "forward_rotation", 0.0);

		LoadIdentifier(params);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("animation");
		data["animation_type"] = JSONValue(animation_type);
		data["animation_method"] = JSONValue(animation_method);
		data["interpolate_rotation"] = JSONValue(interpolate_rotation);
		data["interpolate_translation"] = JSONValue(interpolate_translation);
		data["animate_camera"] = JSONValue(animate_camera);
		data["animate_scale"] = JSONValue(animate_scale);
		data["duration"] = JSONValue(duration);
		data["forward_rotation"] = JSONValue(forward_rotation);
		data["key_ids"] = JSONValue(JSONarrayValue);
		for(uint i = 0; i < key_ids.size(); i++){
			data["key_ids"].append(key_ids[i]);
		}
		SaveIdentifier(data);
		return data;
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
		return "Animation " + GetTargetDisplayText();
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Animation Type", current_animation_type, animation_type_names, animation_type_names.size())){
			animation_type = animation_types(current_animation_type);
		}
		ImGui_SliderFloat("Duration", duration, 0.0f, 10.0f, "%.2f");
		ImGui_Checkbox("Interpolation Rotation", interpolate_rotation);
		ImGui_Checkbox("Interpolation Translation", interpolate_translation);
		ImGui_Checkbox("Animate Camera", animate_camera);
		ImGui_Checkbox("Animate Scale", animate_scale);
	}

	void TargetChanged(){

	}

	void ConnectedChanged(){

	}

	bool Trigger(){
		array<Object@> targets = GetTargetObjects();
		// Don't do anything if the target object does not exist.
		if(targets.size() == 0){
			return false;
		}
		UpdateAnimationKeys();
		UpdateAnimation();
		if(animation_finished){
			animation_finished = false;
			return true;
		}else{
			return false;
		}
	}

	void UpdateAnimationKeys(){
		//Make sure there is always at least two animation key available.
		while(key_ids.size() < 2){
			CreateKey();
		}
	}

	void UpdateAnimation(){
		float alpha = 0.0;
		animation_timer += time_step;
		if(animation_method == constant_speed){
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
		}else if(animation_method == divide_between_keys){
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
			Log(error, "Unknown animation method! " + animation_method);
		}

		ApplyTransform(alpha);
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

	void ApplyTransform(float alpha){
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

			float rotation_y = atan2(-path_direction.x, -path_direction.z) + (forward_rotation / 180.0f * pi);
			float rotation_x = asin(-path_direction.y);

			vec3 previous_direction = normalize(current_key.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
			vec3 current_direction = normalize(next_key.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
			vec3 roll = mix(previous_direction, current_direction, alpha);
			float rotation_z = asin(roll.y);
			new_rotation = quaternion(vec4(0,1,0,rotation_y)) * quaternion(vec4(1,0,0,rotation_x)) * quaternion(vec4(0,0,1,rotation_z));
		}else{
			new_rotation = mix(current_key.GetRotation(), next_key.GetRotation(), alpha);
			float extra_y_rot = (forward_rotation / 180.0f * pi);
			new_rotation = new_rotation.opMul(quaternion(vec4(0,1,0,extra_y_rot)));
		}

		if(animate_scale){
			vec3 scale = mix(current_key.GetScale(), next_key.GetScale(), alpha);
			for(uint i = 0; i < targets.size(); i++){
				targets[i].SetScale(scale);
			}
		}

		for(uint i = 0; i < targets.size(); i++){
			targets[i].SetRotation(new_rotation);
			targets[i].SetTranslation(new_position);
		}
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
		float scale = (object.GetScale().x + object.GetScale().y + object.GetScale().z ) / 3.0f;
		scale_mat[0] = scale;
		scale_mat[5] = scale;
		scale_mat[10] = scale;
		scale_mat[15] = 1.0f;
		mesh_transform = mesh_transform * scale_mat;

		vec4 color = object.IsSelected()?vec4(0.0f, 0.85f, 0.0f, 0.75f):vec4(0.0f, 0.35f, 0.0f, 0.75f);
		DebugDrawWireMesh("Data/Models/drika_hotspot_cube.obj", mesh_transform, color, _delete_on_update);
	}

	void DrawEditing(){
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
			}else{
				key_ids.removeAt(i);
				return;
			}
		}

		UpdateAnimationKeys();

		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void CreateKey(){
		int new_key_id = CreateObject("Data/Objects/drika_hotspot_cube.xml", false);
		key_ids.insertLast(new_key_id);
		Object@ new_key = ReadObjectFromID(new_key_id);
		new_key.SetName("Animation Key");
		new_key.SetSelectable(true);
		new_key.SetTranslatable(true);
		new_key.SetScalable(true);
		new_key.SetRotatable(true);
		new_key.SetScale(vec3(1.0));
		new_key.SetTranslation(this_hotspot.GetTranslation() + vec3(0, key_ids.size(), 0));
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

	void Reset(){
		if(key_ids.size() < 2){
			return;
		}
		if(animation_type == looping_forwards || animation_type == looping_forwards_and_backwards || animation_type == forward){
			key_index = 0;
			@current_key = ReadObjectFromID(key_ids[key_index]);
			@next_key = ReadObjectFromID(key_ids[key_index + 1]);
		}else{
			key_index = key_ids.size() - 1;
			@current_key = ReadObjectFromID(key_ids[key_index]);
			@next_key = ReadObjectFromID(key_ids[key_index - 1]);
		}
		loop_direction = 1.0;
	}
}
