class DrikaDisplayImage : DrikaElement{
	string image_path;
	vec4 tint;
	float scale;

	DrikaDisplayImage(string _image_path = "Data/Textures/drika_hotspot.png", string _tint = "1,1,1,1", string _scale = "1.0"){
		image_path = _image_path;
		tint = StringToVec4(_tint);
		scale = atof(_scale);
		drika_element_type = drika_display_image;
		has_settings = true;
	}

	string GetSaveString(){
		return "display_image" + param_delimiter + image_path + param_delimiter + Vec4ToString(tint) + param_delimiter + scale;
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
