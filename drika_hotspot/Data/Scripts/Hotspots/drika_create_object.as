class DrikaCreateObject : DrikaElement{
	string object_path;
	int spawned_object_id = -1;
	Object@ spawned_object;

	DrikaCreateObject(string _placeholder_id = "-1", string _object_path = default_preview_mesh, string _reference_string = ""){
		placeholder_id = atoi(_placeholder_id);
		placeholder_name = "Create Object Helper";
		object_path = _object_path;
		drika_element_type = drika_create_object;
		reference_string = _reference_string;
		default_placeholder_scale = vec3(1.0);
		has_settings = true;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	string GetReference(){
		return reference_string;
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
    }

	array<string> GetSaveParameters(){
		return {"create_object", placeholder_id, object_path, reference_string};
	}

	string GetDisplayString(){
		return "CreateObject " + object_path;
	}

	void DrawSettings(){
		ImGui_Text("Object Path : ");
		ImGui_SameLine();
		ImGui_Text(object_path);
		if(ImGui_Button("Set Object Path")){
			string new_path = GetUserPickedReadPath("xml", "Data/Objects");
			if(new_path != ""){
				object_path = new_path;
			}
		}
		DrawSetReferenceUI();
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DrawGizmo(placeholder);
		}else{
			CreatePlaceholder();
			StartEdit();
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

			//If the reference already exists then a new one is assigned by the hotspot.
			reference_string = RegisterObject(spawned_object_id, reference_string);

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
