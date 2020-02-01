enum input_types{ 	button_pressed = 0,
					type_text = 1
				};

enum input_identifiers{	up = 0,
						down = 1,
						left = 2,
						right = 3,
						jump = 4,
						crouch = 5,
						slow = 6,
						item = 7,
						drop = 8,
						skip_dialogue = 9,
						attack = 10,
						grab = 11,
						walk = 12,
						input_other = 13
					};

class InputData{
	input_identifiers input_identifier;
	string input_bind_name;
	string input_bind;
	string keyboard_icon;
	string controller_icon;

	InputData(input_identifiers _input_identifier, string _input_bind_name, string _input_bind, string _keyboard_icon, string _controller_icon){
		input_identifier = _input_identifier;
		input_bind_name = _input_bind_name;
		input_bind = _input_bind;
		keyboard_icon = _keyboard_icon;
		controller_icon = _controller_icon;
	}
}

class DrikaOnInput : DrikaElement{
	input_types input_type;
	array<string> input_names;
	int current_input_type;

	int input_index;
	InputData@ input;
	string other_input;

	string typed_text;
	int character_index = 0;
	array<string> input_array;

	array<string> input_type_names = { "Button Press", "Type Text" };

	array<InputData@> inputs = {	InputData(up, "Forward", "up", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(down, "Backward", "down", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(left, "Left", "left", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(right, "Right", "right", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(jump, "Jump", "jump", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(crouch, "Crouch", "crouch", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(slow, "Slow Motion", "slow", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(item, "Equip/sheathe item", "item", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(drop, "Throw/pick-up item", "drop", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(skip_dialogue, "Skip dialogue", "skip_dialogue", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(attack, "Attack", "attack", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(grab, "Grab", "grab", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(walk, "Walk", "walk", "Data/Textures/UI/flatDark/flatDark50.png", "Data/Textures/UI/flatDark/flatDark37.png"),
									InputData(input_other, "Other", "w", "", "")
								};

	DrikaOnInput(JSONValue params = JSONValue()){
		input_type = input_types(GetJSONInt(params, "input_type", button_pressed));
		current_input_type = input_type;

		typed_text = GetJSONString(params, "typed_text", "Drika's Hotspot");
		input_index = GetJSONInt(params, "input_identifier", up);
		other_input = GetJSONString(params, "other_input", "w");

		GetInputData();
		CreateInputList();
		SetInputArray();
		LoadIdentifier(params);
		show_team_option = true;
		show_name_option = true;

		connection_types = {_movement_object};

		drika_element_type = drika_on_input;
		has_settings = true;
	}

	void GetInputData(){
		for(uint i = 0; i < inputs.size(); i++){
			if(inputs[i].input_identifier == input_identifiers(input_index)){
				@input = inputs[i];
				break;
			}
		}
	}

	void CreateInputList(){
		for(uint i = 0; i < inputs.size(); i++){
			if(inputs[i].input_identifier >= int(input_names.size())){
				input_names.resize(inputs[i].input_identifier + 1);
			}
			input_names[inputs[i].input_identifier] = inputs[i].input_bind_name;
		}
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
			data["input_identifier"] = JSONValue(input.input_identifier);
			if(input.input_identifier == input_other){
				data["other_input"] = JSONValue(other_input);
			}
		}
		SaveIdentifier(data);

		return data;
	}

	string GetDisplayString(){
		string display_string = "OnInput " + GetTargetDisplayText() + " ";
		if(input_type == button_pressed){
			return display_string + input.input_bind_name + ((input.input_identifier == input_other)?(" " + other_input):"");
		}else if(input_type == type_text){
			return display_string + typed_text;
		}else{
			return display_string;
		}
	}

	void ApplySettings(){
		SetInputArray();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_Combo("Input Type", current_input_type, input_type_names, input_type_names.size())){
			input_type = input_types(current_input_type);
		}

		if(input_type == button_pressed){
			if(ImGui_Combo("Button", input_index, input_names, input_names.size())){
				GetInputData();
			}
			if(input.input_identifier == input_other){
				ImGui_InputText("Input", other_input, 64);
			}
		}else if(input_type == type_text){
			ImGui_InputText("Input", typed_text, 64);
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void Reset(){
		character_index = 0;
	}

	bool Trigger(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		bool one_triggered = false;
		for(uint i = 0; i < targets.size(); i++){
			if(input_type == type_text){
				if(GetInputPressed(targets[i].controller_id, input_array[character_index])){
					character_index++;
					if(character_index == int(input_array.size())){
						character_index = 0;
						one_triggered = true;
					}
				}
			}else{
				if(input.input_identifier == input_other){
					if(GetInputPressed(targets[i].controller_id, other_input)){
						one_triggered = true;
					}
				}else{
					if(GetInputPressed(targets[i].controller_id, input.input_bind)){
						one_triggered = true;
					}
				}
			}
		}
		return one_triggered;
	}
}
