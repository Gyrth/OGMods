enum billboard_types{ 	billboard_persistent = 0,
						billboard_fade = 1
					};

class DrikaBillboard : DrikaElement{
	string image_path;
	int billboard_id = -1;
	float image_size = 1.0;
	vec4 image_color = vec4(1.0);
	int current_billboard_type;
	billboard_types billboard_type;
	array<string> billboard_type_choices = {"Persistent", "Fade"};

	DrikaBillboard(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "Billboard Helper";
		image_path = GetJSONString(params, "image_path", "Data/Textures/ui/ogicon.png");
		image_color = GetJSONVec4(params, "image_color", vec4(1));
		image_size = GetJSONFloat(params, "image_size", 1.0f);
		billboard_type = billboard_types(GetJSONInt(params, "billboard_type", 0));
		current_billboard_type = billboard_type;

		drika_element_type = drika_billboard;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("billboard");
		data["image_path"] = JSONValue(image_path);
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["image_size"] = JSONValue(image_size);
		data["image_color"] = JSONValue(JSONarrayValue);
		data["image_color"].append(image_color.x);
		data["image_color"].append(image_color.y);
		data["image_color"].append(image_color.z);
		data["image_color"].append(image_color.a);
		data["billboard_type"] = JSONValue(billboard_type);
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void Delete(){
		Reset();
	}

	void Reset(){
		if(billboard_id != -1){
			DebugDrawRemove(billboard_id);
		}
		billboard_id = -1;
	}

	string GetDisplayString(){
		return "Billboard " + image_path;
	}

	void DrawSettings(){
		ImGui_Text("Image Path : " + image_path);
		ImGui_SameLine();
		if(ImGui_Button("Set Image Path")){
			string new_path = GetUserPickedReadPath("png", "Data/Images");
			if(new_path != ""){
				image_path = new_path;
			}
		}
		ImGui_SliderFloat("Image Size", image_size, 0.0f, 10.0f, "%.2f");
		if(ImGui_Combo("Billboard Type", current_billboard_type, billboard_type_choices, billboard_type_choices.size())){
			billboard_type = billboard_types(current_billboard_type);
		}
		ImGui_ColorEdit4("Color", image_color);
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DebugDrawBillboard(image_path, placeholder.GetTranslation(), image_size, image_color, _delete_on_draw);
		}else{
			CreatePlaceholder();
			StartEdit();
		}
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			CreateBillboard();
			return true;
		}else{
			CreatePlaceholder();
			return false;
		}
	}

	void CreateBillboard(){
		Reset();
		int draw_method = _persistent;
		if(billboard_type == billboard_persistent){
			draw_method = _persistent;
		}else if(billboard_type == billboard_fade){
			draw_method = _fade;
		}
		billboard_id = DebugDrawBillboard(image_path, placeholder.GetTranslation(), image_size, image_color, draw_method);
	}
}
