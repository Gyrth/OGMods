enum ui_functions	{
						ui_clear = 0,
						ui_image = 1,
						ui_text = 2,
						ui_font = 3,
						ui_fade_in = 4,
						ui_move_in = 5
					}

class DrikaUserInterface : DrikaElement{
	ui_functions ui_function;
	int current_ui_function;
	string image_path;
	ivec2 size;
	ivec2 position;
	ivec2 position_offset;
	ivec2 size_offset;
	ivec2 max_offset;
	float rotation;
	vec4 color;
	bool keep_aspect;
	array<string> content;
	string text_content;
	string display_content;
	string ui_element_identifier;
	bool ui_element_added = false;
	string font_name;
	int font_size;
	vec4 font_color;
	float font_rotation;
	bool shadowed;
	DrikaUserInterface@ font_element = null;
	array<DrikaUserInterface@> text_elements;

	array<string> ui_function_names =	{
											"Clear",
											"Image",
											"Text",
											"Font",
											"Fade In",
											"Move In"
										};

	DrikaUserInterface(JSONValue params = JSONValue()){
		ui_function = ui_functions(GetJSONInt(params, "ui_function", ui_clear));
		current_ui_function = ui_function;

		image_path = GetJSONString(params, "image_path", "Textures/ui/menus/credits/overgrowth.png");
		rotation = GetJSONFloat(params, "rotation", 0.0);
		position = GetJSONIVec2(params, "position", ivec2(ui_snap_scale, ui_snap_scale) * 5);
		color = GetJSONVec4(params, "color", vec4(1.0, 1.0, 1.0, 1.0));
		keep_aspect = GetJSONBool(params, "keep_aspect", false);
		size = GetJSONIVec2(params, "size", ivec2(720 - (720 % ui_snap_scale), 255 - (255 % ui_snap_scale)));
		position_offset = GetJSONIVec2(params, "position_offset", ivec2(0, 0));
		size_offset = GetJSONIVec2(params, "size_offset", ivec2(0, 0));

		font_name = GetJSONString(params, "font_name", "edosz");
		font_size = GetJSONInt(params, "font_size", 75);
		font_color = GetJSONVec4(params, "font_color", vec4(1.0, 1.0, 1.0, 1.0));
		shadowed = GetJSONBool(params, "shadowed", true);
		font_rotation = GetJSONFloat(params, "font_rotation", 0.0);

		text_content = GetJSONString(params, "text_content", "Example Text");
		ui_element_identifier = GetUniqueID();
		Log(warning, "Unique ID " + ui_element_identifier);

		drika_element_type = drika_user_interface;
		has_settings = true;
	}

	void ReorderDone(){
		UpdateExternalResource();
		SendUIInstruction("set_z_order", {index});
	}

	void UpdateExternalResource(){
		if(ui_function == ui_text){
			DrikaUserInterface@ new_font_element = GetPreviousUIElementOfType(ui_font);
			if(new_font_element !is font_element){
				if(font_element !is null){
					font_element.RemoveTextElement(this);
				}
				@font_element = @new_font_element;
				if(font_element !is null){
					font_element.AddTextElement(this);
				}
				//If the ui element is already on screen (while editing) then update the font.
				if(ui_element_added){
					if(font_element is null){
						SendUIInstruction("font_changed", {""});
					}else{
						SendUIInstruction("font_changed", {font_element.ui_element_identifier});
					}
				}
			}
		}
	}

	void AddTextElement(DrikaUserInterface@ new_text_element){
		for(uint i = 0; i < text_elements.size(); i++){
			if(text_elements[i].ui_element_identifier == new_text_element.ui_element_identifier){
				//Already added to the list.
				return;
			}
		}
		text_elements.insertLast(new_text_element);
	}

	void RemoveTextElement(DrikaUserInterface@ text_element){
		for(uint i = 0; i < text_elements.size(); i++){
			if(text_elements[i].ui_element_identifier == text_element.ui_element_identifier){
				//Found and removed from the list.
				text_elements.removeAt(i);
				break;
			}
		}
	}

