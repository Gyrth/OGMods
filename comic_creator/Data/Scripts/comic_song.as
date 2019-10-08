class ComicSong : ComicElement{
	string name;

	ComicSong(JSONValue params = JSONValue()){
		comic_element_type = comic_music;
		name = GetJSONString(params, "name", "lugaru_menu");

		has_settings = true;
	}

	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			PlaySong(name);
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("play_song");
		data["name"] = JSONValue(name);
		return data;
	}

	string GetDisplayString(){
		return "PlaySong " + name;
	}

	void AddSettings(){
		ImGui_InputText("Song", name, 32);
	}

	void EditDone(){
		PlaySong(name);
	}
}
