enum comic_element_types { 	none,
							comic_grabber,
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
							comic_song};

array<string> comic_element_names = {	"None",
										"Grabber",
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
										"Song"
									};

array<string> sorted_element_names;

array<vec4> display_colors =	{
									vec4(255),
	                                vec4(0, 0, 0, 255),
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
									vec4(164, 43, 43, 255)
								};

vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);

class ComicElement{
	comic_element_types comic_element_type = none;
	bool edit_mode = false;
	bool visible;
	bool has_settings = false;
	vec4 display_color = vec4(1.0);
	int index = -1;

	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	ComicGrabber@ GetGrabber(string grabber_name){return null;}
	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void ShowPage(){}
	void HidePage(){}
	void Update(){}
	void StartEdit(){}
	void SetEdit(bool editing){}
	void SetProgress(int _progress){}
	void AddSettings(){}
	void EditDone(){}
	void SetCurrent(bool _current){}
	void Delete(){}
	void SetIndex(int _index){
		index = _index;
	}
	void SetVisible(bool _visible){
		visible = _visible;
	}
	void SetTarget(ComicElement@ element){}
	void ClearTarget(){}
	JSONValue GetSaveData(){
		return JSONValue();
	}
	void PostInit(){}
}