	DrikaUserInterface@ GetPreviousUIElementOfType(ui_functions function_type){
		for(int i = index - 1; i > -1; i--){
			if(drika_elements[drika_indexes[i]].drika_element_type == drika_user_interface){
				DrikaUserInterface@ found_ui_element = cast<DrikaUserInterface@>(drika_elements[drika_indexes[i]]);
				if(found_ui_element.ui_function == function_type){
					return found_ui_element;
				}
			}
		}
		return null;
	}

	/* DrikaUserInterface@ GetNextElementOfType(array<drika_element_types> types, int starting_point){
		for(uint i = starting_point + 1; i < drika_indexes.size(); i++){
			if(types.find(drika_elements[drika_indexes[i]].drika_element_type) != -1){
				return drika_elements[drika_indexes[i]];
			}
		}
		return null;
	} */

	void PostInit(){
		UpdateDisplayString();
		UpdateExternalResource();
		if(ui_function == ui_font){
			AddUIElement();
		}
		SendUIInstruction("set_z_order", {index});
	}

	void ReceiveEditorMessage(array<string> message){

	}

	void ReceiveMessage(string message){

	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["ui_function"] = JSONValue(ui_function);
		data["ui_element_identifier"] = JSONValue(ui_element_identifier);

		if(ui_function == ui_image){
			data["image_path"] = JSONValue(image_path);
			data["keep_aspect"] = JSONValue(keep_aspect);
			data["rotation"] = JSONValue(rotation);
			data["position"] = JSONValue(JSONarrayValue);
			data["position"].append(position.x);
			data["position"].append(position.y);
			data["color"] = JSONValue(JSONarrayValue);
			data["color"].append(color.x);
			data["color"].append(color.y);
			data["color"].append(color.z);
			data["color"].append(color.a);
			data["size"] = JSONValue(JSONarrayValue);
			data["size"].append(size.x);
			data["size"].append(size.y);
			data["size_offset"] = JSONValue(JSONarrayValue);
			data["size_offset"].append(size_offset.x);
			data["size_offset"].append(size_offset.y);
			data["position_offset"] = JSONValue(JSONarrayValue);
			data["position_offset"].append(position_offset.x);
			data["position_offset"].append(position_offset.y);
		}else if(ui_function == ui_text){
			data["rotation"] = JSONValue(rotation);
			data["position"] = JSONValue(JSONarrayValue);
			data["position"].append(position.x);
			data["position"].append(position.y);
			data["text_content"] = JSONValue(text_content);
		}else if(ui_function == ui_font){
			data["font_name"] = JSONValue(font_name);
			data["font_size"] = JSONValue(font_size);
			data["font_color"] = JSONValue(JSONarrayValue);
			data["font_color"].append(font_color.x);
			data["font_color"].append(font_color.y);
			data["font_color"].append(font_color.z);
			data["font_color"].append(font_color.a);
			data["shadowed"] = JSONValue(shadowed);
			data["font_rotation"] = JSONValue(font_rotation);
		}
		return data;
	}

	string GetDisplayString(){
		string display_string = "UserInterface ";
		display_string += ui_function_names[ui_function] + " ";
		if(ui_function == ui_text){
			display_string += display_content;
		}
		return display_string;
	}

