class DrikaSetCharacter : DrikaElement{
	string character_path;
	array<BeforeValue> original_character_paths;
	bool cache_skeleton_info = true;

	DrikaSetCharacter(JSONValue params = JSONValue()){
		character_path = GetJSONString(params, "character_path", "Data/Characters/guard.xml");
		cache_skeleton_info = GetJSONBool(params, "cache_skeleton_info", true);
		LoadIdentifier(params);
		show_team_option = true;
		show_name_option = true;
		
		connection_types = {_movement_object};
		drika_element_type = drika_set_character;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_character");
		data["character_path"] = JSONValue(character_path);
		data["cache_skeleton_info"] = JSONValue(cache_skeleton_info);
		SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		return "SetCharacter " + GetTargetDisplayText() + " " + character_path;
	}

	void GetOriginalCharacter(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		original_character_paths.resize(0);
		for(uint i = 0; i < targets.size(); i++){
			original_character_paths.insertLast(BeforeValue());
			original_character_paths[i].string_value = targets[i].char_path;
		}
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_Text("Set To Character : ");
		ImGui_SameLine();
		ImGui_Text(character_path);
		if(ImGui_Button("Set Character File")){
			string new_path = GetUserPickedReadPath("xml", "Data/Characters");
			if(new_path != ""){
				character_path = new_path;
			}
		}
		ImGui_Checkbox("Cache Skeleton Info", cache_skeleton_info);
	}

	bool Trigger(){
		if(!triggered){
			GetOriginalCharacter();
		}
		triggered = true;
		return SetParameter(false);
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool SetParameter(bool reset){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			if(targets[i].char_path == (reset?original_character_paths[i].string_value:character_path)){
				continue;
			}
			targets[i].char_path = reset?original_character_paths[i].string_value:character_path;
			string command =	"character_getter.Load(this_mo.char_path);" +
								"this_mo.RecreateRiggedObject(this_mo.char_path);";

			if(cache_skeleton_info){
				command += "CacheSkeletonInfo();";
			}
			if(targets[i].GetIntVar("state") == _ragdoll_state){
				command += "Recover();";
			}
			targets[i].Execute(command);
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
