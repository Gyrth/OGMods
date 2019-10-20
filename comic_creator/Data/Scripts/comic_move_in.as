class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	string name;
	vec2 offset;
	int tween_type;

	ComicMoveIn(JSONValue params = JSONValue()){
		comic_element_type = comic_move_in;
		has_settings = true;

		duration = GetJSONInt(params, "duration", 1000);
		offset = GetJSONVec2(params, "offset", vec2(100.0, 100.0));
		tween_type = GetJSONInt(params, "tween_type", linearTween);
		name = imGUI.getUniqueName("movein");
	}

	void SelectAgain(){
		Preview();
	}

	void Preview(){
		if(@target != null){
			IMMoveIn new_move(duration, offset, IMTweenType(tween_type));
			target.RemoveUpdateBehavior(name);
			target.AddUpdateBehavior(new_move, name);
		}
	}

	bool SetVisible(bool _visible){
		if(@target != null){
			if(!visible){
				target.RemoveUpdateBehavior(name);
				IMMoveIn new_move(duration, offset, IMTweenType(tween_type));
				target.AddUpdateBehavior(new_move, name);
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
		data["function_name"] = JSONValue("move_in");
		data["duration"] = JSONValue(duration);
		data["offset"] = JSONValue(JSONarrayValue);
		data["offset"].append(offset.x);
		data["offset"].append(offset.y);
		data["tween_type"] = JSONValue(tween_type);
		return data;
	}

	string GetDisplayString(){
		return "MoveIn " + duration + " " + offset.x + " " + offset.y;
	}

	void DrawSettings(){
		if(ImGui_DragInt("Duration", duration, 1.0, 1, 10000)){
			Preview();
		}

		if(ImGui_DragFloat2("Offset", offset)){
			Preview();
		}

		if(ImGui_Combo("Tween Type", tween_type, tween_types, tween_types.size())){
			Preview();
		}
	}
}
