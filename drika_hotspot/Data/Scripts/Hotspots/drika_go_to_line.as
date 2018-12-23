class DrikaGoToLine : DrikaElement{
	int line;

	DrikaGoToLine(JSONValue params = JSONValue()){
		line = GetJSONInt(params, "line", 0);
		drika_element_type = drika_go_to_line;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("go_to_line");
		data["line"] = JSONValue(line);
		return data;
	}

	string GetDisplayString(){
		return "GoToLine " + line;
	}

	void DrawSettings(){
		ImGui_InputInt("Line", line);
	}

	bool Trigger(){
		if(line < int(drika_elements.size())){
			current_line = line;
			display_index = drika_indexes[line];
			return false;
		}else{
			Log(info, "The GoToLine isn't valid " + line);
			return false;
		}
	}
}
