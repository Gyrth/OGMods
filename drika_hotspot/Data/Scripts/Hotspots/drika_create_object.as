class DrikaCreateObject : DrikaElement{
	string object_path;
	array<int> spawned_object_ids;

	DrikaCreateObject(JSONValue params = JSONValue()){
		placeholder.Load(params);
		placeholder.name = "Create Object Helper";
		placeholder.default_scale = vec3(1.0);

		object_path = GetJSONString(params, "object_path", default_preview_mesh);
		drika_element_type = drika_create_object;
		reference_string = GetJSONString(params, "reference_string", "");
		has_settings = true;
		placeholder.object_path = object_path;
		@placeholder.parent = this;
	}

	void Delete(){
		Reset();
		placeholder.Remove();
	}

	void PostInit(){
		placeholder.Retrieve();
	}

	JSONValue GetCheckpointData(){
		JSONValue data;
		data["triggered"] = triggered;
		if(triggered){
			data["target_ids"] = JSONValue(JSONarrayValue);
			for(uint i = 0; i < spawned_object_ids.size(); i++){
				data["target_ids"].append(spawned_object_ids[i]);
			}
		}
		return data;
	}

	void SetCheckpointData(JSONValue data = JSONValue()){
		bool checkpoint_triggered = data["triggered"].asBool();

		//The hotspot got reset and the target doesn't exist anymore.
		if(checkpoint_triggered && !triggered){
			spawned_object_ids.resize(0);
			Trigger();
		//The hotspot has not been reset but triggered.
		}else if(checkpoint_triggered){
			JSONValue target_ids = data["target_ids"];
			bool missing_object = false;

			spawned_object_ids.resize(0);
			for(uint i = 0; i < target_ids.size(); i++){
				if(!ObjectExists(target_ids[i].asInt())){
					missing_object = true;
					break;
				}else{
					Log(warning, "Not missing " + object_path + " " + target_ids[i].asInt());
				}
				spawned_object_ids.insertLast(target_ids[i].asInt());
			}

			if(missing_object){
				Log(warning, "Missing " + object_path);
				spawned_object_ids.resize(0);
				Trigger();
			}
		}
	}

	string GetReference(){
		return reference_string;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		placeholder.Save(data);
		data["object_path"] = JSONValue(object_path);
		data["reference_string"] = JSONValue(reference_string);
		return data;
	}

	string GetDisplayString(){
		return "CreateObject " + object_path + " " + reference_string;
	}

	void DrawSettings(){

		float option_name_width = 100.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Object Path");
		ImGui_NextColumn();

		if(ImGui_Button("Set Object Path")){
			string new_path = GetUserPickedReadPath("xml", "Data/Objects");
			if(new_path != ""){
				object_path = new_path;
				placeholder.object_path = object_path;
				placeholder.UpdatePlaceholderPreview();
			}
		}
		ImGui_SameLine();
		ImGui_Text(object_path);
		ImGui_NextColumn();
		DrawSetReferenceUI();
	}

	void DrawEditing(){
		if(placeholder.Exists()){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DrawGizmo(placeholder.GetTranslation(), placeholder.GetRotation(), placeholder.GetScale(), placeholder.IsSelected());
			placeholder.DrawEditing();
		}else{
			placeholder.Create();
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
		if(placeholder.Exists()){
			Log(warning, "Create " + object_path);
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
			placeholder.Create();
			return false;
		}
	}

	void ReceiveMessage(string message, string identifier){
		placeholder.ReceiveMessage(message, identifier);
	}

	void ReceiveMessage(string message){
		placeholder.ReceiveMessage(message);
	}
}
