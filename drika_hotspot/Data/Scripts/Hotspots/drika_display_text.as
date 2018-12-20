class DrikaDisplayText : DrikaElement{
	string display_message;

	DrikaDisplayText(string _display_message = "Drika Display Message"){
		display_message = _display_message;
		drika_element_type = drika_display_text;
		has_settings = true;
	}

	string GetSaveString(){
		return "display_text" + param_delimiter + display_message;
	}

	string GetDisplayString(){
		return "DisplayText " + display_message;
	}

	void DrawSettings(){
		ImGui_InputText("Text", display_message, 64);
	}

	void Reset(){
		if(triggered){
			level.SendMessage("cleartext");
		}
	}

	bool Trigger(){
		if(!triggered){
			triggered = true;
		}
		level.SendMessage("displaytext \"" + display_message + "\"");
		return true;
	}
}
