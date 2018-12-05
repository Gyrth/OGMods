class DrikaSendLevelMessage : DrikaElement{
	string message;
	string display_message;

	DrikaSendLevelMessage(string _message = "level_message"){
		message = _message;
		SetDisplayMessage();
		drika_element_type = drika_send_level_message;
		has_settings = true;
	}

	string GetSaveString(){
		return "send_level_message" + param_delimiter + message;
	}

	string GetDisplayString(){
		return "SendLevelMessage " + display_message;
	}

	void AddSettings(){
		if( ImGui_InputTextMultiline("", message, 64, vec2(-1.0, -1.0)) ){
			SetDisplayMessage();
		}
	}

	void SetDisplayMessage(){
		display_message = join(message.split("\n"), "");
		if(display_message.length() > 30){
			display_message = display_message.substr(0, 30);
		}
	}

	bool Trigger(){
		Log(info, "Send level message " + message);
		level.SendMessage(message);
		return true;
	}
}
