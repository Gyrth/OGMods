class ComicPage : ComicElement{
	array<ComicElement@> elements;
	ComicPage(){
		comic_element_type = comic_page;
	}
	void AddElement(ComicElement@ element){
		elements.insertLast(element);
	}
	void ShowPage(){
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(true);
		}
	}
	void HidePage(){
		Log(info, "hidepage");
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(false);
		}
	}
	string GetSaveString(){
		return "new_page";
	}
	string GetDisplayString(){
		return "New Page";
	}
}
