enum comic_element_types { 	none,
							comic_grabber,
							comic_image,
							comic_page,
						 	comic_fade_in,
							comic_move_in,
							comic_font,
							comic_sound,
							comic_text,
							comic_wait_click};

class ComicElement{
	comic_element_types comic_element_type = none;
	ComicElement@ on_page = null;
	bool edit_mode = false;
	bool visible;
	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	ComicGrabber@ GetGrabber(string grabber_name){return null;}
	string GetSaveString(){return "";}
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void AddElement(ComicElement@ element){}
	void ShowPage(){}
	void HidePage(){}
	void Update(){}
	void SetVisible(bool _visible){
		visible = _visible;
	}
	void SetEdit(bool editing){}
}
