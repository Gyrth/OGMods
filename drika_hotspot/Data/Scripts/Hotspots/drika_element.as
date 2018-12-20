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
							drika_create_object = 15,
							drika_transform_object = 16,
							drika_set_color = 17,
							drika_play_music = 18,
							drika_set_character_param = 19,
							drika_display_text = 20
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
								vec4(96, 76, 40, 255),
								vec4(89, 96, 40, 255),
								vec4(61, 96, 40, 255),
								vec4(96, 47, 40, 255),
								vec4(96, 40, 62, 255),
								vec4(40, 93, 96, 255),
								vec4(40, 93, 96, 255),
								vec4(40, 93, 96, 255)
							};

enum identifier_types {	id = 0,
						reference = 1
					};

enum param_types { 	string_param = 0,
					int_param = 1,
					float_param = 2,
					vec3_param = 3,
					vec3_color_param = 4,
					float_array_param = 5,
					bool_param = 6
				};

class DrikaElement{
	drika_element_types drika_element_type = none;
	bool visible;
	bool triggered = false;
	bool has_settings = false;
	int index = -1;
	int placeholder_id = -1;
	Object@ placeholder;
	int object_id;
	string reference_string = "";
	string placeholder_name;
	identifier_types identifier_type;
	int current_idenifier_type;
	int current_reference;
	vec3 default_placeholder_scale = vec3(0.25);
	array<EntityType> connection_types;
	array<string> available_references;
	bool show_reference_option = false;

	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void Update(){}
	void PostInit(){}
	bool Trigger(){return false;}
	void Reset(){}
	void Delete(){}
	void DrawSettings(){}
	void ApplySettings(){}
	void ConnectedChanged(){}
	void DrawEditing(){}
	void TargetChanged(){}
	void SetCurrent(bool _current){}
	void ReceiveMessage(string message){}
	void ReceiveMessage(string message, int param){}
	void ReceiveMessage(string message, string param){}
	void SetIndex(int _index){
		index = _index;
	}

	void StartEdit(){
		if(placeholder_id != -1 && ObjectExists(placeholder_id)){
			placeholder.SetSelectable(true);
		}
	}

	void EditDone(){
		if(placeholder_id != -1 && ObjectExists(placeholder_id)){
			placeholder.SetSelected(false);
			placeholder.SetSelectable(false);
		}
	}

	bool ConnectTo(Object @other){
		if(other.GetID() == object_id){
			return false;
		}
		if(object_id != -1 && ObjectExists(object_id)){
			hotspot.Disconnect(ReadObjectFromID(object_id));
		}
		object_id = other.GetID();
		ConnectedChanged();
		return false;
	}

	bool Disconnect(Object @other){
		if(other.GetID() == object_id){
			object_id = -1;
			return false;
		}
		return false;
	}

	string Vec3ToString(vec3 value){
		return value.x + "," + value.y + "," + value.z;
	}

	vec3 StringToVec3(string value){
		array<string> values = value.split(",");
		return vec3(atof(values[0]), atof(values[1]), atof(values[2]));
	}

	quaternion StringToQuat(string value){
		array<string> values = value.split(",");
		return quaternion(atof(values[0]), atof(values[1]), atof(values[2]), atof(values[3]));
	}

	string QuatToString(quaternion value){
		return value.x + "," + value.y + "," + value.z + "," + value.w;
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
		placeholder.SetName(placeholder_name);
		placeholder.SetSelectable(true);
		placeholder.SetTranslatable(true);
		placeholder.SetScalable(true);
		placeholder.SetRotatable(true);
		placeholder.SetScale(default_placeholder_scale);
		placeholder.SetTranslation(this_hotspot.GetTranslation());
	}

	void RetrievePlaceholder(){
		if(duplicating){
			//Use the same transform as the original placeholder.
			Object@ old_placeholder = ReadObjectFromID(placeholder_id);
			CreatePlaceholder();
			placeholder.SetScale(old_placeholder.GetScale());
			placeholder.SetTranslation(old_placeholder.GetTranslation());
			placeholder.SetRotation(old_placeholder.GetRotation());
			return;
		}
		if(ObjectExists(placeholder_id)){
			@placeholder = ReadObjectFromID(placeholder_id);
			placeholder.SetName(placeholder_name);
			placeholder.SetSelectable(false);
		}else{
			CreatePlaceholder();
		}
	}

