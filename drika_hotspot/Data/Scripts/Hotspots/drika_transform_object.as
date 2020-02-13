class DrikaTransformObject : DrikaElement{
	bool enabled;

	vec3 before_translation;
	quaternion before_rotation;
	vec3 before_scale;

	DrikaTransformObject(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		drika_element_type = drika_transform_object;
		default_placeholder_scale = vec3(1.0);
		placeholder_name = "Transform Object Helper";
		connection_types = {_movement_object, _env_object, _decal_object, _item_object, _hotspot_object};

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;

		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["placeholder_id"] = JSONValue(placeholder_id);
		target_select.SaveIdentifier(data);
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void GetBeforeParam(){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			before_translation = targets[i].GetTranslation();
			before_rotation = targets[i].GetRotation();
			before_scale = targets[i].GetScale();
		}
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
	}

	string GetDisplayString(){
		return "Transform Object " + target_select.GetTargetDisplayText();
	}

	void GetNewTransform(){
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

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();
	}

	void TargetChanged(){
		GetNewTransform();
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			if(!triggered){
				GetBeforeParam();
			}
			triggered = true;
			return ApplyTransform(false);
		}else{
			CreatePlaceholder();
			return false;
		}
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			array<Object@> targets = target_select.GetTargetObjects();
			for(uint i = 0; i < targets.size(); i++){
				DebugDrawLine(targets[i].GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DrawGizmo(placeholder);
		}else{
			CreatePlaceholder();
			GetNewTransform();
			StartEdit();
		}
	}

	bool ApplyTransform(bool reset){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(targets[i].GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(targets[i].GetID());

				vec3 facing = Mult(reset?before_rotation:placeholder.GetRotation(), vec3(0,0,1));
				float rot = atan2(facing.x, facing.z) * 180.0f / PI;
				float new_rotation = floor(rot + 0.5f);
				vec3 new_facing = Mult(quaternion(vec4(0, 1, 0, new_rotation * 3.1415f / 180.0f)), vec3(1, 0, 0));

				char.SetRotationFromFacing(new_facing);
				char.position = reset?before_translation:placeholder.GetTranslation();
				char.velocity = vec3(0.0, 0.0, 0.0);
			}else{
				targets[i].SetTranslation(reset?before_translation:placeholder.GetTranslation());
				targets[i].SetRotation(reset?before_rotation:placeholder.GetRotation());
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
