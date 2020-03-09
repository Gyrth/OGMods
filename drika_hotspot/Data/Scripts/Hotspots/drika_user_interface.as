enum ui_functions	{
						ui_clear = 0,
						ui_image = 1,
						ui_text = 2
					}

class DrikaUserInterface : DrikaElement{
	ui_functions ui_function;
	int current_ui_function;
	string image_path;
	vec2 size;
	vec2 position;
	float rotation;
	vec4 color;
	bool keep_aspect;
	vec2 position_offset;
	vec2 size_offset;
	array<string> content;
	string joined_content;
	string display_content;
	vec2 max_offset;
	string ui_element_identifier;

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
		position = GetJSONVec2(params, "position", vec2(ui_snap_scale, ui_snap_scale));
		color = GetJSONVec4(params, "color", vec4(1.0, 1.0, 1.0, 1.0));
		keep_aspect = GetJSONBool(params, "keep_aspect", false);
		size = GetJSONVec2(params, "size", vec2(720 - (720 % ui_snap_scale), 255 - (255 % ui_snap_scale)));
		position_offset = GetJSONVec2(params, "position_offset", vec2(0.0, 0.0));
		size_offset = GetJSONVec2(params, "size_offset", vec2(0.0, 0.0));

		string original_content = GetJSONString(params, "text_content", "Example Text");
		content = original_content.split("\\n");
		joined_content = join(content, "\n");
		display_content = join(content, " ");
		ui_element_identifier = GetUniqueID();
		Log(warning, "Unique ID " + ui_element_identifier);

		drika_element_type = drika_user_interface;
		has_settings = true;
	}

	void ReadMaxOffsets(){
		/* max_offset = image.getSizeX(); */
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["ui_function"] = JSONValue(ui_function);

		if(ui_function == ui_clear){

		}else if(ui_function == ui_image){


		}else if(ui_function == ui_text){

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
			ui_function = ui_functions(current_ui_function);
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

			float slider_width = ImGui_GetWindowWidth() / 2.0 - 40.0;
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position ");

			ImGui_SameLine();
			ImGui_PushItemWidth(slider_width);

			if(ImGui_DragFloat("##Position X", position.x, 1.0, 0, 2560, "%.0f")){

			}

			ImGui_SameLine();
			if(ImGui_DragFloat("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){

			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size ");
			ImGui_SameLine();
			if(ImGui_DragFloat("##size_x", size.x, 1.0, 1.0f, 1000, "%.0f")){

			}
			ImGui_SameLine();
			if(ImGui_DragFloat("##size_y", size.y, 1.0, 1.0f, 1000, "%.0f")){

			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position Offset ");
			ImGui_SameLine();
			if(ImGui_DragFloat("##position_offset_x", position_offset.x, 1.0, 0.0f, max_offset.x, "%.0f")){

			}
			ImGui_SameLine();
			if(ImGui_DragFloat("##position_offset_y", position_offset.y, 1.0, 0.0f, max_offset.y, "%.0f")){

			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Size Offset ");
			ImGui_SameLine();
			if(ImGui_DragFloat("##size_offset_x", size_offset.x, 1.0, 1.0f, max_offset.x, "%.0f")){

			}
			ImGui_SameLine();
			if(ImGui_DragFloat("##size_offset_y", size_offset.y, 1.0, 1.0f, max_offset.y, "%.0f")){

			}

			ImGui_PopItemWidth();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_SameLine();
			if(ImGui_SliderFloat("###Rotation", rotation, -360, 360, "%.0f")){

			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Color ");
			ImGui_SameLine();
			if(ImGui_ColorEdit4("###Color", color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){

			}

			ImGui_Checkbox("Keep aspect ratio", keep_aspect);
		}else if(ui_function == ui_text){
			float slider_width = ImGui_GetWindowWidth() / 2.0 - 40.0;
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Position ");

			ImGui_SameLine();
			ImGui_PushItemWidth(slider_width);

			if(ImGui_DragFloat("##Position X", position.x, 1.0, 0, 2560, "%.0f")){

			}

			ImGui_SameLine();
			if(ImGui_DragFloat("##Position Y", position.y, 1.0, 0, 1440, "%.0f")){

			}

			ImGui_PopItemWidth();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Rotation ");
			ImGui_SameLine();
			if(ImGui_SliderFloat("###rotation", rotation, -360, 360, "%.0f")){

			}

			ImGui_SetTextBuf(joined_content);
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				content = ImGui_GetTextBuf().split("\n");
			}
		}
	}

	void StartEdit(){
		level.SendMessage("drika_edit_ui true " + hotspot.GetID());
		TriggerUIElement();
	}

	void TriggerUIElement(){
		if(ui_function == ui_clear){
			level.SendMessage("drika_ui_clear");
		}else if(ui_function == ui_image){
			string msg = "drika_ui_add_image ";
			msg += ui_element_identifier + " ";
			msg += image_path + " ";
			msg += position.x + " ";
			msg += position.y + " ";
			msg += size.x + " ";
			msg += size.y + " ";
			msg += rotation + " ";
			msg += color.x + " ";
			msg += color.y + " ";
			msg += color.z + " ";
			msg += color.a + " ";
			msg += keep_aspect + " ";
			msg += position_offset.x + " ";
			msg += position_offset.y + " ";
			msg += size_offset.x + " ";
			msg += size_offset.y + " ";
			level.SendMessage(msg);
		}else if(ui_function == ui_text){

			level.SendMessage("drika_edit_ui true " + hotspot.GetID());
		}
	}

	void EditDone(){
		level.SendMessage("drika_edit_ui false");
	}

	bool Trigger(){
		TriggerUIElement();
		return true;
	}
}
