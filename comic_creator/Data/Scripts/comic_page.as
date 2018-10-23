class ComicPage : ComicElement{
	array<ComicElement@> elements;
	ComicPage(int _index){
		index = _index;
		comic_element_type = comic_page;
		display_color = HexColor("#7b5c85");
	}
	void SetTarget(ComicElement@ element){
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
		return "NewPage";
	}
}
