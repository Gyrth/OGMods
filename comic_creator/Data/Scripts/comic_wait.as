class ComicWait : ComicElement{

	float duration;

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

	void AddSettings(){
		float slider_width = ImGui_GetWindowWidth() - 80.0;
		ImGui_PushItemWidth(slider_width);

		ImGui_Text("Duration :");
		ImGui_SameLine();
		ImGui_SliderFloat("###duration", duration, 0, 1000, "%.0f");

		ImGui_PopItemWidth();
	}
}
