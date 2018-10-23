class ComicCrawlIn : ComicElement{
	ComicElement@ target = null;
	int duration;
	float timer = 0.0;
	ComicCrawlIn(int _duration, int _index){
		index = _index;
		comic_element_type = comic_crawl_in;
		has_settings = true;
		duration = _duration;
		display_color = HexColor("#4e887c");
	}
	void SetCurrent(bool _current){
		if(_current){
			timer = 0.0;
		}else{
			target.SetProgress(100);
		}
	}
	void SetTarget(ComicElement@ element){
		@target = element;
	}
	void Update(){
		if(timer < duration){
			timer += time_step * 1000.0;
			target.SetProgress(int(timer * 100.0 / duration));
		}
	}
	string GetSaveString(){
		return "crawl_in " + duration;
	}
	string GetDisplayString(){
		return "CrawlIn " + duration;
	}
	void AddSettings(){
		if(ImGui_DragInt("Duration", duration, 1.0, 1, 10000)){
			timer = 0.0;
		}
	}
}
