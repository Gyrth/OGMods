class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	vec2 offset;
	string name;
	ComicMoveIn(ComicElement@ _target, int _duration, vec2 _offset){
		comic_element_type = comic_move_in;
		has_settings = true;
		display_color = HexColor("#987150");

		duration = _duration;
		offset = _offset;
		@target = _target;
		name = "movein" + update_behavior_counter;
		update_behavior_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			IMMoveIn new_move(duration, offset, inSineTween);
			target.AddUpdateBehavior(new_move, name);
		}else{
			target.RemoveUpdateBehavior(name);
		}
	}
	string GetSaveString(){
		return "move_in " + duration + " " + offset.x + " " + offset.y;
	}
	string GetDisplayString(){
		return "MoveIn " + duration;
	}
	void AddSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
	}
}