	void InterpIdentifier(string _identifier_type, string _identifier){
		identifier_type = identifier_types(atoi(_identifier_type));
		current_idenifier_type = identifier_type;
		if(identifier_type == id){
			object_id = atoi(_identifier);
		}else if(identifier_type == reference){
			reference_string = _identifier;
		}
	}

	void StartSettings(){
		if(HasReferences()){
			show_reference_option = true;
			available_references = GetReferences();
			if(identifier_type == reference){
				//Find the index of the chosen reference.
				for(uint i = 0; i < available_references.size(); i++){
					if(available_references[i] == reference_string){
						current_reference = i;
						return;
					}
				}
			}
			//By default pick the first one.
			reference_string = available_references[current_reference];
		}else{
			show_reference_option = false;
			//Force the identifier type to id when no references are available.
			if(identifier_type == reference){
				current_idenifier_type = id;
				identifier_type = identifier_types(current_idenifier_type);
			}
		}
	}

	void DrawSelectTargetUI(){
		if(show_reference_option){
			array<string> identifier_choices = {"ID", "Reference"};
			if(ImGui_Combo("Identifier Type", current_idenifier_type, identifier_choices, identifier_choices.size())){
				identifier_type = identifier_types(current_idenifier_type);
			}
		}
		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", object_id)){
				TargetChanged();
			}
		}else if(identifier_type == reference){
			if(ImGui_Combo("Reference", current_reference, available_references, available_references.size())){
				reference_string = available_references[current_reference];
				TargetChanged();
			}
		}
	}

	Object@ GetTargetObject(){
		Object@ target_object;
		if(identifier_type == id){
			if(object_id == -1 || !ObjectExists(object_id)){
				Log(warning, "Object does not exist with id " + object_id);
				return null;
			}else{
				@target_object = ReadObjectFromID(object_id);
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				Log(warning, "Object does not exist with reference " + reference_string);
				return null;
			}
			@target_object = ReadObjectFromID(registered_object_id);
		}
		return target_object;
	}

	void DrawGizmo(Object@ target){
		mat4 gizmo_transform_y;
		gizmo_transform_y.SetTranslationPart(target.GetTranslation());
		gizmo_transform_y.SetRotationPart(Mat4FromQuaternion(target.GetRotation()));
		mat4 gizmo_transform_x = gizmo_transform_y;
		mat4 gizmo_transform_z = gizmo_transform_y;

		mat4 scale_mat_y;
		scale_mat_y[0] = 1.0;
		scale_mat_y[5] = target.GetScale().y;
		scale_mat_y[10] = 1.0;
		scale_mat_y[15] = 1.0f;
		gizmo_transform_y = gizmo_transform_y * scale_mat_y;

		mat4 scale_mat_x;
		scale_mat_x[0] = target.GetScale().x;
		scale_mat_x[5] = 1.0;
		scale_mat_x[10] = 1.0;
		scale_mat_x[15] = 1.0f;
		gizmo_transform_x = gizmo_transform_x * scale_mat_x;

		mat4 scale_mat_z;
		scale_mat_z[0] = 1.0;
		scale_mat_z[5] = 1.0;
		scale_mat_z[10] = target.GetScale().z;
		scale_mat_z[15] = 1.0f;
		gizmo_transform_z = gizmo_transform_z * scale_mat_z;

		DebugDrawWireMesh("Data/Models/drika_gizmo_y.obj", gizmo_transform_y, vec4(0.0f, 0.0f, 0.5f, 0.15f), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_x.obj", gizmo_transform_x, vec4(0.5f, 0.0f, 0.0f, 0.15f), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_z.obj", gizmo_transform_z, vec4(0.0f, 0.5, 0.0f, 0.15f), _delete_on_update);
	}

}
