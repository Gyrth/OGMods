class DrikaSetObjectParam : DrikaElement{
	int object_id;
	int current_type;
	string param_name;

	string string_param_before;
	string string_param_after;

	int int_param_before = 0;
	int int_param_after = 0;

	float float_param_before = 0.0;
	float float_param_after = 0.0;

	param_types param_type;

	DrikaSetObjectParam(int _object_id = -1, int _param_type = 0, string _param_name = "drika_param", string _param_before = "drika_value_before", string _param_after = "drika_value_after"){
		object_id = _object_id;
		param_name = _param_name;
		param_type = param_types(_param_type);
		current_type = param_type;

		drika_element_type = drika_set_object_param;
		has_settings = true;

		string_param_before = _param_before;
		string_param_after = _param_after;

		int_param_before = atoi(_param_before);
		int_param_after = atoi(_param_after);

		float_param_before = atof(_param_before);
		float_param_after = atof(_param_after);
	}

	string GetSaveString(){
		if(param_type == int_param){
			string_param_before = "" + int_param_before;
			string_param_after = "" + int_param_after;
		}else if(param_type == float_param){
			string_param_before = "" + float_param_before;
			string_param_after = "" + float_param_after;
		}
		return "set_object_param " + object_id + " " + int(param_type) + " " + param_name + " " + string_param_before + " " + string_param_after;
	}

	string GetDisplayString(){
		return "SetObjectParam " + string_param_after;
	}

	void AddSettings(){
		ImGui_InputInt("Object ID", object_id);
		ImGui_InputText("Param Name", param_name, 64);

		if(ImGui_Combo("Param Type", current_type, {"String", "Integer", "Float"})){
			param_type = param_types(current_type);
		}

		/* if(ImGui_BeginCombo("Param Type", "")){
			if(ImGui_Selectable("String", current_type == 0)){
				current_type = 0;
			}else if(ImGui_Selectable("Integer", current_type == 1)){
				current_type = 1;
			}else if(ImGui_Selectable("Float", current_type == 2)){
				current_type = 2;
			}
			ImGui_EndCombo();
		} */

		if(param_type == string_param){
			ImGui_InputText("Before", string_param_before, 64);
			ImGui_InputText("After", string_param_after, 64);
		}else if(param_type == int_param){
			ImGui_InputInt("Before", int_param_before);
			ImGui_InputInt("After", int_param_after);
		}else{
			ImGui_SliderFloat("Before", float_param_before, -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}
	}

	bool Trigger(){
		return SetParameter(false);
	}

	bool SetParameter(bool reset){
		if(ObjectExists(object_id)){
			ScriptParams@ params = ReadObjectFromID(object_id).GetScriptParams();
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
