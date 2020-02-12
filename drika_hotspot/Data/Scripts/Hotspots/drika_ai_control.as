enum ai_goals {
				_patrol,
				_attack,
				_investigate_slow,
				_investigate_urgent,
				_investigate_around,
				_get_help,
				_escort,
				_get_weapon,
				_get_closest_weapon
			};

class DrikaAIControl : DrikaElement{
	int current_ai_goal;
	int ai_goal;
	int target_id;

	array<ai_goals> goals_with_placeholders = {_investigate_slow, _investigate_urgent};

	array<string> ai_goal_names = {		"Patrol",
										"Attack",
										"Investigate Slow",
										"Investigate Urgent",
										"Investigate Around",
										"Get Help",
										"Escort",
										"Get Weapon",
										"Get Closest Weapon"
									};

	DrikaAIControl(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "AIControl Helper";
		ai_goal = ai_goals(GetJSONInt(params, "ai_goal", _investigate_slow));
		target_id = GetJSONInt(params, "target_id", -1);
		current_ai_goal = ai_goal;

		connection_types = {_movement_object};
		drika_element_type = drika_ai_control;
		has_settings = true;

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;
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
		data["target_id"] = JSONValue(target_id);
		target_select.SaveIdentifier(data);
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
		return "AIControl " + ai_goal_names[ai_goal] + " " + target_select.GetTargetDisplayText();
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();

		if(ImGui_Combo("AIGoal", current_ai_goal, ai_goal_names)){
			ai_goal = ai_goals(current_ai_goal);
		}

		if(ai_goal == _patrol){
			ImGui_InputInt("Pathpoint ID", target_id);
		}else if(ai_goal == _attack){
			ImGui_InputInt("Attack Character ID", target_id);
		}else if(ai_goal == _escort){
			ImGui_InputInt("Escord Character ID", target_id);
		}else if(ai_goal == _get_weapon){
			ImGui_InputInt("Weapon ID", target_id);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		string command = "";

		switch(ai_goal){
			case _patrol:
				{
					if(ObjectExists(target_id)){
						Object@ target_object = ReadObjectFromID(target_id);
						if(target_object.GetType() == _path_point_object){
							for(uint i = 0; i < targets.size(); i++){
								ReadObjectFromID(targets[i].GetID()).ConnectTo(target_object);
							}
						}
					}
					command += "SetGoal(_patrol);";
				}
				break;
			case _attack:
				command += "Notice(" + target_id + ");";
				command += "SetGoal(_attack);";
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
				command += "escort_id = " + target_id + ";";
				command += "SetGoal(_escort);";
				break;
			case _get_weapon:
				command += "SetGoal(_get_weapon);";
				command += "weapon_target_id = " + target_id + ";";
				break;
			case _get_closest_weapon:
				command += "CheckForNearbyWeapons();";
				command += "SetGoal(_get_weapon);";
				break;

			default:
				break;
		}

		for(uint i = 0; i < targets.size(); i++){
			Log(warning, "Execute " + command);
			targets[i].Execute(command);
		}

		triggered = true;
		return true;
	}

	void Reset(){
		if(triggered){
			array<MovementObject@> targets = target_select.GetTargetMovementObjects();

			if(ai_goal == _patrol){
				if(ObjectExists(target_id)){
					Object@ target_object = ReadObjectFromID(target_id);
					if(target_object.GetType() == _path_point_object){
						for(uint i = 0; i < targets.size(); i++){
							ReadObjectFromID(targets[i].GetID()).Disconnect(target_object);
						}
					}
				}
			}

			triggered = false;
		}
	}
}
