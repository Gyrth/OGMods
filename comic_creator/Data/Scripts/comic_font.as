class ComicFont : ComicElement{
	string font_name;
	int font_size;
	vec4 font_color;
	bool shadowed;
	array<ComicText@> texts;
	vec4 new_color;
	FontSetup font("edosz", 75, HexColor("#CCCCCC"), true);

	ComicFont(JSONValue params = JSONValue()){
		comic_element_type = comic_font;

		font_name = GetJSONString(params, "font_name", "edosz");
		font_size = GetJSONInt(params, "font_size", 75);
		font_color = GetJSONVec4(params, "font_color", vec4(1.0, 1.0, 1.0, 1.0));
		shadowed = GetJSONBool(params, "shadowed", true);

		font.fontName = font_name;
		font.size = font_size;
		font.color = font_color;
		font.shadowed = shadowed;

		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_font");
		data["font_name"] = JSONValue(font_name);
		data["font_color"] = JSONValue(JSONarrayValue);
		data["font_color"].append(font_color.x);
		data["font_color"].append(font_color.y);
		data["font_color"].append(font_color.z);
		data["shadowed"] = JSONValue(shadowed);
		return data;
	}

	string GetDisplayString(){
		return "SetFont " + font_name + " " + font_size + (shadowed ? " shadowed" : "");
	}

	void ClearTarget(){
		texts.resize(0);
	}

	void SetTarget(ComicElement@ element){
		ComicText@ new_text = cast<ComicText>(element);
		@new_text.comic_font = this;
		/* new_text.SetNewText();
		new_text.UpdateContent(); */
		texts.insertLast(new_text);
	}

	void AddSettings(){
		ImGui_Text("Font : " + font_name);
		ImGui_SameLine();
		if(ImGui_Button("Pick Font")){
			string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
			if(new_path != ""){
				array<string> path_split = new_path.split("/");
				for(uint i = 0; i < path_split.size(); i++){
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
}
