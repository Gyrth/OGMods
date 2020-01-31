enum input_types{ 	button_pressed = 0,
					type_text = 1
				};

class DrikaOnInput : DrikaElement{
	input_types input_type;
	int current_input_type;
	string input_bind;
	int input_index;
	string typed_text;
	int character_index = 0;
	array<string> input_array;

	array<string> input_type_names = { "Button Press", "Type Text" };

	array<string> input_bind_names = {
	    "Forward",
	    "Backwards",
	    "Left",
	    "Right",
	    "Jump",
	    "Crouch",
	    "Slow Motion",
	    "Equip/sheathe item",
	    "Throw/pick-up item",
	    "Skip dialogue",
	    "Attack",
	    "Grab",
	    "Walk",
		"Other"
	};

	array<string> input_binds = {
	    "up",
	    "down",
	    "left",
	    "right",
	    "jump",
	    "crouch",
	    "slow",
	    "item",
	    "drop",
	    "skip_dialogue",
	    "attack",
	    "grab",
	    "walk",
		"w"
	};

	DrikaOnInput(JSONValue params = JSONValue()){
		input_type = input_types(GetJSONInt(params, "input_type", button_pressed));
		current_input_type = input_type;
		typed_text = GetJSONString(params, "typed_text", "Drika's Hotspot");
		input_bind = GetJSONString(params, "input_bind", input_binds[0]);
		input_index = input_binds.find(input_bind);
		SetInputArray();

		drika_element_type = drika_on_input;
		has_settings = true;
	}

	void SetInputArray(){
		input_array.resize(0);
		for(uint i = 0; i < typed_text.length(); i++){
			if(typed_text.substr(i, 1) == " "){
				input_array.insertLast("space");
			}else{
				input_array.insertLast(typed_text.substr(i, 1));
			}
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["input_type"] = JSONValue(input_type);
		if(input_type == type_text){
			data["typed_text"] = JSONValue(typed_text);
		}else if(input_type == button_pressed){
			data["input_bind"] = JSONValue(input_bind);
		}
		return data;
	}

	string GetDisplayString(){
		if(input_type == button_pressed){
			return "OnInput " + input_bind_names[input_index] + ((input_bind_names[input_index] == "Other")?(" " + input_bind):"");
		}else if(input_type == type_text){
			return "OnInput " + typed_text;
		}else{
			return "OnInput";
		}
	}

	void ApplySettings(){
		SetInputArray();
	}

	void DrawSettings(){
		if(ImGui_Combo("Input Type", current_input_type, input_type_names, input_type_names.size())){
			input_type = input_types(current_input_type);
		}

		if(input_type == button_pressed){
			if(ImGui_Combo("Button", input_index, input_bind_names, input_bind_names.size())){
				input_bind = input_binds[input_index];
			}
			if(input_bind_names[input_index] == "Other"){
				ImGui_InputText("Input", input_bind, 64);
			}
		}else if(input_type == type_text){
			ImGui_InputText("Input", typed_text, 64);
		}
	}

	void Reset(){
		character_index = 0;
	}

	bool Trigger(){
		if(input_type == type_text){
			if(GetInputPressed(0, input_array[character_index])){
				character_index++;
				if(character_index == int(input_array.size())){
					character_index = 0;
					return true;
				}
			}
		}else{
			if(GetInputPressed(0, input_bind)){
				return true;
			}
		}
		return false;
	}
}
