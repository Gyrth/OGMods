class ComicWaitClick : ComicElement{

	bool clicked = false;

	ComicWaitClick(JSONValue params = JSONValue()){
		comic_element_type = comic_wait_click;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("wait_click");
		return data;
	}

	void ParseInput(bool left_mouse, bool right_mouse){
		if(left_mouse){
			if(CanPlayForward()){
				play_direction = 1;
				clicked = true;
			}else{
				StorageSetInt32("progress_" + comic_path, 0);
				if(environment_state == in_game){
					CloseComic();
					SetPaused(false);
				}else{
					this_ui.SendCallback("back");
				}
			}
		}else if(right_mouse){
			if(CanPlayBackward()){
				play_direction = -1;
				clicked = true;
			}
		}
	}

	bool SetVisible(bool _visible){
		if(clicked){
			clicked = false;
			return true;
		}else{
			return false;
		}
	}

	string GetDisplayString(){
		return "WaitClick";
	}
}
