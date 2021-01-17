enum drika_ui_element_types	{
								none,
								drika_ui_image,
								drika_ui_text,
								drika_ui_font
							};

vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);

class DrikaUIElement{
	drika_ui_element_types drika_ui_element_type = none;
	bool visible;
	string ui_element_identifier;
	bool editing;
	int index = 0;
	string json_string;

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

class FadeOut{
	string name;
	string identifier;
	float timer;
	float duration;
	IMElement @target;
	IMTweenType tween_type;
	bool preview;

	FadeOut(string _name, string _identifier, float _duration, int _tween_type, IMElement@ _target, bool _preview){
		name = _name;
		identifier = _identifier;
		duration = _duration / 1000.0f;
		tween_type = IMTweenType(_tween_type);
		preview = _preview;
		@target = @_target;
	}

	bool Update(){
		timer += time_step;

		if(timer >= duration){
			timer = duration;
			target.setAlpha(1.0f - ApplyTween((timer / duration), tween_type));
			//Don't remove the UIELement when DHS is editing and previewing the transitions.
			if(!preview){
				level.SendMessage("drika_ui_remove_element " + identifier);
			}
			return true;
		}

		target.setAlpha(1.0f - ApplyTween((timer / duration), tween_type));
		return false;
	}

	void Remove(){
		target.setAlpha(1.0f);
	}
}
