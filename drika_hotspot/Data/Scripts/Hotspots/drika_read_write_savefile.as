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
	//The variables that can be changed by the user don't have a default value, instead this is done in the constructor.
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
	DrikaGoToLineSelect@ continue_element;
	bool continue_if_false;
	bool if_any_are_true;
	//These strings are not changed by the user, but simply to display readable text in the dropdown menus.
	array<string> mode_choices = {"Read", "Write"};
	array<string> condition_choices = {"No additional conditions", "One additional condition", "Two additional conditions"};

	DrikaReadWriteSaveFile(JSONValue params = JSONValue())
	{
		//Every user editable variable is retrieved from the JSON data.
		//However when a variable isn't found the default value at the end is returned.
		//This makes sure older savedata is still valid when adding new functions.
		continue_if_false = GetJSONBool(params, "continue_if_false", false);
		if_any_are_true = GetJSONBool(params, "if_any_are_true", false);
		@continue_element = DrikaGoToLineSelect("continue_line", params);
		param = GetJSONString(params, "param", "drika_save_param");
		value = GetJSONString(params, "value", "drika_save_value");
		param2 = GetJSONString(params, "param2", "drika_save_param_two");
		value2 = GetJSONString(params, "value2", "drika_save_value_two");
		param3 = GetJSONString(params, "param3", "drika_save_param_three");
		value3 = GetJSONString(params, "value3", "drika_save_value_three");

		//The mode and count are enum values which can't be used by dropdown menus (combo).
		read_write_mode = read_write_modes(GetJSONInt(params, "read_write_mode", 0));
		condition_count = additional_conditions(GetJSONInt(params, "condition_count", 0));
		//So we need to use an extra integer value to keep track of the currently selected dropdown item.
		current_read_write_mode = read_write_mode;
		current_condition_count = condition_count;
		//Every DHS function has it's own enum value that describes it's type.
		drika_element_type = drika_read_write_savefile;
		//Not sure why this was added. But the settings can be turned off if there are none to show.
		has_settings = true;
	}

	void PostInit(){
		//Objects in the scene are often not ready yet when you run your function in the constructor.
		//That's why we run this function on the first update only once, in which case all objects in the scene are added.
		continue_element.PostInit();
	}

	JSONValue GetSaveData(){
		//Every function returns it's savedata to DHS for saving separately.
		//The JSON library takes any variable type, and when writing to a file it saves it as strings.
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
		if(continue_if_false){
			continue_element.SaveGoToLine(data);
		}
		return data;
	}

	string GetDisplayString(){
		//This creates a readable string for the UI to display.
		//Setting the text color and determinating text cutoff is done in the main DHS script.
		continue_element.CheckLineAvailable();
		string display_string;

		if(read_write_mode == read){
			if(condition_count == condition_count_none){
				display_string += "Read " + param + " " + value;
			}else if(condition_count == condition_count_one){
				display_string += "Check two conditions";
			}else if(condition_count == condition_count_two){
				display_string += "Check three conditions";
			}
			display_string += (continue_if_false?" else line " + continue_element.GetTargetLineIndex():"");
		}else if(read_write_mode == write){
			display_string += "Write " + param + " " + value;
		}

		return display_string;
	}

	void DrawSettings(){
		//The settings are divided into two column by default. (Exceptions do exist)
		//Inside the first column a description/name of the setting is displayed.
		//To keep this visible at all times a static width is used.
		float option_name_width = 150.0;

		//You need to keep good track of the number of columns and how many times you use NextColumn.
		//Or else every UI element going forward is going to be in the wrong column.
		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		//This function makes the UI element vertically centered.
		//We need to do this a lot because going to a new column seems to undo this setting.
		ImGui_AlignTextToFramePadding();
		//By default we are on the first column, so add the first descriptor for the setting.
		ImGui_Text("Read Write Mode");
		//Now we are going to the second column where the actual setting is displayed.
		ImGui_NextColumn();
		//The window size can change so we need to calculate the maximum amount of width we have left.
		float second_column_width = ImGui_GetContentRegionAvailWidth();

		//This values is then used to make sure dropdown menus and other elements have the correct width.
		ImGui_PushItemWidth(second_column_width);
		//We use an enum for tracking the current read/write mode, but a combo can only use integers for the currently selected item.
		//So when the combo changes the ``current_`` value, we also change the enum value by casting it to the correct enum type.
		if(ImGui_Combo("##Read Write Mode", current_read_write_mode, mode_choices, mode_choices.size())){
			read_write_mode = read_write_modes(current_read_write_mode);
		}
		//The setting is now rendering so clear the width for the next item.
		ImGui_PopItemWidth();
		//Using NextColumn here goes from the second column to the first column because we only have two columns.
		ImGui_NextColumn();

		if(read_write_mode == read){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Additional Conditions");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("##Additional Conditions", current_condition_count, condition_choices, condition_choices.size())){
				condition_count = additional_conditions(current_condition_count);
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			//You can show/hide certain settings based on conditions.
			//However the settings still keep their values.
			if(condition_count == condition_count_none){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Check if param");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("Parameter", param, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Is equal to");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("Value", value, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();
			}

			if(condition_count != condition_count_none){
				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("First Parameter");
				ImGui_NextColumn();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Name 1");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Name 1", param, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Value 1");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Value 1", value, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_Separator();
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Second Parameter");
				ImGui_NextColumn();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Name 2");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Name 2", param2, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Value 2");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Value 2", value2, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_Separator();
			}

			if(condition_count == condition_count_two){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Third Parameter");
				ImGui_NextColumn();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Name 3");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Name 3", param3, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Parameter Value 3");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_InputText("##Parameter Value 3", value3, 64);
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_Separator();
			}

			if(condition_count != condition_count_none){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Continue if any true");
				ImGui_NextColumn();
				ImGui_Checkbox("###Continue if any true", if_any_are_true);
				ImGui_NextColumn();
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("If not, go to line");
			ImGui_NextColumn();
			ImGui_Checkbox("###If not, go to line", continue_if_false);
			ImGui_NextColumn();

			if(continue_if_false){
				continue_element.DrawGoToLineUI();
			}
		}else{
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Parameter name");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_InputText("Parameter", param, 64);
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Parameter Value");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_InputText("Value", value, 64);
			ImGui_PopItemWidth();
			ImGui_NextColumn();
			ImGui_NextColumn();

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
		//When DHS arrives at this function it will keep running Trigger on every update untill true is returned.
		//In which case this function is done. Every function needs to handle it's own reset on trigger if it supports multiple triggers.
		int continue_line = continue_element.GetTargetLineIndex();
		if(read_write_mode == read and condition_count == condition_count_none){
			if(ReadParamValue() == value){
				return true;
			}else{
				if (continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_line;
					display_index = drika_indexes[continue_line];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_one and if_any_are_true == false){
			if(ReadParamValue() == value and ReadParam2Value() == value2){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_line;
					display_index = drika_indexes[continue_line];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_two and if_any_are_true == false){
			if(ReadParamValue() == value and ReadParam2Value() == value2 and ReadParam3Value() == value3){
				return true;
			}else{
				if (continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_line;
					display_index = drika_indexes[continue_line];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_one and if_any_are_true == true){
			if(ReadParamValue() == value or ReadParam2Value() == value2){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_line;
					display_index = drika_indexes[continue_line];
				}
				return false;
			}
		}else if(read_write_mode == read and condition_count == condition_count_two and if_any_are_true == true){
			if(ReadParamValue() == value or ReadParam2Value() == value2 or ReadParam3Value() == value3){
				return true;
			}else{
				if(continue_if_false == true and continue_line < int(drika_elements.size())){
					current_line = continue_line;
					display_index = drika_indexes[continue_line];
				}
				return false;
			}
		}else{
			WriteParamValue(false);
			return true;
		}
	}
}
