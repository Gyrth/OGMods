class DrikaWaitLevelMessage : DrikaElement{
	string message;
	bool received_message = false;

	DrikaWaitLevelMessage(string _message = "continue_drika_hotspot"){
		message = _message;
		drika_element_type = drika_wait_level_message;
		has_settings = true;
	}

	string GetSaveString(){
		return "wait_level_message" + param_delimiter + message;
	}

	string GetDisplayString(){
		return "WaitLevelMessage " + message;
	}

	void AddSettings(){
		ImGui_Text("Wait for message : ");
		ImGui_InputText("Message", message, 64);
	}

	void ReceiveMessage(string _message){
		if(_message == message){
			Log(info, "Received correct message");
			received_message = true;
		}
	}

	bool Trigger(){
		return received_message;
	}

	void Reset(){
		received_message = false;
	}
}
