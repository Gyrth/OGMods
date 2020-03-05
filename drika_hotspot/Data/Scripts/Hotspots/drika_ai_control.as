enum ai_goals {
				_patrol,
				_attack,
				_investigate_slow,
				_investigate_urgent,
				_investigate_around,
				_get_help,
				_escort,
				_get_weapon,
				_get_closest_weapon,
				_throw_weapon
			};

class DrikaAIControl : DrikaElement{
	int current_ai_goal;
	int ai_goal;
	TargetSelect ai_target(this, "ai_target");

	array<ai_goals> goals_with_placeholders = {_investigate_slow, _investigate_urgent};

	array<string> ai_goal_names = {		"Patrol",
										"Attack",
										"Investigate Slow",
										"Investigate Urgent",
										"Investigate Around",
										"Get Help",
										"Escort",
										"Get Weapon",
										"Get Closest Weapon",
										"Throw Weapon"
									};

	DrikaAIControl(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "AIControl Helper";
		ai_goal = ai_goals(GetJSONInt(params, "ai_goal", _investigate_slow));
		current_ai_goal = ai_goal;

		connection_types = {_movement_object};
		drika_element_type = drika_ai_control;
		has_settings = true;

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;
		ai_target.LoadIdentifier(params);
		SetTargetOptions();
	}

