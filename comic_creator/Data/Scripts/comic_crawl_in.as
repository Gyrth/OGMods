class ComicCrawlIn : ComicElement{
	ComicElement@ target = null;
	float duration;
	float timer = 0.0;
	ComicCrawlIn(ComicElement@ _target, int _duration){
		comic_element_type = comic_crawl_in;
		@target = _target;
		duration = _duration / 1000.0;
	}
	void SetCurrent(bool _current){
		if(_current){
			timer = 0.0;
		}else{
			Log(info, "progress 100" );
			target.SetProgress(100);
		}
	}
	void Update(){
		if(timer < duration){
			timer += time_step;
			target.SetProgress(int(timer * 100.0 / duration));
		}
	}
	string GetSaveString(){
		return "crawl_in " + int(duration * 1000);
	}
}
