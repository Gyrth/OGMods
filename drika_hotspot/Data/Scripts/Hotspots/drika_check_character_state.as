enum state_choices { 	awake = 0,
						unconscious = 1,
						dead = 2,
						knows_about = 3,
						in_combat = 4,
						moving = 5,
						attacking = 6,
						ragdolling = 7,
						hit_reacting = 8,
						patrolling = 9,
						investigating = 10,
						getting_help = 11,
						fleeing = 12,
						in_proximity = 13,
						right_footstep = 14,
						left_footstep = 15,
						takes_damage = 16
					}

enum AIGoal {
    _ai_patrol,
    _ai_attack,
    _ai_investigate,
    _ai_get_help,
    _ai_escort,
    _ai_get_weapon,
    _ai_navigate,
    _ai_struggle,
    _ai_hold_still,
    _ai_flee
};

class HealthData{
	int character_id;
	float blood_health;
	float temp_health;
	float permanent_health;

	HealthData(MovementObject@ char){
		character_id = char.GetID();
		blood_health = char.GetFloatVar("blood_health");
		temp_health = char.GetFloatVar("temp_health");
		permanent_health = char.GetFloatVar("permanent_health");
	}

	bool CheckHealthDecreased(){
		if(!MovementObjectExists(character_id)){
			Log(warning, "The target character does not exist anymore! " + character_id);
			return false;
		}

		MovementObject@ char = ReadCharacterID(character_id);
		if(char.GetFloatVar("blood_health") < blood_health){
			return true;
		}else if(char.GetFloatVar("temp_health") < temp_health){
			return true;
		}else if(char.GetFloatVar("permanent_health") < permanent_health){
			return true;
		}
		return false;
	}
}

class DrikaCheckCharacterState : DrikaElement{
	array<string> state_choice_names = {"Awake", "Unconscious", "Dead", "Knows About", "In Combat", "Moving", "Attacking", "Ragdolling", "Blocked Attack", "AI Patrolling", "AI Investigating", "AI Getting Help", "AI Fleeing", "In Proximity", "Right Footstep", "Left Footstep", "Takes Damage"};
	state_choices state_choice;
	int current_state_choice;
	bool equals = true;
	DrikaTargetSelect@ known_target;
	float proximity_distance;
	bool continue_if_false = false;
	DrikaGoToLineSelect@ continue_element;
	array<bool> foot_down;
	bool check_all;
	bool check_all_known;
	bool got_before_health;
	array<HealthData@> health_data;

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_choice = state_choices(GetJSONInt(params, "state_check", awake));
		current_state_choice = state_choice;
		equals = GetJSONBool(params, "equals", true);
		proximity_distance = GetJSONFloat(params, "proximity_distance", 1.0);
		continue_if_false = GetJSONBool(params, "continue_if_false", false);
		check_all = GetJSONBool(params, "check_all", false);
		check_all_known = GetJSONBool(params, "check_all_known", false);
		@continue_element = DrikaGoToLineSelect("continue_line", params);

		@target_select = DrikaTargetSelect(this, params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;

		@known_target = DrikaTargetSelect(this, params, "known_target");
		SetTargetOptions();

		drika_element_type = drika_check_character_state;
		connection_types = {_movement_object};

		has_settings = true;
	}

	void PostInit(){
		continue_element.PostInit();
		target_select.PostInit();
	}

	void SetTargetOptions(){
		if(state_choice == in_proximity){
			known_target.target_option = id_option | name_option | character_option | reference_option | team_option | item_option;
		}else{
			known_target.target_option = id_option | name_option | character_option | reference_option | team_option;
		}
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
		known_target.CheckAvailableTargets();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["state_check"] = JSONValue(state_choice);
		data["equals"] = JSONValue(equals);
		data["check_all"] = JSONValue(check_all);
		data["check_all_known"] = JSONValue(check_all_known);
		if(state_choice == knows_about){
			known_target.SaveIdentifier(data);
		}else if(state_choice == in_proximity){
			known_target.SaveIdentifier(data);
			data["proximity_distance"] = JSONValue(proximity_distance);
		}
		data["continue_if_false"] = JSONValue(continue_if_false);
		if(continue_if_false){
			continue_element.SaveGoToLine(data);
		}
		target_select.SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		continue_element.CheckLineAvailable();
		return "CheckCharacterState" + " " + target_select.GetTargetDisplayText() + (equals?" ":" not ") + state_choice_names[state_choice] + ((state_choice == knows_about || state_choice == in_proximity)?" " +  known_target.GetTargetDisplayText():"") + (continue_if_false?" else line " + continue_element.GetTargetLineIndex():"");
	}

