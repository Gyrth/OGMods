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

		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Level Message");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();

		ImGui_PushItemWidth(second_column_width);
		if(ImGui_InputText("###Level Message", message, 64)){
			SetDisplayMessage();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();
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
