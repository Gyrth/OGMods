class ComicPage : ComicElement{
	array<ComicElement@> elements;

	ComicPage(JSONValue params = JSONValue()){
		comic_element_type = comic_page;
		display_color = HexColor("#7b5c85");
	}

	void ClearTarget(){
		elements.resize(0);
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
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(false);
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("new_page");
		return data;
	}

	string GetDisplayString(){
		return "NewPage";
	}
}
