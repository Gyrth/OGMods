enum read_write_modes 	{
							read = 0,
							write = 1
						};
enum additional_conditions 	{
							condition_count_none = 0,
							condition_count_one = 1,
							condition_count_two = 2
						};

class DrikaReadWriteSaveFile : DrikaElement{
	string param;
	string value;
	string param2;
	string value2;
	string param3;
	string value3;
	read_write_modes read_write_mode;
	additional_conditions condition_count;
	int current_read_write_mode;
	int current_condition_count;
	int continue_line;
	DrikaElement@ continue_element;
	bool continue_if_false = false;
	bool if_any_are_true = false;
	array<string> mode_choices = {"Read", "Write"};
	array<string> condition_choices = {"No additional conditions", "One additional condition", "Two additional conditions"};

	DrikaReadWriteSaveFile(JSONValue params = JSONValue()){
		continue_if_false = GetJSONBool(params, "continue_if_false", false);
		if_any_are_true = GetJSONBool(params, "if_any_are_true", false);
		continue_line = GetJSONInt(params, "continue_line", 0);
		param = GetJSONString(params, "param", "drika_save_param");
		value = GetJSONString(params, "value", "drika_save_value");
		param2 = GetJSONString(params, "param2", "drika_save_param_two");
		value2 = GetJSONString(params, "value2", "drika_save_value_two");
		param3 = GetJSONString(params, "param3", "drika_save_param_three");
		value3 = GetJSONString(params, "value3", "drika_save_value_three");

		read_write_mode = read_write_modes(GetJSONInt(params, "read_write_mode", 0));
		condition_count = additional_conditions(GetJSONInt(params, "condition_count", 0));
		current_read_write_mode = read_write_mode;
		current_condition_count = condition_count;
		drika_element_type = drika_read_write_savefile;
		has_settings = true;

		if(duplicating){
			GetTargetElement();
		}
	}

	void PostInit(){
		if(!duplicating){
			GetTargetElement();
		}
	}

	void GetTargetElement(){
		@continue_element = drika_elements[drika_indexes[continue_line]];
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["param"] = JSONValue(param);
		data["value"] = JSONValue(value);
		data["param2"] = JSONValue(param2);
		data["value2"] = JSONValue(value2);
		data["param3"] = JSONValue(param3);
		data["value3"] = JSONValue(value3);
		data["read_write_mode"] = JSONValue(read_write_mode);
		data["condition_count"] = JSONValue(condition_count);
		data["continue_if_false"] = JSONValue(continue_if_false);
		data["if_any_are_true"] = JSONValue(if_any_are_true);
		if(continue_if_false && @continue_element != null){
			data["continue_line"] = JSONValue(continue_element.index);
		}
		return data;
	}

	string GetDisplayString(){
		GoToLineCheckAvailable(continue_element);
		string display_string;

		if(read_write_mode == read){
			if(condition_count == condition_count_none){
				display_string += "Read " + param + " " + value;
			}else if(condition_count == condition_count_one){
				display_string += "Check two conditions";
			}else if(condition_count == condition_count_two){
				display_string += "Check three conditions";
			}
			display_string += (continue_if_false?" else line " + continue_element.index:"");
		}else if(read_write_mode == write){
			display_string += "Write " + param + " " + value;
		}

		return display_string;
	}

	void DrawSettings(){
		ImGui_Text("Read Write Mode");
		ImGui_SameLine();
		if(ImGui_Combo("##Read Write Mode", current_read_write_mode, mode_choices, mode_choices.size())){
			read_write_mode = read_write_modes(current_read_write_mode);
		}

		if(read_write_mode == read){
			ImGui_Text("Additional Conditions");
			ImGui_SameLine();
			if(ImGui_Combo("##Additional Conditions", current_condition_count, condition_choices, condition_choices.size())){
				condition_count = additional_conditions(current_condition_count);
			}

			if(condition_count == condition_count_none){
				ImGui_Text("Check if param : ") ;
				ImGui_InputText("Parameter", param, 64);
				ImGui_Text("Is equal to : ");
				ImGui_InputText("Value", value, 64);
			}

			if(condition_count != condition_count_none){
				ImGui_Separator();
				ImGui_Text("First Parameter");

				ImGui_Text("Parameter Name 1");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Name 1", param, 64);
				ImGui_Text("Parameter Value 1");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Value 1", value, 64);

				ImGui_Separator();
				ImGui_Text("Second Parameter");

				ImGui_Text("Parameter Name 2");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Name 2", param2, 64);
				ImGui_Text("Parameter Value 2");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Value 2", value2, 64);
				ImGui_Separator();
			}

			if(condition_count == condition_count_two){
				ImGui_Text("Third Parameter");

				ImGui_Text("Parameter Name 3");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Name 3", param3, 64);
				ImGui_Text("Parameter Value 3");
				ImGui_SameLine();
				ImGui_InputText("##Parameter Value 3", value3, 64);

				ImGui_Separator();
			}

			if(condition_count != condition_count_none){
				ImGui_Checkbox("Continue if any of the conditions are true", if_any_are_true);
			}

			ImGui_Checkbox("If not, go to specified line:", continue_if_false);
			if(continue_if_false == true){
				AddGoToLineCombo(continue_element, "line");
			}
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
	}

	string ReadParamValue(){
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");
		return data.GetValue(param);
	}

	string ReadParam2Value(){
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");
		return data.GetValue(param2);
	}

	string ReadParam3Value(){
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");
		return data.GetValue(param3);
	}

	bool Trigger(){
		if(read_write_mode == read and condition_count == condition_count_none){
			if(ReadParamValue() == value){
				return true;
			}else{
				if (continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_element.index;
					display_index = drika_indexes[continue_element.index];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_one and if_any_are_true == false){
			if(ReadParamValue() == value and ReadParam2Value() == value2){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_element.index;
					display_index = drika_indexes[continue_element.index];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_two and if_any_are_true == false){
			if(ReadParamValue() == value and ReadParam2Value() == value2 and ReadParam3Value() == value3){
				return true;
			}else{
				if (continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_element.index;
					display_index = drika_indexes[continue_element.index];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_one and if_any_are_true == true){
			if(ReadParamValue() == value or ReadParam2Value() == value2){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_element.index;
					display_index = drika_indexes[continue_element.index];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_two and if_any_are_true == true){
			if(ReadParamValue() == value or ReadParam2Value() == value2 or ReadParam3Value() == value3){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_element.index;
					display_index = drika_indexes[continue_element.index];
				}
				return false;
			}
		}else{
			WriteParamValue(false);
			return true;
		}
	}
}
