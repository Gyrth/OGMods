class DrikaTransformObject : DrikaElement{
	bool enabled;
	int current_idenifier_type;

	vec3 before_translation;
	quaternion before_rotation;
	vec3 before_scale;

	DrikaTransformObject(string _placeholder_id = "-1", string _identifier_type = "0", string _identifier = "-1"){
		drika_element_type = drika_transform_object;
		placeholder_id = atoi(_placeholder_id);
		identifier_type = identifier_types(atoi(_identifier_type));
		current_idenifier_type = identifier_type;

		if(identifier_type == id){
			object_id = atoi(_identifier);
		}else if(identifier_type == reference){
			reference_string = _identifier;
		}

		if(ObjectExists(placeholder_id)){
			@placeholder = ReadObjectFromID(placeholder_id);
		}else{
			CreatePlaceholder();
		}
		placeholder.SetSelectable(false);

		has_settings = true;
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
		placeholder.SetScale(target_object.GetBoundingBox() * target_object.GetScale());
	}

	void AddSettings(){
		if(ImGui_Combo("Identifier Type", current_idenifier_type, {"ID", "Reference"})){
			identifier_type = identifier_types(current_idenifier_type);
		}

		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", object_id)){
				Log(info, "getting trnaform");
				GetNewTransform();
			}
		}else if (identifier_type == reference){
			if(ImGui_InputText("Reference", reference_string, 64)){
				GetNewTransform();
			}
		}
	}

	void Editing(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelectable(true);
		}else{
			CreatePlaceholder();
		}
	}

	void EditDone(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelected(false);
			placeholder.SetSelectable(false);
		}
	}

	void CreatePlaceholder(){
		placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
		@placeholder = ReadObjectFromID(placeholder_id);
		placeholder.SetSelectable(true);
		placeholder.SetTranslatable(true);
		placeholder.SetScalable(true);
		placeholder.SetRotatable(true);
		placeholder.SetScale(vec3(1.0));
		placeholder.SetTranslation(this_hotspot.GetTranslation());
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
			DebugDrawLine(object.GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
		mat4 gizmo_transform_y;
		gizmo_transform_y.SetTranslationPart(placeholder.GetTranslation());
		gizmo_transform_y.SetRotationPart(Mat4FromQuaternion(placeholder.GetRotation()));
		mat4 gizmo_transform_x = gizmo_transform_y;
		mat4 gizmo_transform_z = gizmo_transform_y;

		mat4 scale_mat_y;
		scale_mat_y[0] = 1.0;
		scale_mat_y[5] = placeholder.GetScale().y;
		scale_mat_y[10] = 1.0;
		scale_mat_y[15] = 1.0f;
		gizmo_transform_y = gizmo_transform_y * scale_mat_y;

		mat4 scale_mat_x;
		scale_mat_x[0] = placeholder.GetScale().x;
		scale_mat_x[5] = 1.0;
		scale_mat_x[10] = 1.0;
		scale_mat_x[15] = 1.0f;
		gizmo_transform_x = gizmo_transform_x * scale_mat_x;

		mat4 scale_mat_z;
		scale_mat_z[0] = 1.0;
		scale_mat_z[5] = 1.0;
		scale_mat_z[10] = placeholder.GetScale().z;
		scale_mat_z[15] = 1.0f;
		gizmo_transform_z = gizmo_transform_z * scale_mat_z;

		DebugDrawWireMesh("Data/Models/drika_gizmo_y.obj", gizmo_transform_y, vec4(0.0f, 0.0f, 0.5f, 0.15f), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_x.obj", gizmo_transform_x, vec4(0.5f, 0.0f, 0.0f, 0.15f), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_z.obj", gizmo_transform_z, vec4(0.0f, 0.5, 0.0f, 0.15f), _delete_on_update);
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
