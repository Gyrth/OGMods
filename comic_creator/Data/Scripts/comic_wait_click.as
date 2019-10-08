class ComicWaitClick : ComicElement{

	ComicWaitClick(JSONValue params = JSONValue()){
		comic_element_type = comic_wait_click;
		display_color = HexColor("#7b828a");
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("wait_click");
		return data;
	}

	string GetDisplayString(){
		return "WaitClick";
	}
}
