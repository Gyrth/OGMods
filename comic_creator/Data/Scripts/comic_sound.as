class ComicSound : ComicElement{
	string path;
	ComicSound(string _path){
		comic_element_type = comic_sound;
		has_settings = true;
		path = _path;
	}
	void SetCurrent(bool _current){
		if(creator_state == playing && play_direction == 1){
			PlaySound(path);
		}else if(creator_state == editing && _current){
			PlaySound(path);
		}
	}
	void SetVisible(bool _visible){
		visible = _visible;
	}
	string GetSaveString(){
		return "play_sound " + path;
	}
	string GetDisplayString(){
		return "PlaySound " + path;
	}
	void AddSettings(){
		ImGui_Text("Current Sound : " + path);
		if(ImGui_Button("Set Sound")){
			string new_path = GetUserPickedReadPath("wav", "Data/Sounds");
			if(new_path != ""){
				path = new_path;
			}
		}
	}
}
