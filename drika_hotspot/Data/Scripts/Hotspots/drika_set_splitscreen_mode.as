class DrikaSetSplitScreenMode : DrikaElement{
	array<string> mode_choices = {"None", "Full", "Split"};
	int mode;

	DrikaSetSplitScreenMode(JSONValue params = JSONValue()){
		mode = GetJSONInt(params, "mode", kModeNone);

		drika_element_type = drika_set_splitscreen_mode;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_splitscreen_mode");
		data["mode"] = JSONValue(mode);
		return data;
	}

	string GetDisplayString(){
		return "SetSplitScreenMode " + mode_choices[mode];
	}

	void DrawSettings(){
		if(ImGui_Combo("SplitScreen Mode", mode, mode_choices, mode_choices.size())){

		}
	}

	bool Trigger(){
		if(mode == kModeNone){
			SetSplitScreenMode(kModeNone);
		}else if(mode == kModeFull){
			SetSplitScreenMode(kModeFull);
		}else if(mode == kModeSplit){
			SetSplitScreenMode(kModeSplit);
		}
		return true;
	}

	void Reset(){
		SetSplitScreenMode(kModeNone);
	}
}
