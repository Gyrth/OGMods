class ComicCrawlIn : ComicElement{
	ComicText@ target = null;
	int duration;
	float timer = 0.0;
	float text_sound_timer = 0.0;
	bool skip = false;

	ComicCrawlIn(JSONValue params = JSONValue()){
		comic_element_type = comic_crawl_in;
		duration = GetJSONInt(params, "duration", 1000);
		has_settings = true;
	}

	void SelectAgain(){
		timer = 0.0;
	}

	void ParseInput(bool left_mouse, bool right_mouse){
		if(left_mouse){
			if(CanPlayForward()){
				play_direction = 1;
				skip = true;
			}else{
				skip = true;
			}
		}else if(right_mouse){
			if(CanPlayBackward()){
				play_direction = -1;
				skip = true;
			}
		}
	}

	bool SetVisible(bool _visible){
		if(skip){
			skip = false;
			target.SetProgress(100.0);
			timer = 0.0;
			return true;
		}else if(_visible && (creator_state == playing && play_direction == 1 || (creator_state == editing && edit_mode))){
			if(@target != null && timer < duration){
				timer += time_step * 1000.0;
				target.SetProgress(int(timer * 100.0 / duration));
				if(use_text_sounds){
					text_sound_timer -= time_step;
					if(text_sound_timer <= 0.0){
						text_sound_timer = 0.15;
						PlayTextSound(text_sound_variant);
					}
				}
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
