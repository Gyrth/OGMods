class DrikaGoToLine : DrikaElement{
	DrikaElement@ line_element;
	int line;
	int line2;
	int line3;
	int line4;
	int line5;
	int line6;
	int line7;
	int line8;
	int line9;
	int line10;
	bool choice_line2 = false;
	bool choice_line3 = false;
	bool choice_line4 = false;
	bool choice_line5 = false;
	bool choice_line6 = false;
	bool choice_line7 = false;
	bool choice_line8 = false;
	bool choice_line9 = false;
	bool choice_line10 = false;

	DrikaGoToLine(JSONValue params = JSONValue()){
		line = GetJSONInt(params, "line", 0);
		line2 = GetJSONInt(params, "line2", 0);
		line3 = GetJSONInt(params, "line3", 0);
		line4 = GetJSONInt(params, "line4", 0);
		line5 = GetJSONInt(params, "line5", 0);
		line6 = GetJSONInt(params, "line6", 0);
		line7 = GetJSONInt(params, "line7", 0);
		line8 = GetJSONInt(params, "line8", 0);
		line9 = GetJSONInt(params, "line9", 0);
		line10 = GetJSONInt(params, "line10", 0);
		choice_line2 = GetJSONBool(params, "choice_line2", false);
		choice_line3 = GetJSONBool(params, "choice_line3", false);
		choice_line4 = GetJSONBool(params, "choice_line4", false);
		choice_line5 = GetJSONBool(params, "choice_line5", false);
		choice_line6 = GetJSONBool(params, "choice_line6", false);
		choice_line7 = GetJSONBool(params, "choice_line7", false);
		choice_line8 = GetJSONBool(params, "choice_line8", false);
		choice_line9 = GetJSONBool(params, "choice_line9", false);
		choice_line10 = GetJSONBool(params, "choice_line10", false);
		drika_element_type = drika_go_to_line;
		has_settings = true;
	}

	void PostInit(){
		@line_element = drika_elements[drika_indexes[line]];
	}

	JSONValue GetSaveData(){
		JSONValue data;
		if(@line_element != null){
			data["line"] = JSONValue(line_element.index);
		}
		data["line2"] = JSONValue(line2);
		data["line3"] = JSONValue(line3);
		data["line4"] = JSONValue(line4);
		data["line5"] = JSONValue(line5);
		data["line6"] = JSONValue(line6);
		data["line7"] = JSONValue(line7);
		data["line8"] = JSONValue(line8);
		data["line9"] = JSONValue(line9);
		data["line10"] = JSONValue(line10);
		data["choice_line2"] = JSONValue(choice_line2);
		data["choice_line3"] = JSONValue(choice_line3);
		data["choice_line4"] = JSONValue(choice_line4);
		data["choice_line5"] = JSONValue(choice_line5);
		data["choice_line6"] = JSONValue(choice_line6);
		data["choice_line7"] = JSONValue(choice_line7);
		data["choice_line8"] = JSONValue(choice_line8);
		data["choice_line9"] = JSONValue(choice_line9);
		data["choice_line10"] = JSONValue(choice_line10);
		return data;
	}

	string GetDisplayString(){
		//Elements can be deleted when this function isn't being edited. So this function is used to continuesly check the target element.
		if(@line_element == null || line_element.deleted){
			//If the line_element gets deleted then just pick the first one.
			@line_element = drika_elements[0];
		}

		if(choice_line2 == false){
			if(@line_element != null){
				return "GoToLine " + line_element.index;
			}else{
				return "GoToLine";
			}
		}else{
			return "Randomly pick from a list of lines to go to ";
		}
	}

	void DrawSettings(){
		ImGui_Checkbox("Pick a random line from a list of choices", choice_line2);

		if(@line_element == null){
			return;
		}

		if(!choice_line2){
			string preview_value = line_element.line_number + line_element.GetDisplayString();
			ImGui_Text("Go to line : ");
			ImGui_SameLine();
			ImGui_PushStyleColor(ImGuiCol_Text, line_element.GetDisplayColor());
			ImGui_PushItemWidth(-1.0);
			if(ImGui_BeginCombo("###line", preview_value)){
			    for(uint i = 0; i < drika_indexes.size(); i++){
					int item_no = drika_indexes[i];
			        bool is_selected = (line_element.index == drika_indexes[i]);
					vec4 text_color = drika_elements[item_no].GetDisplayColor();

					ImGui_PushStyleColor(ImGuiCol_Text, text_color);
			        if(ImGui_Selectable(drika_elements[item_no].line_number + drika_elements[item_no].GetDisplayString(), is_selected)){
						@line_element = drika_elements[item_no];
						line = line_element.index;
					}
					ImGui_PopStyleColor();
			    }
			    ImGui_EndCombo();
			}
			ImGui_PopItemWidth();
			ImGui_PopStyleColor();
		}else{
			ImGui_InputInt("Line", line);
			ImGui_InputInt("Line 2", line2);
			ImGui_Checkbox("Add a third line", choice_line3);
			if(choice_line3 == true){
				ImGui_InputInt("Line 3", line3);
				ImGui_Checkbox("Add a fourth line", choice_line4);
				if(choice_line4 == true){
					ImGui_InputInt("Line 4", line4);
					ImGui_Checkbox("Add a fifth line", choice_line5);
					if(choice_line5 == true){
						ImGui_InputInt("Line 5", line5);
						ImGui_Checkbox("Add a sixth line", choice_line6);
						if(choice_line6 == true){
							ImGui_InputInt("Line 6", line6);
							ImGui_Checkbox("Add a seventh line", choice_line7);
							if(choice_line7 == true){
								ImGui_InputInt("Line 7", line7);
								ImGui_Checkbox("Add an eighth line", choice_line8);
								if(choice_line8 == true){
									ImGui_InputInt("Line 8", line8);
									ImGui_Checkbox("Add a ninth line", choice_line9);
									if(choice_line9 == true){
										ImGui_InputInt("Line 9", line9);
										ImGui_Checkbox("Add a tenth line", choice_line10);
										if(choice_line10 == true){
											ImGui_InputInt("Line 10", line10);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	bool Trigger(){
		if(!choice_line2){
			current_line = line_element.index;
			display_index = drika_indexes[line_element.index];
			return false;
		}else{
			array<int> line_list = {line};
			if (choice_line2 == true) {line_list.insertLast(line2);}
			if (choice_line3 == true) {line_list.insertLast(line3);}
			if (choice_line4 == true) {line_list.insertLast(line4);}
			if (choice_line5 == true) {line_list.insertLast(line5);}
			if (choice_line6 == true) {line_list.insertLast(line6);}
			if (choice_line7 == true) {line_list.insertLast(line7);}
			if (choice_line8 == true) {line_list.insertLast(line8);}
			if (choice_line9 == true) {line_list.insertLast(line9);}
			if (choice_line10 == true) {line_list.insertLast(line10);}
			int random_value = line_list[rand() % line_list.length()];

			if(random_value < int(drika_elements.size())){
				current_line = random_value;
				display_index = drika_indexes[random_value];
				return false;
			}else{
				Log(info, "The GoToLine isn't valid " + random_value);
				return false;
			}
		}
	}
}
