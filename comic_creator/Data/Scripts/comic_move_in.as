class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	string name;
	int x_offset;
	int y_offset;
	ComicMoveIn(int _duration, vec2 _offset, int _index){
		index = _index;
		comic_element_type = comic_move_in;
		has_settings = true;
		display_color = HexColor("#987150");

		duration = _duration;
		x_offset = int(_offset.x);
		y_offset = int(_offset.y);
		name = "movein" + element_counter;
		element_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(@target != null){
			if(visible){
				IMMoveIn new_move(duration, vec2(x_offset, y_offset), inSineTween);
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
		return "move_in " + duration + " " + x_offset + " " + y_offset;
	}
	string GetDisplayString(){
		return "MoveIn " + duration + " " + x_offset + " " + y_offset;
	}
	void AddSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
		ImGui_DragInt("X Offset", x_offset, 1.0, -10000, 10000);
		ImGui_DragInt("Y Offset", y_offset, 1.0, -10000, 10000);
	}
}
