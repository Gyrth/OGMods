class DrikaSlowMotion : DrikaElement{
	float target_time_scale;
	float duration;
	float delay;
	float timer;
	bool wait;

	DrikaSlowMotion(JSONValue params = JSONValue()){
		target_time_scale = GetJSONFloat(params, "target_time_scale", 0.5);
		duration = GetJSONFloat(params, "duration", 2.0);
		delay = GetJSONFloat(params, "delay", 0.25);
		wait = GetJSONBool(params, "wait", true);
		SetTimer();

		drika_element_type = drika_slow_motion;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["target_time_scale"] = JSONValue(target_time_scale);
		data["duration"] = JSONValue(duration);
		data["delay"] = JSONValue(delay);
		data["wait"] = JSONValue(wait);
		return data;
	}

	string GetDisplayString(){
		return "SlowMotion " + duration;
	}

	void ApplySettings(){
		SetTimer();
	}

	void SetTimer(){
		timer = (delay + duration) * target_time_scale;
	}

	void DrawSettings(){
		ImGui_Checkbox("Wait until finished", wait);
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Target Time Scale");
		ImGui_SameLine();
		ImGui_SliderFloat("##Target Time Scale", target_time_scale, 0.0f, 1.0f, "%.2f");
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Duration");
		ImGui_SameLine();
		ImGui_SliderFloat("##Duration", duration, 0.0f, 10.0f, "%.2f");
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Delay");
		ImGui_SameLine();
		ImGui_SliderFloat("##Delay", delay, 0.0f, 10.0f, "%.2f");
	}

	void Reset(){
		triggered = false;
	}

	bool Trigger(){
		if(!triggered){
			triggered = true;
			TimedSlowMotion(target_time_scale, duration, delay);
		}
		if(timer <= 0.0 || !wait){
			triggered = false;
			SetTimer();
			return true;
		}else{
			timer -= time_step;
			return false;
		}
	}
}
