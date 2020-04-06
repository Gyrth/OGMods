enum item_trigger_types {	check_id = 0,
							check_label = 1};

class DrikaOnItemEnterExit : DrikaElement{
	string item_label;
	int item_id;
	int current_combo_item = 0;
	item_trigger_types trigger_type;
	array<string> item_triggger_choices = {"Check ID", "Check Label"};

	DrikaOnItemEnterExit(JSONValue params = JSONValue()){
		trigger_type = item_trigger_types(GetJSONInt(params, "trigger_type", 0));
		current_combo_item = int(trigger_type);
		item_id = GetJSONInt(params, "item_id", -1);
		item_label = GetJSONString(params, "item_label", "");

		connection_types = {_item_object};
		drika_element_type = drika_on_item_enter_exit;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["trigger_type"] = JSONValue(trigger_type);
		data["item_label"] = JSONValue(item_label);
		return data;
	}

	string GetDisplayString(){
		if(trigger_type == check_id){
			return "OnItemEnter " + item_id;
		}else{
			return "OnItemEnter " + item_label;
		}
	}

	void DrawSettings(){
		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Check for");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Check for", current_combo_item, item_triggger_choices, item_triggger_choices.size())){
			trigger_type = item_trigger_types(current_combo_item);
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(trigger_type == check_id){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("ID");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_InputInt("##ID", item_id);
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else{
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Label");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_InputText("##Label", item_label, 64);
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}
	}

	void ReceiveMessage(string message, int param){
		if(trigger_type == check_id && message == "ItemEnter"){
			if(param == item_id){
				triggered = true;
			}
		}
	}

	void ReceiveMessage(string message, string param){
		if(trigger_type == check_label && message == "ItemEnter"){
			if(param == item_label){
				triggered = true;
			}
		}
	}

	bool Trigger(){
		if(triggered){
			triggered = false;
			return true;
		}else{
			return false;
		}
	}
}
