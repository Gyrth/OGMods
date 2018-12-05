class DrikaSetEnabled : DrikaElement{
	bool enabled;
	int object_id;
	Object@ object;

	DrikaSetEnabled(int _object_id = -1, bool _enabled = true){
		object_id = _object_id;
		enabled = _enabled;
		drika_element_type = drika_set_enabled;
		has_settings = true;
		if(ObjectExists(object_id)){
			@object = ReadObjectFromID(object_id);
			if(enabled == true){
				object.SetCollisionEnabled(false);
			}
		}
		Reset();
	}
	string GetSaveString(){
		return "set_enabled" + param_delimiter + object_id + param_delimiter + enabled;
	}

	string GetDisplayString(){
		return "SetEnabled " + object_id + " " + enabled;
	}

	void AddSettings(){
		ImGui_InputInt("Object ID", object_id);
		ImGui_Text("Set To : ");
		ImGui_SameLine();
		ImGui_Checkbox("", enabled);
	}

	bool Trigger(){
		if(!ObjectExists(object_id)){
			Log(warning, "Object does not exist with id " + object_id);
			return false;
		}else{
			object.SetEnabled(enabled);
			return true;
		}
	}

	void DrawEditing(){
		if(object_id != -1 && ObjectExists(object_id)){
			DebugDrawLine(object.GetTranslation(), this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
		}
	}

	void Reset(){
		if(ObjectExists(object_id)){
			object.SetEnabled(!enabled);
		}
	}
}