	void DrawSettings(){
		ImGui_AlignTextToFramePadding();
		ImGui_Text("UI Function");
		ImGui_SameLine();
		if(ImGui_Combo("##UI Function", current_ui_function, ui_function_names, ui_function_names.size())){
			if(current_ui_function != ui_function){
				SendLevelMessage("drika_ui_remove_element");
				ui_element_added = false;
				ui_function = ui_functions(current_ui_function);
				StartEdit();
			}
		}

		if(ui_function == ui_image){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Image Path : " + image_path);
			ImGui_SameLine();
			if(ImGui_Button("Set Image Path")){
				string new_path = GetUserPickedReadPath("png", "Data/Images");
				if(new_path != ""){
					//Remove the Data/ in the beginning of the path because IMImage starts in Data/.
					array<string> split_path = new_path.split("/");
					split_path.removeAt(0);
					image_path = join(split_path, "/");
					SendUIInstruction("set_image_path", {image_path});
				}
			}

			ImGui_Columns(2, false);
			float margin = 8.0;
			float option_name_width = 130.0;
			float second_column_width = ImGui_GetWindowContentRegionWidth() - option_name_width + margin;
			float slider_width = (second_column_width / 2.0) - margin;
			ImGui_SetColumnWidth(0, option_name_width);
			ImGui_SetColumnWidth(1, second_column_width);

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##Position X", position.x, 1.0, 0, 2560, "%.0f")){
				SendUIInstruction("set_position", {position.x, position.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){
				SendUIInstruction("set_position", {position.x, position.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##size_x", size.x, 1.0, 1.0f, 1000, "%.0f")){
				SendUIInstruction("set_size", {size.x, size.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##size_y", size.y, 1.0, 1.0f, 1000, "%.0f")){
				SendUIInstruction("set_size", {size.x, size.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position Offset ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##position_offset_x", position_offset.x, 1.0, 0.0f, max_offset.x, "%.0f")){
				SendUIInstruction("set_position_offset", {position_offset.x, position_offset.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##position_offset_y", position_offset.y, 1.0, 0.0f, max_offset.y, "%.0f")){
				SendUIInstruction("set_position_offset", {position_offset.x, position_offset.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size Offset ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##size_offset_x", size_offset.x, 1.0, 1.0f, max_offset.x, "%.0f")){
				SendUIInstruction("set_size_offset", {size_offset.x, size_offset.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##size_offset_y", size_offset.y, 1.0, 1.0f, max_offset.y, "%.0f")){
				SendUIInstruction("set_size_offset", {size_offset.x, size_offset.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_SliderFloat("###Rotation", rotation, -360, 360, "%.0f")){
				SendUIInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Color ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_ColorEdit4("###Color", color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
				SendUIInstruction("set_color", {color.x, color.y, color.z, color.a});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Keep aspect ratio ");
			ImGui_NextColumn();
			if(ImGui_Checkbox("##Keep aspect ratio", keep_aspect)){
				SendUIInstruction("set_aspect_ratio", {keep_aspect});
			}
		}else if(ui_function == ui_text){
			ImGui_SetTextBuf(text_content);
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, ImGui_GetWindowHeight() / 2.0))){
				text_content = ImGui_GetTextBuf();
				SendUIInstruction("set_content", {"\"" + text_content + "\""});
			}

			ImGui_Columns(2, false);
			float margin = 8.0;
			float option_name_width = 130.0;
			float second_column_width = ImGui_GetWindowContentRegionWidth() - option_name_width + margin;
			float slider_width = (second_column_width / 2.0) - margin;
			ImGui_SetColumnWidth(0, option_name_width);
			ImGui_SetColumnWidth(1, second_column_width);

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position ");

			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##Position X", position.x, 1.0, 0, 2560, "%.0f")){
				SendUIInstruction("set_position", {position.x, position.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){
				SendUIInstruction("set_position", {position.x, position.y});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_SliderFloat("###rotation", rotation, -360, 360, "%.0f")){
				SendUIInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
		}else if(ui_function == ui_font){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Font : " + font_name);
			ImGui_SameLine();
			if(ImGui_Button("Pick Font")){
				string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
				if(new_path != ""){
					array<string> path_split = new_path.split("/");
					for(uint i = 0; i < path_split.size(); i++){
						if(path_split[i].findFirst(".ttf") != -1){
							string new_font_name = join(path_split[i].split(".ttf"), "");
							font_name = new_font_name;
							SendUIInstruction("set_font", {font_name});
							break;
						}
					}
				}
			}

			ImGui_Columns(2, false);
			float margin = 8.0;
			float option_name_width = 130.0;
			float second_column_width = ImGui_GetWindowContentRegionWidth() - option_name_width + margin;
			float slider_width = (second_column_width / 2.0) - margin;
			ImGui_SetColumnWidth(0, option_name_width);
			ImGui_SetColumnWidth(1, second_column_width);

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Font Color ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_ColorEdit4("###Font Color", font_color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
				SendUIInstruction("set_font_color", {font_color.x, font_color.y, font_color.z, font_color.a});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Shadowed ");
			ImGui_NextColumn();
			if(ImGui_Checkbox("##Shadowed", shadowed)){
				SendUIInstruction("set_shadowed", {shadowed});
			}

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text Size ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_DragInt("###Text Size", font_size, 0.5, 1, 100)){
				SendUIInstruction("set_font_size", {font_size});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_SliderFloat("###Rotation", font_rotation, -360, 360, "%.0f")){
				SendUIInstruction("set_font_rotation", {font_rotation});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}
	}

	void StartEdit(){
		SendLevelMessage("drika_edit_ui", "true", "" + hotspot.GetID());
		AddUIElement();
		SendLevelMessage("drika_ui_set_editing", "true");
	}

	void AddUIElement(){
		if(ui_element_added){
			return;
		}
		ui_element_added = true;
		if(ui_function == ui_clear){
			SendLevelMessage("drika_ui_clear");
		}else if(ui_function == ui_image){
			JSONValue data = GetSaveData();
			data["index"] = JSONValue(index);
			SendJSONMessage("drika_ui_add_image", data);
		}else if(ui_function == ui_text){
			JSONValue data = GetSaveData();
			data["index"] = JSONValue(index);
			if(font_element is null){
				data["font_id"] = JSONValue("");
			}else{
				data["font_id"] = JSONValue(font_element.ui_element_identifier);
			}
			SendJSONMessage("drika_ui_add_text", data);
		}else if(ui_function == ui_font){
			JSONValue data = GetSaveData();
			data["index"] = JSONValue(index);
			SendJSONMessage("drika_ui_add_font", data);
		}
	}

	void SendJSONMessage(string message_name, JSONValue json_value){
		string msg = message_name + " ";

		JSON data;
		data.getRoot() = json_value;

		//Level messages strip out the " so add an extra \ to prevent this.
		string json_string = data.writeString(false);
		json_string = join(json_string.split("\""), "\\\"");

		msg += "\"" + json_string + "\"";
		level.SendMessage(msg);
	}

	void SendLevelMessage(string param_1, string param_2 = "", string param_3 = ""){
		string msg = param_1 + " ";
		msg += ui_element_identifier + " ";
		msg += param_2 + " ";
		msg += param_3 + " ";
		level.SendMessage(msg);
	}

	void SendUIInstruction(string param_1, array<string> params){
		//This message goes to the drika_controller levelscript and then to the correct ui_element.
		string msg = "drika_ui_instruction ";
		msg += ui_element_identifier + " ";
		msg += param_1 + " ";
		for(uint i = 0; i < params.size(); i++){
			msg += params[i] + " ";
		}
		level.SendMessage(msg);
	}

	void ReadUIInstruction(array<string> instruction){
		//This function comes from the ui_element on screen -> drika_controller levelscript -> drika_hotspot -> here.
		Log(warning, "Got instruction " + instruction[0]);
		if(instruction[0] == "set_position"){
			position.x = atoi(instruction[1]);
			position.y = atoi(instruction[2]);
		}else if(instruction[0] == "set_size"){
			size.x = atoi(instruction[1]);
			size.y = atoi(instruction[2]);
		}
	}

	void EditDone(){
		SendLevelMessage("drika_edit_ui", "false");
		SendLevelMessage("drika_ui_set_editing", "false");
		UpdateDisplayString();
	}

	void ApplySettings(){
		if(ui_function == ui_font){
			SendFontHasChanged();
		}
	}

	void UpdateDisplayString(){
		if(ui_function == ui_text){
			display_content = join(text_content.split("\n"), " ");
			if(display_content.length() < 35){
				display_content = "\"" + display_content + "\"";
			}else{
				display_content = "\"" + display_content.substr(0, 35) + "..." + "\"";
			}
		}
	}

	void Reset(){
		if(ui_function == ui_image || ui_function == ui_text){
			SendLevelMessage("drika_ui_remove_element");
			ui_element_added = false;
		}
	}

	void Delete(){
		SendLevelMessage("drika_ui_remove_element");
	}

	bool Trigger(){
		AddUIElement();
		return true;
	}

	void SendFontHasChanged(){
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].FontHasChanged();
		}
	}

	void FontHasChanged(){
		if(font_element is null){
			SendUIInstruction("font_changed", {""});
		}else{
			SendUIInstruction("font_changed", {font_element.ui_element_identifier});
		}
	}
}
