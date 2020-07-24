enum transform_modes	{
							transform_to_placeholder = 0,
							transform_to_target = 1,
							move_towards_target = 2
						}

class DrikaTransformObject : DrikaElement{
	vec3 before_translation;
	quaternion before_rotation;
	vec3 before_scale;
	DrikaTargetSelect target_location(this, "target_location");
	bool use_target_location;
	bool use_target_rotation;
	bool use_target_scale;
	vec3 translation_offset;
	transform_modes transform_mode;
	int current_transform_mode;
	float move_speed;
	float extra_yaw;

	array<string> transform_mode_names =	{
												"Transform To Placeholder",
												"Transform To Target",
												"Move To Target"
											};

	DrikaTransformObject(JSONValue params = JSONValue()){
		placeholder.Load(params);
		placeholder.name = "Transform Object Helper";
		placeholder.default_scale = vec3(1.0);

		translation_offset = GetJSONVec3(params, "translation_offset", vec3(0.0));
		drika_element_type = drika_transform_object;
		connection_types = {_movement_object, _env_object, _decal_object, _item_object, _hotspot_object};

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option | item_option;

		transform_mode = transform_modes(GetJSONInt(params, "transform_mode", transform_to_placeholder));
		current_transform_mode = transform_mode;
		use_target_location = GetJSONBool(params, "use_target_location", true);
		use_target_rotation = GetJSONBool(params, "use_target_rotation", false);
		use_target_scale = GetJSONBool(params, "use_target_scale", false);
		move_speed = GetJSONFloat(params, "move_speed", 1.0);
		extra_yaw = GetJSONFloat(params, "extra_yaw", 0.0);
		target_location.LoadIdentifier(params);
		target_location.target_option = id_option | name_option | character_option | reference_option | team_option | item_option;

		has_settings = true;
	}
	
	void PostInit(){
		if(transform_mode == transform_to_placeholder){
			placeholder.Retrieve();
		}
		target_select.PostInit();
		target_location.PostInit();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		target_select.SaveIdentifier(data);
		data["transform_mode"] = JSONValue(transform_mode);
		if(transform_mode == transform_to_target){
			target_location.SaveIdentifier(data);
			data["translation_offset"] = JSONValue(JSONarrayValue);
			data["translation_offset"].append(translation_offset.x);
			data["translation_offset"].append(translation_offset.y);
			data["translation_offset"].append(translation_offset.z);
			data["use_target_location"] = JSONValue(use_target_location);
			data["use_target_rotation"] = JSONValue(use_target_rotation);
			data["use_target_scale"] = JSONValue(use_target_scale);
		}else if(transform_mode == transform_to_placeholder){
			placeholder.Save(data);
		}else if(transform_mode == move_towards_target){
			target_location.SaveIdentifier(data);
			data["move_speed"] = JSONValue(move_speed);
			data["extra_yaw"] = JSONValue(extra_yaw);
		}
		return data;
	}

