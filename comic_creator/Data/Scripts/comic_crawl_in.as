class ComicCrawlIn : ComicElement{
	ComicText@ target = null;
	int duration;
	float timer = 0.0;

	ComicCrawlIn(JSONValue params = JSONValue()){
		comic_element_type = comic_crawl_in;
		duration = GetJSONInt(params, "duration", 1000);
		has_settings = true;
	}

	void SelectAgain(){
		timer = 0.0;
	}

	bool SetVisible(bool _visible){
		if(_visible && (creator_state == playing && play_direction == 1 || (creator_state == editing && edit_mode))){
			if(@target != null && timer < duration){
				timer += time_step * 1000.0;
				target.SetProgress(int(timer * 100.0 / duration));
				return false;
			}
		}else{
			target.SetProgress(100.0);
			timer = 0.0;
		}
		return true;
	}

	void SetEditing(bool editing){
		if(!editing && @target != null){
			target.SetProgress(100);
		}
		timer = 0.0;
		edit_mode = editing;
	}

	void RefreshTarget(){
		@target = cast<ComicText>(GetPreviousElementOfType({comic_text}, index));
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

	void DrawSettings(){
		if(ImGui_DragInt("Duration", duration, 1.0, 1, 10000)){
			timer = 0.0;
		}
	}
}
