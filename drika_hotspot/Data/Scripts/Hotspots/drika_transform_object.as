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

		InterpIdentifier(params);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("transform_object");
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void GetBeforeParam(){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		before_translation = target_object.GetTranslation();
		before_rotation = target_object.GetRotation();
		before_scale = target_object.GetScale();
	}

	void Delete(){
		Reset();
		QueueDeleteObjectID(placeholder_id);
	}

	string GetDisplayString(){
		string display_string;
		if(identifier_type == id){
			display_string = "" + object_id;
		}else if(identifier_type == reference){
			display_string = "" + reference_string;
		}
		return "Transform Object " + display_string;
	}

	void GetNewTransform(){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		placeholder.SetTranslation(target_object.GetTranslation());
		placeholder.SetRotation(target_object.GetRotation());
		vec3 bounds = target_object.GetBoundingBox();
		if(bounds == vec3(0.0)){
			bounds = vec3(1.0);
		}
		placeholder.SetScale(bounds * target_object.GetScale());
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
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id) && ObjectExists(placeholder_id)){
			Object@ object = ReadObjectFromID(object_id);
			DebugDrawLine(object.GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DrawGizmo(placeholder);
		}else{
			CreatePlaceholder();
			GetNewTransform();
			StartEdit();
		}
	}

	bool ApplyTransform(bool reset){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return false;
		}
		target_object.SetTranslation(reset?before_translation:placeholder.GetTranslation());
		target_object.SetRotation(reset?before_rotation:placeholder.GetRotation());
		vec3 scale = placeholder.GetScale();
		vec3 bounds = target_object.GetBoundingBox();
		if(bounds == vec3(0.0)){
			bounds = vec3(1.0);
		}
		vec3 new_scale = vec3(scale.x / bounds.x, scale.y / bounds.y, scale.z / bounds.z);
		target_object.SetScale(reset?before_scale:new_scale);
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyTransform(true);
		}
	}
}
