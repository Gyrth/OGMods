class DrikaCreateObject : DrikaElement{
	string object_path;
	int spawned_object_id = -1;
	Object@ spawned_object;
	string reference;
	bool show_reference_option = show_reference_option;

	DrikaCreateObject(string _placeholder_id = "-1", string _object_path = default_preview_mesh, string _reference = ""){
		placeholder_id = atoi(_placeholder_id);
		object_path = _object_path;
		drika_element_type = drika_create_object;
		has_settings = true;
		reference = _reference;
		if(reference != ""){
			show_reference_option = true;
		}

		if(ObjectExists(placeholder_id)){
			@placeholder = ReadObjectFromID(placeholder_id);
		}else{
			CreatePlaceholder();
		}
		placeholder.SetSelectable(false);
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
    }

	string GetSaveString(){
		return "create_object" + param_delimiter + placeholder_id + param_delimiter + object_path + param_delimiter + reference;
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
				SetPreviewMesh();
			}
		}
		ImGui_Checkbox("Set Reference", show_reference_option);
		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip("If a reference is set it can be used by other functions\nlike Set Object Param or Transform Object.");
			ImGui_PopStyleColor();
		}
		if(show_reference_option){
			ImGui_InputText("Reference", reference, 64);
		}
	}

	void StartEdit(){
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

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void CreatePlaceholder(){
		placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
		@placeholder = ReadObjectFromID(placeholder_id);
		placeholder.SetSelectable(true);
		placeholder.SetTranslatable(true);
		placeholder.SetScalable(true);
		placeholder.SetRotatable(true);
		placeholder.SetScale(vec3(0.25));
		placeholder.SetTranslation(this_hotspot.GetTranslation());
		SetPreviewMesh();
	}

	void SetPreviewMesh(){
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

	void Reset(){
		if(spawned_object_id != -1){
			DeRegisterObject(reference);
			QueueDeleteObjectID(spawned_object_id);
			spawned_object_id = -1;
		}
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			spawned_object_id = CreateObject(object_path);

			//If the reference already exists then a new one is assigned by the hotspot.
			reference = RegisterObject(spawned_object_id, reference);

			@spawned_object = ReadObjectFromID(spawned_object_id);
			spawned_object.SetSelectable(true);
			spawned_object.SetTranslatable(true);
			spawned_object.SetScalable(true);
			spawned_object.SetRotatable(true);
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
