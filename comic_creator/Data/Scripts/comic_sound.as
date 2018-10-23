class ComicSound : ComicElement{
	string path;
	ComicSound(string _path, int _index){
		index = _index;
		comic_element_type = comic_sound;
		has_settings = true;
		path = _path;
		display_color = HexColor("#916342");
	}
	void SetCurrent(bool _current){
		if(creator_state == editing && _current){
			PlaySound(path);
		}
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible && creator_state == playing && play_direction == 1){
			PlaySound(path);
		}
	}
	string GetSaveString(){
		return "play_sound " + path;
	}
	string GetDisplayString(){
		return "PlaySound " + path;
	}
	void AddSettings(){
		ImGui_Text("Current Sound : ");
		ImGui_Text(path);
		if(ImGui_Button("Set Sound")){
			string new_path = GetUserPickedReadPath("wav", "Data/Sounds");
			if(new_path != ""){
				path = new_path;
			}
		}
	}
}
