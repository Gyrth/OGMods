class ComicWaitClick : ComicElement{
	ComicWaitClick(){
		comic_element_type = comic_wait_click;
	}
	string GetSaveString(){
		return "wait_click";
	}

	string GetDisplayString(){
		return "Wait Click";
	}
}
