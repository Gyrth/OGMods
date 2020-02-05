enum character_options { 	aggression = 0,
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
							muscle = 18,
							peripheral_fov_distance = 19,
							peripheral_fov_horizontal = 20,
							peripheral_fov_vertical = 21,
							species = 22,
							static_char = 23,
							teams = 24,
							fall_damage_mult = 25,
							fear_afraid_at_health_level = 26,
							fear_always_afraid_on_sight = 27,
							fear_causes_fear_on_sight = 28,
							fear_never_afraid_on_sight = 29,
							no_look_around = 30,
							stick_to_nav_mesh = 31,
							throw_counter_probability = 32,
							is_throw_trainer = 33,
							weapon_catch_skill = 34,
							wearing_metal_armor = 35,
							ignite = 36,
							extinguish = 37,
							is_player = 38,
							kill = 39,
							revive = 40,
							limp_ragdoll = 41,
							injured_ragdoll = 42,
							ragdoll = 43,
							cut_throat = 44,
							apply_damage = 45,
							wet = 46
					};

class DrikaCharacterControl : DrikaElement{
	int current_type;

	string string_param_after = "";
	int int_param_after = 0;
	bool bool_param_after = false;
	float float_param_after = 0.0;
	float recovery_time;
	float roll_recovery_time;
	float damage_amount;
	float wet_amount;

	array<BeforeValue@> params_before;

	param_types param_type;
	character_options character_option;
	string param_name;