	void GetBeforeParam(){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			before_translation = GetTargetTranslation(targets[i]);
			before_rotation = GetTargetRotation(targets[i]);
			before_scale = targets[i].GetScale();
		}
	}

	void Delete(){
		if(transform_mode == transform_to_placeholder){
			placeholder.Remove();
		}
	}

	string GetDisplayString(){
		return transform_mode_names[current_transform_mode] + " " + target_select.GetTargetDisplayText();
	}

	void SetPlaceholderTransform(){
		if(transform_mode == transform_to_placeholder){
			array<Object@> targets = target_select.GetTargetObjects();
			for(uint i = 0; i < targets.size(); i++){
				placeholder.SetTranslation(targets[i].GetTranslation());
				placeholder.SetRotation(targets[i].GetRotation());
				vec3 bounds = targets[i].GetBoundingBox();
				if(bounds == vec3(0.0)){
					bounds = vec3(1.0);
				}
				placeholder.SetScale(bounds * targets[i].GetScale());
			}
		}
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
		target_location.CheckAvailableTargets();
	}

	void DrawSettings(){
		float option_name_width = 150.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Transform Target");
		ImGui_NextColumn();
		ImGui_NextColumn();
		target_select.DrawSelectTargetUI();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Transform Mode");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("###Transform Mode", current_transform_mode, transform_mode_names, transform_mode_names.size())){
			transform_mode = transform_modes(current_transform_mode);
			if(transform_mode != transform_to_placeholder){
				placeholder.Remove();
			}
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(transform_mode == transform_to_target){
			target_location.DrawSelectTargetUI();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Translation Offset");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_DragFloat3("###Translation Offset", translation_offset, 0.001f, -5.0f, 5.0f, "%.3f")){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Target Location");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Checkbox("###Use Target Location", use_target_location)){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Target Rotation");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Checkbox("###Use Target Rotation", use_target_rotation)){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Target Scale");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Checkbox("###Use Target Scale", use_target_scale)){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(transform_mode == move_towards_target){
			target_location.DrawSelectTargetUI();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Speed");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_DragFloat("###Speed", move_speed, 0.001f, 0.01f, 50.0f, "%.3f")){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Extra Yaw");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_DragFloat("###Extra Yaw", extra_yaw, 0.01f, 0.0f, 360.0f, "%.3f")){

			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}
	}

	void TargetChanged(){
		SetPlaceholderTransform();
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeParam();
		}
		triggered = true;
		return ApplyTransform(false);
	}

	void DrawEditing(){
		if(transform_mode == transform_to_placeholder){
			if(placeholder.Exists()){
				array<Object@> targets = target_select.GetTargetObjects();
				for(uint i = 0; i < targets.size(); i++){
					DebugDrawLine(targets[i].GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
				DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				DrawGizmo(placeholder.object);
			}else{
				placeholder.Create();
				SetPlaceholderTransform();
				StartEdit();
			}
		}else if(transform_mode == transform_to_target || transform_mode == move_towards_target){
			array<Object@> target_location_objects = target_location.GetTargetObjects();
			array<Object@> targets = target_select.GetTargetObjects();

			for(uint i = 0; i < targets.size(); i++){
				DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				for(uint j = 0; j < target_location_objects.size(); j++){
					DebugDrawLine(targets[i].GetTranslation(), GetTargetTranslation(target_location_objects[j]) + translation_offset, vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
			}

			for(uint j = 0; j < target_location_objects.size(); j++){
				vec3 gizmo_location = use_target_location?GetTargetTranslation(target_location_objects[j]):before_translation;
				quaternion gizmo_rotation = use_target_rotation?GetTargetRotation(target_location_objects[j]):before_rotation;
				vec3 gizmo_scale = use_target_scale?target_location_objects[j].GetScale():before_scale;
				DrawGizmo(gizmo_location + translation_offset, gizmo_rotation, gizmo_scale, true);
			}
		}
	}

	bool ApplyTransform(bool reset){
		array<Object@> targets = target_select.GetTargetObjects();

		for(uint i = 0; i < targets.size(); i++){
			if(transform_mode == transform_to_target){
				array<Object@> target_location_objects = target_location.GetTargetObjects();
				for(uint j = 0; j < target_location_objects.size(); j++){
					if(use_target_location){
						SetTargetTranslation(targets[i], reset?before_translation:GetTargetTranslation(target_location_objects[j]) + translation_offset);
					}
					if(use_target_rotation){
						SetTargetRotation(targets[i], reset?before_rotation:GetTargetRotation(target_location_objects[j]));
					}
					if(use_target_scale){
						vec3 scale = target_location_objects[j].GetScale();
						vec3 bounds = targets[i].GetBoundingBox();
						if(bounds == vec3(0.0)){
							bounds = vec3(1.0);
						}
						vec3 new_scale = vec3(scale.x / bounds.x, scale.y / bounds.y, scale.z / bounds.z);
						targets[i].SetScale(reset?before_scale:new_scale);
					}
				}
			}else if(transform_mode == transform_to_placeholder){
				if(!placeholder.Exists()){
					Log(warning, "Placeholder does not exist!");
					return false;
				}
				SetTargetTranslation(targets[i], reset?before_translation:placeholder.GetTranslation());
				SetTargetRotation(targets[i], reset?before_rotation:placeholder.GetRotation());
				vec3 scale = placeholder.GetScale();
				vec3 bounds = targets[i].GetBoundingBox();
				if(bounds == vec3(0.0)){
					bounds = vec3(1.0);
				}
				vec3 new_scale = vec3(scale.x / bounds.x, scale.y / bounds.y, scale.z / bounds.z);
				targets[i].SetScale(reset?before_scale:new_scale);
			}else if(transform_mode == move_towards_target){
				array<Object@> target_location_objects = target_location.GetTargetObjects();
				for(uint j = 0; j < target_location_objects.size(); j++){

					vec3 move_direction = normalize(GetTargetTranslation(target_location_objects[j]) - GetTargetTranslation(targets[i]));
					vec3 new_translation = GetTargetTranslation(targets[i]) + (move_direction * time_step * move_speed);

					float rotation_y = atan2(-move_direction.x, -move_direction.z) + (extra_yaw / 180.0f * PI);
					float rotation_x = asin(move_direction.y);
					float rotation_z = 0.0f;
					quaternion new_rotation = quaternion(vec4(0,1,0,rotation_y)) * quaternion(vec4(1,0,0,rotation_x)) * quaternion(vec4(0,0,1,rotation_z));

					SetTargetTranslation(targets[i], reset?before_translation:new_translation);
					SetTargetRotation(targets[i], reset?before_rotation:new_rotation);
				}
			}
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyTransform(true);
		}
	}
}
