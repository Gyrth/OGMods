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
						sky_tint = 13,
						sun_position = 14,
						sun_color = 15,
						sun_intensity = 16,
						other = 17
					};

class DrikaSetLevelParam : DrikaElement{
	int current_type;
	string param_name;
	bool has_function = false;
	bool delete_before = false;

	string string_param_before;
	string string_param_after;

	float float_param_before;
	float float_param_after;

	int int_param_before;
	int int_param_after;

	vec3 vec3_param_before;
	vec3 vec3_param_after;

	level_params level_param;
	param_types param_type;

	array<int> string_parameters = {achievements, custom_shaders, gpu_particle_field, load_tip, objectives, other};
	array<int> float_parameters = {fog_amount, hdr_black_point, hdr_bloom_multiplier, hdr_white_point, saturation, sky_brightness, sky_rotation, sun_intensity};
	array<int> vec3_parameters = {sun_position};
	array<int> vec3_color_parameters = {sky_tint, sun_color};
	array<int> int_parameters = {level_boundaries};
	array<int> function_parameters = {sky_tint, hdr_black_point, hdr_bloom_multiplier, hdr_white_point, sun_position, sun_color, sun_intensity};

	array<int> mult_100_params = {hdr_black_point, hdr_bloom_multiplier, hdr_white_point, saturation, sky_brightness};

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
									"Sky Tint",
									"Sun Position",
									"Sun Color",
									"Sun Intensity",
									"Other..."
								};

	DrikaSetLevelParam(string _level_param = "0", string _param_after = "no_kills"){
		level_param = level_params(atoi(_level_param));
		current_type = level_param;
		param_name = param_names[current_type];

		drika_element_type = drika_set_level_param;
		has_settings = true;
		SetParamType();
		InterpParam(_param_after);
		GetBeforeParam();
	}

	void SetParamType(){
		if(string_parameters.find(level_param) != -1){
			param_type = string_param;
		}else if(float_parameters.find(level_param) != -1){
			param_type = float_param;
		}else if(vec3_parameters.find(level_param) != -1){
			param_type = vec3_param;
		}else if(vec3_color_parameters.find(level_param) != -1){
			param_type = vec3_color_param;
		}else if(int_parameters.find(level_param) != -1){
			param_type = int_param;
		}
		if(function_parameters.find(level_param) != -1){
			has_function = true;
		}else{
			has_function = false;
		}
	}

	void InterpParam(string _param){
		if(param_type == vec3_param || param_type == vec3_color_param){
			vec3_param_after = StringToVec3(_param);
		}else if(param_type == float_param){
			float_param_after = atof(_param);
		}else if(param_type == int_param){
			int_param_after = atoi(_param);
		}else if(param_type == string_param){
			if(level_param == other){
				array<string> split_param = _param.split(";");
				if(split_param.size() == 2){
					param_name = split_param[0];
					string_param_after = split_param[1];
				}
			}else{
				string_param_after = _param;
			}
		}
	}

	string GetSaveString(){
		string save_string;
		if(level_param == other){
			save_string = param_name + ";" + string_param_after;
		}else if(param_type == string_param){
			save_string = string_param_after;
		}else if(param_type == vec3_param || param_type == vec3_color_param){
			save_string = Vec3ToString(vec3_param_after);
		}else if(param_type == float_param){
			save_string = "" + float_param_after;
		}else if(param_type == int_param){
			save_string = "" + int_param_after;
		}
		return "set_level_param" + param_delimiter + int(level_param) + param_delimiter + save_string;
	}

	string GetDisplayString(){
		string display_string;
		if(level_param == other){
			display_string = string_param_after;
		}else if(param_type == string_param){
			display_string = string_param_after;
		}else if(param_type == vec3_param || param_type == vec3_color_param){
			display_string = Vec3ToString(vec3_param_after);
		}else if(param_type == float_param){
			display_string = "" + float_param_after;
		}else if(param_type == int_param){
			display_string = "" + int_param_after;
		}
		return "SetLevelParam " + param_name + " " + display_string;
	}

	void AddSettings(){
		if(ImGui_Combo("Param Type", current_type, param_names)){
			level_param = level_params(current_type);
			param_name = param_names[current_type];
			SetParamType();
			GetBeforeParam();
			if(param_type == string_param){
				string_param_after = string_param_before;
			}else if(param_type == float_param){
				float_param_after = float_param_before;
			}else if(param_type == int_param){
				int_param_after = int_param_before;
			}else if(param_type == vec3_param || param_type == vec3_color_param){
				vec3_param_after = vec3_param_before;
			}
		}

		if(param_type == string_param){
			if(level_param == other){
				ImGui_InputText("Param Name", param_name, 64);
			}
			ImGui_InputText("After", string_param_after, 64);
		}else if(param_type == float_param){
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}else if(param_type == vec3_param){
			ImGui_InputFloat3("After", vec3_param_after);
		}else if(param_type == vec3_color_param){
			ImGui_ColorPicker3("After", vec3_param_after, 0);
		}else if(param_type == int_param){
			ImGui_InputInt("After", int_param_after);
		}
	}

	void GetBeforeParam(){
		if(has_function){
			switch(level_param){
				case sun_position:
					vec3_param_before = GetSunPosition();
					break;
				case sun_color:
					vec3_param_before = GetSunColor();
					break;
				case sun_intensity:
					float_param_before = GetSunAmbient();
					break;
				case sky_tint:
					vec3_param_before = GetSkyTint();
					break;
				case hdr_black_point:
					float_param_before = GetHDRBlackPoint() * 100.0f;
					break;
				case hdr_bloom_multiplier:
					float_param_before = GetHDRBloomMult() * 100.0f;
					break;
				case hdr_white_point:
					float_param_before = GetHDRWhitePoint() * 100.0f;
					break;
				default:
					Log(warning, "Found a non standard parameter type. " + param_type);
					break;
			}
		}else{
			ScriptParams@ params = level.GetScriptParams();

			if(!params.HasParam(param_name)){
				delete_before = true;
				return;
			}else{
				delete_before = false;
			}

			if(param_type == string_param){
				if(!params.HasParam(param_name)){
					params.AddString(param_name, string_param_after);
				}
				string_param_before = params.GetString(param_name);
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddFloat(param_name, float_param_after);
				}
				float current_value = params.GetFloat(param_name);
				if(mult_100_params.find(level_param) != -1){
					current_value *= 100.0f;
				}
				float_param_before = current_value;
			}else if(param_type == int_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, int_param_after);
				}
				int_param_before = params.GetInt(param_name);
			}
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
		if(has_function){
			switch(level_param){
				case sky_tint:
					{
						ScriptParams@ params = level.GetScriptParams();
						vec3 new_color = reset?vec3_param_before:vec3_param_after;
						params.SetString("Sky Tint", int(new_color.x * 255) + ", " + int(new_color.y * 255) + ", " + int(new_color.z * 255));
						SetSkyTint(new_color);
					}
					break;
				case sun_position:
					SetSunPosition(reset?vec3_param_before:vec3_param_after);
					break;
				case sun_color:
					SetSunColor(reset?vec3_param_before:vec3_param_after);
					break;
				case sun_intensity:
					SetSunAmbient(reset?float_param_before:float_param_after);
					break;
				case hdr_black_point:
					SetHDRBlackPoint((reset?float_param_before:float_param_after) / 100.0f);
					break;
				case hdr_bloom_multiplier:
					SetHDRBloomMult((reset?float_param_before:float_param_after) / 100.0f);
					break;
				case hdr_white_point:
					SetHDRWhitePoint((reset?float_param_before:float_param_after) / 100.0f);
					break;
				default:
					Log(warning, "Found a non standard parameter type. " + param_type);
					break;
			}
		}else{
			ScriptParams@ params = level.GetScriptParams();

			if(reset && delete_before){
				params.Remove(param_name);
				return true;
			}

			if(param_type == string_param){
				params.SetString(param_name, reset?string_param_before:string_param_after);
			}else if(param_type == float_param){
				float new_value = reset?float_param_before:float_param_after;
				if(mult_100_params.find(level_param) != -1){
					new_value /= 100.0f;
				}
				params.SetFloat(param_name, new_value);
			}else if(param_type == int_param){
				params.SetInt(param_name, reset?int_param_before:int_param_after);
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
