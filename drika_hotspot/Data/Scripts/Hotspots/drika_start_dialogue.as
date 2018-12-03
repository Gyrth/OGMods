class DrikaStartDialogue : DrikaElement{
	string dialogue_name;

	DrikaStartDialogue(string _dialogue_name = "drika_dialogue"){
		dialogue_name = _dialogue_name;
		drika_element_type = drika_start_dialogue;
		display_color = vec4(110, 94, 180, 255);
		has_settings = true;
	}

	string GetSaveString(){
		return "start_dialogue " + dialogue_name;
	}

	string GetDisplayString(){
		return "DrikaStartDialogue " + dialogue_name;
	}

	void AddSettings(){
		ImGui_InputText("Dialogue Name", dialogue_name, 64);
	}

	bool Trigger(){
		bool player_in_valid_state = false;
		for(int i = 0, len = GetNumCharacters(); i < len; i++){
			MovementObject@ mo = ReadCharacter(i);
			if(mo.controlled && mo.QueryIntFunction("int CanPlayDialogue()") == 1){
				player_in_valid_state = true;
			}
		}
		if(player_in_valid_state){
			level.SendMessage("start_dialogue \"" + dialogue_name + "\"");
			return true;
		}else{
			return false;
		}
	}
}
