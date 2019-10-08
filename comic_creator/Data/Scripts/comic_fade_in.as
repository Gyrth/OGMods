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
	}

	void PostInit(){
		name = "fadein" + index;
	}

	void SetVisible(bool _visible){
		visible = _visible;
		if(@target != null){
			if(visible){
				IMFadeIn new_fade(duration, IMTweenType(tween_type));
				target.AddUpdateBehavior(new_fade, name);
			}else{
				target.RemoveUpdateBehavior(name);
			}
		}
	}

	void ClearTarget(){
		@target = null;
	}

	void SetTarget(ComicElement@ element){
		@target = element;
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

	void AddSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
		ImGui_Combo("Tween Type", tween_type, tween_types, tween_types.size());
	}
}
