class ComicMusic : ComicElement{
	string path;
	ComicMusic(string _path, int _index){
		index = _index;
		path = _path;
		comic_element_type = comic_music;
		has_settings = true;
		display_color = HexColor("#a42b2b");
		element_counter += 1;
		Log(info, "AddMusic " + path);
		AddMusic(path);
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){

		}
	}
	string GetSaveString(){
		return "add_music " + path;
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
