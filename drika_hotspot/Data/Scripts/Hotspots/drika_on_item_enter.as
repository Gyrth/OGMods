enum item_trigger_types {	check_id = 0,
							check_label = 1};

class DrikaOnItemEnter : DrikaElement{
	string item_label;
	int item_id;
	int current_combo_item = 0;
	item_trigger_types trigger_type;
	array<string> item_triggger_choices = {"Check ID", "Check Label"};

	DrikaOnItemEnter(string _trigger_type = "0", string _param = "-1"){
		drika_element_type = drika_on_item_enter;
		has_settings = true;
		trigger_type = item_trigger_types(atoi(_trigger_type));
		current_combo_item = int(trigger_type);

		if(trigger_type == check_id){
			item_id = atoi(_param);
		}else{
			item_label = _param;
		}
	}

	array<string> GetSaveParameters(){
		if(trigger_type == check_id){
			return {"on_item_enter", trigger_type, item_id};
		}else{
			return {"on_item_enter", trigger_type, item_label};
		}
	}

	string GetDisplayString(){
		if(trigger_type == check_id){
			return "OnItemEnter " + item_id;
		}else{
			return "OnItemEnter " + item_label;
		}
	}

	void DrawSettings(){
		if(ImGui_Combo("Check for", current_combo_item, item_triggger_choices, item_triggger_choices.size())){
			trigger_type = item_trigger_types(current_combo_item);
		}
		if(trigger_type == check_id){
			ImGui_InputInt("ID", item_id);
		}else{
			ImGui_InputText("Label", item_label, 64);
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
