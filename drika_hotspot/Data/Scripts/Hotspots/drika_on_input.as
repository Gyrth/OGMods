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

	InputData(input_identifiers _input_identifier, string _input_bind_name, string _input_bind){
		input_identifier = _input_identifier;
		input_bind_name = _input_bind_name;
		input_bind = _input_bind;
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
	bool use_prompt;
	bool custom_prompt;
	string custom_prompt_path;
	float prompt_size;
	vec4 prompt_color = vec4(0.5, 0.5, 0.5, 1.0);
	string current_prompt_icon;

	array<string> input_type_names = { "Button Press", "Type Text" };

	array<InputData@> inputs = {	InputData(up, "Forward", "up"),
									InputData(down, "Backward", "down"),
									InputData(left, "Left", "left"),
									InputData(right, "Right", "right"),
									InputData(jump, "Jump", "jump"),
									InputData(crouch, "Crouch", "crouch"),
									InputData(slow, "Slow Motion", "slow"),
									InputData(item, "Equip/sheathe item", "item"),
									InputData(drop, "Throw/pick-up item", "drop"),
									InputData(skip_dialogue, "Skip dialogue", "skip_dialogue"),
									InputData(attack, "Attack", "attack"),
									InputData(grab, "Grab", "grab"),
									InputData(walk, "Walk", "walk"),
									InputData(input_other, "Other", "w")
								};

	DrikaOnInput(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "Input Prompt Helper";

		input_type = input_types(GetJSONInt(params, "input_type", button_pressed));
		current_input_type = input_type;

		typed_text = GetJSONString(params, "typed_text", "Drika's Hotspot");
		input_index = GetJSONInt(params, "input_identifier", up);
		other_input = GetJSONString(params, "other_input", "w");
		use_prompt = GetJSONBool(params, "use_prompt", false);
		custom_prompt = GetJSONBool(params, "custom_prompt", false);
		custom_prompt_path = GetJSONString(params, "custom_prompt_path", "Data/Textures/UI/keyboard/f.png");
		prompt_size = GetJSONFloat(params, "prompt_size", 0.25);

		GetInputData();
		CreateInputList();
		SetInputArray();

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option;

		connection_types = {_movement_object};

		drika_element_type = drika_on_input;
		has_settings = true;
	}

	void PostInit(){
		if(use_prompt){
			RetrievePlaceholder();
			GetIcon();
		}
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
		data["placeholder_id"] = JSONValue(placeholder_id);

		if(input_type == type_text){
			data["typed_text"] = JSONValue(typed_text);
		}else if(input_type == button_pressed){
			data["input_identifier"] = JSONValue(input.input_identifier);
			if(input.input_identifier == input_other){
				data["other_input"] = JSONValue(other_input);
			}
			data["use_prompt"] = JSONValue(use_prompt);
			if(use_prompt){
				data["prompt_size"] = JSONValue(prompt_size);
				data["custom_prompt"] = JSONValue(custom_prompt);
				if(custom_prompt){
					data["custom_prompt_path"] = JSONValue(custom_prompt_path);
				}
			}
		}
		target_select.SaveIdentifier(data);

		return data;
	}

	string GetDisplayString(){
		string display_string = "OnInput " + target_select.GetTargetDisplayText() + " ";
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

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();
		if(ImGui_Combo("Input Type", current_input_type, input_type_names, input_type_names.size())){
			input_type = input_types(current_input_type);
		}

		if(input_type == button_pressed){
			if(ImGui_Combo("Button", input_index, input_names, input_names.size())){
				GetInputData();
				GetIcon();
			}

			if(input.input_identifier == input_other){
				if(ImGui_InputText("Input", other_input, 64)){
					GetIcon();
				}
			}

			if(ImGui_Checkbox("Use prompt", use_prompt)){
				GetIcon();
			}

			if(use_prompt){
				ImGui_DragFloat("prompt Size", prompt_size, 0.001f, 0.0f, 5.0f, "%.2f");
				ImGui_Checkbox("Custom Prompt", custom_prompt);
				if(custom_prompt){
					ImGui_Text("Path : " + custom_prompt_path);
					if(ImGui_Button("Set Path")){
						string new_path = "";
						new_path = GetUserPickedReadPath("png", "Data/Textures/UI");
						if(new_path != ""){
							custom_prompt_path = new_path;
						}
					}
				}
			}
		}else if(input_type == type_text){
			ImGui_InputText("Input", typed_text, 64);
		}
	}

	void TargetChanged(){
		GetIcon();
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}

		if(use_prompt && input_type == button_pressed){
			if(placeholder_id != -1 && ObjectExists(placeholder_id)){
				DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}else{
				CreatePlaceholder();
			}
		}else{
			if(placeholder_id != -1 && ObjectExists(placeholder_id)){
				QueueDeleteObjectID(placeholder_id);
				placeholder_id = -1;
			}
		}
		DrawPrompt();
	}

	void Delete(){
		if(ObjectExists(placeholder_id)){
			QueueDeleteObjectID(placeholder_id);
		}
	}

	void Reset(){
		character_index = 0;
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
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

		DrawPrompt();

		return one_triggered;
	}

	void DrawPrompt(){
		if(use_prompt){
			if(placeholder_id != -1 && ObjectExists(placeholder_id)){
				if(custom_prompt){
					DebugDrawBillboard(custom_prompt_path, placeholder.GetTranslation(), prompt_size, prompt_color, _delete_on_update);
				}else{
					DebugDrawBillboard(current_prompt_icon, placeholder.GetTranslation(), prompt_size, prompt_color, _delete_on_update);
				}
			}
		}
	}

	void GetIcon(){
		if(!use_prompt){
			return;
		}
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		//When the target MO is -1 then just get the keyboard icon so that it has something to render.
		if(targets.size() == 0){
			current_prompt_icon = GetKeyboardIcon();
		}else{
			for(uint i = 0; i < targets.size(); i++){
				current_prompt_icon = (targets[i].controller_id == 0)?GetKeyboardIcon():GetControllerIcon();
			}
		}
	}

	string GetKeyboardIcon(){
		string bind = input.input_bind;
		string binding_value = (input.input_identifier != input_other)?GetBindingValue("key", bind):other_input;
		string path = "Data/Textures/UI/keyboard/" + binding_value + ".png";

		if(FileExists(path)){
			return path;
		}

		return "Data/UI/spawner/thumbs/Hotspot/empty.png";
	}

	string GetControllerIcon(){
		string bind = input.input_bind;
		string binding_value = (input.input_identifier != input_other)?GetBindingValue("gamepad_" + GetConfigValueInt("menu_player_config"), bind):other_input;
		string path = "Data/Textures/UI/controller/" + binding_value + ".png";

		if(FileExists(path)){
			return path;
		}

		return "Data/UI/spawner/thumbs/Hotspot/empty.png";
	}

}
