class ComicFadeIn : ComicElement{
	ComicElement@ target;
	int duration;
	string name;
	ComicFadeIn(ComicElement@ _target, int _duration){
		comic_element_type = comic_fade_in;

		duration = _duration;
		@target = _target;
		name = "fadein" + update_behavior_counter;
		update_behavior_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			IMFadeIn new_fade(duration, inSineTween);
			target.AddUpdateBehavior(new_fade, name);
		}else{
			target.RemoveUpdateBehavior(name);
		}
	}
	string GetSaveString(){
		return "fade_in " + duration;
	}
	string GetDisplayString(){
		return "Fade In " + duration;
	}
}
