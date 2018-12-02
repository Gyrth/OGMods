enum drika_element_types { 	none,
							drika_wait_level_message,
							drika_wait,
							drika_set_enabled,
							drika_set_character,
							drika_create_particle,
							drika_play_sound,
							drika_go_to_line,
							drika_on_character_enter,
							drika_on_item_enter};

class DrikaElement{
	drika_element_types drika_element_type = none;
	bool visible;
	bool has_settings = false;
	vec4 display_color = vec4(1.0);
	int index = -1;
	int placeholder_id;
	Object@ placeholder;

	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void Update(){}
	bool Trigger(){return false;}
	void Reset(){}
	void AddSettings(){}
	void ApplySettings(){}
	void EditDone(){}
	void Editing(){}
	void DrawEditing(){}
	void SetCurrent(bool _current){}
	void Delete(){}
	void ReceiveMessage(string message){}
	void ReceiveMessage(string message, int param){}
	void ReceiveMessage(string message, string param){}
	void SetIndex(int _index){
		index = _index;
	}

	string Vec3ToString(vec3 value){
		return value.x + "," + value.y + "," + value.z + ",";
	}

	vec3 StringToVec3(string value){
		array<string> values = value.split(",");
		return vec3(atof(values[0]), atof(values[1]), atof(values[2]));
	}

	void CreatePlaceholder(){
		placeholder_id = CreateObject("Data/Objects/drika_hotspot_cube.xml", false);
		@placeholder = ReadObjectFromID(placeholder_id);
		placeholder.SetSelectable(true);
		placeholder.SetTranslatable(true);
		placeholder.SetScalable(true);
		placeholder.SetRotatable(true);
		placeholder.SetScale(vec3(0.25));
		placeholder.SetTranslation(this_hotspot.GetTranslation());
	}
}
