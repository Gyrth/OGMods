class DrikaTransformObject : DrikaElement{
	vec3 before_translation;
	quaternion before_rotation;
	vec3 before_scale;
	DrikaTargetSelect target_location(this, "target_location");
	bool use_target_object;
	bool use_target_location;
	bool use_target_rotation;
	bool use_target_scale;
	vec3 translation_offset;

	DrikaTransformObject(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		translation_offset = GetJSONVec3(params, "translation_offset", vec3(0.0));
		drika_element_type = drika_transform_object;
		default_placeholder_scale = vec3(1.0);
		placeholder_name = "Transform Object Helper";
		connection_types = {_movement_object, _env_object, _decal_object, _item_object, _hotspot_object};

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option | item_option;

		use_target_object = GetJSONBool(params, "use_target_object", false);
		use_target_location = GetJSONBool(params, "use_target_location", true);
		use_target_rotation = GetJSONBool(params, "use_target_rotation", false);
		use_target_scale = GetJSONBool(params, "use_target_scale", false);
		target_location.LoadIdentifier(params);
		target_location.target_option = id_option | name_option | character_option | reference_option | team_option | item_option;

		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["placeholder_id"] = JSONValue(placeholder_id);
		target_select.SaveIdentifier(data);
		data["use_target_object"] = JSONValue(use_target_object);
		if(use_target_object){
			target_location.SaveIdentifier(data);
			data["translation_offset"] = JSONValue(JSONarrayValue);
			data["translation_offset"].append(translation_offset.x);
			data["translation_offset"].append(translation_offset.y);
			data["translation_offset"].append(translation_offset.z);
			data["use_target_location"] = JSONValue(use_target_location);
			data["use_target_rotation"] = JSONValue(use_target_rotation);
			data["use_target_scale"] = JSONValue(use_target_scale);
		}
		return data;
	}

	void PostInit(){
		if(!use_target_object){
			RetrievePlaceholder();
		}
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
		if(!use_target_object){
			RemovePlaceholder();
		}
	}

	string GetDisplayString(){
		return "Transform Object " + target_select.GetTargetDisplayText();
	}

	void SetPlaceholderTransform(){
		if(!use_target_object){
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
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		target_select.DrawSelectTargetUI();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Use Target Object");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Checkbox("###Use Target Object", use_target_object)){
			if(use_target_object){
				RemovePlaceholder();
			}
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(use_target_object){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Using Target");
			ImGui_NextColumn();

			target_location.DrawSelectTargetUI();
			ImGui_NextColumn();

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
		if(!use_target_object){
			if(ObjectExists(placeholder_id)){
				array<Object@> targets = target_select.GetTargetObjects();
				for(uint i = 0; i < targets.size(); i++){
					DebugDrawLine(targets[i].GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
				DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
				DrawGizmo(placeholder);
			}else{
				CreatePlaceholder();
				SetPlaceholderTransform();
				StartEdit();
			}
		}else{
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
			if(use_target_object){
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
			}else{
				if(placeholder_id == -1 || !ObjectExists(placeholder_id)){
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
