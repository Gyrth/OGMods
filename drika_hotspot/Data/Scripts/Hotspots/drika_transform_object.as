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

		LoadIdentifier(params);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("transform_object");
		data["placeholder_id"] = JSONValue(placeholder_id);
		SaveIdentifier(data);
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void GetBeforeParam(){
		array<Object@> targets = GetTargetObjects();
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
		return "Transform Object " + GetTargetDisplayText();
	}

	void GetNewTransform(){
		array<Object@> targets = GetTargetObjects();
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
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
	}

	void TargetChanged(){
		GetNewTransform();
	}

	void ConnectedChanged(){
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
			array<Object@> targets = GetTargetObjects();
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
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
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
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyTransform(true);
		}
	}
}
