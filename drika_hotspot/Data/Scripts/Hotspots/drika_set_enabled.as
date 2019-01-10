class DrikaSetEnabled : DrikaElement{
	bool enabled;
	array<BeforeValue> before_values;

	DrikaSetEnabled(JSONValue params = JSONValue()){
		enabled = GetJSONBool(params, "enabled", true);
		LoadIdentifier(params);
		show_team_option = true;
		show_name_option = true;

		drika_element_type = drika_set_enabled;
		connection_types = {_env_object, _hotspot_object};
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_enabled");
		data["enabled"] = JSONValue(enabled);
		SaveIdentifier(data);
		return data;
	}

	void Delete(){
		Reset();
	}

	string GetDisplayString(){
		return "SetEnabled " + GetTargetDisplayText() + " " + enabled;
	}

	void StartSettings(){
		CheckReferenceAvailable();
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
		array<Object@> targets = GetTargetObjects();
		before_values.resize(0);
		for(uint i = 0; i < targets.size(); i++){
			before_values.insertLast(BeforeValue());
			before_values[i].bool_value = targets[i].GetEnabled();
		}
	}

	void DrawEditing(){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool ApplyEnabled(bool reset){
		array<Object@> targets = GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			targets[i].SetEnabled(reset?before_values[i].bool_value:enabled);
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			ApplyEnabled(true);
		}
	}
}
