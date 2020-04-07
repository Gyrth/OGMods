class DrikaSetEnabled : DrikaElement{
	bool enabled;
	array<BeforeValue> before_values;

	DrikaSetEnabled(JSONValue params = JSONValue()){
		enabled = GetJSONBool(params, "enabled", true);

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option | batch_option;

		drika_element_type = drika_set_enabled;
		connection_types = {_env_object, _hotspot_object};
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["enabled"] = JSONValue(enabled);
		target_select.SaveIdentifier(data);
		return data;
	}

	void Delete(){
		Reset();
	}

	string GetDisplayString(){
		return "SetEnabled " + target_select.GetTargetDisplayText() + " " + enabled;
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){
		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Target");
		ImGui_NextColumn();
		ImGui_NextColumn();

		target_select.DrawSelectTargetUI();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Set Enabled To");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_Checkbox("###Set To", enabled);
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeParam();
		}
		triggered = true;
		return ApplyEnabled(false);
	}

	void GetBeforeParam(){
		array<Object@> targets = target_select.GetTargetObjects();
		before_values.resize(0);
		for(uint i = 0; i < targets.size(); i++){
			before_values.insertLast(BeforeValue());
			before_values[i].bool_value = targets[i].GetEnabled();
		}
	}

	void DrawEditing(){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool ApplyEnabled(bool reset){
		array<Object@> targets = target_select.GetTargetObjects();
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
