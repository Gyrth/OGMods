class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	vec2 offset;
	string name;
	ComicMoveIn(int _duration, vec2 _offset, int _index){
		index = _index;
		comic_element_type = comic_move_in;
		has_settings = true;
		display_color = HexColor("#987150");

		duration = _duration;
		offset = _offset;
		name = "movein" + element_counter;
		element_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(@target != null){	
			if(visible){
				IMMoveIn new_move(duration, offset, inSineTween);
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
