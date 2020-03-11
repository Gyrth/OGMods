enum ui_functions	{
						ui_clear = 0,
						ui_image = 1,
						ui_text = 2
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
	string joined_content;
	string text_content;
	string display_content;
	string ui_element_identifier;
	bool ui_element_added = false;

	array<string> ui_function_names =	{
											"Clear",
											"Image",
											"Text"
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

		text_content = GetJSONString(params, "text_content", "Example Text");
		content = text_content.split("\\n");
		joined_content = join(content, "\n");
		display_content = join(content, " ");
		ui_element_identifier = GetUniqueID();
		Log(warning, "Unique ID " + ui_element_identifier);

		drika_element_type = drika_user_interface;
		has_settings = true;
	}

	void PostInit(){

	}

	void ReadMaxOffsets(){
		/* max_offset = image.getSizeX(); */
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
		}
		return data;
	}

	string GetDisplayString(){
		return "UserInterface ";
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
					image_path = new_path;
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
				SendInstruction("set_position", {position.x, position.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){
				SendInstruction("set_position", {position.x, position.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##size_x", size.x, 1.0, 1.0f, 1000, "%.0f")){
				SendInstruction("set_size", {size.x, size.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##size_y", size.y, 1.0, 1.0f, 1000, "%.0f")){
				SendInstruction("set_size", {size.x, size.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position Offset ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##position_offset_x", position_offset.x, 1.0, 0.0f, max_offset.x, "%.0f")){
				SendInstruction("set_position_offset", {position_offset.x, position_offset.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##position_offset_y", position_offset.y, 1.0, 0.0f, max_offset.y, "%.0f")){
				SendInstruction("set_position_offset", {position_offset.x, position_offset.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size Offset ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(slider_width);
			if(ImGui_DragInt("##size_offset_x", size_offset.x, 1.0, 1.0f, max_offset.x, "%.0f")){
				SendInstruction("set_size_offset", {size_offset.x, size_offset.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##size_offset_y", size_offset.y, 1.0, 1.0f, max_offset.y, "%.0f")){
				SendInstruction("set_size_offset", {size_offset.x, size_offset.y});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_SliderFloat("###Rotation", rotation, -360, 360, "%.0f")){
				SendInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Color ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_ColorEdit4("###Color", color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
				SendInstruction("set_color", {color.x, color.y, color.z, color.a});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Keep aspect ratio ");
			ImGui_NextColumn();
			if(ImGui_Checkbox("##Keep aspect ratio", keep_aspect)){
				SendInstruction("set_aspect_ratio", {keep_aspect});
			}
		}else if(ui_function == ui_text){
			ImGui_NextColumn();
			ImGui_SetTextBuf(text_content);
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, ImGui_GetWindowHeight() / 2.0))){
				text_content = ImGui_GetTextBuf();
				SendInstruction("set_content", {"\"" + text_content + "\""});
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
				SendInstruction("set_position", {position.x, position.y});
			}
			ImGui_SameLine();
			if(ImGui_DragInt("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){
				SendInstruction("set_position", {position.x, position.y});
			}
			ImGui_PopItemWidth();

			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width - margin);
			if(ImGui_SliderFloat("###rotation", rotation, -360, 360, "%.0f")){
				SendInstruction("set_rotation", {rotation});
			}
			ImGui_PopItemWidth();
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
			SendJSONMessage("drika_ui_add_image", GetSaveData());
		}else if(ui_function == ui_text){
			SendJSONMessage("drika_ui_add_text", GetSaveData());
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

	void SendInstruction(string param_1, array<string> params){
		string msg = "drika_ui_instruction ";
		msg += ui_element_identifier + " ";
		msg += param_1 + " ";
		for(uint i = 0; i < params.size(); i++){
			msg += params[i] + " ";
		}
		level.SendMessage(msg);
	}

	void EditDone(){
		SendLevelMessage("drika_edit_ui", "false");
		SendLevelMessage("drika_ui_set_editing", "false");
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
}
