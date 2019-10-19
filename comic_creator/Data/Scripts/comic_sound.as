class ComicSound : ComicElement{
	string path;

	ComicSound(JSONValue params = JSONValue()){
		comic_element_type = comic_sound;
		path = GetJSONString(params, "path", "Data/Sounds/FistImpact_1.wav");

		has_settings = true;
	}

	void SelectAgain(){
		PlaySound(path);
	}

	bool SetVisible(bool _visible){
		if(!visible && !(creator_state == editing && play_direction == -1)){
			PlaySound(path);
		}

		visible = _visible;
		return visible;
	}

	void SetEditing(bool editing){
		if(editing){
			PlaySound(path);
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("play_sound");
		data["path"] = JSONValue(path);
		return data;
	}

	string GetDisplayString(){
		return "PlaySound " + path;
	}

	void DrawSettings(){
		ImGui_Text("Current Sound : ");
		ImGui_Text(path);
		if(ImGui_Button("Set Sound")){
			string new_path = GetUserPickedReadPath("wav", "Data/Sounds");
			if(new_path != ""){
				path = new_path;
				PlaySound(path);
			}
		}
	}
}
