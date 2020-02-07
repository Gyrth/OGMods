class DrikaGoToLine : DrikaElement{
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
	DrikaElement@ line_element;
	DrikaElement@ line_element_2;
	DrikaElement@ line_element_3;
	DrikaElement@ line_element_4;
	DrikaElement@ line_element_5;
	DrikaElement@ line_element_6;
	DrikaElement@ line_element_7;
	DrikaElement@ line_element_8;
	DrikaElement@ line_element_9;
	DrikaElement@ line_element_10;

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
		@line_element = drika_elements[drika_indexes[line]];
		@line_element_2 = drika_elements[drika_indexes[line2]];
		@line_element_3 = drika_elements[drika_indexes[line3]];
		@line_element_4 = drika_elements[drika_indexes[line4]];
		@line_element_5 = drika_elements[drika_indexes[line5]];
		@line_element_6 = drika_elements[drika_indexes[line6]];
		@line_element_7 = drika_elements[drika_indexes[line7]];
		@line_element_8 = drika_elements[drika_indexes[line8]];
		@line_element_9 = drika_elements[drika_indexes[line9]];
		@line_element_10 = drika_elements[drika_indexes[line10]];
	}

	JSONValue GetSaveData(){
		JSONValue data;
		if(@line_element != null){
			data["line"] = JSONValue(line_element.index);
		}
		if(@line_element_2 != null){
			data["line2"] = JSONValue(line_element_2.index);
		}
		if(@line_element_3 != null){
			data["line3"] = JSONValue(line_element_3.index);
		}
		if(@line_element_4 != null){
			data["line4"] = JSONValue(line_element_4.index);
		}
		if(@line_element_5 != null){
			data["line5"] = JSONValue(line_element_5.index);
		}
		if(@line_element_6 != null){
			data["line6"] = JSONValue(line_element_6.index);
		}
		if(@line_element_7 != null){
			data["line7"] = JSONValue(line_element_7.index);
		}
		if(@line_element_8 != null){
			data["line8"] = JSONValue(line_element_8.index);
		}
		if(@line_element_9 != null){
			data["line9"] = JSONValue(line_element_9.index);
		}
		if(@line_element_10 != null){
			data["line10"] = JSONValue(line_element_10.index);
		}

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
		GoToLineCheckAvailable(line_element);
		if(choice_line2){
			GoToLineCheckAvailable(line_element_2);
			if(choice_line3){
				GoToLineCheckAvailable(line_element_3);
				if(choice_line4){
					GoToLineCheckAvailable(line_element_4);
					if(choice_line5){
						GoToLineCheckAvailable(line_element_5);
						if(choice_line6){
							GoToLineCheckAvailable(line_element_6);
							if(choice_line7){
								GoToLineCheckAvailable(line_element_7);
								if(choice_line8){
									GoToLineCheckAvailable(line_element_8);
									if(choice_line9){
										GoToLineCheckAvailable(line_element_9);
										if(choice_line10){
											GoToLineCheckAvailable(line_element_10);
										}
									}
								}
							}
						}
					}
				}
			}
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

		if(!choice_line2){
			AddGoToLineCombo(line_element, "line");
		}else{
			AddGoToLineCombo(line_element, "line");
			AddGoToLineCombo(line_element_2, "line2");
			ImGui_Checkbox("Add a third line", choice_line3);
			if(choice_line3 == true){
				AddGoToLineCombo(line_element_3, "line3");
				ImGui_Checkbox("Add a fourth line", choice_line4);
				if(choice_line4 == true){
					AddGoToLineCombo(line_element_4, "line4");
					ImGui_Checkbox("Add a fifth line", choice_line5);
					if(choice_line5 == true){
						AddGoToLineCombo(line_element_5, "line5");
						ImGui_Checkbox("Add a sixth line", choice_line6);
						if(choice_line6 == true){
							AddGoToLineCombo(line_element_6, "line6");
							ImGui_Checkbox("Add a seventh line", choice_line7);
							if(choice_line7 == true){
								AddGoToLineCombo(line_element_7, "line7");
								ImGui_Checkbox("Add an eighth line", choice_line8);
								if(choice_line8 == true){
									AddGoToLineCombo(line_element_8, "line8");
									ImGui_Checkbox("Add a ninth line", choice_line9);
									if(choice_line9 == true){
										AddGoToLineCombo(line_element_9, "line9");
										ImGui_Checkbox("Add a tenth line", choice_line10);
										if(choice_line10 == true){
											AddGoToLineCombo(line_element_10, "line10");
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
			array<DrikaElement@> line_list = {line_element};
			if (choice_line2 == true) {line_list.insertLast(line_element_2);}
			if (choice_line3 == true) {line_list.insertLast(line_element_3);}
			if (choice_line4 == true) {line_list.insertLast(line_element_4);}
			if (choice_line5 == true) {line_list.insertLast(line_element_5);}
			if (choice_line6 == true) {line_list.insertLast(line_element_6);}
			if (choice_line7 == true) {line_list.insertLast(line_element_7);}
			if (choice_line8 == true) {line_list.insertLast(line_element_8);}
			if (choice_line9 == true) {line_list.insertLast(line_element_9);}
			if (choice_line10 == true) {line_list.insertLast(line_element_10);}
			DrikaElement@ random_element = line_list[rand() % line_list.length()];

			current_line = random_element.index;
			display_index = drika_indexes[random_element.index];
			return false;
		}
	}
}
