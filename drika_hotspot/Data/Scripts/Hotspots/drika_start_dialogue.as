class DrikaStartDialogue : DrikaElement{
	string dialogue_name;

	DrikaStartDialogue(string _dialogue_name = "drika_dialogue"){
		dialogue_name = _dialogue_name;
		drika_element_type = drika_start_dialogue;
		has_settings = true;
	}

	array<string> GetSaveParameters(){
		return {"start_dialogue", dialogue_name};
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
