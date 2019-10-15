class ComicWait : ComicElement{

	float duration;
	float wait_timer = 0.0;

	ComicWait(JSONValue params = JSONValue()){
		comic_element_type = comic_wait;
		duration = GetJSONFloat(params, "duration", 1.0);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("wait");
		data["duration"] = JSONValue(duration);
		return data;
	}

	string GetDisplayString(){
		return "Wait " + duration;
	}

	bool SetVisible(bool _visible){
		if(_visible){
			if(wait_timer == 0.0){
				wait_timer = duration / 1000.0;
			}else{
				wait_timer -= time_step;
				if(wait_timer <= 0.0){
					wait_timer = 0.0;
					return true;
				}
			}
		}else{
			wait_timer = 0.0;
		}
		return false;
	}

	void DrawSettings(){
		float slider_width = ImGui_GetWindowWidth() - 80.0;
		ImGui_PushItemWidth(slider_width);

		ImGui_Text("Duration :");
		ImGui_SameLine();
		ImGui_SliderFloat("###duration", duration, 0, 1000, "%.0f");

		ImGui_PopItemWidth();
	}
}
