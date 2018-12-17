class DrikaPlaySound : DrikaElement{
	string sound_path;

	DrikaPlaySound(string _placeholder_id = "-1", string _sound_path = "Data/Sounds/weapon_foley/impact/weapon_knife_hit_neck_2.wav"){
		placeholder_id = atoi(_placeholder_id);
		placeholder_name = "Play Sound Helper";
		sound_path = _sound_path;
		drika_element_type = drika_play_sound;
		has_settings = true;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
	}

	string GetSaveString(){
		return "play_sound" + param_delimiter + placeholder_id + param_delimiter + sound_path;
	}

	string GetDisplayString(){
		return "PlaySound " + sound_path;
	}

	void AddSettings(){
		ImGui_Text("Sound Path : ");
		ImGui_SameLine();
		ImGui_Text(sound_path);
		if(ImGui_Button("Set Sound Path")){
			string new_path = GetUserPickedReadPath("wav", "Data/Sounds");
			if(new_path != ""){
				sound_path = new_path;
			}
		}
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DebugDrawBillboard("Data/Textures/ui/speaker.png", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_update);
		}else{
			CreatePlaceholder();
			StartEdit();
		}
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			PlaySound(sound_path, placeholder.GetTranslation());
			return true;
		}else{
			CreatePlaceholder();
			return false;
		}
	}
}
