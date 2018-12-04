enum level_params { 	achievements = 0,
						custom_shaders = 1,
						fog_amount = 2,
						gpu_particle_field = 3,
						hdr_black_point = 4,
						hdr_bloom_multiplier = 5,
						hdr_white_point = 6,
						level_boundaries = 7,
						load_tip = 8,
						objectives = 9,
						saturation = 10,
						sky_brightness = 11,
						sky_rotation = 12,
						sky_tint = 13}

array<int> string_parameters = {achievements, custom_shaders, gpu_particle_field, load_tip, objectives};
array<int> float_parameters = {fog_amount, hdr_black_point, hdr_bloom_multiplier, hdr_white_point, saturation, sky_brightness, sky_rotation};
array<int> color_parameters = {sky_tint};
array<int> int_parameters = {level_boundaries};
array<int> function_parameters = {sky_tint};

array<string> param_names = {	"Achievements",
 								"Custom Shader",
								"Fog amount",
								"GPU Particle Field",
								"HDR Black point",
								"HDR Bloom multiplier",
								"HDR White point",
								"Level Boundaries",
								"Load Tip",
								"Objectives",
								"Saturation",
								"Sky Brightness",
								"Sky Rotation",
								"Sky Tint"
							};


class DrikaSetLevelParam : DrikaElement{
	int current_type;
	string param_name;

	string string_param_before;
	string string_param_after;

	bool has_function = false;

	float float_param_before;
	float float_param_after;

	int int_param_before;
	int int_param_after;

	vec3 vec3_param_before;
	vec3 vec3_param_after;

	level_params level_param;
	param_types param_type;

	DrikaSetLevelParam(int _level_param = 0, string _param_before = "flawless", string _param_after = "no_kills"){

		level_param = level_params(_level_param);
		current_type = level_param;

		drika_element_type = drika_set_level_param;
		has_settings = true;

		string_param_before = _param_before;
		string_param_after = _param_after;

		SetParamType();
		InterpParam();
		param_name = param_names[current_type];
	}

	void SetParamType(){
		if(string_parameters.find(level_param) != -1){
			param_type = string_param;
		}else if(float_parameters.find(level_param) != -1){
			param_type = float_param;
		}else if(color_parameters.find(level_param) != -1){
			param_type = vec3_param;
		}else if(int_parameters.find(level_param) != -1){
			param_type = int_param;
		}
		if(function_parameters.find(level_param) != -1){
			has_function = true;
		}else{
			has_function = false;
		}
	}

	void InterpParam(){
		if(param_type == vec3_param){
			vec3_param_before = StringToVec3(string_param_before);
			vec3_param_after = StringToVec3(string_param_after);
		}else if(param_type == float_param){
			float_param_before = atof(string_param_before);
			float_param_after = atof(string_param_after);
		}else if(param_type == int_param){
			int_param_before = atoi(string_param_before);
			int_param_after = atoi(string_param_after);
		}
	}

	string GetSaveString(){
		if(param_type == vec3_param){
			string_param_before = Vec3ToString(vec3_param_before);
			string_param_after = Vec3ToString(vec3_param_after);
		}else if(param_type == float_param){
			string_param_before = "" + float_param_before;
			string_param_after = "" + float_param_after;
		}else if(param_type == int_param){
			string_param_before = "" + int_param_before;
			string_param_after = "" + int_param_after;
		}
		return "set_level_param " + int(level_param) + " " + string_param_before + " " + string_param_after;
	}

	string GetDisplayString(){
		return "SetLevelParam " + param_name + " " + string_param_after;
	}

	void AddSettings(){
		if(ImGui_Combo("Param Type", current_type, param_names)){
			level_param = level_params(current_type);
			param_name = param_names[current_type];
			SetParamType();
			GetParameter();
		}

		if(param_type == string_param){
			ImGui_InputText("Before", string_param_before, 64);
			ImGui_InputText("After", string_param_after, 64);
		}else if(param_type == float_param){
			ImGui_SliderFloat("Before", float_param_before, -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}else if(param_type == vec3_param){
			ImGui_ColorPicker3("Before", vec3_param_before, 0);
			ImGui_ColorPicker3("After", vec3_param_after, 0);
		}else if(param_type == int_param){
			ImGui_InputInt("Before", int_param_before);
			ImGui_InputInt("After", int_param_after);
		}
	}

	void GetParameter(){
		if(has_function){
			switch(level_param){
				case sky_tint:
					vec3_param_before = GetSkyTint();
					vec3_param_after = GetSkyTint();
					break;
				default:
					Log(warning, "Found a non standard parameter type. " + param_type);
					break;
			}
		}else{
			ScriptParams@ params = level.GetScriptParams();
			if(param_type == string_param){
				if(!params.HasParam(param_name)){
					params.AddString(param_name, "");
				}
				string_param_before = params.GetString(param_name);
				string_param_after = string_param_before;
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddFloat(param_name, 0.0f);
				}
				float_param_before = params.GetFloat(param_name);
				float_param_after = float_param_before;
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, 0);
				}
				int_param_before = params.GetInt(param_name);
				int_param_after = int_param_before;
			}
		}
	}

	bool Trigger(){
		return SetParameter(false);
	}

	bool SetParameter(bool reset){
		if(has_function){
			switch(level_param){
				case sky_tint:
					SetSkyTint(vec3_param_after);
					break;
				default:
					Log(warning, "Found a non standard parameter type. " + param_type);
					break;
			}
		}else{
			ScriptParams@ params = level.GetScriptParams();
			if(param_type == string_param){
				if(reset && params.GetString(param_name) != string_param_after){
					return false;
				}
				params.SetString(param_name, reset?string_param_before:string_param_after);
			}else if(param_type == float_param){
				if(reset && params.GetFloat(param_name) != float_param_after){
					return false;
				}
				params.SetFloat(param_name, reset?float_param_before:float_param_after);
			}else if(param_type == int_param){
				if(reset && params.GetInt(param_name) != int_param_after){
					return false;
				}
				params.SetInt(param_name, reset?int_param_before:int_param_after);
			}
		}
		return true;
	}

	void Reset(){
		SetParameter(true);
	}
}
