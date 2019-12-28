enum ai_goals {
				_patrol,
				_attack,
				_investigate_slow,
				_investigate_urgent,
				_investigate_body,
				_investigate_around,
				_investigate_attack,
				_get_help,
				_escort,
				_get_weapon,
				_get_closest_weapon,
				_flee
			};

class DrikaAIControl : DrikaElement{
	int current_ai_goal;
	int ai_goal;

	array<string> ai_goal_names = {		"Patrol",
										"Attack",
										"Investigate Slow",
										"Investigate Urgent",
										"Investigate Body",
										"Investigate Around",
										"Investigate Attack",
										"Get Help",
										"Escort",
										"Get Weapon",
										"Get Closest Weapon",
										"Flee"
									};

	DrikaAIControl(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "AIControl Helper";
		ai_goal = ai_goals(GetJSONInt(params, "ai_goal", _investigate_slow));
		current_ai_goal = ai_goal;
		show_team_option = true;
		show_name_option = true;

		connection_types = {_movement_object};
		drika_element_type = drika_ai_control;
		has_settings = true;
		LoadIdentifier(params);
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("ai_control");
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["ai_goal"] = JSONValue(ai_goal);
		SaveIdentifier(data);
		return data;
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			if(ObjectExists(placeholder_id)){
				DebugDrawLine(placeholder.GetTranslation(), targets[i].position, vec3(0.0, 1.0, 0.0), _delete_on_update);
				DebugDrawBillboard("Data/Textures/ui/challenge_mode/quit_icon_c.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_update);
			}else{
				CreatePlaceholder();
				StartEdit();
			}
		}

	}

	string GetDisplayString(){
		string display_string = "";
		return "AIControl " + GetTargetDisplayText() + " " + display_string;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();

		if(ImGui_Combo("AIGoal", current_ai_goal, ai_goal_names)){
			ai_goal = ai_goals(current_ai_goal);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		string command = "";

		switch(ai_goal){
			case _patrol:

				command += "SetGoal(_patrol);";
				break;
			case _attack:

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
			case _investigate_body:
				{
					vec3 target_pos = placeholder.GetTranslation();
					command += "nav_target = vec3(" + target_pos.x + "," + target_pos.y + "," + target_pos.z + ");";
					command += "SetGoal(_investigate);";
					command += "SetSubGoal(_investigate_body);";
				}
				break;
			case _investigate_around:
				{
					vec3 target_pos = placeholder.GetTranslation();
					command += "nav_target = vec3(" + target_pos.x + "," + target_pos.y + "," + target_pos.z + ");";
					command += "SetGoal(_investigate);";
					command += "SetSubGoal(_investigate_around);";
				}
				break;
			case _investigate_attack:
				{
					vec3 target_pos = placeholder.GetTranslation();
					command += "nav_target = vec3(" + target_pos.x + "," + target_pos.y + "," + target_pos.z + ");";
					command += "SetGoal(_investigate);";
					command += "SetSubGoal(_investigate_attack);";
				}
				break;
			case _get_help:

				command += "SetGoal(_get_help);";
				break;
			case _escort:

				command += "SetGoal(_escort);";
				break;
			case _get_weapon:

				command += "SetGoal(_get_weapon);";
				break;
			case _get_closest_weapon:

				command += "SetGoal(_get_weapon);";
				break;
			case _flee:

				command += "SetGoal(_flee);";
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
			triggered = false;
		}
	}
}
