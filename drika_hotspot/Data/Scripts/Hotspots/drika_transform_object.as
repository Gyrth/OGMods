class DrikaTransformObject : DrikaElement{
	bool enabled;
	int current_idenifier_type;

	vec3 before_translation;
	quaternion before_rotation;
	vec3 before_scale;

	DrikaTransformObject(string _placeholder_id = "-1", string _identifier_type = "0", string _identifier = "-1"){
		drika_element_type = drika_transform_object;
		placeholder_id = atoi(_placeholder_id);
		default_placeholder_scale = vec3(1.0);
		placeholder_name = "Transform Object Helper";
		identifier_type = identifier_types(atoi(_identifier_type));
		current_idenifier_type = identifier_type;
		has_settings = true;

		if(identifier_type == id){
			object_id = atoi(_identifier);
		}else if(identifier_type == reference){
			reference_string = _identifier;
		}

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

	string GetSaveString(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		return "transform_object" + param_delimiter + placeholder_id + param_delimiter + int(identifier_type) + param_delimiter + save_identifier;
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

	void AddSettings(){
		if(ImGui_Combo("Identifier Type", current_idenifier_type, {"ID", "Reference"})){
			identifier_type = identifier_types(current_idenifier_type);
		}

		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", object_id)){
				GetNewTransform();
			}
		}else if (identifier_type == reference){
			if(ImGui_InputText("Reference", reference_string, 64)){
				GetNewTransform();
			}
		}
	}

	void StartEdit(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelectable(true);
		}
	}

	void EditDone(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelected(false);
			placeholder.SetSelectable(false);
		}
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeParam();
		}
		triggered = true;
		return ApplyTransform(false);
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
			Object@ object = ReadObjectFromID(object_id);
			DebugDrawLine(object.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			if(ObjectExists(placeholder_id)){
				DebugDrawLine(object.GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
		}
		if(ObjectExists(placeholder_id)){
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
		Log(info, "bounds " + bounds.x + " " + bounds.y + " " + bounds.z);
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
