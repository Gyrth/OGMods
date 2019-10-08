class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	string name;
	vec2 offset;
	int tween_type;

	ComicMoveIn(JSONValue params = JSONValue()){
		comic_element_type = comic_move_in;
		has_settings = true;
		display_color = HexColor("#987150");

		duration = GetJSONInt(params, "duration", 1000);
		offset = GetJSONVec2(params, "offset", vec2(100.0, 100.0));
		tween_type = GetJSONInt(params, "tween_type", linearTween);
	}

	void PostInit(){
		name = "movein" + index;
	}

	void SetVisible(bool _visible){
		visible = _visible;
		if(@target != null){
			if(visible){
				IMMoveIn new_move(duration, offset, IMTweenType(tween_type));
				target.AddUpdateBehavior(new_move, name);
			}else{
				target.RemoveUpdateBehavior(name);
			}
		}
	}

	void SetTarget(ComicElement@ element){
		@target = element;
	}

	void ClearTarget(){
		@target = null;
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

	void AddSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
		ImGui_DragFloat2("Offset", offset);
		ImGui_Combo("Tween Type", tween_type, tween_types, tween_types.size());
	}
}
