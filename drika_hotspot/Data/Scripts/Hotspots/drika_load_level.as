class DrikaLoadLevel : DrikaElement{
	string level_path;

	DrikaLoadLevel(JSONValue params = JSONValue()){
		level_path = GetJSONString(params, "level_path", "Data/Levels/nothing.xml");
		drika_element_type = drika_load_level;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("load_level");
		data["level_path"] = JSONValue(level_path);
		return data;
	}

	string GetDisplayString(){
		return "LoadLevel " + level_path;
	}

	void DrawSettings(){
		ImGui_Text("Level Path : " + level_path);
		ImGui_SameLine();
		if(ImGui_Button("Set Level Path")){
			string new_path = GetUserPickedReadPath("xml", "Data/Levels");
			if(new_path != ""){
				level_path = new_path;
			}
		}
	}

	bool Trigger(){
		LoadLevel(level_path);
		return true;
	}
}
