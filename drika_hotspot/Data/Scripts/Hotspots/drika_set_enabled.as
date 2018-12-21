class DrikaSetEnabled : DrikaElement{
	bool enabled;
	bool before_enabled;

	DrikaSetEnabled(string _identifier_type = "0", string _identifier = "-1", string _enabled = "true"){
		enabled = (_enabled == "true");
		drika_element_type = drika_set_enabled;
		connection_types = {_env_object};
		InterpIdentifier(_identifier_type, _identifier);
		has_settings = true;
	}

	void Delete(){
		Reset();
	}

	array<string> GetSaveParameters(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		return {"set_enabled", identifier_type, save_identifier, enabled};
	}

	string GetDisplayString(){
		string display_string;
		if(identifier_type == id){
			display_string = "" + object_id;
		}else if(identifier_type == reference){
			display_string = "" + reference_string;
		}
		return "SetEnabled " + display_string + " " + enabled;
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_Text("Set To : ");
		ImGui_SameLine();
		ImGui_Checkbox("", enabled);
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeParam();
		}
		triggered = true;
		return ApplyEnabled(false);
	}

	void GetBeforeParam(){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		before_enabled = target_object.GetEnabled();
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
			Object@ object = ReadObjectFromID(object_id);
			DebugDrawLine(object.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool ApplyEnabled(bool reset){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return false;
		}
		target_object.SetEnabled(reset?before_enabled:enabled);
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyEnabled(true);
		}
	}
}
