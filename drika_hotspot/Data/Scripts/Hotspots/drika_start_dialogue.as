class DrikaStartDialogue : DrikaElement{
	string dialogue_name;

	DrikaStartDialogue(JSONValue params = JSONValue()){
		dialogue_name = GetJSONString(params, "dialogue_name", "drika_dialogue");

		drika_element_type = drika_start_dialogue;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("start_dialogue");
		data["dialogue_name"] = JSONValue(dialogue_name);
		return data;
	}

	string GetDisplayString(){
		return "StartDialogue " + dialogue_name;
	}

	void DrawSettings(){
		ImGui_InputText("Dialogue Name", dialogue_name, 64);
	}

	bool Trigger(){
		level.SendMessage("start_dialogue \"" + dialogue_name + "\"");
		return true;
	}
}
