class ComicCrawlIn : ComicElement{
	ComicElement@ target = null;
	int duration;
	float timer = 0.0;

	ComicCrawlIn(JSONValue params = JSONValue()){
		comic_element_type = comic_crawl_in;
		duration = GetJSONInt(params, "duration", 1000);
		has_settings = true;
	}

	void SetCurrent(bool _current){
		if(@target != null){
			if(_current){
				timer = 0.0;
			}else{
				target.SetProgress(100);
			}
		}
	}

	void SelectAgain(){
		if(@target != null){
			timer = 0.0;
		}
	}

	void ClearTarget(){
		@target = null;
	}

	void SetTarget(ComicElement@ element){
		@target = element;
	}

	void Update(){
		if(@target != null && timer < duration){
			timer += time_step * 1000.0;
			target.SetProgress(int(timer * 100.0 / duration));
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("crawl_in");
		data["duration"] = JSONValue(duration);
		return data;
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
