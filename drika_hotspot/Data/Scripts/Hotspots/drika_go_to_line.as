class DrikaGoToLine : DrikaElement{
	int line;

	DrikaGoToLine(string _line = "0"){
		line = atoi(_line);
		drika_element_type = drika_go_to_line;
		has_settings = true;
	}

	string GetSaveString(){
		return "go_to_line" + param_delimiter + line;
	}

	string GetDisplayString(){
		return "GoToLine " + line;
	}

	void AddSettings(){
		ImGui_DragInt("Line", line, 1.0, 1, 10000);
	}

	bool Trigger(){
		if(line < int(drika_elements.size())){
			current_line = line;
			return false;
		}else{
			Log(info, "The GoToLine isn't valid");
			return false;
		}
	}
}
