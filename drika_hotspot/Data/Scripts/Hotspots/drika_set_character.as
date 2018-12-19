class DrikaSetCharacter : DrikaElement{
	string character_path;
	string original_character_path;
	bool cache_skeleton_info = true;

	DrikaSetCharacter(string _object_id = "-1", string _character_path = "Data/Characters/guard.xml", string _cache_skeleton_info = "true"){
		object_id = atoi(_object_id);
		character_path = _character_path;
		drika_element_type = drika_set_character;
		has_settings = true;
		cache_skeleton_info = ((_cache_skeleton_info == "true")?true:false);
		connection_types = {_movement_object};
	}

	void PostInit(){
		if(!MovementObjectExists(object_id)){
			Log(warning, "Character does not exist with id " + object_id);
		}
	}

	string GetSaveString(){
		return "set_character" + param_delimiter + object_id + param_delimiter + character_path + param_delimiter + (cache_skeleton_info?"true":"false");
	}

	string GetDisplayString(){
		return "SetCharacter " + object_id + " " + character_path;
	}

	void GetOriginalCharacter(){
		if(object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			original_character_path = character.char_path;
		}
	}

	void AddSettings(){
		if(ImGui_InputInt("Character ID", object_id)){

		}
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
		if(object_id == -1 || !MovementObjectExists(object_id)){
			return false;
		}
		if(!triggered){
			GetOriginalCharacter();
		}
		triggered = true;
		SetParameter(false);
		return true;
	}

	void DrawEditing(){
		if(object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	void SetParameter(bool reset){
		if(object_id != -1 && MovementObjectExists(object_id)){
			MovementObject@ character = ReadCharacterID(object_id);
			if(character.char_path == (reset?original_character_path:character_path)){
				return;
			}
			character.char_path = reset?original_character_path:character_path;
			string command =	"character_getter.Load(this_mo.char_path);" +
								"this_mo.RecreateRiggedObject(this_mo.char_path);";

			if(cache_skeleton_info){
				command += "CacheSkeletonInfo();";
			}
			if(character.GetIntVar("state") == _ragdoll_state){
				command += "Recover();";
			}
			character.Execute(command);
		}
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetParameter(true);
		}
	}
}
