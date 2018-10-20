class ComicSound : ComicElement{
	string path;
	ComicSound(string _path){
		comic_element_type = comic_sound;
		path = _path;
	}
	void SetCurrent(bool _current){
		if(_current){
			PlaySound(path);
		}
	}
	string GetSaveString(){
		return "play_sound " + path;
	}
}
