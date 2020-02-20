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
						in_proximity = 13
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

class DrikaCheckCharacterState : DrikaElement{
	array<string> state_choice_names = {"Awake", "Unconscious", "Dead", "Knows About", "In Combat", "Moving", "Attacking", "Ragdolling", "Blocked Attack", "AI Patrolling", "AI Investigating", "AI Getting Help", "AI Fleeing", "In Proximity"};
	state_choices state_choice;
	int current_state_choice;
	bool equals = true;
	TargetSelect known_target(this, "known_target");
	float proximity_distance;

	DrikaCheckCharacterState(JSONValue params = JSONValue()){
		state_choice = state_choices(GetJSONInt(params, "state_check", awake));
		current_state_choice = state_choice;
		equals = GetJSONBool(params, "equals", true);
		proximity_distance = GetJSONFloat(params, "proximity_distance", 1.0);

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;

		known_target.LoadIdentifier(params);
		SetTargetOptions();

		drika_element_type = drika_check_character_state;
		connection_types = {_movement_object};

		has_settings = true;
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
		if(state_choice == knows_about){
			known_target.SaveIdentifier(data);
		}else if(state_choice == in_proximity){
			known_target.SaveIdentifier(data);
			data["proximity_distance"] = JSONValue(proximity_distance);
		}
		target_select.SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "CheckCharacterState" + " " + target_select.GetTargetDisplayText() + (equals?" ":" not ") + state_choice_names[state_choice] + ((state_choice == knows_about || state_choice == in_proximity)?" " +  known_target.GetTargetDisplayText():"");
	}

	void DrawSettings(){
		target_select.DrawSelectTargetUI();
		ImGui_Checkbox("Equals", equals);
		if(ImGui_Combo("Check for", current_state_choice, state_choice_names, state_choice_names.size())){
			state_choice = state_choices(current_state_choice);
			SetTargetOptions();
			StartSettings();
		}

		if(state_choice == knows_about){
			ImGui_Separator();
			ImGui_Text("Known Character");
			known_target.DrawSelectTargetUI();
		}else if(state_choice == in_proximity){
			ImGui_Separator();
			ImGui_Text("Proximity Target");
			known_target.DrawSelectTargetUI();
			ImGui_Text("Proximity Distance");
			ImGui_SameLine();
			ImGui_SliderFloat("##Proximity Distance", proximity_distance, 0.0, 100.0, "%.2f");
		}
	}

	void DrawEditing(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);

			if(state_choice == knows_about){
				array<MovementObject@> known_targets = known_target.GetTargetMovementObjects();

				for(uint j = 0; j < known_targets.size(); j++){
					DebugDrawLine(targets[i].position, known_targets[j].position, vec3(0.0, 1.0, 0.0), _delete_on_update);
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
					DebugDrawLine(targets[i].position, target_location, vec3(0.0, 1.0, 0.0), _delete_on_update);
				}
			}
		}
	}

	bool Trigger(){
		array<MovementObject@> targets = target_select.GetTargetMovementObjects();
		if(targets.size() == 0){return false;}

		bool all_in_state = true;

		for(uint i = 0; i < targets.size(); i++){
			if(state_choice == knows_about){
				array<MovementObject@> known_targets = known_target.GetTargetMovementObjects();

				for(uint j = 0; j < known_targets.size(); j++){
					string command = "self_id = situation.KnownID(" + known_targets[j].GetID() + ");";
					targets[i].Execute(command);
					bool known = (targets[i].GetIntVar("self_id") != -1);
					if(known != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == in_combat){
				bool state;
				if(!targets[i].controlled){
					state = (targets[i].GetIntVar("goal") == _ai_attack);
				}else{
					state = (targets[i].QueryIntFunction("int CombatSong()") == 1);
				}
				if(state != equals){
					all_in_state = false;
				}
			}else if(state_choice == moving){
				bool state = (length(targets[i].velocity) > 1.0);
				if(state != equals){
					all_in_state = false;
				}
			}else if(state_choice == attacking){
				bool state = (targets[i].GetIntVar("state") == _attack_state);
				if(state != equals){
					all_in_state = false;
				}
			}else if(state_choice == ragdolling){
				bool state = (targets[i].GetIntVar("state") == _ragdoll_state);
				if(state != equals){
					all_in_state = false;
				}
			}else if(state_choice == hit_reacting){
				bool state = (targets[i].GetIntVar("state") == _hit_reaction_state);
				if(state != equals){
					all_in_state = false;
				}
			}else if(state_choice == patrolling){
				if(!targets[i].controlled){
					bool state = (targets[i].GetIntVar("goal") == _ai_patrol);
					if(state != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == investigating){
				if(!targets[i].controlled){
					bool state = (targets[i].GetIntVar("goal") == _ai_investigate);
					if(state != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == getting_help){
				if(!targets[i].controlled){
					bool state = (targets[i].GetIntVar("goal") == _ai_get_help);
					if(state != equals){
						all_in_state = false;
					}
				}
			}else if(state_choice == fleeing){
				if(!targets[i].controlled){
					bool state = (targets[i].GetIntVar("goal") == _ai_flee);
					if(state != equals){
						all_in_state = false;
					}
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

					bool state = (distance(targets[i].position, target_location) < proximity_distance);
					if(state != equals){
						all_in_state = false;
					}
				}
			}else{
				if((targets[i].GetIntVar("knocked_out") != state_choice) == equals){
					all_in_state = false;
				}
			}
		}
		return all_in_state;
	}
}
