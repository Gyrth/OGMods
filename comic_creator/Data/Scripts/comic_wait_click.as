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

	bool SetVisible(bool _visible){
		if(GetInputPressed(0, "mouse0")){
			if(CanPlayForward()){
				play_direction = 1;
				clicked = true;
				return false;
			}else{
				StorageSetInt32("progress_" + comic_path, 0);
				if(environment_state == in_game){
					CloseComic();
					SetPaused(false);
				}else{
					imGUI.receiveMessage(IMMessage("Back"));
				}
			}
		}else if(GetInputPressed(0, "grab")){
			if(CanPlayBackward()){
				play_direction = -1;
				clicked = true;
				return false;
			}
		}

		if(clicked){
			clicked = false;
			return true;
		}

		return false;
	}

	string GetDisplayString(){
		return "WaitClick";
	}
}
