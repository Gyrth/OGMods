enum drika_element_types { 	none = 0,
							drika_wait_level_message = 1,
							drika_wait = 2,
							drika_set_enabled = 3,
							drika_set_character = 4,
							drika_create_particle = 5,
							drika_play_sound = 6,
							drika_go_to_line = 7,
							drika_on_character_enter_exit = 8,
							drika_on_item_enter = 9,
							drika_send_level_message = 10,
							drika_start_dialogue = 11,
							drika_set_object_param = 12,
							drika_set_level_param = 13,
							drika_set_camera_param = 14,
							drika_create_object = 15
						};

array<vec4> display_colors = {	vec4(255),
								vec4(110, 94, 180, 255),
								vec4(152, 113, 80, 255),
								vec4(88, 122, 147, 255),
								vec4(78, 136, 124, 255),
								vec4(56, 92, 54, 255),
								vec4(145, 99, 66, 255),
								vec4(163, 111, 155, 255),
								vec4(161, 181, 100, 255),
								vec4(148, 69, 64, 255),
								vec4(132, 150, 75, 255),
								vec4(196, 145, 145, 255),
								vec4(90, 154, 191, 255),
								vec4(90, 154, 191, 255),
								vec4(90, 154, 191, 255),
								vec4(90, 154, 191, 255)
							};

enum identifier_types {	id = 0,
						reference = 1
					};

enum param_types { 	string_param = 0,
					int_param = 1,
					float_param = 2,
					vec3_param = 3,
					vec3_color_param = 4,
					float_array_param = 5
				};

class DrikaElement{
	drika_element_types drika_element_type = none;
	bool visible;
	bool has_settings = false;
	int index = -1;
	int placeholder_id;
	Object@ placeholder;

	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void Update(){}
	bool Trigger(){return false;}
	void Reset(){}
	void Delete(){}
	void AddSettings(){}
	void ApplySettings(){}
	void EditDone(){}
	void Editing(){}
	void DrawEditing(){}
	void SetCurrent(bool _current){}
	void ReceiveMessage(string message){}
	void ReceiveMessage(string message, int param){}
	void ReceiveMessage(string message, string param){}
	void SetIndex(int _index){
		index = _index;
	}

	string Vec3ToString(vec3 value){
		return value.x + "," + value.y + "," + value.z;
	}

	vec3 StringToVec3(string value){
		array<string> values = value.split(",");
		return vec3(atof(values[0]), atof(values[1]), atof(values[2]));
	}

	string FloatArrayToString(array<float> values){
		string return_value = "";
		for(uint i = 0; i < values.size(); i++){
			return_value += ((i == 0)?"":";") + values[i];
		}
		return return_value;
	}

	array<float> StringToFloatArray(string value){
		array<string> values = value.split(";");
		array<float> return_value;
		for(uint i = 0; i < values.size(); i++){
			return_value.insertLast(atof(values[i]));
		}
		return return_value;
	}

	vec4 GetDisplayColor(){
		return display_colors[drika_element_type];
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
