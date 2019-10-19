class ComicFadeIn : ComicElement{
	ComicElement@ target;
	int duration;
	float new_duration;
	string name;
	int tween_type;

	ComicFadeIn(JSONValue params = JSONValue()){
		comic_element_type = comic_fade_in;

		duration = GetJSONInt(params, "duration", 1000);
		tween_type = GetJSONInt(params, "tween_type", linearTween);
		has_settings = true;
		name = imGUI.getUniqueName("fadein");
	}

	void SelectAgain(){
		Preview();
	}

	void Preview(){
		if(@target != null){
			IMFadeIn new_fade(duration, IMTweenType(tween_type));
			target.RemoveUpdateBehavior(name);
			target.AddUpdateBehavior(new_fade, name);
		}
	}

	bool SetVisible(bool _visible){
		if(@target != null){
			if(!visible){
				IMFadeIn new_fade(duration, IMTweenType(tween_type));
				target.AddUpdateBehavior(new_fade, name);
			}else if(_visible == false){
				target.RemoveUpdateBehavior(name);
			}
		}
		visible = _visible;
		return visible;
	}

	void SetEditing(bool editing){
		if(editing){
			Preview();
		}
	}

	void RefreshTarget(){
		@target = GetPreviousElementOfType({comic_text, comic_image}, index);
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("fade_in");
		data["duration"] = JSONValue(duration);
		data["tween_type"] = JSONValue(tween_type);
		return data;
	}

	string GetDisplayString(){
		return "FadeIn " + duration;
	}

	void DrawSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
		if(ImGui_Combo("Tween Type", tween_type, tween_types, tween_types.size())){
			Preview();
		}
	}
}
