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
					}

array<int> string_parameters = {achievements, custom_shaders, gpu_particle_field, load_tip, objectives};
array<int> float_parameters = {fog_amount, hdr_black_point, hdr_bloom_multiplier, hdr_white_point, saturation, sky_brightness, sky_rotation, sun_intensity};
array<int> vec3_parameters = {sun_position};
array<int> vec3color_parameters = {sky_tint, sun_color};
array<int> int_parameters = {level_boundaries};
array<int> function_parameters = {sky_tint, hdr_black_point, hdr_bloom_multiplier, hdr_white_point, sun_position, sun_color, sun_intensity};

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
								"Sun Intensity"
							};


class DrikaSetLevelParam : DrikaElement{
	int current_type;
	string param_name;
	bool has_function = false;

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

	DrikaSetLevelParam(int _level_param = 0, string _param_after = "no_kills"){

		level_param = level_params(_level_param);
		current_type = level_param;

		drika_element_type = drika_set_level_param;
		has_settings = true;

		string_param_after = _param_after;

		Log(info, string_param_after);

		SetParamType();
		InterpParam();
		GetBeforeParam();
		param_name = param_names[current_type];
	}

	void SetParamType(){
		if(string_parameters.find(level_param) != -1){
			param_type = string_param;
		}else if(float_parameters.find(level_param) != -1){
			param_type = float_param;
		}else if(vec3_parameters.find(level_param) != -1){
			param_type = vec3_param;
		}else if(vec3color_parameters.find(level_param) != -1){
			param_type = vec3color_param;
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
		if(param_type == vec3_param || param_type == vec3color_param){
			vec3_param_after = StringToVec3(string_param_after);
		}else if(param_type == float_param){
			float_param_after = atof(string_param_after);
		}else if(param_type == int_param){
			int_param_after = atoi(string_param_after);
		}
	}

	string GetSaveString(){
		if(param_type == vec3_param || param_type == vec3color_param){
			string_param_after = Vec3ToString(vec3_param_after);
		}else if(param_type == float_param){
			string_param_after = "" + float_param_after;
		}else if(param_type == int_param){
			string_param_after = "" + int_param_after;
		}
		return "set_level_param " + int(level_param) + " " + string_param_after;
	}

	string GetDisplayString(){
		return "SetLevelParam " + param_name + " " + string_param_after;
	}

	void AddSettings(){
		if(ImGui_Combo("Param Type", current_type, param_names)){
			level_param = level_params(current_type);
			param_name = param_names[current_type];
			SetParamType();
			GetBeforeParam();
		}

		if(param_type == string_param){
			ImGui_InputText("After", string_param_after, 64);
		}else if(param_type == float_param){
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}else if(param_type == vec3_param){
			ImGui_InputFloat3("After", vec3_param_after);
		}else if(param_type == vec3color_param){
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
					float_param_before = GetHDRBlackPoint();
					break;
				case hdr_bloom_multiplier:
					float_param_before = GetHDRBloomMult();
					break;
				case hdr_white_point:
					float_param_before = GetHDRWhitePoint();
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
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddFloat(param_name, 0.0f);
				}
				float_param_before = params.GetFloat(param_name);
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, 0);
				}
				int_param_before = params.GetInt(param_name);
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
					SetSkyTint(reset?vec3_param_before:vec3_param_after);
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
					SetHDRBlackPoint(reset?float_param_before:float_param_after);
					break;
				case hdr_bloom_multiplier:
					SetHDRBloomMult(reset?float_param_before:float_param_after);
					break;
				case hdr_white_point:
					SetHDRWhitePoint(reset?float_param_before:float_param_after);
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
