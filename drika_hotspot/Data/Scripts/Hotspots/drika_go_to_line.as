class DrikaGoToLine : DrikaElement{
	bool choice_line2 = false;
	bool choice_line3 = false;
	bool choice_line4 = false;
	bool choice_line5 = false;
	bool choice_line6 = false;
	bool choice_line7 = false;
	bool choice_line8 = false;
	bool choice_line9 = false;
	bool choice_line10 = false;
	GoToLineSelect@ line_element;
	GoToLineSelect@ line_element_2;
	GoToLineSelect@ line_element_3;
	GoToLineSelect@ line_element_4;
	GoToLineSelect@ line_element_5;
	GoToLineSelect@ line_element_6;
	GoToLineSelect@ line_element_7;
	GoToLineSelect@ line_element_8;
	GoToLineSelect@ line_element_9;
	GoToLineSelect@ line_element_10;

	DrikaGoToLine(JSONValue params = JSONValue()){
		@line_element = GoToLineSelect("line", params);
		@line_element_2 = GoToLineSelect("line2", params);
		@line_element_3 = GoToLineSelect("line3", params);
		@line_element_4 = GoToLineSelect("line4", params);
		@line_element_5 = GoToLineSelect("line5", params);
		@line_element_6 = GoToLineSelect("line6", params);
		@line_element_7 = GoToLineSelect("line7", params);
		@line_element_8 = GoToLineSelect("line8", params);
		@line_element_9 = GoToLineSelect("line9", params);
		@line_element_10 = GoToLineSelect("line10", params);

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
		line_element.PostInit();
		line_element_2.PostInit();
		line_element_3.PostInit();
		line_element_4.PostInit();
		line_element_5.PostInit();
		line_element_6.PostInit();
		line_element_7.PostInit();
		line_element_8.PostInit();
		line_element_9.PostInit();
		line_element_10.PostInit();
	}

	JSONValue GetSaveData(){
		JSONValue data;

		data["choice_line2"] = JSONValue(choice_line2);
		data["choice_line3"] = JSONValue(choice_line3);
		data["choice_line4"] = JSONValue(choice_line4);
		data["choice_line5"] = JSONValue(choice_line5);
		data["choice_line6"] = JSONValue(choice_line6);
		data["choice_line7"] = JSONValue(choice_line7);
		data["choice_line8"] = JSONValue(choice_line8);
		data["choice_line9"] = JSONValue(choice_line9);
		data["choice_line10"] = JSONValue(choice_line10);

		line_element.SaveGoToLine(data);
		if(choice_line2){
			line_element_2.SaveGoToLine(data);
			if(choice_line3){
				line_element_3.SaveGoToLine(data);
				if(choice_line4){
					line_element_4.SaveGoToLine(data);
					if(choice_line5){
						line_element_5.SaveGoToLine(data);
						if(choice_line6){
							line_element_6.SaveGoToLine(data);
							if(choice_line7){
								line_element_7.SaveGoToLine(data);
								if(choice_line8){
									line_element_8.SaveGoToLine(data);
									if(choice_line9){
										line_element_9.SaveGoToLine(data);
										if(choice_line10){
											line_element_10.SaveGoToLine(data);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		return data;
	}

	string GetDisplayString(){
		line_element.CheckLineAvailable();
		if(choice_line2){
			line_element_2.CheckLineAvailable();
			if(choice_line3){
				line_element_3.CheckLineAvailable();
				if(choice_line4){
					line_element_4.CheckLineAvailable();
					if(choice_line5){
						line_element_5.CheckLineAvailable();
						if(choice_line6){
							line_element_6.CheckLineAvailable();
							if(choice_line7){
								line_element_7.CheckLineAvailable();
								if(choice_line8){
									line_element_8.CheckLineAvailable();
									if(choice_line9){
										line_element_9.CheckLineAvailable();
										if(choice_line10){
											line_element_10.CheckLineAvailable();
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
				return "GoToLine " + line_element.GetTargetLineIndex();
			}else{
				return "GoToLine";
			}
		}else{
			return "Randomly pick from a list of lines to go to ";
		}
	}

	void DrawSettings(){
		ImGui_Checkbox("Pick a random line from a list of choices", choice_line2);

		line_element.DrawGoToLineUI();

		if(choice_line2){
			line_element_2.DrawGoToLineUI();
			ImGui_Checkbox("Add a third line", choice_line3);
			if(choice_line3 == true){
				line_element_3.DrawGoToLineUI();
				ImGui_Checkbox("Add a fourth line", choice_line4);
				if(choice_line4 == true){
					line_element_4.DrawGoToLineUI();
					ImGui_Checkbox("Add a fifth line", choice_line5);
					if(choice_line5 == true){
						line_element_5.DrawGoToLineUI();
						ImGui_Checkbox("Add a sixth line", choice_line6);
						if(choice_line6 == true){
							line_element_6.DrawGoToLineUI();
							ImGui_Checkbox("Add a seventh line", choice_line7);
							if(choice_line7 == true){
								line_element_7.DrawGoToLineUI();
								ImGui_Checkbox("Add an eighth line", choice_line8);
								if(choice_line8 == true){
									line_element_8.DrawGoToLineUI();
									ImGui_Checkbox("Add a ninth line", choice_line9);
									if(choice_line9 == true){
										line_element_9.DrawGoToLineUI();
										ImGui_Checkbox("Add a tenth line", choice_line10);
										if(choice_line10 == true){
											line_element_10.DrawGoToLineUI();
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
			current_line = line_element.GetTargetLineIndex();
			display_index = drika_indexes[line_element.GetTargetLineIndex()];
			return false;
		}else{
			array<GoToLineSelect@> line_list = {line_element};
			if (choice_line2 == true) {line_list.insertLast(line_element_2);}
			if (choice_line3 == true) {line_list.insertLast(line_element_3);}
			if (choice_line4 == true) {line_list.insertLast(line_element_4);}
			if (choice_line5 == true) {line_list.insertLast(line_element_5);}
			if (choice_line6 == true) {line_list.insertLast(line_element_6);}
			if (choice_line7 == true) {line_list.insertLast(line_element_7);}
			if (choice_line8 == true) {line_list.insertLast(line_element_8);}
			if (choice_line9 == true) {line_list.insertLast(line_element_9);}
			if (choice_line10 == true) {line_list.insertLast(line_element_10);}
			GoToLineSelect@ random_element = line_list[rand() % line_list.length()];

			current_line = random_element.GetTargetLineIndex();
			display_index = drika_indexes[random_element.GetTargetLineIndex()];
			return false;
		}
	}
}
