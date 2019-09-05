class AnimationGroup{
	string name;
	array<string> animations;
	AnimationGroup(string _name){
		name = _name;
	}
	void AddAnimation(string _animation){
		animations.insertLast(_animation);
	}
}
