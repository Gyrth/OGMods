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
		data["function_name"] = JSONValue("slow_motion");
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
		ImGui_Checkbox("Wait untill finished", wait);
		ImGui_SliderFloat("Target Time Scale", target_time_scale, 0.0f, 1.0f, "%.2f");
		ImGui_SliderFloat("Duration", duration, 0.0f, 10.0f, "%.2f");
		ImGui_SliderFloat("Delay", delay, 0.0f, 10.0f, "%.2f");
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
