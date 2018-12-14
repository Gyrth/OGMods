enum character_params { 	aggression = 0,
							attack_damage = 1,
							attack_knockback = 2,
							attack_speed = 3,
							block_followup = 4,
							block_skill = 5,
							cannot_be_disarmed = 6,
							character_scale = 7,
							damage_resistance = 8,
							ear_size = 9,
							fat = 10,
							focus_fov_distance = 11,
							focus_fov_horizontal = 12,
							focus_fov_vertical = 13,
							ground_aggression = 14,
							knocked_out_shield = 15,
							left_handed = 16,
							movement_speed = 17,
							muscle = 19,
							peripheral_fov_distance = 20,
							peripheral_fov_horizontal = 21,
							peripheral_fov_vertical = 22,
							species = 23,
							static_char = 24,
							teams = 25
					};

class DrikaSetCharacterParam : DrikaElement{
	int current_type;
	int character_id;

	string string_param_before;
	string string_param_after;

	int int_param_before = 0;
	int int_param_after = 0;

	float float_param_before = 0.0;
	float float_param_after = 0.0;

	param_types param_type;
	character_params character_param;
	string param_name;

	array<int> string_parameters = {species, teams};
	array<int> float_parameters = {aggression, attack_damage, attack_knockback, attack_speed, block_followup, block_skill, character_scale, damage_resistance, ear_size, fat, focus_fov_distance, focus_fov_horizontal, focus_fov_vertical, ground_aggression, movement_speed, muscle, peripheral_fov_distance, peripheral_fov_horizontal, peripheral_fov_vertical};
	array<int> int_parameters = {knocked_out_shield};
	array<int> bool_parameters = {cannot_be_disarmed, left_handed, static_char};

	array<string> param_names = {	"Aggression",
	 								"Attack Damage",
									"Attack Knockback",
									"Attack Speed",
									"Block Follow-up",
									"Block Skill",
									"Cannot Be Disarmed",
									"Character Scale",
									"Damage Resistance",
									"Ear Size",
									"Fat",
									"Focus FOV distance",
									"Focus FOV horizontal",
									"Focus FOV vertical",
									"Ground Aggression",
									"Knockout Shield",
									"Left handed",
									"Movement Speed",
									"Muscle",
									"Peripheral FOV distance",
									"Peripheral FOV horizontal",
									"Peripheral FOV vertical",
									"Species",
									"Static",
									"Teams"
								};

	DrikaSetCharacterParam(string _identifier = "-1", string _param_type = "0", string _param_after = "50.0"){
		character_param = character_params(atoi(_param_type));
		character_id = atoi(_identifier);
		current_type = param_type;

		drika_element_type = drika_set_character_param;
		string_param_after = _param_after;
		has_settings = true;
		SetParamType();
		SetParamName();
	}

	void SetParamType(){
		if(string_parameters.find(character_param) != -1){
			param_type = string_param;
		}else if(float_parameters.find(character_param) != -1){
			param_type = float_param;
		}else if(int_parameters.find(character_param) != -1){
			param_type = int_param;
		}else if(int_parameters.find(character_param) != -1){
			param_type = bool_param;
		}
	}

	void SetParamName(){
		param_name = param_names[param_type];
	}

	void Delete(){
		SetParameter(true);
	}

