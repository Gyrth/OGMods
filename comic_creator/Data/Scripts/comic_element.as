enum comic_element_types	{
								none,
								comic_image,
								comic_page,
							 	comic_fade_in,
								comic_move_in,
								comic_font,
								comic_sound,
								comic_text,
								comic_wait_click,
								comic_crawl_in,
								comic_music,
								comic_song,
								comic_wait
							};

array<string> comic_element_names =	{
										"None",
										"Image",
										"Page",
										"Fade In",
										"Move In",
										"Font",
										"Sound",
										"Text",
										"Wait For Click",
										"Crawl In",
										"Music",
										"Song",
										"Wait"
									};

array<string> sorted_element_names;

array<vec4> display_colors =	{
									vec4(255),
	                                vec4(110, 94, 180, 255),
									vec4(123, 92, 133, 255),
									vec4(88, 122, 147, 255),
									vec4(152, 113, 80, 255),
									vec4(144, 143, 64, 255),
									vec4(164, 43, 43, 255),
									vec4(85, 131, 102, 255),
									vec4(123, 130, 138, 255),
									vec4(78, 136, 124, 255),
									vec4(164, 43, 43, 255),
									vec4(164, 43, 43, 255),
									vec4(166, 176, 187, 255)
								};

vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);

class ComicElement{
	comic_element_types comic_element_type = none;
	bool edit_mode = false;
	bool visible;
	bool has_settings = false;
	int index = -1;

	void PostInit(){}
	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	Grabber@ GetGrabber(string grabber_name){return null;}
	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void SetEditing(bool editing){}
	void DrawSettings(){}
	void EditDone(){}
	void Delete(){}
	void SetIndex(int _index){
		index = _index;
	}
	bool SetVisible(bool _visible){
		visible = _visible;
		return visible;
	}
	JSONValue GetSaveData(){
		return JSONValue();
	}
	vec4 GetDisplayColor(){
		return display_colors[comic_element_type];
	}
	void SelectAgain(){}
	void RefreshTarget(){}
}
