class DrikaTransformObject : DrikaElement{
	bool enabled;
	int object_id;
	string reference_string;
	int current_idenifier_type;
	identifier_types identifier_type;
	bool triggered = false;

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
		Object@ target_object;
		if(identifier_type == id){
			if(object_id == -1 || !ObjectExists(object_id)){
				Log(warning, "Object does not exist with id " + object_id);
				return;
			}else{
				@target_object = ReadObjectFromID(object_id);
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				Log(warning, "Object does not exist with reference " + reference_string);
				return;
			}
			@target_object = ReadObjectFromID(registered_object_id);
		}
		Log(info, "getting before values! ");
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

	void AddSettings(){
		if(ImGui_Combo("Identifier Type", current_idenifier_type, {"ID", "Reference"})){
			identifier_type = identifier_types(current_idenifier_type);
			SetPreviewMesh();
		}

		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", object_id)){
				SetPreviewMesh();
			}
		}else if (identifier_type == reference){
			if(ImGui_InputText("Reference", reference_string, 64)){
				SetPreviewMesh();
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
		SetPreviewMesh();
	}

	void SetPreviewMesh(){
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder);
		int target_id;
		if(identifier_type == id){
			if(object_id == -1 || !ObjectExists(object_id)){
				Log(warning, "Object does not exist with id " + object_id);
				return;
			}else{
				target_id = object_id;
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				Log(warning, "Object does not exist with reference " + reference_string);
				return;
			}
			target_id = registered_object_id;
		}
		if(IsGroupDerived(target_id)){
			placeholder_object.SetPreview(default_preview_mesh);
		}else{
			//Need a way to get Object xml path to make this work.
			/* placeholder_object.SetPreview(target_id); */
			placeholder_object.SetPreview(default_preview_mesh);
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
			DebugDrawLine(object.GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool ApplyTransform(bool reset){
		Log(info, "ApplyTransform! " + reset + "  " + triggered);
		Object@ target_object;
		if(identifier_type == id){
			if(object_id == -1 || !ObjectExists(object_id)){
				Log(warning, "Object does not exist with id " + object_id);
				return false;
			}else{
				@target_object = ReadObjectFromID(object_id);
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				Log(warning, "Object does not exist with reference " + reference_string);
				return false;
			}
			@target_object = ReadObjectFromID(registered_object_id);
		}
		target_object.SetTranslation(reset?before_translation:placeholder.GetTranslation());
		target_object.SetRotation(reset?before_rotation:placeholder.GetRotation());
		target_object.SetScale(reset?before_scale:placeholder.GetScale());
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyTransform(true);
		}
	}
}
