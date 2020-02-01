enum drika_element_types { 	none = 0,
							drika_wait_level_message = 1,
							drika_wait = 2,
							drika_set_enabled = 3,
							drika_set_character = 4,
							drika_create_particle = 5,
							drika_play_sound = 6,
							drika_go_to_line = 7,
							drika_on_character_enter_exit = 8,
							drika_on_item_enter_exit = 9,
							drika_send_level_message = 10,
							drika_start_dialogue = 11,
							drika_set_object_param = 12,
							drika_set_level_param = 13,
							drika_set_camera_param = 14,
							drika_create_object = 15,
							drika_transform_object = 16,
							drika_set_color = 17,
							drika_play_music = 18,
							drika_character_control = 19,
							drika_display_text = 20,
							drika_display_image = 21,
							drika_load_level = 22,
							drika_check_character_state = 23,
							drika_set_velocity = 24,
							drika_slow_motion = 25,
							drika_on_input = 26,
							drika_set_morph_target = 27,
							drika_set_bone_inflate = 28,
							drika_send_character_message = 29,
							drika_animation = 30,
							drika_billboard = 31,
							drika_read_write_savefile = 32,
							drika_dialogue = 33,
							drika_comment = 34,
							drika_ai_control = 35
						};

array<string> drika_element_names = {	"None",
										"Wait Level Message",
										"Wait",
										"Set Enabled",
										"Set Character",
										"Create Particle",
										"Play Sound",
										"Go To Line",
										"On Character Enter Exit",
										"On Item Enter Exit",
										"Send Level Message",
										"Start Dialogue",
										"Set Object Parameter",
										"Set Level Parameter",
										"Set Camera Parameter",
										"Create Object",
										"Transform Object",
										"Set Color",
										"Play Music",
										"Character Control",
										"Display Text",
										"Display Image",
										"Load Level",
										"Check Character State",
										"Set Velocity",
										"Slow Motion",
										"On Input",
										"Set Morph Target",
										"Set Bone Inflate",
										"Send Character Message",
										"Animation",
										"Billboard",
										"Read Write Save File",
										"Dialogue",
										"Comment",
										"AI Control"
									};

array<string> sorted_element_names;

