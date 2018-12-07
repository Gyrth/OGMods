class DrikaSetCharacter : DrikaElement{
	int character_id;
	string character_path;
	string original_character_path;
	MovementObject@ character;

	DrikaSetCharacter(string _character_id = "-1", string _character_path = "Data/Characters/guard.xml"){
		character_id = atoi(_character_id);
		character_path = _character_path;
		drika_element_type = drika_set_character;
		has_settings = true;
		if(MovementObjectExists(character_id)){
			@character = ReadCharacterID(character_id);
			GetOriginalCharacter();
		}else{
			Log(warning, "Character does not exist with id " + character_id);
		}
	}

	string GetSaveString(){
		return "set_character" + param_delimiter + character_id + param_delimiter + character_path;
	}

	string GetDisplayString(){
		return "SetCharacter " + character_id + " " + character_path;
	}

	void GetOriginalCharacter(){
		if(character_id != -1 && MovementObjectExists(character_id)){
			original_character_path = character.char_path;
		}
	}

	void AddSettings(){
		if(ImGui_InputInt("Character ID", character_id)){
			if(MovementObjectExists(character_id)){
				@character = ReadCharacterID(character_id);
				GetOriginalCharacter();
			}
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
	}

	bool Trigger(){
		if(character_id == -1 || !MovementObjectExists(character_id)){
			return false;
		}
		SetParameter(false);
		return true;
	}

	void DrawEditing(){
		if(character_id != -1 && MovementObjectExists(character_id)){
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
		}
	}

	void SetParameter(bool reset){
		if(character_id != -1 && MovementObjectExists(character_id)){
			if(character.char_path == (reset?original_character_path:character_path)){
				return;
			}
			character.char_path = reset?original_character_path:character_path;
			character.Execute(	"character_getter.Load(this_mo.char_path);" +
								"this_mo.RecreateRiggedObject(this_mo.char_path);" +
								"ResetSecondaryAnimation(true);" +
						        "ResetLayers();" +
						        "CacheSkeletonInfo();");
		}
	}

	void Reset(){
		SetParameter(true);
	}
}
