class DrikaDisplayText : DrikaElement{
	string display_message;
	int font_size;
	string font_path;

	DrikaDisplayText(JSONValue params = JSONValue()){
		display_message = GetJSONString(params, "display_message", "Drika Display Message");
		font_size = GetJSONInt(params, "font_size", 10);
		font_path = GetJSONString(params, "font_path", "Data/Fonts/Cella.ttf");

		drika_element_type = drika_display_text;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("display_text");
		data["display_message"] = JSONValue(display_message);
		data["font_size"] = JSONValue(font_size);
		data["font_path"] = JSONValue(font_path);
		return data;
	}

	string GetDisplayString(){
		array<string> split_message = display_message.split("\n");
		return "DisplayText " + split_message[0];
	}

	void StartSettings(){
		ImGui_SetTextBuf(display_message);
	}

	void DrawSettings(){
		ImGui_Text("Font Path : " + font_path);
		ImGui_SameLine();
		if(ImGui_Button("Set Font Path")){
			string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
			if(new_path != ""){
				font_path = new_path;
			}
		}
		ImGui_SliderInt("Font Size", font_size, 0, 100, "%.0f");
		if(ImGui_InputTextMultiline("##TEXT", vec2(-1.0, -1.0))){
			display_message = ImGui_GetTextBuf();
		}
	}

	void Reset(){
		if(triggered){
			ShowText("", font_size, font_path);
		}
	}

	bool Trigger(){
		if(!triggered){
			triggered = true;
		}
		ShowText(display_message, font_size, font_path);
		return true;
	}
}
