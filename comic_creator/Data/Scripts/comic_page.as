class ComicPage : ComicElement{
	array<ComicElement@> elements;
	ComicPage@ previous_page;

	ComicPage(JSONValue params = JSONValue()){
		comic_element_type = comic_page;
	}

	void RefreshTarget(){
		elements.resize(0);
		@previous_page = cast<ComicPage>(GetPreviousElementOfType({comic_page}, index));

		// A page needs to get all the comic elements untill it finds different page.
		for(uint j = index + 1; j < comic_indexes.size(); j++){
			if(comic_elements[comic_indexes[j]].comic_element_type == comic_page){
				// Found a new page so adding no more elements to this page.
				break;
			}else{
				elements.insertLast(comic_elements[comic_indexes[j]]);
			}
		}
	}

	bool SetVisible(bool _visible){
		if(_visible && !visible && play_direction == 1 && @previous_page != null){
			previous_page.HidePage();
		}else if(!_visible && visible && play_direction == -1 && @previous_page != null){
			previous_page.ShowPage();
		}
		visible = _visible;
		return true;
	}

	void HidePage(){
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(false);
		}
	}

	void ShowPage(){
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(true);
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
