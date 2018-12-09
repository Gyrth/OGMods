string default_preview_mesh = "Data/Objects/primitives/edged_cone.xml";
class DrikaCreateObject : DrikaElement{
	string object_path;
	int spawned_object_id = -1;
	Object@ spawned_object;

	DrikaCreateObject(string _placeholder_id = "-1", string _object_path = default_preview_mesh){
		placeholder_id = atoi(_placeholder_id);
		object_path = _object_path;
		drika_element_type = drika_create_object;
		has_settings = true;

		if(ObjectExists(placeholder_id)){
			@placeholder = ReadObjectFromID(placeholder_id);
		}else{
			CreatePlaceholder();
		}
		placeholder.SetSelectable(false);
	}

	~DrikaCreateObject()
    {
		Log(warning, "Destructor DrikaCreateObject");
		QueueDeleteObjectID(placeholder_id);
    }

	string GetSaveString(){
		return "create_object" + param_delimiter + placeholder_id + param_delimiter + object_path;
	}

	string GetDisplayString(){
		return "CreateObject " + object_path;
	}

	void AddSettings(){
		ImGui_Text("Object Path : ");
		ImGui_SameLine();
		ImGui_Text(object_path);
		if(ImGui_Button("Set Object Path")){
			string new_path = GetUserPickedReadPath("xml", "Data/Objects");
			if(new_path != ""){
				object_path = new_path;
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

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void CreatePlaceholder(){
		placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
		@placeholder = ReadObjectFromID(placeholder_id);
		placeholder.SetEditorLabel("Drika Create Object Helper");
		placeholder.SetSelectable(true);
		placeholder.SetTranslatable(true);
		placeholder.SetScalable(true);
		placeholder.SetRotatable(true);
		placeholder.SetScale(vec3(0.25));
		placeholder.SetTranslation(this_hotspot.GetTranslation());
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder);
		int new_object_id = CreateObject(object_path);
		Object@ main_object = ReadObjectFromID(new_object_id);
		if(IsGroupDerived(new_object_id)){
			placeholder_object.SetPreview(default_preview_mesh);
		}else{
			placeholder_object.SetPreview(object_path);
		}
		QueueDeleteObjectID(new_object_id);
	}

	void EditDone(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelected(false);
			placeholder.SetSelectable(false);
		}
	}

	void Reset(){
		if(spawned_object_id != -1){
			QueueDeleteObjectID(spawned_object_id);
			spawned_object_id = -1;
		}
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			spawned_object_id = CreateObject(object_path);
			@spawned_object = ReadObjectFromID(spawned_object_id);
			spawned_object.SetTranslation(placeholder.GetTranslation());
			spawned_object.SetRotation(placeholder.GetRotation());
			spawned_object.SetScale(placeholder.GetScale());
			return true;
		}else{
			CreatePlaceholder();
			return false;
		}
	}
}