	void DrawSettings(){

		float option_name_width = 140.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Target Character");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_NextColumn();

		target_select.DrawSelectTargetUI();

		if(target_select.identifier_type == team){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Check All");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_Checkbox("##Check All", check_all);
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Check for");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("###Check for", current_state_choice, state_choice_names, state_choice_names.size())){
			state_choice = state_choices(current_state_choice);
			SetTargetOptions();
			StartSettings();
			if(state_choice == right_footstep || state_choice == left_footstep){
				continue_if_false = false;
			}
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(state_choice != right_footstep && state_choice != left_footstep){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Equals");
			ImGui_NextColumn();
			ImGui_Checkbox("###Equals", equals);
			ImGui_NextColumn();
		}

		if(state_choice == knows_about){
			ImGui_Separator();
			ImGui_Text("Known Character");
			ImGui_NextColumn();
			ImGui_NextColumn();
			known_target.DrawSelectTargetUI();

			if(known_target.identifier_type == team){
				ImGui_AlignTextToFramePadding();
				ImGui_Text("Check All Known");
				ImGui_NextColumn();
				ImGui_PushItemWidth(second_column_width);
				ImGui_Checkbox("##Check All Known", check_all_known);
				ImGui_PopItemWidth();
				ImGui_NextColumn();
			}
		}else if(state_choice == in_proximity){
			ImGui_Separator();
			ImGui_Text("Proximity Target");
			ImGui_NextColumn();
			ImGui_NextColumn();
			known_target.DrawSelectTargetUI();

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Proximity Distance");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			ImGui_SliderFloat("###Proximity Distance", proximity_distance, 0.0, 100.0, "%.2f");
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(state_choice == takes_damage){

		}

		if(state_choice != right_footstep && state_choice != left_footstep){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("If not, go to line");
			ImGui_NextColumn();

			ImGui_Checkbox("###If not, go to line", continue_if_false);
			ImGui_NextColumn();
			if(continue_if_false){
				continue_element.DrawGoToLineUI();
			}
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			MovementObject@ target = targets[i];
			DebugDrawLine(target.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);

			if(state_choice == knows_about){
				array<MovementObject@> known_targets = known_target.GetTargetMovementObjects();

				for(uint j = 0; j < known_targets.size(); j++){
					DebugDrawLine(target.position, known_targets[j].position, vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
			}else if(state_choice == in_proximity){
				array<Object@> target_objects = known_target.GetTargetObjects();

				for(uint j = 0; j < target_objects.size(); j++){
					vec3 target_location = target_objects[j].GetTranslation();

					if(target_objects[j].GetType() == _item_object){
						ItemObject@ item_obj = ReadItemID(target_objects[j].GetID());
						target_location = item_obj.GetPhysicsPosition();
					}else if(target_objects[j].GetType() == _movement_object){
						MovementObject@ char = ReadCharacterID(target_objects[j].GetID());
						target_location = char.position;
					}
					DebugDrawLine(target.position, target_location, vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
			}
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		bool all_in_state = true;

		for(uint i = 0; i < targets.size(); i++){
			MovementObject@ target = targets[i];
			bool state;

			if(state_choice == knows_about){
				array<MovementObject@> known_targets = known_target.GetTargetMovementObjects();

				for(uint j = 0; j < known_targets.size(); j++){
					string command = "self_id = situation.KnownID(" + known_targets[j].GetID() + ");";
					target.Execute(command);
					state = (target.GetIntVar("self_id") != -1);
					//Return true immediately when we don't have to check all characters and the check returns true.
					if(!check_all_known && state == equals){
						all_in_state = true;
						break;
					}
					if(state != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == in_combat){
				if(!target.controlled){
					state = (target.GetIntVar("goal") == _ai_attack);
				}else{
					state = (target.QueryIntFunction("int CombatSong()") == 1);
				}
			}else if(state_choice == moving){
				state = (length(target.velocity) > 1.0);
			}else if(state_choice == attacking){
				state = (target.GetIntVar("state") == _attack_state);
			}else if(state_choice == ragdolling){
				state = (target.GetIntVar("state") == _ragdoll_state);
			}else if(state_choice == hit_reacting){
				state = (target.GetIntVar("state") == _hit_reaction_state);
			}else if(state_choice == patrolling){
				if(!target.controlled){
					state = (target.GetIntVar("goal") == _ai_patrol);
				}else{
					return false;
				}
			}else if(state_choice == investigating){
				if(!target.controlled){
					state = (target.GetIntVar("goal") == _ai_investigate);
				}else{
					return false;
				}
			}else if(state_choice == getting_help){
				if(!target.controlled){
					state = (target.GetIntVar("goal") == _ai_get_help);
				}else{
					return false;
				}
			}else if(state_choice == fleeing){
				if(!target.controlled){
					state = (target.GetIntVar("goal") == _ai_flee);
				}else{
					return false;
				}
			}else if(state_choice == in_proximity){
				array<Object@> target_objects = known_target.GetTargetObjects();

				for(uint j = 0; j < target_objects.size(); j++){
					vec3 target_location = target_objects[j].GetTranslation();

					if(target_objects[j].GetType() == _item_object){
						ItemObject@ item_obj = ReadItemID(target_objects[j].GetID());
						target_location = item_obj.GetPhysicsPosition();
					}else if(target_objects[j].GetType() == _movement_object){
						MovementObject@ char = ReadCharacterID(target_objects[j].GetID());
						target_location = char.position;
					}

					state = (distance(target.position, target_location) < proximity_distance);
					if(!check_all && state == equals){
						all_in_state = true;
						break;
					}
					if(state != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == awake || state_choice == unconscious || state_choice == dead){
				state = (target.GetIntVar("knocked_out") == state_choice);
			}else if(state_choice == right_footstep){
				//First get the foot status.
				vec3 leg_pos = target.rigged_object().GetIKTargetPosition("right_leg");
				if(foot_down.size() < i + 1){
					col.GetSlidingSphereCollision(leg_pos, 0.1);
					foot_down.insertLast((sphere_col.NumContacts() > 0));
					all_in_state = false;
				}else{
					col.GetSlidingSphereCollision(leg_pos, 0.1);
					//Now check if the foot status has changed.
					bool current_foot_down = (sphere_col.NumContacts() > 0);
					//If any of the characters has a foot that goes from not planted to planted, then a footstep is heard.
					if(foot_down[i] == false && current_foot_down == true){
						foot_down.resize(0);
						all_in_state = true;
						break;
					}else{
						foot_down[i] = current_foot_down;
						all_in_state = false;
					}
				}
			}else if(state_choice == left_footstep){
				//First get the foot status.
				vec3 leg_pos = target.rigged_object().GetIKTargetPosition("left_leg");
				if(foot_down.size() < i + 1){
					col.GetSlidingSphereCollision(leg_pos, 0.1);
					foot_down.insertLast((sphere_col.NumContacts() > 0));
					all_in_state = false;
				}else{
					col.GetSlidingSphereCollision(leg_pos, 0.1);
					//Now check if the foot status has changed.
					bool current_foot_down = (sphere_col.NumContacts() > 0);
					//If any of the characters has a foot that goes from not planted to planted, then a footstep is heard.
					if(foot_down[i] == false && current_foot_down == true){
						foot_down.resize(0);
						all_in_state = true;
						break;
					}else{
						foot_down[i] = current_foot_down;
						all_in_state = false;
					}
				}
			}else if(state_choice == takes_damage){
				HealthData@ target_health_data = null;
				//Get the cached health data or create a new one if it doesn't exist.
				for(uint j = 0; j < health_data.size(); j++){
					if(target.GetID() == health_data[j].character_id){
						@target_health_data = health_data[j];
						break;
					}
				}

				//Create a new health data if this character isn't tracked yet.
				if(@target_health_data == null){
					health_data.insertLast(HealthData(target));
				}else{
					state = target_health_data.CheckHealthDecreased();
					if(!check_all && state == equals){
						all_in_state = true;
						break;
					}
					if(state != equals){
						all_in_state = false;
					}
				}
			}

			if(!check_all && state == equals){
				all_in_state = true;
				break;
			}
			if(state != equals){
				all_in_state = false;
			}
		}

		if(!all_in_state && continue_if_false){
			current_line = continue_element.GetTargetLineIndex();
			display_index = drika_indexes[continue_element.GetTargetLineIndex()];
		}

		//Reset all the health data so that it can be used again.
		if(all_in_state){
			health_data.resize(0);
		}

		return all_in_state;
	}

	void Reset(){
		triggered = false;
	}

	void Delete(){
		target_select.Delete();
		known_target.Delete();
	}
}
