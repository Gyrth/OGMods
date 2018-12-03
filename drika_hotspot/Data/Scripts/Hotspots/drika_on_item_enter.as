enum item_trigger_types {	check_id,
						check_label};

class DrikaOnItemEnter : DrikaElement{
	string item_label;
	int item_id;
	int current_item = 0;
	item_trigger_types trigger_type;
	bool triggered = false;

	DrikaOnItemEnter(int _item_id = -1, string _item_label = ""){
		item_id = _item_id;
		item_label = _item_label;
		drika_element_type = drika_on_item_enter;
		display_color = vec4(110, 94, 180, 255);
		has_settings = true;
		if(item_label == ""){
			trigger_type = check_id;
		}else{
			trigger_type = check_label;
		}
	}

	string GetSaveString(){
		return "on_item_enter " + item_id + " " + item_label;
	}

	string GetDisplayString(){
		if(trigger_type == check_id){
			return "OnItemEnter " + item_id;
		}else{
			return "OnItemEnter " + item_label;
		}
	}

	void AddSettings(){
		if(ImGui_Combo("Check for", current_item, {"Check ID", "Check Label"})){
			if(current_item == 0){
				trigger_type = check_id;
			}else{
				trigger_type = check_label;
			}
		}
		if(trigger_type == check_id){
			ImGui_InputInt("ID", item_id);
		}else{
			ImGui_InputText("Label", item_label, 64);
		}
	}

	void ReceiveMessage(string message, int param){
		Log(info, "item enter " + message + param);
		if(trigger_type == check_id && message == "ItemEnter"){
			if(param == item_id){
				triggered = true;
			}
		}
	}

	void ReceiveMessage(string message, string param){
		Log(info, "item enter " + message + param);
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
