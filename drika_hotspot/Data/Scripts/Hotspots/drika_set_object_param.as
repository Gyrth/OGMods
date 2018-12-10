class DrikaSetObjectParam : DrikaElement{
	int current_type;
	int current_idenifier_type;
	string param_name;

	string string_param_before;
	string string_param_after;

	int int_param_before = 0;
	int int_param_after = 0;

	float float_param_before = 0.0;
	float float_param_after = 0.0;

	param_types param_type;

	DrikaSetObjectParam(string _identifier_type = "0", string _identifier = "-1", string _param_type = "0", string _param_name = "drika_param", string _param_after = "drika_new_value"){
		param_name = _param_name;
		param_type = param_types(atoi(_param_type));
		identifier_type = identifier_types(atoi(_identifier_type));
		current_type = param_type;
		current_idenifier_type = identifier_type;

		if(identifier_type == id){
			object_id = atoi(_identifier);
		}else if(identifier_type == reference){
			reference_string = _identifier;
		}

		drika_element_type = drika_set_object_param;
		string_param_after = _param_after;
		has_settings = true;

		InterpParam();
		GetBeforeParam();
	}

	void Delete(){
		SetParameter(true);
	}

	void InterpParam(){
		//No need to interp the string param since the input is already a string.
		if(param_type == float_param){
			float_param_after = atof(string_param_after);
		}else if(param_type == int_param){
			int_param_after = atoi(string_param_after);
		}
	}

	void GetBeforeParam(){
		if(ObjectExists(object_id)){
			ScriptParams@ params = level.GetScriptParams();
			if(param_type == string_param){
				if(!params.HasParam(param_name)){
					params.AddString(param_name, string_param_after);
				}
				string_param_before = params.GetString(param_name);
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddFloat(param_name, float_param_after);
				}
				float_param_before = params.GetFloat(param_name);
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, int_param_after);
				}
				int_param_before = params.GetInt(param_name);
			}
		}
	}

	void ApplySettings(){
		GetBeforeParam();
	}

	string GetSaveString(){
		string save_identifier;
		if(identifier_type == id){
			save_identifier = "" + object_id;
		}else if(identifier_type == reference){
			save_identifier = "" + reference_string;
		}
		if(param_type == int_param){
			string_param_after = "" + int_param_after;
		}else if(param_type == float_param){
			string_param_after = "" + float_param_after;
		}
		return "set_object_param" + param_delimiter + int(identifier_type) + param_delimiter + save_identifier + param_delimiter + int(param_type) + param_delimiter + param_name + param_delimiter + string_param_after;
	}

	string GetDisplayString(){
		return "SetObjectParam " + param_name + " " + string_param_after;
	}

	void AddSettings(){
		if(ImGui_Combo("Identifier Type", current_idenifier_type, {"ID", "Reference"})){
			identifier_type = identifier_types(current_idenifier_type);
		}

		if(identifier_type == id){
			ImGui_InputInt("Object ID", object_id);
		}else if (identifier_type == reference){
			ImGui_InputText("Reference", reference_string, 64);
		}
		ImGui_InputText("Param Name", param_name, 64);

		if(ImGui_Combo("Param Type", current_type, {"String", "Integer", "Float"})){
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
			DebugDrawLine(target_object.GetTranslation(), this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
		}
	}

	bool Trigger(){
		return SetParameter(false);
	}

	bool SetParameter(bool reset){
		if(ObjectExists(object_id)){
			Object@ target_object;

			if(identifier_type == id){
				@target_object = ReadObjectFromID(object_id);
			}else if (identifier_type == reference){
				int registered_object_id = GetRegisteredObjectID(reference_string);
				if(registered_object_id == -1){
					return true;
				}
				@target_object = ReadObjectFromID(registered_object_id);
			}

			ScriptParams@ params = target_object.GetScriptParams();

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
		return false;
	}

	void Reset(){
		SetParameter(true);
	}
}
