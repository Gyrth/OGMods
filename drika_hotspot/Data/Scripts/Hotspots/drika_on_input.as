class DrikaOnInput : DrikaElement{
	string input;
	int character_index = 0;
	bool type_text;
	array<string> input_array;
	string input_list = "";
	array<string> input_strings = { "attack (Left mouse button)", "grab (Right Mouse Button)", "backspace", "tab", "clear", "return", "pause", "esc", "space", "!", "#", "$", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "[", "\\", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "delete", "keypad0", "keypad1", "keypad2", "keypad3", "keypad4", "keypad5", "keypad6", "keypad7", "keypad8", "keypad9", "keypad.", "keypad/", "keypad*", "keypad-", "keypad+", "keypadenter", "keypad=", "up", "down", "right", "left", "insert", "home", "end", "pageup", "pagedown", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "numlock", "capslock", "scrollock", "rshift", "lshift", "rctrl", "lctrl", "ralt", "lalt", "rmeta", "lmeta", "lsuper", "rsuper", "mode", "compose", "help", "print", "sysreq", "break", "menu", "power", "euro" };

	DrikaOnInput(JSONValue params = JSONValue()){
		input = GetJSONString(params, "input", "attack");
		type_text = GetJSONBool(params, "type_text", false);
		SetInputArray();
		CreateInputList();

		drika_element_type = drika_on_input;
		has_settings = true;
	}

	int line_counter = 0;
	void CreateInputList(){
		for(uint i = 0; i < input_strings.size(); i++){
			if(line_counter + input_strings[i].length() + 5 > 100){
				input_list += "\n";
				line_counter = 0;
			}
			input_list += input_strings[i] + "\t";
			line_counter += input_strings[i].length() + 5;
		}
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
		if(!type_text && ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip(input_list);
			ImGui_PopStyleColor();
		}
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
