class ComicSound : ComicElement{
	string path;
	ComicSound(string _path){
		path = _path;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			PlaySound(path);
		}
	}
	string GetSaveString(){
		return "play_sound " + path;
	}
}
