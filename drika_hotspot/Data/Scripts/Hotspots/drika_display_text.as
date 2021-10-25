class DrikaDisplayText : DrikaElement{
	string display_message;
	int font_size;
	string font_path;

	DrikaDisplayText(JSONValue params = JSONValue()){
		display_message = GetJSONString(params, "display_message", "Drika Display Message");
		font_size = GetJSONInt(params, "font_size", 10);
		font_path = GetJSONString(params, "font_path", "Data/Fonts/Cella.ttf");

		drika_element_type = drika_display_text;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["display_message"] = JSONValue(display_message);
		data["font_size"] = JSONValue(font_size);
		data["font_path"] = JSONValue(font_path);
		return data;
	}

	string GetDisplayString(){
		array<string> split_message = display_message.split("\n");
		return "DisplayText " + split_message[0];
	}

	void StartEdit(){
		ShowText(ParseDisplayMessage(display_message), font_size, font_path);
	}

	void EditDone(){
		ShowText("", font_size, font_path);
	}

	void DrawSettings(){
		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Font Path");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		if(ImGui_Button("Set Font Path")){
			string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
			if(new_path != ""){
				new_path = ShortenPath(new_path);
				array<string> path_split = new_path.split("/");
				string file_name = path_split[path_split.size() - 1];
				string file_extension = file_name.substr(file_name.length() - 3, 3);

				if(file_extension == "ttf" || file_extension == "TTF"){
					font_path = new_path;
					ShowText(ParseDisplayMessage(display_message), font_size, font_path);
				}else{
					DisplayError("Font issue", "Only ttf font files are supported.");
				}
			}
		}
		ImGui_SameLine();
		ImGui_Text(font_path);
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Font Size");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_SliderInt("##Font Size", font_size, 0, 100, "%.0f")){
			ShowText(ParseDisplayMessage(display_message), font_size, font_path);
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Text");
		ImGui_NextColumn();
		ImGui_SetTextBuf(display_message);
		if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
			display_message = ImGui_GetTextBuf();
			ShowText(ParseDisplayMessage(display_message), font_size, font_path);
		}
		ImGui_NextColumn();
		ImGui_NextColumn();
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Entering words between [brackets] will cause that word to be interpreted as a variable.");
		ImGui_Text("If you want to display a word between brackets on screen, just add a backslash in front of that \\[word].");
		ImGui_NextColumn();
	}

	string ParseDisplayMessage(string input) // This function reads the input for items between braces[] and interprets those as variables.
	{
		int position_in_string = 0;

		while(uint(position_in_string) < input.length()) // First let's see if there are any braces in the string at all.
		{
			int start_brace_pos = input.findFirst("[", position_in_string); //We'll use these two statements a lot, so let's assign them to a variable.
			int end_brace_pos = input.findFirst("]", start_brace_pos);

			if (start_brace_pos >= 0 && end_brace_pos >= 0)
			{
				string unfiltered_braces = input.substr(start_brace_pos, end_brace_pos - start_brace_pos + 1); //First get the contents of the braces, including extra start braces inside
				string filtered_braces = unfiltered_braces.substr(unfiltered_braces.findLast("["),unfiltered_braces.length()); //Reduce to the start brace closest to the end brace
				string stored_value;

				int difference = unfiltered_braces.length() - filtered_braces.length(); //We use this to figure out the start position to replace the [variable]

				if (start_brace_pos + difference == 0 || input[start_brace_pos + difference - 1] != "\\"[0]) //We need to check if there is a backslash first
				{
					input.erase(start_brace_pos + difference, filtered_braces.length()); //Here we erase the variable name
					stored_value = ReadParamValue(filtered_braces.substr(1, filtered_braces.length() - 2)); //Get the actual contents of the variable
					input.insert(start_brace_pos + difference, stored_value); //And replace filtered_braces with those contents
				}
				else
				{
				input.erase(start_brace_pos + difference - 1,1); //If there was a backslash just before the variable, that's the only thing we want to remove
				stored_value = filtered_braces;
				}

				position_in_string = start_brace_pos + difference + stored_value.length(); //Let's update our position and continue checking
			}
			else
			{
				break;
			}
		}

		return input;
	}


	string ReadParamValue(string key)
		{
		SavedLevel@ data = save_file.GetSavedLevel("drika_data");

		return (data.GetValue("[" + key + "]") == "true")? data.GetValue(key) : "--ERROR - " + key + " does not exist--";
		}

	void Reset(){
		if(triggered){
			ShowText("", font_size, font_path);
		}
	}

	bool Trigger(){
		if(!triggered){
			triggered = true;
		}
		ShowText(ParseDisplayMessage(display_message), font_size, font_path);
		return true;
	}
}
