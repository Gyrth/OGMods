class DrikaQuickLaunchElement{
	string query;
	string json;
	drika_element_types type = none;

	DrikaQuickLaunchElement(string _query, string _json){
		query = _query;
		json = _json;

		JSON data;
		if(!data.parseString(json)){
			Log(warning, "Unable to parse the JSON in the quick launch element! " + json);
		}else{
			JSONValue root = data.getRoot();
			type = drika_element_types(root["function"].asInt());
		}
	}
}

class DrikaQuickLaunch{

	bool open_quick_launch = false;
	string quick_launch_search_buffer = "";
	string database_path = "Data/Scripts/drika_quick_launch_database.json";
	array<DrikaQuickLaunchElement@> database;
	array<DrikaQuickLaunchElement@> results;
	int selected_item = 0;

	DrikaQuickLaunch(){
	}

	void Init(){
		JSON data;

		if(!data.parseFile(database_path)){
			Log(warning, "Unable to parse the JSON in the quick launch database!");
			return;
		}

		JSONValue root = data.getRoot();
		array<string> list_groups = root.getMemberNames();

		for(uint i = 0; i < list_groups.size(); i++){
			database.insertLast(DrikaQuickLaunchElement(list_groups[i], root[list_groups[i]].asString()));
		}
	}

	void Draw(){
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(700.0f, 450.0f), ImGuiSetCond_FirstUseEver);

		if(open_quick_launch){
			ImGui_OpenPopup("Quick Launch");
			quick_launch_search_buffer = "";
			QueryElement(quick_launch_search_buffer);
			open_quick_launch = false;
		}

		if(ImGui_BeginPopupModal("Quick Launch", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove)){
			ImGui_BeginChild("Quick Launch Elements", vec2(-1, -1));
			ImGui_PushItemWidth(-1);

			ImGui_AlignTextToFramePadding();
			ImGui_SetTextBuf(quick_launch_search_buffer);
			ImGui_Text("Search");
			ImGui_SameLine();
			ImGui_PushItemWidth(ImGui_GetContentRegionAvailWidth());
			if(ImGui_IsRootWindowOrAnyChildFocused() && !ImGui_IsAnyItemActive() && !ImGui_IsMouseClicked(0)){
				ImGui_SetKeyboardFocusHere(-1);
			}

			if(ImGui_InputText("", ImGuiInputTextFlags_AutoSelectAll)){
				quick_launch_search_buffer = ImGui_GetTextBuf();
				QueryElement(quick_launch_search_buffer);
				selected_item = 0;
			}
			ImGui_PopItemWidth();

			ImGui_SetWindowFontScale(3.0);
			for(uint i = 0; i < results.size(); i++){
				vec4 text_color = display_colors[results[i].type];
				ImGui_PushStyleColor(ImGuiCol_Text, text_color);
				bool line_selected = selected_item == int(i);

				string display_string = results[i].query;
				display_string = join(display_string.split("\n"), "");
				float space_for_characters = ImGui_CalcTextSize(display_string).x;

				if(space_for_characters > ImGui_GetWindowContentRegionWidth()){
					display_string = display_string.substr(0, int(display_string.length() * (ImGui_GetWindowContentRegionWidth() / space_for_characters)) - 3) + "...";
				}

				if(ImGui_Selectable(display_string, line_selected, ImGuiSelectableFlags_AllowDoubleClick)){

				}

				ImGui_PopStyleColor();
			}
			ImGui_SetWindowFontScale(1.0);

			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_Escape))){
				ImGui_CloseCurrentPopup();
			}

			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(selected_item > 0){
					selected_item -= 1;
					/* update_scroll = true; */
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(selected_item < int(results.size() - 1)){
					selected_item += 1;
					/* update_scroll = true; */
				}
			}

			ImGui_PopItemWidth();
			ImGui_EndChild();

			if(!ImGui_IsMouseHoveringAnyWindow() && ImGui_IsMouseClicked(0)){
				ImGui_CloseCurrentPopup();
			}

			ImGui_EndPopup();
		}
		ImGui_PopStyleVar();
	}

	void QueryElement(string query){
		results.resize(0);
		if(query == ""){
			results = database;
		}else{
			for(uint i = 0; i < database.size(); i++){
				if(ToLowerCase(database[i].query).findFirst(ToLowerCase(query)) != -1){
					results.insertLast(database[i]);
				}
			}
		}
	}

	void Update(){
		if(GetInputDown(0, "lctrl") && GetInputPressed(0, "return")){
			open_quick_launch = true;
		}
	}
}
