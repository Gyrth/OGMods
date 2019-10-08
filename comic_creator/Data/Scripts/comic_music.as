class ComicMusic : ComicElement{
	string path;

	ComicMusic(JSONValue params = JSONValue()){
		comic_element_type = comic_music;

		path = GetJSONString(params, "path", "Data/Music/lugaru.xml");
		AddMusic(path);
		has_settings = true;
	}

	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){

		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("add_music");
		data["path"] = JSONValue(path);
		return data;
	}

	string GetDisplayString(){
		return "AddMusic " + path;
	}

	void AddSettings(){
		ImGui_Text("Current Music : ");
		ImGui_Text(path);
		if(ImGui_Button("Set Music XML")){
			string new_path = GetUserPickedReadPath("xml", "Data/Music");
			if(new_path != ""){
				RemoveMusic(path);
				path = new_path;
				AddMusic(path);
			}
		}
	}
}
