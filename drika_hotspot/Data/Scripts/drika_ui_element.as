enum drika_ui_element_types	{
								none,
								drika_ui_image,
								drika_ui_text
							};

vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);

class DrikaUIElement{
	drika_ui_element_types drika_ui_element_type = none;
	bool visible;
	string ui_element_identifier;
	bool editing;

	void AddPosition(ivec2 added_positon){}
	void AddSize(ivec2 added_size, int direction_x, int direction_y){}
	DrikaUIGrabber@ GetGrabber(string grabber_name){return null;}
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void SetEditing(bool editing){}
	void Delete(){}
	void SetIndex(int _index){}
	bool SetVisible(bool _visible){
		visible = _visible;
		return visible;
	}
	void SelectAgain(){}
	void RefreshTarget(){}
	void ParseInput(bool left_mouse, bool right_mouse){}
	void ReadUIInstruction(array<string> instruction){}
}
