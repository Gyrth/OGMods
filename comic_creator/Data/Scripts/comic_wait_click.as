class ComicWaitClick : ComicElement{
	ComicWaitClick(int _index){
		index = _index;
		comic_element_type = comic_wait_click;
		display_color = HexColor("#7b828a");
	}
	string GetSaveString(){
		return "wait_click";
	}

	string GetDisplayString(){
		return "WaitClick";
	}
}
