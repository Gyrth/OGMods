class DrikaPlaySound : DrikaElement{
	string sound_path;

	DrikaPlaySound(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "Play Sound Helper";
		sound_path = GetJSONString(params, "sound_path", "Data/Sounds/weapon_foley/impact/weapon_knife_hit_neck_2.wav");

		drika_element_type = drika_play_sound;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("play_sound");
		data["sound_path"] = JSONValue(sound_path);
		data["placeholder_id"] = JSONValue(placeholder_id);
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
	}

	string GetDisplayString(){
		return "PlaySound " + sound_path;
	}

	void DrawSettings(){
		ImGui_Text("Sound Path : " + sound_path);
		ImGui_SameLine();
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
