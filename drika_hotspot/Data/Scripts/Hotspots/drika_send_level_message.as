class DrikaSendLevelMessage : DrikaElement{
	string message;
	string display_message;

	DrikaSendLevelMessage(JSONValue params = JSONValue()){
		message = GetJSONString(params, "message", "continue_drika_hotspot");

		drika_element_type = drika_send_level_message;
		has_settings = true;
		SetDisplayMessage();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["message"] = JSONValue(message);
		return data;
	}

	string GetDisplayString(){
		return "SendLevelMessage " + display_message;
	}

	void DrawSettings(){
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Message");
		ImGui_SameLine();
		if(ImGui_InputText("##Message", message, 64)){
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
		level.SendMessage(message);
		return true;
	}
}
