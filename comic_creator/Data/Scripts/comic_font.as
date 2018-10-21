class ComicFont : ComicElement{
	string font_name;
	int font_size;
	vec4 font_color;
	bool shadowed;
	array<ComicText@> texts;

	vec4 new_color;

	FontSetup font("edosz", 75, HexColor("#CCCCCC"), true);
	ComicFont(string _font_name, int _font_size, vec3 _font_color, bool _shadowed){
		comic_element_type = comic_font;
		has_settings = true;

		font_name = _font_name;
		font_size = _font_size;
		font_color = vec4(_font_color / 255.0, 1.0);
		shadowed = _shadowed;
		Log(info, font_color.x + " " + font_color.y + " " + font_color.z);

		font.fontName = _font_name;
		font.size = _font_size;
		font.color = font_color;
		font.shadowed = _shadowed;
	}
	string GetSaveString(){
		return "set_font " + font_name + " " + font_size + " " + int(font_color.x * 255) + " " + int(font_color.y * 255) + " " + int(font_color.z * 255) + " " + (shadowed ? "true" : "false");
	}
	string GetDisplayString(){
		return "SetFont " + font_name + " " + font_size + (shadowed ? " shadowed" : "");
	}

	void AddSettings(){
		ImGui_Text("Current Font : " + font_name);
		ImGui_SameLine();
		if(ImGui_Button("Pick Font")){
			string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
			if(new_path != ""){
				array<string> path_split = new_path.split("/");
				for(uint i = 0; i < path_split.size(); i++){
					Log(info, path_split[i]);
					if(path_split[i].findFirst(".ttf") != -1){
						string new_font_name = join(path_split[i].split(".ttf"), "");
						font_name = new_font_name;
						font.fontName = new_font_name;
						break;
					}
				}
			}
		}
		if(ImGui_ColorEdit4("Font Color", font_color, ImGuiColorEditFlags_HEX | ImGuiColorEditFlags_Uint8)){
			font.color = font_color;
		}
		if(ImGui_Checkbox("Shadowed", shadowed)){
			font.shadowed = shadowed;
		}
		if(ImGui_DragInt("Text Size", font_size, 0.5, 1, 100)){
			font.size = font_size;
		}
	}

	void EditDone(){
		for(uint i = 0; i < texts.size(); i++){
			// Updating the text also refreshes the font.
			texts[i].SetNewText();
			texts[i].UpdateContent();
		}
	}
}