	void SetTargetOptions(){
		if(ai_goal == _patrol){
			ai_target.target_option = id_option | reference_option;
		}else if(ai_goal == _get_weapon){
			ai_target.target_option = id_option | reference_option | item_option;
		}else if(ai_goal == _attack || ai_goal == _escort){
			ai_target.target_option = id_option | name_option | character_option | reference_option | team_option;
		}else if(ai_goal == _throw_weapon){
			ai_target.target_option = character_option;
		}
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		if(goals_with_placeholders.find(ai_goals(ai_goal)) != -1){
			data["placeholder_id"] = JSONValue(placeholder_id);
		}
		data["ai_goal"] = JSONValue(ai_goal);
		target_select.SaveIdentifier(data);
		ai_target.SaveIdentifier(data);
		return data;
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			PlaceholderCheck();
			if(placeholder_id != -1 && ObjectExists(placeholder_id)){
				DebugDrawLine(placeholder.GetTranslation(), targets[i].position, vec3(0.0, 1.0, 0.0), _delete_on_update);
				DebugDrawBillboard("Data/Textures/ui/challenge_mode/quit_icon_c.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_update);
			}

			if(ai_goal == _patrol || ai_goal == _attack || ai_goal == _escort || ai_goal == _get_weapon || ai_goal == _throw_weapon){
				array<Object@> ai_targets = ai_target.GetTargetObjects();

				for(uint j = 0; j < ai_targets.size(); j++){
					vec3 target_location = ai_targets[j].GetTranslation();

					if(ai_targets[j].GetType() == _item_object){
						ItemObject@ item_obj = ReadItemID(ai_targets[j].GetID());
						target_location = item_obj.GetPhysicsPosition();
					}else if(ai_targets[j].GetType() == _movement_object){
						MovementObject@ char = ReadCharacterID(ai_targets[j].GetID());
						target_location = char.position;
					}
					DebugDrawLine(targets[i].position, target_location, vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
			}
		}
	}

	void PlaceholderCheck(){
		if(goals_with_placeholders.find(ai_goals(ai_goal)) == -1 && placeholder_id != -1 && ObjectExists(placeholder_id)){
			QueueDeleteObjectID(placeholder_id);
			placeholder_id = -1;
		}else if(goals_with_placeholders.find(ai_goals(ai_goal)) != -1 && (placeholder_id == -1 || !ObjectExists(placeholder_id))){
			CreatePlaceholder();
		}
	}

	string GetDisplayString(){
		string display_text = "AIControl " + target_select.GetTargetDisplayText() + " " + ai_goal_names[ai_goal];
		if(ai_goal == _patrol || ai_goal == _attack || ai_goal == _escort || ai_goal == _get_weapon || ai_goal == _throw_weapon){
			display_text += " " + ai_target.GetTargetDisplayText();
		}
		return display_text;
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
		ai_target.CheckAvailableTargets();
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("AIGoal");
		ImGui_SameLine();
		if(ImGui_Combo("##AIGoal", current_ai_goal, ai_goal_names)){
			ai_goal = ai_goals(current_ai_goal);
			SetTargetOptions();
			StartSettings();
		}

		if(ai_goal == _patrol || ai_goal == _attack || ai_goal == _escort || ai_goal == _get_weapon || ai_goal == _throw_weapon){
			ImGui_Separator();
			if(ai_goal == _patrol){
				ImGui_Text("Pathpoint");
			}else if(ai_goal == _attack){
				ImGui_Text("Attack Character");
			}else if(ai_goal == _escort){
				ImGui_Text("Escort Character");
			}else if(ai_goal == _get_weapon){
				ImGui_Text("Weapon");
			}else if(ai_goal == _throw_weapon){
				ImGui_Text("Target Character");
			}
			ai_target.DrawSelectTargetUI();
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		array<Object@> ai_targets = ai_target.GetTargetObjects();
		if(targets.size() == 0){return false;}

		if(ai_goal == _patrol || ai_goal == _attack || ai_goal == _escort || ai_goal == _get_weapon || ai_goal == _throw_weapon){
			if(ai_targets.size() == 0){
				return false;
			}
		}

		for(uint i = 0; i < targets.size(); i++){
			string command;

			switch(ai_goal){
				case _patrol:
					{
						for(uint j = 0; j < ai_targets.size(); j++){
							if(ai_targets[j].GetType() == _path_point_object){
								ReadObjectFromID(targets[i].GetID()).ConnectTo(ai_targets[j]);
							}
						}
						command += "SetGoal(_patrol);";
					}
					break;
				case _attack:
					{
						for(uint j = 0; j < ai_targets.size(); j++){
							command += "Notice(" + ai_targets[j].GetID() + ");";
						}
						command += "SetGoal(_attack);";
					}
					break;
				case _investigate_slow:
					{
						vec3 target_pos = placeholder.GetTranslation();
						command += "nav_target = vec3(" + target_pos.x + "," + target_pos.y + "," + target_pos.z + ");";
						command += "SetGoal(_investigate);";
						command += "SetSubGoal(_investigate_slow);";
					}
					break;
				case _investigate_urgent:
					{
						vec3 target_pos = placeholder.GetTranslation();
						command += "nav_target = vec3(" + target_pos.x + "," + target_pos.y + "," + target_pos.z + ");";
						command += "SetGoal(_investigate);";
						command += "SetSubGoal(_investigate_urgent);";
					}
					break;
				case _investigate_around:
					{
						command += "nav_target = this_mo.position;";
						command += "SetGoal(_investigate);";
						command += "SetSubGoal(_investigate_around);";
						command += "investigate_target_id = -1;";
					}
					break;
				case _get_help:
					command += "ally_id = GetClosestCharacterID(1000.0f, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE | _TC_KNOWN);";
					command += "SetGoal(_get_help);";
					break;
				case _escort:
					{
						for(uint j = 0; j < ai_targets.size(); j++){
							command += "escort_id = " + ai_targets[j].GetID() + ";";
						}
						command += "SetGoal(_escort);";
					}
					break;
				case _get_weapon:
					{
						command += "SetGoal(_get_weapon);";
						for(uint j = 0; j < ai_targets.size(); j++){
							command += "weapon_target_id = " + ai_targets[j].GetID() + ";";
						}
					}
					break;
				case _get_closest_weapon:
					command += "CheckForNearbyWeapons();";
					command += "SetGoal(_get_weapon);";
					break;
				case _throw_weapon:
						{
							int weapon_id = targets[i].GetArrayIntVar("weapon_slots", targets[i].GetIntVar("primary_weapon_slot"));
							if(weapon_id != -1){
								command += "target_id = " + ai_targets[0].GetID() + ";";
								command += "going_to_throw_item = true;";
					            command += "going_to_throw_item_time = time;";
							}
						}
						break;
				default:
					break;
			}

			Log(warning, "Execute " + command);
			targets[i].Execute(command);
		}

		triggered = true;
		return true;
	}

	void Reset(){
		if(triggered){
			array<MovementObject@> targets = target_select.GetTargetMovementObjects();
			array<Object@> ai_targets = ai_target.GetTargetObjects();

			if(ai_goal == _patrol){
				for(uint j = 0; j < ai_targets.size(); j++){
					if(ai_targets[j].GetType() == _path_point_object){
						for(uint i = 0; i < targets.size(); i++){
							ReadObjectFromID(targets[i].GetID()).Disconnect(ai_targets[j]);
						}
					}
				}
			}

			triggered = false;
		}
	}
}
