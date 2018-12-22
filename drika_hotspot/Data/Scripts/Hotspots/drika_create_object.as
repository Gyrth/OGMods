class DrikaCreateObject : DrikaElement{
	string object_path;
	array<int> spawned_object_ids;

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

	array<string> GetSaveParameters(){
		return {"create_object", placeholder_id, object_path, reference_string};
	}

	string GetDisplayString(){
		return "CreateObject " + object_path + " " + reference_string;
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
		if(triggered){
			for(uint i = 0; i < spawned_object_ids.size(); i++){
				QueueDeleteObjectID(spawned_object_ids[i]);
			}
			spawned_object_ids.resize(0);
			triggered = false;
		}
	}

	bool Trigger(){
		triggered = true;
		if(ObjectExists(placeholder_id)){
			int spawned_object_id = CreateObject(object_path);
			spawned_object_ids.insertLast(spawned_object_id);

			RegisterObject(spawned_object_id, reference_string);

			Object@ spawned_object = ReadObjectFromID(spawned_object_id);
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
