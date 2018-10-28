class ComicSong : ComicElement{
	string name;
	ComicSong(string _name, int _index){
		index = _index;
		name = _name;
		comic_element_type = comic_music;
		has_settings = true;
		display_color = HexColor("#a42b2b");
		element_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			PlaySong(name);
		}
	}
	string GetSaveString(){
		return "play_song " + name;
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
