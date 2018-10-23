class ComicFadeIn : ComicElement{
	ComicElement@ target;
	int duration;
	float new_duration;
	string name;
	ComicFadeIn(int _duration, int _index){
		index = _index;
		comic_element_type = comic_fade_in;
		has_settings = true;
		display_color = HexColor("#587a93");

		duration = _duration;
		name = "fadein" + element_counter;
		element_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(@target != null){
			if(visible){
				IMFadeIn new_fade(duration, inSineTween);
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
	string GetSaveString(){
		return "fade_in " + duration;
	}
	string GetDisplayString(){
		return "FadeIn " + duration;
	}
	void AddSettings(){
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
	}
}