	array<int> string_parameters = {species, teams};
	array<int> float_parameters = {aggression, attack_damage, attack_knockback, attack_speed, block_followup, block_skill, character_scale, damage_resistance, ear_size, fat, focus_fov_distance, focus_fov_horizontal, focus_fov_vertical, ground_aggression, movement_speed, muscle, peripheral_fov_distance, peripheral_fov_horizontal, peripheral_fov_vertical, fall_damage_mult, fear_afraid_at_health_level, throw_counter_probability, weapon_catch_skill};
	array<int> int_parameters = {knocked_out_shield};
	array<int> bool_parameters = {cannot_be_disarmed, left_handed, static_char, fear_always_afraid_on_sight, fear_causes_fear_on_sight, fear_never_afraid_on_sight, no_look_around, stick_to_nav_mesh, is_throw_trainer, wearing_metal_armor};
	array<int> function_parameters = {ignite, extinguish, is_player, kill, revive, limp_ragdoll, injured_ragdoll, ragdoll, cut_throat, apply_damage, wet};

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
									"Teams",
									"Fall Damage Multiplier",
									"Fear - Afraid At Health Level",
									"Fear - Always Afraid On Sight",
									"Fear - Causes Fear On Sight",
									"Fear - Never Afraid On Sight",
									"No Look Around",
									"Stick To Nav Mesh",
									"Throw Counter Probability",
									"Throw Trainer",
									"Weapon Catch Skill",
									"Wearing Metal Armor",
									"Ignite",
									"Extinguish",
									"Is Player",
									"Kill",
									"Revive",
									"Limp Ragdoll",
									"Injured Ragdoll",
									"Ragdoll",
									"Cut Throat",
									"Apply Damage",
									"Wet"
								};

	DrikaCharacterControl(JSONValue params = JSONValue()){
		character_option = character_options(GetJSONInt(params, "character_option", 0));
		current_type = character_option;
		param_type = param_types(GetJSONInt(params, "param_type", 0));

		show_team_option = true;
		show_name_option = true;
		show_character_option = true;

		recovery_time = GetJSONFloat(params, "recovery_time", 1.0);
		roll_recovery_time = GetJSONFloat(params, "roll_recovery_time", 0.2);
		damage_amount = GetJSONFloat(params, "damage_amount", 1.0);
		wet_amount = GetJSONFloat(params, "wet_amount", 1.0);

		connection_types = {_movement_object};
		drika_element_type = drika_character_control;
		has_settings = true;
		LoadIdentifier(params);
		SetParamType();
		InterpParam(params);
		SetParamName();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["character_option"] = JSONValue(character_option);
		data["param_type"] = JSONValue(param_type);
		if(param_type == int_param){
			data["param_after"] = JSONValue(int_param_after);
		}else if(param_type == float_param){
			data["param_after"] = JSONValue(float_param_after);
		}else if(param_type == bool_param){
			data["param_after"] = JSONValue(bool_param_after);
		}else if(param_type == string_param){
			data["param_after"] = JSONValue(string_param_after);
		}
		if(character_option == limp_ragdoll || character_option == injured_ragdoll || character_option == ragdoll){
			data["recovery_time"] = JSONValue(recovery_time);
			data["roll_recovery_time"] = JSONValue(roll_recovery_time);
		}else if(character_option == apply_damage){
			data["damage_amount"] = JSONValue(damage_amount);
		}else if(character_option == wet){
			data["wet_amount"] = JSONValue(wet_amount);
		}
		SaveIdentifier(data);
		return data;
	}

	void SetParamType(){
		if(string_parameters.find(character_option) != -1){
			param_type = string_param;
		}else if(float_parameters.find(character_option) != -1){
			param_type = float_param;
		}else if(int_parameters.find(character_option) != -1){
			param_type = int_param;
		}else if(bool_parameters.find(character_option) != -1){
			param_type = bool_param;
		}else if(function_parameters.find(character_option) != -1){
			param_type = function_param;
		}
	}

	void InterpParam(JSONValue _params){
		if(param_type == float_param){
			float_param_after = GetJSONFloat(_params, "param_after", 0.0);
		}else if(param_type == int_param){
			int_param_after = GetJSONInt(_params, "param_after", 0);
		}else if(param_type == bool_param){
			bool_param_after = GetJSONBool(_params, "param_after", false);
		}else if(param_type == string_param){
			string_param_after = GetJSONString(_params, "param_after", "");
		}else if(param_type == function_param){
			//This type doesn't have any parameters.
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void SetParamName(){
		param_name = param_names[character_option];
	}

	void GetBeforeParam(){
		//Use the Objects in stead of MovementObject so that the params are available.
		array<Object@> targets = GetTargetObjects();
		params_before.resize(0);

		for(uint i = 0; i < targets.size(); i++){
			ScriptParams@ params = targets[i].GetScriptParams();
			params_before.insertLast(BeforeValue());

			if(!params.HasParam(param_name)){
				params_before[i].delete_before = true;
				return;
			}else{
				params_before[i].delete_before = false;
			}

			if(param_type == string_param){
				if(!params.HasParam(param_name)){
					params.AddString(param_name, string_param_after);
				}
				params_before[i].string_value = params.GetString(param_name);
			}else if(param_type == float_param){
				if(!params.HasParam(param_name)){
					params.AddFloat(param_name, float_param_after);
				}
				params_before[i].float_value = params.GetFloat(param_name);
			}else if(param_type == int_param){
				if(!params.HasParam(param_name)){
					params.AddInt(param_name, int_param_after);
				}
				params_before[i].int_value = params.GetInt(param_name);
			}else if(param_type == bool_param){
				if(!params.HasParam(param_name)){
					params.AddIntCheckbox(param_name, bool_param_after);
				}
				params_before[i].bool_value = (params.GetInt(param_name) == 1);
			}else if(character_option == is_player){
				if(targets[i].GetType() == _movement_object){
					MovementObject@ char = ReadCharacterID(targets[i].GetID());
					params_before[i].bool_value = char.is_player;
				}
			}
		}
	}

	string GetDisplayString(){
		string display_string;
		if(param_type == int_param){
			display_string = "" + int_param_after;
		}else if(param_type == float_param){
			display_string = "" + float_param_after;
		}else if(param_type == bool_param){
			display_string = bool_param_after?"true":"false";
		}else if(param_type == string_param){
			display_string = string_param_after;
		}
		return "SetCharacterParam " + GetTargetDisplayText() + " " + param_name + " " + display_string;
	}

	void StartSettings(){
		CheckReferenceAvailable();
		CheckCharactersAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		if(ImGui_Combo("Param Type", current_type, param_names)){
			character_option = character_options(current_type);
			SetParamType();
			SetParamName();
		}

		switch(character_option){
			case aggression:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.2f");
				break;
			case attack_damage:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.1f");
				break;
			case attack_knockback:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.1f");
				break;
			case attack_speed:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.1f");
				break;
			case block_followup:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case block_skill:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case cannot_be_disarmed:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case character_scale:
				ImGui_SliderFloat(param_name, float_param_after, 60, 140, "%.2f");
				break;
			case damage_resistance:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.1f");
				break;
			case ear_size:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 300.0, "%.1f");
				break;
			case fat:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.3f");
				break;
			case focus_fov_distance:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case focus_fov_horizontal:
				ImGui_SliderFloat(param_name, float_param_after, 0.573, 90.0, "%.2f");
				break;
			case focus_fov_vertical:
				ImGui_SliderFloat(param_name, float_param_after, 0.573, 90.0, "%.2f");
				break;
			case ground_aggression:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.2f");
				break;
			case knocked_out_shield:
				ImGui_SliderInt(param_name, int_param_after, 0, 10);
				break;
			case left_handed:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case movement_speed:
				ImGui_SliderFloat(param_name, float_param_after, 10.0, 150.0, "%.1f");
				break;
			case muscle:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 200.0, "%.3f");
				break;
			case peripheral_fov_distance:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case peripheral_fov_horizontal:
				ImGui_SliderFloat(param_name, float_param_after, 0.573, 90.0, "%.2f");
				break;
			case peripheral_fov_vertical:
				ImGui_SliderFloat(param_name, float_param_after, 0.573, 90.0, "%.2f");
				break;
			case species:
				ImGui_InputText(param_name, string_param_after, 64);
				break;
			case static_char:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case teams:
				ImGui_InputText(param_name, string_param_after, 64);
				break;
			case fall_damage_mult:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 10.0, "%.1f");
				break;
			case fear_afraid_at_health_level:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.2f");
				break;
			case fear_always_afraid_on_sight:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case fear_causes_fear_on_sight:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case fear_never_afraid_on_sight:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case no_look_around:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case stick_to_nav_mesh:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case throw_counter_probability:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case is_throw_trainer:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case weapon_catch_skill:
				ImGui_SliderFloat(param_name, float_param_after, 0.0, 100.0, "%.1f");
				break;
			case wearing_metal_armor:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case ignite:
				break;
			case extinguish:
				break;
			case is_player:
				ImGui_Checkbox(param_name, bool_param_after);
				break;
			case kill:
				break;
			case revive:
				break;
			case limp_ragdoll:
				ImGui_SliderFloat("Recovery Time", recovery_time, 0.0, 10.0, "%.1f");
				ImGui_SliderFloat("Roll Recovery Time", roll_recovery_time, 0.0, 10.0, "%.1f");
				break;
			case injured_ragdoll:
				ImGui_SliderFloat("Recovery Time", recovery_time, 0.0, 10.0, "%.1f");
				ImGui_SliderFloat("Roll Recovery Time", roll_recovery_time, 0.0, 10.0, "%.1f");
				break;
			case ragdoll:
				ImGui_SliderFloat("Recovery Time", recovery_time, 0.0, 10.0, "%.1f");
				ImGui_SliderFloat("Roll Recovery Time", roll_recovery_time, 0.0, 10.0, "%.1f");
				break;
			case apply_damage:
				ImGui_SliderFloat("Amount", damage_amount, 0.0, 2.0, "%.1f");
				break;
			case cut_throat:
				break;
			case wet:
				ImGui_SliderFloat("Amount", wet_amount, 0.0, 1.0, "%.1f");
				break;
			default:
				Log(warning, "Found a non standard parameter type. " + param_type);
				break;
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
		//Use the Objects in stead of MovementObject so that the params are available.
		array<Object@> targets = GetTargetObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			ScriptParams@ params = targets[i].GetScriptParams();

			if(reset && params_before[i].delete_before){
				params.Remove(param_name);
				return true;
			}

			if(!params.HasParam(param_name) && param_type != function_param){
				if(param_type == string_param){
					params.AddString(param_name, reset?params_before[i].string_value:string_param_after);
				}else if(param_type == int_param){
					params.AddInt(param_name, reset?params_before[i].int_value:int_param_after);
				}else if(param_type == float_param){
					params.AddFloatSlider(param_name, reset?params_before[i].float_value:float_param_after, "min:0,max:1000,step:0.0001,text_mult:1");
				}else if(param_type == bool_param){
					params.AddIntCheckbox(param_name, reset?params_before[i].bool_value:bool_param_after);
				}
			}else{
				switch(character_option){
					case aggression:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case attack_damage:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case attack_knockback:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case attack_speed:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case block_followup:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case block_skill:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case cannot_be_disarmed:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case character_scale:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case damage_resistance:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case ear_size:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case fat:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 200.0);
						break;
					case focus_fov_distance:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after);
						break;
					case focus_fov_horizontal:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 57.2957);
						break;
					case focus_fov_vertical:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 57.2957);
						break;
					case ground_aggression:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case knocked_out_shield:
						params.SetInt(param_name, reset?params_before[i].int_value:int_param_after);
						break;
					case left_handed:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case movement_speed:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case muscle:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 200.0);
						break;
					case peripheral_fov_distance:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after);
						break;
					case peripheral_fov_horizontal:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 57.2957);
						break;
					case peripheral_fov_vertical:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 57.2957);
						break;
					case species:
						params.SetString(param_name, reset?params_before[i].string_value:string_param_after);
						break;
					case static_char:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case teams:
						params.SetString(param_name, reset?params_before[i].string_value:string_param_after);
						break;
					case fall_damage_mult:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after);
						break;
					case fear_afraid_at_health_level:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case fear_always_afraid_on_sight:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case fear_causes_fear_on_sight:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case fear_never_afraid_on_sight:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case no_look_around:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case stick_to_nav_mesh:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case throw_counter_probability:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case is_throw_trainer:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case weapon_catch_skill:
						params.SetFloat(param_name, reset?params_before[i].float_value:float_param_after / 100.0);
						break;
					case wearing_metal_armor:
						params.SetInt(param_name, (reset?params_before[i].bool_value:bool_param_after)?1:0);
						break;
					case ignite:
						if(targets[i].GetType() == _movement_object){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							if(!reset){
								char.ReceiveMessage("ignite");
							}else{
								char.ReceiveMessage("extinguish");
							}
						}
						break;
					case extinguish:
						if(!reset){
							if(targets[i].GetType() == _movement_object){
								MovementObject@ char = ReadCharacterID(targets[i].GetID());
								char.ReceiveMessage("extinguish");
							}
						}
						break;
					case is_player:
						if(targets[i].GetType() == _movement_object){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.is_player = reset?params_before[i].bool_value:bool_param_after;
						}
						break;
					case kill:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("temp_health = -1.0;permanent_health = -1.0;blood_health = -1.0;SetKnockedOut(_dead);CharacterDefeated();Ragdoll(_RGDL_LIMP);");
						}
						break;
					case revive:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.QueueScriptMessage("full_revive");
						}
						break;
					case limp_ragdoll:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("Ragdoll(_RGDL_LIMP);recovery_time = " + recovery_time + ";roll_recovery_time = " + roll_recovery_time + ";");
						}
						break;
					case injured_ragdoll:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("if(state != _ragdoll_state){string sound = \"Data/Sounds/hit/hit_hard.xml\";PlaySoundGroup(sound, this_mo.position);}Ragdoll(_RGDL_INJURED);recovery_time = " + recovery_time + ";roll_recovery_time = " + roll_recovery_time + ";");
						}
						break;
					case ragdoll:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("GoLimp();recovery_time = " + recovery_time + ";roll_recovery_time = " + roll_recovery_time + ";");
						}
						break;
					case cut_throat:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("CutThroat();");
						}
						break;
					case apply_damage:
						if(!reset){
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.Execute("TakeBloodDamage(" + damage_amount + ");if(knocked_out != _awake){Ragdoll(_RGDL_INJURED);}");
						}
						break;
					case wet:
						{
							MovementObject@ char = ReadCharacterID(targets[i].GetID());
							char.rigged_object().SetWet(reset?0.0:wet_amount);
						}
						break;
					default:
						Log(warning, "Found a non standard parameter type. " + param_type);
						break;
				}
			}

			//To make sure the parameters are being used, refresh them in aschar.
			if(targets[i].GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(targets[i].GetID());
				char.Execute("SetParameters();");
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
