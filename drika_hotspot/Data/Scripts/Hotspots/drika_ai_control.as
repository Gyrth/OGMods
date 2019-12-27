enum ai_goals {
				_patrol,
				_attack,
				_investigate,
				_get_help,
				_escort,
				_get_weapon,
				_navigate,
				_struggle,
				_hold_still,
				_flee
			};

enum ai_sub_goals {
					_unknown,
					_provoke_attack,
					_avoid_jump_kick,
					_knock_off_ledge,
					_wait_and_attack,
					_rush_and_attack,
					_defend,
					_surround_target,
					_escape_surround,
					_investigate_slow,
					_investigate_urgent,
					_investigate_body,
					_investigate_around,
					_investigate_attack
				};

class DrikaAIControl : DrikaElement{
	int current_ai_goal;
	int current_ai_sub_goal;
	int ai_goal;
	int ai_sub_goal;

	array<string> ai_goal_names = {		"Patrol",
										"Attack",
										"Investigate",
										"Get Help",
										"Escort",
										"Get Weapon",
										"Navigate",
										"Struggle",
										"Hold Still",
										"Flee"
									};

	array<string> ai_sub_goal_names = {
										"Unknown",
										"Provoke Attack",
										"Avoid Jump Kick",
										"Knock Off Ledge",
										"Wait and Attack",
										"Rush and Attack",
										"Defend",
										"Surround Target",
										"Escape Surround",
										"Investigate Slow",
										"Investigate Urgent",
										"Investigate Body",
										"Investigate Around",
										"Investigate Attack"
									};

	DrikaAIControl(JSONValue params = JSONValue()){
		ai_goal = ai_goals(GetJSONInt(params, "ai_goal", _investigate));
		current_ai_goal = ai_goal;
		ai_sub_goal = ai_sub_goals(GetJSONInt(params, "ai_sub_goal", _investigate_slow));
		current_ai_sub_goal = ai_sub_goal;
		show_team_option = true;
		show_name_option = true;

		connection_types = {_movement_object};
		drika_element_type = drika_ai_control;
		has_settings = true;
		LoadIdentifier(params);
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("ai_control");
		data["ai_goal"] = JSONValue(ai_goal);
		data["ai_sub_goal"] = JSONValue(ai_sub_goal);
		SaveIdentifier(data);
		return data;
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
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

		if(ImGui_Combo("AISubGoal", current_ai_sub_goal, ai_sub_goal_names)){
			ai_sub_goal = ai_sub_goals(current_ai_sub_goal);
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			targets[i].Execute("nav_target = vec3(0,0,0);");
			targets[i].Execute("SetGoal(AIGoal(" + ai_goal + "));");
			targets[i].Execute("SetSubGoal(AISubGoal(" + (ai_sub_goal - 1) + "));");
			switch(ai_goal){
				case _patrol:
					break;
				case _attack:
					break;
				case _investigate:
					break;
				case _get_help:
					break;
				case _escort:
					break;
				case _get_weapon:
					break;
				case _navigate:
					break;
				case _struggle:
					break;
				case _hold_still:
					break;
				case _flee:
					break;

				default:
					break;
			}
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
