class DrikaOnInput : DrikaElement{
	string input;
	int character_index = 0;
	bool type_text;
	array<string> input_array;

	DrikaOnInput(JSONValue params = JSONValue()){
		input = GetJSONString(params, "input", "attack");
		type_text = GetJSONBool(params, "type_text", false);
		SetInputArray();

		drika_element_type = drika_on_input;
		has_settings = true;
	}

	void SetInputArray(){
		for(uint i = 0; i < input.length(); i++){
			input_array.insertLast(input.substr(i, 1));
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("on_input");
		data["input"] = JSONValue(input);
		data["type_text"] = JSONValue(type_text);
		return data;
	}

	string GetDisplayString(){
		return "OnInput " + input;
	}

	void ApplySettings(){
		SetInputArray();
	}

	void DrawSettings(){
		ImGui_Checkbox("Type text", type_text);
		ImGui_InputText("Input", input, 64);
	}

	void Reset(){
		character_index = 0;
	}

	bool Trigger(){
		if(type_text){
			if(GetInputPressed(0, input_array[character_index])){
				character_index++;
				if(character_index == int(input_array.size())){
					character_index = 0;
					return true;
				}
			}
		}else{
			if(GetInputPressed(0, input)){
				return true;
			}
		}
		return false;
	}
}