	void GetBeforeParam(){
		if(ObjectExists(character_id)){
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
			}else if(param_type == int_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, int_param_after);
				}
				int_param_before = params.GetInt(param_name);
			}else if(param_type == bool_param){
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
		if(param_type == int_param){
			string_param_after = "" + int_param_after;
		}else if(param_type == float_param){
			string_param_after = "" + float_param_after;
		}
		return "set_character_param" + param_delimiter + character_id + param_delimiter + int(character_param) + param_delimiter + string_param_after;
	}

	string GetDisplayString(){
		return "SetCharacterParam " + character_id + " " + string_param_after;
	}

	void AddSettings(){
		ImGui_InputInt("Character ID", character_id);

		if(ImGui_Combo("Param Type", current_type, param_names)){
			character_param = character_params(current_type);
			SetParamType();
			SetParamName();
		}

		switch(character_param){
			case aggression:
				ImGui_SliderFloat("Aggression", float_param_after, 0.0, 1.0, "%.3f");
				break;
			case attack_damage:
				ImGui_SliderFloat("Attack Damage", float_param_after, 0.0, 2.0, "%.2f");
				break;
			case attack_knockback:
				ImGui_SliderFloat("Attack Knockback", float_param_after, 0.0, 2.0, "%.2f");
				break;
			case attack_speed:
				ImGui_SliderFloat("Attack Speed", float_param_after, 0.0, 2.0, "%.2f");
				break;
			case block_followup:
				ImGui_SliderFloat("Block Follow-up", float_param_after, 0.0, 1.0, "%.2f");
				break;
			case block_skill:
				ImGui_SliderFloat("Block Skill", float_param_after, 0.0, 1.0, "%.2f");
				break;
			case cannot_be_disarmed:
				params.AddIntCheckbox("Cannot Be Disarmed", (int_param_after == 1)?true:false);
				break;
			case character_scale:
				ImGui_SliderFloat("Character Scale", float_param_after, 0.6, 1.4, "%.2f");
				break;
			case damage_resistance:
				ImGui_SliderFloat("Damage Resistance", float_param_after, 0.0, 2.0, "%.2f");
				break;
			case ear_size:
				ImGui_SliderFloat("Ear Size", float_param_after, 0.0, 3.0, "%.2f");
				break;
			case fat:
				ImGui_SliderFloat("Fat", float_param_after, 0.0, 1.0, "%.2f");
				break;
			case focus_fov_distance:
				ImGui_SliderFloat("Focus FOV distance", float_param_after, 0.0, 100.0, "%.2f");
				break;
			case focus_fov_horizontal:
				ImGui_SliderFloat("Focus FOV horizontal", float_param_after, 0.01, 1.570796, "%.2f");
				break;
			case focus_fov_vertical:
				ImGui_SliderFloat("Focus FOV vertical", float_param_after, 0.01, 1.570796, "%.2f");
				break;
			case ground_aggression:
				ImGui_SliderFloat("Ground Aggression", float_param_after, 0.0, 1.0, "%.2f");
				break;
			case knocked_out_shield:
				params.AddIntSlider("Knockout Shield", int_param_after,"min:0,max:10");
				break;
			case left_handed:
				params.AddIntCheckbox("Left handed", (int_param_after == 1)?true:false);
				break;
			case movement_speed:
				ImGui_SliderFloat("Movement Speed", float_param_after, 0.1, 1.5, "%.2f");
				break;
			case muscle:
				ImGui_SliderFloat("Muscle", float_param_after, 0.0, 1.0, "%.2f");
				break;
			case peripheral_fov_distance:
				ImGui_SliderFloat("Peripheral FOV distance", float_param_after, 0.0, 100.0, "%.2f");
				break;
			case peripheral_fov_horizontal:
				ImGui_SliderFloat("Peripheral FOV horizontal", float_param_after, 0.01, 1.570796, "%.2f");
				break;
			case peripheral_fov_vertical:
				ImGui_SliderFloat("Peripheral FOV vertical", float_param_after, 0.01, 1.570796, "%.2f");
				break;
			case species:
				params.AddString("Species", string_param_after);
				break;
			case static_char:
				params.AddIntCheckbox("Static", (int_param_after == 1)?true:false);
				break;
			case teams:
				params.AddString("Teams", string_param_after);
				break;
			default:
				Log(warning, "Found a non standard parameter type. " + param_type);
				break;
		}
	}

	void DrawEditing(){
		if(identifier_type == id && character_id != -1 && ObjectExists(character_id)){
			Object@ target_object = ReadObjectFromID(character_id);
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
		if(target_object.GetType() == _movement_object){
			MovementObject@ char = ReadCharacterID(target_object.GetID());
			char.Execute("SetParameters();");
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
