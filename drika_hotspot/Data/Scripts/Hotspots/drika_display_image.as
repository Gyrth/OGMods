class DrikaDisplayImage : DrikaElement{
	string image_path;
	vec4 tint;
	float scale;
	bool clear_image = false;

	DrikaDisplayImage(JSONValue params = JSONValue()){
		image_path = GetJSONString(params, "image_path", "Data/Textures/drika_hotspot.png");
		tint = GetJSONVec4(params, "tint", vec4(1.0f));
		scale = GetJSONFloat(params, "scale", 1.0);
		clear_image = GetJSONBool(params, "clear_image", false);

		drika_element_type = drika_display_image;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("display_image");
		data["image_path"] = JSONValue(image_path);
		data["scale"] = JSONValue(scale);
		data["clear_image"] = JSONValue(clear_image);
		data["tint"] = JSONValue(JSONarrayValue);
		data["tint"].append(tint.x);
		data["tint"].append(tint.y);
		data["tint"].append(tint.z);
		data["tint"].append(tint.a);
		return data;
	}

	string GetDisplayString(){
		if(clear_image){
			return "DisplayImage clear";
		}else{
			return "DisplayImage " + image_path;
		}
	}

	void DrawSettings(){
		ImGui_Checkbox("Clear Image", clear_image);
		if(!clear_image){
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
			ImGui_ColorEdit4("Color", tint);
		}
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
		if(clear_image){
			ShowImage("", tint, scale);
		}else{
			ShowImage(image_path, tint, scale);
		}
		return true;
	}
}
