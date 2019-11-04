enum read_write_modes 	{
							read = 0,
							write = 1
						};

class DrikaReadWriteSaveFile : DrikaElement{
	string param;
	string value;
	read_write_modes read_write_mode;
	int current_read_write_mode;
	array<string> mode_choices = {"Read", "Write"};
	bool read_checked = false;
	string read_value = "";

	DrikaReadWriteSaveFile(JSONValue params = JSONValue()){
		param = GetJSONString(params, "param", "drika_save_param");
		value = GetJSONString(params, "value", "drika_save_value");
		read_write_mode = read_write_modes(GetJSONInt(params, "read_write_mode", 0));
		current_read_write_mode = read_write_mode;
		drika_element_type = drika_read_write_savefile;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("read_write_savefile");
		data["param"] = JSONValue(param);
		data["value"] = JSONValue(value);
		data["read_write_mode"] = JSONValue(read_write_mode);
		return data;
	}

	string GetDisplayString(){
		if(read_write_mode == read){
			return "Read " + param + " " + value;
		}else{
			return "Write " + param + " " + value;
		}
	}

	void DrawSettings(){
		if(ImGui_Combo("Read Write Mode", current_read_write_mode, mode_choices, mode_choices.size())){
			read_write_mode = read_write_modes(current_read_write_mode);
		}
		if(read_write_mode == read){
			ImGui_Text("Check if param : ");
			ImGui_InputText("Parameter", param, 64);
			ImGui_Text("Is equal to : ");
			ImGui_InputText("Value", value, 64);
		}else{
			ImGui_Text("Set param : ");
			ImGui_InputText("Parameter", param, 64);
			ImGui_Text("To : ");
			ImGui_InputText("Value", value, 64);
			if(ImGui_Button("Reset value")){
				WriteParamValue(true);
			}
		}
	}

	void WriteParamValue(bool reset){
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");
		data.SetValue(param, reset?"":value);
		save_file.WriteInPlace();
		level.SendMessage("drika_write_savefile");
	}

	string ReadParamValue(){
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");
		return data.GetValue(param);
	}

	void Reset(){
		read_checked = false;
		read_value = "";
	}

	bool Trigger(){
		if(read_write_mode == read){
			if(!read_checked){
				read_value = ReadParamValue();
				read_checked = true;
			}
			return read_value == value;
		}else{
			WriteParamValue(false);
			return true;
		}
	}

	void ReceiveMessage(string message){
		if(message == "drika_write_savefile"){
			read_checked = false;
		}
	}
}
