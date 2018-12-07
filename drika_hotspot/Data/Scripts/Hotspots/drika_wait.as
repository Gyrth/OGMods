class DrikaWait : DrikaElement{
	float timer;
	int duration;
	DrikaWait(string _duration = "1000"){
		duration = atoi(_duration);
		timer = duration / 1000.0;
		drika_element_type = drika_wait;
		has_settings = true;
	}
	string GetSaveString(){
		return "wait" + param_delimiter + duration;
	}

	string GetDisplayString(){
		return "Wait " + duration;
	}
	void AddSettings(){
		ImGui_Text("Wait in ms : ");
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
	}
	bool Trigger(){
		if(timer <= 0.0){
			Reset();
			return true;
		}else{
			timer -= time_step;
			return false;
		}
	}
	void Reset(){
		timer = duration / 1000.0;
	}
}
