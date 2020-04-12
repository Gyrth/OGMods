enum billboard_update_types{ 	billboard_persistent = 0,
								billboard_fade = 1
							};

enum billboard_types{	billboard_image = 0,
						billboard_text = 1
					};

class DrikaBillboard : DrikaElement{
	string image_path;
	array<int> billboard_ids;
	float image_size = 1.0;
	vec4 image_color = vec4(1.0);
	string billboard_text_string;
	float overbright;

	int current_billboard_update_type;
	billboard_update_types billboard_update_type;
	array<string> billboard_update_type_choices = {"Persistent", "Fade"};

	int current_billboard_type;
	billboard_types billboard_type;
	array<string> billboard_type_choices = {"Image", "Text"};

	DrikaBillboard(JSONValue params = JSONValue()){
		placeholder.Load(params);
		placeholder.name = "Billboard Helper";
		placeholder.default_scale = vec3(1.0);

		image_path = GetJSONString(params, "image_path", "Data/Textures/ui/ogicon.png");
		image_color = GetJSONVec4(params, "image_color", vec4(1));
		image_size = GetJSONFloat(params, "image_size", 1.0f);
		overbright = GetJSONFloat(params, "overbright", 0.0f);
		billboard_text_string = GetJSONString(params, "billboard_text_string", "Example billboard text.");

		billboard_type = billboard_types(GetJSONInt(params, "billboard_type", billboard_image));
		current_billboard_type = billboard_type;

		billboard_update_type = billboard_update_types(GetJSONInt(params, "billboard_update_type", billboard_persistent));
		current_billboard_update_type = billboard_update_type;

		drika_element_type = drika_billboard;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["image_path"] = JSONValue(image_path);
		data["image_size"] = JSONValue(image_size);
		data["image_color"] = JSONValue(JSONarrayValue);
		data["image_color"].append(image_color.x);
		data["image_color"].append(image_color.y);
		data["image_color"].append(image_color.z);
		data["image_color"].append(image_color.a);
		data["overbright"] = JSONValue(overbright);
		data["billboard_type"] = JSONValue(billboard_type);
		data["billboard_update_type"] = JSONValue(billboard_update_type);
		data["billboard_text_string"] = JSONValue(billboard_text_string);
		placeholder.Save(data);
		return data;
	}

	void PostInit(){
		placeholder.Retrieve();
	}

	void Delete(){
		Reset();
		placeholder.Remove();
	}

	void Reset(){
		for(uint i = 0; i < billboard_ids.size(); i++){
			DebugDrawRemove(billboard_ids[i]);
		}
		billboard_ids.resize(0);
	}

	string GetDisplayString(){
		if(billboard_type == billboard_image){
			return "Billboard " + image_path;
		}else if(billboard_type == billboard_text){
			return "Billboard " + billboard_text_string;
		}
		return "Billboard";
	}

	void DrawSettings(){

		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Billboard Type");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Billboard Type", current_billboard_type, billboard_type_choices, billboard_type_choices.size())){
			billboard_type = billboard_types(current_billboard_type);
			Reset();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Billboard Update Type");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Billboard Update Type", current_billboard_update_type, billboard_update_type_choices, billboard_update_type_choices.size())){
			billboard_update_type = billboard_update_types(current_billboard_update_type);
			Reset();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(billboard_type == billboard_image){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Image Path");
			ImGui_NextColumn();
			if(ImGui_Button("Set Image Path")){
				string new_path = GetUserPickedReadPath("png", "Data/Images");
				if(new_path != ""){
					image_path = new_path;
				}
			}
			ImGui_PopItemWidth();
			ImGui_SameLine();
			ImGui_Text(image_path);
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Image Size");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderFloat("##Image Size", image_size, 0.0f, 10.0f, "%.2f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Tint");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_ColorEdit4("##Tint", image_color);
			ImGui_PopItemWidth();
			ImGui_NextColumn();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Overbright");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderFloat("##Overbright", overbright, 0.0f, 10.0f, "%.1f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(billboard_type == billboard_text){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Text");
			ImGui_NextColumn();
			ImGui_SetTextBuf(billboard_text_string);
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
				billboard_text_string = ImGui_GetTextBuf();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}
	}

	void DrawEditing(){
		if(placeholder.Exists()){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			if(billboard_type == billboard_image){
				float multiplier = 1.0 + overbright;
				vec4 combined_color = vec4(image_color.x * multiplier, image_color.y * multiplier, image_color.z * multiplier, image_color.a);
				DebugDrawBillboard(image_path, placeholder.GetTranslation(), image_size, combined_color, _delete_on_draw);
			}else if(billboard_type == billboard_text){
				DebugDrawText(placeholder.GetTranslation(), billboard_text_string, 1.0, false, _delete_on_draw);
			}
		}else{
			placeholder.Create();
			StartEdit();
		}
	}

	void StartEdit(){
		DrikaElement::StartEdit();
		Reset();
	}

	bool Trigger(){
		if(placeholder.Exists()){
			CreateBillboard();
			return true;
		}else{
			placeholder.Create();
			return false;
		}
	}

	void CreateBillboard(){
		Reset();
		int draw_method = _persistent;
		if(billboard_update_type == billboard_persistent){
			draw_method = _persistent;
		}else if(billboard_update_type == billboard_fade){
			draw_method = _fade;
		}

		if(billboard_type == billboard_image){
			float multiplier = 1.0 + overbright;
			vec4 combined_color = vec4(image_color.x * multiplier, image_color.y * multiplier, image_color.z * multiplier, image_color.a);
			billboard_ids.insertLast(DebugDrawBillboard(image_path, placeholder.GetTranslation(), image_size, combined_color, draw_method));
		}else if(billboard_type == billboard_text){
			billboard_ids.insertLast(DebugDrawText(placeholder.GetTranslation(), billboard_text_string, 1.0, false, draw_method));
		}
	}
}
