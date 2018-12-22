class DrikaSetObjectParam : DrikaElement{
	int current_type;
	string param_name;
	bool delete_before = false;

	string string_param_before;
	string string_param_after;

	int int_param_before = 0;
	int int_param_after = 0;

	float float_param_before = 0.0;
	float float_param_after = 0.0;

	param_types param_type;
	array<string> param_type_choices = {"String", "Integer", "Float"};

	DrikaSetObjectParam(string _identifier_type = "0", string _identifier = "-1", string _param_type = "0", string _param_name = "drika_param", string _param_after = "drika_new_value"){
		param_name = _param_name;
		param_type = param_types(atoi(_param_type));
		current_type = param_type;
		connection_types = {_env_object, _movement_object};
		InterpIdentifier(_identifier_type, _identifier);
		drika_element_type = drika_set_object_param;
		has_settings = true;

		InterpParam(_param_after);
	}

	void Delete(){
		SetParameter(true);
	}

	void InterpParam(string _param){
		if(param_type == float_param){
			float_param_after = atof(_param);
		}else if(param_type == int_param){
			int_param_after = atoi(_param);
		}else if(param_type == string_param){
			string_param_after = _param;
		}
	}

	void GetBeforeParam(){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		ScriptParams@ params = target_object.GetScriptParams();
		//If the param does not exist then just remove it when resetting.
		if(!params.HasParam(param_name)){
			delete_before = true;
			return;
		}else{
			delete_before = false;
		}
		if(param_type == string_param){
			string_param_before = params.GetString(param_name);
		}else if(param_type == float_param){
			float_param_before = params.GetFloat(param_name);
		}else if(param_type == int_param){
			int_param_before = params.GetInt(param_name);
		}
	}

	array<string> GetSaveParameters(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		string save_string;
		if(param_type == string_param){
			save_string = string_param_after;
		}else if(param_type == float_param){
			save_string = "" + float_param_after;
		}else if(param_type == int_param){
			save_string = "" + int_param_after;
		}
		return {"set_object_param", identifier_type, save_identifier, param_type, param_name, save_string};
	}

	string GetDisplayString(){
		string display_identifier;
		if(identifier_type == id){
			display_identifier = "" + object_id;
		}else if(identifier_type == reference){
			display_identifier = "" + reference_string;
		}
		string display_string;
		if(param_type == string_param){
			display_string = string_param_after;
		}else if(param_type == float_param){
			display_string = "" + float_param_after;
		}else if(param_type == int_param){
			display_string = "" + int_param_after;
		}
		return "SetObjectParam " + display_identifier + " " + param_name + " " + display_string;
	}
	
	void StartSettings(){
		CheckReferenceOptionAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		ImGui_InputText("Param Name", param_name, 64);
		if(ImGui_Combo("Param Type", current_type, param_type_choices, param_type_choices.size())){
			param_type = param_types(current_type);
		}

		if(param_type == string_param){
			ImGui_InputText("After", string_param_after, 64);
		}else if(param_type == int_param){
			ImGui_InputInt("After", int_param_after);
		}else{
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}
	}

	void DrawEditing(){
		if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
			Object@ target_object = ReadObjectFromID(object_id);
			DebugDrawLine(target_object.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool Trigger(){
		if(!triggered){
			GetBeforeParam();
		}
		triggered = true;
		return SetParameter(false);
	}

	bool SetParameter(bool reset){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return false;
		}
		ScriptParams@ params = target_object.GetScriptParams();

		if(reset && delete_before){
			params.Remove(param_name);
			return true;
		}

		if(!params.HasParam(param_name)){
			if(param_type == string_param){
				params.AddString(param_name, reset?string_param_before:string_param_after);
			}else if(param_type == int_param){
				params.AddInt(param_name, reset?int_param_before:int_param_after);
			}else if(param_type == float_param){
				params.AddFloatSlider(param_name, reset?float_param_before:float_param_after, "min:0,max:1000,step:0.0001,text_mult:1");
			}
		}else{
			if(param_type == string_param){
				params.SetString(param_name, reset?string_param_before:string_param_after);
			}else if(param_type == int_param){
				params.SetInt(param_name, reset?int_param_before:int_param_after);
			}else if(param_type == float_param){
				params.Remove(param_name);
				params.AddFloatSlider(param_name, reset?float_param_before:float_param_after, "min:0,max:1000,step:0.0001,text_mult:1");
				/* params.SetFloat(param_name, reset?float_param_before:float_param_after); */
			}
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetParameter(true);
		}
	}
}
