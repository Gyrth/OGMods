class DrikaLoadLevel : DrikaElement{
	string level_path;

	DrikaLoadLevel(string _level_path = "Data/Levels/nothing.xml"){
		level_path = _level_path;
		drika_element_type = drika_load_level;
		has_settings = true;
	}

	string GetSaveString(){
		return "load_level" + param_delimiter + level_path;
	}

	string GetDisplayString(){
		return "LoadLevel " + level_path;
	}

	void DrawSettings(){
		ImGui_Text("Level Path : " + level_path);
		ImGui_SameLine();
		if(ImGui_Button("Set Sound Path")){
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
