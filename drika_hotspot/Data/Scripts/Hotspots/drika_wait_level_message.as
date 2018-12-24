class DrikaWaitLevelMessage : DrikaElement{
	string message;
	bool received_message = false;

	DrikaWaitLevelMessage(JSONValue params = JSONValue()){
		message = GetJSONString(params, "message", "continue_drika_hotspot");

		drika_element_type = drika_wait_level_message;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("wait_level_message");
		data["message"] = JSONValue(message);
		return data;
	}

	string GetDisplayString(){
		return "WaitLevelMessage " + message;
	}

	void DrawSettings(){
		ImGui_Text("Wait for message : ");
		ImGui_InputText("Message", message, 64);
	}

	void ReceiveMessage(string _message){
		if(_message == message){
			Log(info, "Received correct message " + message);
			received_message = true;
		}
	}

	bool Trigger(){
		if(received_message){
			received_message = false;
			return true;
		}else{
			return false;
		}
	}

	void Reset(){
		received_message = false;
	}
}
