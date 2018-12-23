class DrikaDisplayImage : DrikaElement{
	string image_path;
	vec4 tint;
	float scale;

	DrikaDisplayImage(JSONValue params = JSONValue()){
		image_path = GetJSONString(params, "image_path", "Data/Textures/drika_hotspot.png");
		tint = GetJSONVec4(params, "tint", vec4(1.0f));
		scale = GetJSONFloat(params, "scale", 1.0);

		drika_element_type = drika_display_image;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("display_image");
		data["image_path"] = JSONValue(image_path);
		data["scale"] = JSONValue(scale);
		data["tint"] = JSONValue(JSONarrayValue);
		data["tint"].append(tint.x);
		data["tint"].append(tint.y);
		data["tint"].append(tint.z);
		data["tint"].append(tint.a);
		return data;
	}

	string GetDisplayString(){
		return "DisplayImage " + image_path;
	}

	void DrawSettings(){
		ImGui_Text("Image Path : ");
		ImGui_SameLine();
		ImGui_Text(image_path);
		if(ImGui_Button("Set Image Path")){
			string new_path = GetUserPickedReadPath("png", "Data/Textures");
			if(new_path != ""){
				image_path = new_path;
			}
		}
		ImGui_SliderFloat("Scale", scale, 0.0f, 100.0f, "%.1f");
		ImGui_ColorPicker4("Color", tint, 0);
	}

	void Reset(){
		if(triggered){
			ShowImage("", tint, scale);
		}
	}

	bool Trigger(){
		if(!triggered){
			triggered = true;
		}
		ShowImage(image_path, tint, scale);
		return true;
	}
}
