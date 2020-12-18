array<string> tween_types = {
								"linearTween",
							    "inQuadTween",
							    "outQuadTween",
							    "inOutQuadTween",
							    "outInQuadTween",
							    "inCubicTween",
							    "outCubicTween",
							    "inOutCubicTween",
							    "outInCubicTween",
							    "inQuartTween",
							    "outQuartTween",
							    "inOutQuartTween",
							    "outInQuartTween",
							    "inQuintTween",
							    "outQuintTween",
							    "inOutQuintTween",
							    "outInQuintTween",
							    "inSineTween",
							    "outSineTween",
							    "inOutSineTween",
							    "outInSineTween",
							    "inExpoTween",
							    "outExpoTween",
							    "inOutExpoTween",
							    "outInExpoTween",
							    "inCircTween",
							    "outCircTween",
							    "inOutCircTween",
							    "outInCircTween",
							    "outBounceTween",
							    "inBounceTween",
							    "inOutBounceTween",
    							"outInBounceTween"
							};

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
	string ui_element_identifier;
	bool ui_element_added = false;
	string font_name;
	int font_size;
	vec4 font_color;
	bool shadowed;
	DrikaUserInterface@ font_element = null;
	array<DrikaUserInterface@> text_elements;

	bool use_fade_in;
	int fade_in_duration;
	int fade_in_tween_type;

	bool use_move_in;
	int move_in_duration;
	int move_in_tween_type;
	ivec2 move_in_offset;

	array<string> ui_function_names =	{
											"Clear",
											"Image",
											"Text",
											"Font"
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

		use_fade_in = GetJSONBool(params, "use_fade_in", false);
		fade_in_duration = GetJSONInt(params, "fade_in_duration", 1000);
		fade_in_tween_type = GetJSONInt(params, "fade_in_tween_type", 0);

		use_move_in = GetJSONBool(params, "use_move_in", false);
		move_in_duration = GetJSONInt(params, "move_in_duration", 1000);
		move_in_tween_type = GetJSONInt(params, "move_in_tween_type", 0);
		move_in_offset = GetJSONIVec2(params, "move_in_offset", ivec2(100, 100));

		text_content = GetJSONString(params, "text_content", "Example Text");
		ui_element_identifier = GetUniqueID();

		drika_element_type = drika_user_interface;
		has_settings = true;
	}

	JSONValue GetCheckpointData(){
		JSONValue data;
		data["ui_element_added"] = ui_element_added;
		return data;
	}

	void SetCheckpointData(JSONValue data = JSONValue()){
		//The current ui elements are handled by the levelscript (drika_controller) so no need to add them here.
		ui_element_added = data["ui_element_added"].asBool();
	}

	void ReorderDone(){
		UpdateExternalResource();
		SendUIInstruction("set_z_order", {index});
	}

	void UpdateExternalResource(){
		if(ui_function == ui_text){
			DrikaUserInterface@ new_font_element = GetPreviousUIElementOfType({ui_font});
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
					FontHasChanged();
				}
			}
		}
	}

	void SendAddUpdateBehaviour(){
		if(use_fade_in){
			SendUIInstruction("add_update_behaviour", {"fade_in", fade_in_duration, fade_in_tween_type, "fade_" + ui_element_identifier});
		}
		if(use_move_in){
			SendUIInstruction("add_update_behaviour", {"move_in", move_in_duration, move_in_offset.x, move_in_offset.y, move_in_tween_type, "move_" + ui_element_identifier});
		}
	}

	void SendRemoveUpdatebehaviour(){
		SendUIInstruction("remove_update_behaviour", {"fade_" + ui_element_identifier});
		SendUIInstruction("remove_update_behaviour", {"move_" + ui_element_identifier});
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

	DrikaUserInterface@ GetPreviousUIElementOfType(array<ui_functions> function_types){
		for(int i = index - 1; i > -1; i--){
			if(drika_elements[drika_indexes[i]].drika_element_type == drika_user_interface){
				DrikaUserInterface@ found_ui_element = cast<DrikaUserInterface@>(drika_elements[drika_indexes[i]]);
				if(function_types.find(found_ui_element.ui_function) != -1){
					return found_ui_element;
				}
			}
		}
		return null;
	}

	array<DrikaUserInterface@> GetAllUIElements(){
		array<DrikaUserInterface@> collection;
		for(uint i = 0; i < drika_elements.size(); i++){
			if(drika_elements[i].drika_element_type == drika_user_interface){
				DrikaUserInterface@ found_ui_element = cast<DrikaUserInterface@>(drika_elements[i]);
				collection.insertLast(found_ui_element);
			}
		}
		return collection;
	}

	void PostInit(){
		UpdateExternalResource();
		//The font needs to be available from the start so that during editing the text are using the correct font.
		if(ui_function == ui_font){
			AddUIElement();
		}
		SendUIInstruction("set_z_order", {index});
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
			data["use_fade_in"] = JSONValue(use_fade_in);
			if(use_fade_in){
				data["fade_in_duration"] = JSONValue(fade_in_duration);
				data["fade_in_tween_type"] = JSONValue(fade_in_tween_type);
			}
			data["use_move_in"] = JSONValue(use_move_in);
			if(use_move_in){
				data["move_in_duration"] = JSONValue(move_in_duration);
				data["move_in_tween_type"] = JSONValue(move_in_tween_type);
			}
		}else if(ui_function == ui_text){
			data["rotation"] = JSONValue(rotation);
			data["position"] = JSONValue(JSONarrayValue);
			data["position"].append(position.x);
			data["position"].append(position.y);
			data["text_content"] = JSONValue(text_content);
			data["use_fade_in"] = JSONValue(use_fade_in);
			if(use_fade_in){
				data["fade_in_duration"] = JSONValue(fade_in_duration);
				data["fade_in_tween_type"] = JSONValue(fade_in_tween_type);
			}
			data["use_move_in"] = JSONValue(use_move_in);
			if(use_move_in){
				data["move_in_duration"] = JSONValue(move_in_duration);
				data["move_in_tween_type"] = JSONValue(move_in_tween_type);
				data["move_in_offset"] = JSONValue(JSONarrayValue);
				data["move_in_offset"].append(move_in_offset.x);
				data["move_in_offset"].append(move_in_offset.y);
			}
		}else if(ui_function == ui_font){
			data["font_name"] = JSONValue(font_name);
			data["font_size"] = JSONValue(font_size);
			data["font_color"] = JSONValue(JSONarrayValue);
			data["font_color"].append(font_color.x);
			data["font_color"].append(font_color.y);
			data["font_color"].append(font_color.z);
			data["font_color"].append(font_color.a);
			data["shadowed"] = JSONValue(shadowed);
		}
		return data;
	}

	string GetDisplayString(){
		string display_string = "UserInterface ";
		display_string += ui_function_names[ui_function] + " ";
		if(ui_function == ui_text){
			display_string += "\"" + text_content + "\"";
		}else if(ui_function == ui_font){
			display_string += font_name + " " + font_size;
		}

		return display_string;
	}

	void DrawSettings(){

		float option_name_width = 140.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("UI Function");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		float slider_width = second_column_width / 2.0;
		float margin = 3.0;
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##UI Function", current_ui_function, ui_function_names, ui_function_names.size())){
			if(current_ui_function != ui_function){
				SendRemoveUpdatebehaviour();
				RemoveUIElement();
				ui_function = ui_functions(current_ui_function);
				StartEdit();
				ReorderElements();
			}
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(ui_function == ui_image){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Image Path");
			ImGui_NextColumn();
			if(ImGui_Button("Set Image Path")){
				string new_path = GetUserPickedReadPath("png", "Data/Images");
				if(new_path != ""){
					new_path = new_path;
					//Remove the Data/ in the beginning of the path because IMImage starts in Data/.
					array<string> split_path = new_path.split("/");
					split_path.removeAt(0);
					image_path = join(split_path, "/");
					SendUIInstruction("set_image_path", {image_path});
				}
			}
			ImGui_SameLine();
			ImGui_Text(image_path);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position");
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
			ImGui_Text("Size");
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
			ImGui_Text("Position Offset");
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
			ImGui_Text("Size Offset");
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
			ImGui_Text("Rotation");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("###Rotation", rotation, -360, 360, "%.0f")){
				SendUIInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Color");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_ColorEdit4("###Color", color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
				SendUIInstruction("set_color", {color.x, color.y, color.z, color.a});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Keep aspect ratio");
			ImGui_NextColumn();
			if(ImGui_Checkbox("##Keep aspect ratio", keep_aspect)){
				SendUIInstruction("set_aspect_ratio", {keep_aspect});
			}
			ImGui_NextColumn();
		}else if(ui_function == ui_text){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text");
			ImGui_NextColumn();
			ImGui_SetTextBuf(text_content);

			if(ImGui_IsRootWindowOrAnyChildFocused() && !ImGui_IsAnyItemActive() && !ImGui_IsMouseClicked(0)){
				ImGui_SetKeyboardFocusHere(0);
			}

			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, ImGui_GetWindowHeight() / 3.0), ImGuiInputTextFlags_AllowTabInput)){
				text_content = ImGui_GetTextBuf();
				SendUIInstruction("set_content", {"\"" + text_content + "\""});
			}
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position");

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
			ImGui_Text("Rotation");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_SliderFloat("###rotation", rotation, -360, 360, "%.0f")){
				SendUIInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(ui_function == ui_font){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Font");
			ImGui_NextColumn();
			if(ImGui_Button("Pick Font")){
				string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
				if(new_path != ""){
					array<string> path_split = new_path.split("/");
					string file_name = path_split[path_split.size() - 1];
					string file_extension = file_name.substr(file_name.length() - 3, 3);

					if(file_extension == "ttf" || file_extension == "TTF"){
						font_name = file_name.substr(0, file_name.length() - 4);
						SendUIInstruction("set_font", {font_name});
					}else{
						DisplayError("Font issue", "Only ttf font files are supported.");
					}
				}
			}
			ImGui_SameLine();
			ImGui_Text(font_name);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Font Color");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_ColorEdit4("###Font Color", font_color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
				SendUIInstruction("set_font_color", {font_color.x, font_color.y, font_color.z, font_color.a});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Shadowed");
			ImGui_NextColumn();
			if(ImGui_Checkbox("##Shadowed", shadowed)){
				SendUIInstruction("set_shadowed", {shadowed});
			}

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text Size");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_DragInt("###Text Size", font_size, 0.5, 1, 100)){
				SendUIInstruction("set_font_size", {font_size});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}

		if(ui_function == ui_image || ui_function == ui_text){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Fade In");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Checkbox("##Use Fade In", use_fade_in)){
				SendRemoveUpdatebehaviour();
				SendAddUpdateBehaviour();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			if(use_fade_in){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Fade In Duration");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_DragInt("##Fade Duration", fade_in_duration, 1.0, 1, 10000)){
					SendRemoveUpdatebehaviour();
					SendAddUpdateBehaviour();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Fade In Tween");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_Combo("##Fade Tween Type", fade_in_tween_type, tween_types, tween_types.size())){
					SendRemoveUpdatebehaviour();
					SendAddUpdateBehaviour();
				}

				ImGui_PopItemWidth();
				ImGui_NextColumn();
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Use Move In");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Checkbox("##Use Move In", use_move_in)){
				SendRemoveUpdatebehaviour();
				SendAddUpdateBehaviour();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			if(use_move_in){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Move In Duration");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_DragInt("##Duration", move_in_duration, 1.0, 1, 10000)){
					SendRemoveUpdatebehaviour();
					SendAddUpdateBehaviour();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Move In Tween");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_Combo("##Tween Type", move_in_tween_type, tween_types, tween_types.size())){
					SendRemoveUpdatebehaviour();
					SendAddUpdateBehaviour();
				}

				ImGui_PopItemWidth();
				ImGui_NextColumn();

				ImGui_AlignTextToFramePadding();
				ImGui_Text("Move In Offset");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				if(ImGui_DragInt2("##Move In Offset", move_in_offset)){
					SendRemoveUpdatebehaviour();
					SendAddUpdateBehaviour();
				}
				ImGui_PopItemWidth();
				ImGui_NextColumn();
			}
		}
	}

	void StartEdit(){
		SendLevelMessage("drika_edit_ui", {true, hotspot.GetID(), show_grid, ui_snap_scale});
		AddUIElement();
		SendLevelMessage("drika_ui_set_editing", {true});
	}

	void AddUIElement(){
		if(ui_function == ui_clear){
			array<DrikaUserInterface@> target_elements = GetAllUIElements();
			for(uint i = 0; i < target_elements.size(); i++){
				//Make sure the fonts are still available when cleaing the screen.
				if(target_elements[i].ui_function == ui_image || target_elements[i].ui_function == ui_text){
					target_elements[i].RemoveUIElement();
				}
			}
		}else if(ui_function == ui_image){
			if(!ui_element_added){
				JSONValue data = GetSaveData();
				data["type"] = JSONValue(ui_image);
				data["index"] = JSONValue(index);
				SendJSONMessage("drika_ui_add_element", data);
			}
			SendRemoveUpdatebehaviour();
			SendAddUpdateBehaviour();
			ui_element_added = true;
		}else if(ui_function == ui_text){
			if(!ui_element_added){
				JSONValue data = GetSaveData();
				data["type"] = JSONValue(ui_text);
				data["index"] = JSONValue(index);
				if(font_element is null){
					data["font_id"] = JSONValue("");
				}else{
					data["font_id"] = JSONValue(font_element.ui_element_identifier);
				}
				SendJSONMessage("drika_ui_add_element", data);
			}
			ui_element_added = true;
			SendRemoveUpdatebehaviour();
			SendAddUpdateBehaviour();
		}else if(ui_function == ui_font){
			if(!ui_element_added){
				ui_element_added = true;
				JSONValue data = GetSaveData();
				data["index"] = JSONValue(index);
				data["type"] = JSONValue(ui_font);
				SendJSONMessage("drika_ui_add_element", data);
			}
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

	void SendLevelMessage(string param_1, array<string> params = {}){
		//This message goes to the drika_controller levelscript and then to the correct ui_element.
		string msg = param_1 + " ";
		msg += ui_element_identifier + " ";
		for(uint i = 0; i < params.size(); i++){
			msg += params[i] + " ";
		}
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
		/* Log(warning, "Got instruction " + instruction[0]); */
		if(instruction[0] == "set_position"){
			position.x = atoi(instruction[1]);
			position.y = atoi(instruction[2]);
		}else if(instruction[0] == "set_size"){
			size.x = atoi(instruction[1]);
			size.y = atoi(instruction[2]);
		}
	}

	void EditDone(){
		SendLevelMessage("drika_edit_ui", {false});
		SendLevelMessage("drika_ui_set_editing", {false});
	}

	void ApplySettings(){
		if(ui_function == ui_font){
			SendFontHasChanged();
		}
	}

	void Reset(){
		RemoveUIElement();
	}

	void RemoveUIElement(){
		if(ui_element_added){
			if(ui_function == ui_image || ui_function == ui_text || ui_function == ui_font){
				SendLevelMessage("drika_ui_remove_element");
				ui_element_added = false;
			}
		}
	}

	void Delete(){
		RemoveUIElement();
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