array<vec4> display_colors = {	vec4(255),
                                vec4(230, 184, 175, 255),
                                vec4(255, 153, 0, 255),
                                vec4(0, 243, 255, 255),
                                vec4(0, 173, 182, 255),
                                vec4(0, 255, 0, 255),
                                vec4(0, 255, 149, 255),
                                vec4(255, 255, 0, 255),
                                vec4(255, 0, 0, 255),
                                vec4(150, 0, 0, 255),
                                vec4(221, 126, 107, 255),
                                vec4(150, 0, 150, 255),
                                vec4(0, 113, 194, 255),
                                vec4(0, 43, 255, 255),
                                vec4(126, 139, 226, 255),
                                vec4(0, 182, 0, 255),
                                vec4(162, 250, 255, 255),
                                vec4(203, 200, 255, 255),
                                vec4(0, 173, 101, 255),
                                vec4(0, 149, 255, 255),
                                vec4(156, 255, 159, 255),
                                vec4(153, 255, 193, 255),
                                vec4(255, 0, 255, 255),
                                vec4(255, 117, 117, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(153, 174, 255, 255),
								vec4(255, 255, 255, 255),
								vec4(153, 174, 255, 255)
                            };

enum identifier_types {	id = 0,
						reference = 1,
						team = 2,
						name = 3
					};

enum param_types { 	string_param = 0,
					int_param = 1,
					float_param = 2,
					vec3_param = 3,
					vec3_color_param = 4,
					float_array_param = 5,
					bool_param = 6,
					function_param = 7
				};

class BeforeValue{
	string string_value;
	float float_value;
	int int_value;
	bool bool_value;
	vec3 vec3_value;
	bool delete_before = false;
}

class DrikaElement{
	drika_element_types drika_element_type = none;
	bool visible;
	bool triggered = false;
	bool has_settings = false;
	bool parallel_operation = false;
	int index = -1;
	int placeholder_id = -1;
	Object@ placeholder;
	int object_id = -1;
	int new_object_id = -1;
	string reference_string = "drika_reference";
	string placeholder_name;
	identifier_types identifier_type = id;
	int current_identifier_type = -1;
	int current_reference;
	vec3 default_placeholder_scale = vec3(0.25);
	array<EntityType> connection_types;
	array<string> available_references;
	bool show_reference_option = false;
	bool show_team_option = false;
	bool show_name_option = false;
	string character_team = "team_drika";
	string new_character_team = "team_drika";
	string object_name = "drika_object";
	string new_object_name = "drika_object";
	float PI = 3.14159265359f;

	string GetDisplayString(){return "";}
	string GetReference(){return "";}
	void Update(){}
	void PostInit(){}
	bool Trigger(){return false;}
	void Reset(){}
	void Delete(){}
	void DrawSettings(){}
	void ApplySettings(){}
	void StartSettings(){}
	void DrawEditing(){}
	void PreTargetChanged(){}
	void TargetChanged(){}
	void SetCurrent(bool _current){}
	void ReceiveEditorMessage(array<string> message){}
	void ReceiveMessage(string message){}
	void ReceiveMessage(string message, int param){}
	void ReceiveMessage(string message, string param){}
	void ReceiveMessage(string message, int param_1, int param_2){}
	void ReceiveMessage(string message, string param, int id_param){}
	void SetIndex(int _index){
		index = _index;
	}

	void LeftClick(){
		array<Object@> target_objects = GetTargetObjects();
		if(this_hotspot.IsSelected() && ObjectExists(placeholder_id)){
			this_hotspot.SetSelected(false);
			for(uint i = 0 ; i < target_objects.size(); i++){
				target_objects[i].SetSelected(false);
			}
			placeholder.SetSelected(true);
		}else if(ObjectExists(placeholder_id) && placeholder.IsSelected()){
			placeholder.SetSelected(false);
			this_hotspot.SetSelected(false);
			for(uint i = 0 ; i < target_objects.size(); i++){
				target_objects[i].SetSelected(true);
			}
		}else{
			if(ObjectExists(placeholder_id)){
				placeholder.SetSelected(false);
			}
			for(uint i = 0 ; i < target_objects.size(); i++){
				target_objects[i].SetSelected(false);
			}
			this_hotspot.SetSelected(true);
		}
	}

	JSONValue GetSaveData(){
		return JSONValue();
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
			PreTargetChanged();
			Disconnect(ReadObjectFromID(object_id));
		}
		new_object_id = other.GetID();
		object_id = new_object_id;
		TargetChanged();
		return false;
	}

	bool Disconnect(Object @other){
		if(other.GetID() == object_id){
			object_id = -1;
			return false;
		}
		return false;
	}

	void ClearTarget(){
		object_id = -1;
		reference_string = "drika_reference";
		character_team = "team_drika";
		object_name = "drika_object";
	}

	string Vec3ToString(vec3 value){
		return value.x + "," + value.y + "," + value.z;
	}

	vec3 StringToVec3(string value){
		array<string> values = value.split(",");
		return vec3(atof(values[0]), atof(values[1]), atof(values[2]));
	}

	string Vec4ToString(vec4 value){
		return value.x + "," + value.y + "," + value.z + "," + value.a;
	}

	vec4 StringToVec4(string value){
		array<string> values = value.split(",");
		return vec4(atof(values[0]), atof(values[1]), atof(values[2]), atof(values[3]));
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
		placeholder.SetTranslation(this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0));
	}

	void RetrievePlaceholder(){
		if(duplicating){
			if(ObjectExists(placeholder_id)){
				//Use the same transform as the original placeholder.
				Object@ old_placeholder = ReadObjectFromID(placeholder_id);
				CreatePlaceholder();
				placeholder.SetScale(old_placeholder.GetScale());
				placeholder.SetTranslation(old_placeholder.GetTranslation());
				placeholder.SetRotation(old_placeholder.GetRotation());
			}else{
				placeholder_id = -1;
			}
		}else{
			if(ObjectExists(placeholder_id)){
				@placeholder = ReadObjectFromID(placeholder_id);
				placeholder.SetName(placeholder_name);
				placeholder.SetSelectable(false);
			}else{
				CreatePlaceholder();
			}
		}
	}

	void LoadIdentifier(JSONValue params){
		if(params.isMember("identifier_type")){
			if(params["identifier_type"].asInt() == id){
				identifier_type = identifier_types(id);
				new_object_id = params["identifier"].asInt();
				object_id = new_object_id;
			}else if(params["identifier_type"].asInt() == reference){
				identifier_type = identifier_types(reference);
				reference_string = params["identifier"].asString();
			}else if(params["identifier_type"].asInt() == team){
				identifier_type = identifier_types(team);
				new_character_team = params["identifier"].asString();
				character_team = new_character_team;
			}else if(params["identifier_type"].asInt() == name){
				identifier_type = identifier_types(name);
				new_object_name = params["identifier"].asString();
				object_name = new_object_name;
			}
		}else{
			//By default the id is used as identifier with -1 as the target id.
			identifier_type = identifier_types(id);
		}
	}

	void SaveIdentifier(JSONValue &inout data){
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}else if(identifier_type == name){
			data["identifier"] = JSONValue(object_name);
		}
	}

	void CheckReferenceAvailable(){
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
				current_identifier_type = id;
				identifier_type = identifier_types(current_identifier_type);
			}
		}
	}

	void DrawSelectTargetUI(){
		array<string> identifier_choices = {"ID"};
		if(show_reference_option){
			identifier_choices.insertLast("Reference");
		}
		if(show_team_option){
			identifier_choices.insertLast("Team");
		}
		if(show_name_option){
			identifier_choices.insertLast("Name");
		}

		if(current_identifier_type == -1){
			for(uint i = 0; i < identifier_choices.size(); i++){
				if(	identifier_type == id && identifier_choices[i] == "ID"||
				 	identifier_type == team && identifier_choices[i] == "Team"||
					identifier_type == reference && identifier_choices[i] == "Reference"||
					identifier_type == name && identifier_choices[i] == "Name"){
					current_identifier_type = i;
					break;
				}
			}
		}

		if(ImGui_Combo("Identifier Type", current_identifier_type, identifier_choices, identifier_choices.size())){
			if(identifier_choices[current_identifier_type] == "ID"){
				identifier_type = id;
			}else if(identifier_choices[current_identifier_type] == "Team"){
				identifier_type = team;
			}else if(identifier_choices[current_identifier_type] == "Reference"){
				identifier_type = reference;
			}else if(identifier_choices[current_identifier_type] == "Name"){
				identifier_type = name;
			}
		}
		if(identifier_type == id){
			if(ImGui_InputInt("Object ID", new_object_id)){
				PreTargetChanged();
				object_id = new_object_id;
				TargetChanged();
			}
		}else if(identifier_type == reference){
			if(ImGui_Combo("Reference", current_reference, available_references, available_references.size())){
				PreTargetChanged();
				reference_string = available_references[current_reference];

				TargetChanged();
			}
		}else if(identifier_type == team){
			if(ImGui_InputText("Team", new_character_team, 64)){
				PreTargetChanged();
				character_team = new_character_team;
				TargetChanged();
			}
		}else if(identifier_type == name){
			if(ImGui_InputText("Name", new_object_name, 64)){
				PreTargetChanged();
				object_name = new_object_name;
				TargetChanged();
			}
		}
	}

	void DrawSetReferenceUI(){
		ImGui_InputText("Set Reference", reference_string, 64);
		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip("If a reference is set it can be used by other functions\nlike Set Object Param or Transform Object.");
			ImGui_PopStyleColor();
		}
	}

	array<Object@> GetTargetObjects(){
		array<Object@> target_objects;
		if(identifier_type == id){
			if(object_id == -1){
				//Do nothing.
			}else if(!ObjectExists(object_id)){
				Log(warning, "The object with id " + object_id + " doesn't exist anymore, so resetting to -1.");
				object_id = -1;
			}else{
				target_objects.insertLast(ReadObjectFromID(object_id));
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				//Does not exist yet.
			}else{
				target_objects.insertLast(ReadObjectFromID(registered_object_id));
			}
		}else if (identifier_type == team){
			array<int> object_ids = GetObjectIDs();
			for(uint i = 0; i < object_ids.size(); i++){
				Object@ obj = ReadObjectFromID(object_ids[i]);
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Teams")){
					//Removed all the spaces.
					string no_spaces_param = join(obj_params.GetString("Teams").split(" "), "");
					//Teams are , seperated.
					array<string> teams = no_spaces_param.split(",");
					if(teams.find(character_team) != -1){
						target_objects.insertLast(obj);
					}
				}
			}
		}else if (identifier_type == name){
			array<int> object_ids = GetObjectIDs();
			for(uint i = 0; i < object_ids.size(); i++){
				Object@ obj = ReadObjectFromID(object_ids[i]);
				if(obj.GetName() == object_name){
					target_objects.insertLast(obj);
				}
			}
		}
		return target_objects;
	}

	array<MovementObject@> GetTargetMovementObjects(){
		array<MovementObject@> target_movement_objects;
		if(identifier_type == id){
			if(object_id == -1){
				//Do nothing.
			}else if(!MovementObjectExists(object_id)){
				Log(warning, "The MovementObject with id " + object_id + " doesn't exist or is not a MovementObject, so resetting to -1.");
				object_id = -1;
			}else{
				target_movement_objects.insertLast(ReadCharacterID(object_id));
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				//Does not exist yet.
			}else if(MovementObjectExists(registered_object_id)){
				target_movement_objects.insertLast(ReadCharacterID(registered_object_id));
			}
		}else if (identifier_type == team){
			array<int> mo_ids = GetObjectIDsType(_movement_object);
			for(uint i = 0; i < mo_ids.size(); i++){
				MovementObject@ mo = ReadCharacterID(mo_ids[i]);
				Object@ obj = ReadObjectFromID(mo_ids[i]);
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Teams")){
					//Removed all the spaces.
					string no_spaces_param = join(obj_params.GetString("Teams").split(" "), "");
					//Teams are , seperated.
					array<string> teams = no_spaces_param.split(",");
					if(teams.find(character_team) != -1){
						target_movement_objects.insertLast(mo);
					}
				}
			}
		}else if (identifier_type == name){
			array<int> mo_ids = GetObjectIDsType(_movement_object);
			for(uint i = 0; i < mo_ids.size(); i++){
				Object@ obj = ReadObjectFromID(mo_ids[i]);
				MovementObject@ mo = ReadCharacterID(mo_ids[i]);
				if(obj.GetName() == object_name){
					target_movement_objects.insertLast(mo);
				}
			}
		}
		return target_movement_objects;
	}

	string GetTargetDisplayText(){
		if(identifier_type == id){
			return "" + object_id;
		}else if (identifier_type == reference){
			return reference_string;
		}else if (identifier_type == team){
			return character_team;
		}else if (identifier_type == name){
			return object_name;
		}
		return "NA";
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

		float color_mult = 1.0;
		if(!target.IsSelected()){
			color_mult = 0.05;
		}

		DebugDrawWireMesh("Data/Models/drika_gizmo_y.obj", gizmo_transform_y, mix(vec4(), vec4(0.0f, 0.0f, 1.0f, 0.15f), color_mult), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_x.obj", gizmo_transform_x, mix(vec4(), vec4(1.0f, 0.0f, 0.0f, 0.15f), color_mult), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_z.obj", gizmo_transform_z, mix(vec4(), vec4(0.0f, 1.0, 0.0f, 0.15f), color_mult), _delete_on_update);
	}

}
