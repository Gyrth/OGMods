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
							drika_ai_control = 35,
							drika_user_interface = 36,
							drika_checkpoint = 37
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
										"AI Control",
										"User Interface",
										"Checkpoint"
									};

array<string> sorted_element_names;

array<vec4> display_colors = {};

enum identifier_types {	id = 0,
						reference = 1,
						team = 2,
						name = 3,
						character = 4,
						item = 5,
						batch = 6,
						cam = 7,
						box_select = 8
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

enum select_states {	select_hotspot = 0,
						select_placeholder = 1,
						select_target = 2,
						select_target_select_placeholder = 3
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
	DrikaPlaceholder placeholder();
	array<EntityType> connection_types;
	string line_number;
	bool deleted = false;
	string reference_string = "";
	bool reference_already_taken = false;
	DrikaTargetSelect @target_select = DrikaTargetSelect(this, JSONValue());
	int export_index = -1;
	select_states select_state = select_hotspot;
	vec2 node_position;
	vec2 node_slot_in_position;
	vec2 node_slot_then_position;
	vec2 node_slot_else_position;
	DrikaElement@ nodes_slot_then_connected;

	string GetDisplayString(){return "";}
	string GetReferenceString(){return reference_string;}
	array<int> GetReferenceObjectIDs(){return {};}
	void Update(){}
	void PostInit(){}
	bool Trigger(){return false;}
	void PostTrigger(){}
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
	void ReceiveMessage(array<string> messages){}
	void ReadUIInstruction(array<string> instruction){}
	void HotspotStartEdit(){}
	void HotspotStopEdit(){}
	void SetIndex(int _index){
		index = _index;
	}
	void ReorderDone(){}

	DrikaElement(){
		node_position = vec2(125.0, 125.0 + (100.0f * drika_elements.size()));
	}

	~DrikaElement(){
		/* Log(warning, "Deleted " + GetDisplayString()); */
	}

	void SetExportIndex(int _index){
		export_index = _index;
	}

	void ClearExportIndex(){
		export_index = -1;
	}

	bool ConnectTo(Object @other){
		return target_select.ConnectTo(other);
	}

	bool Disconnect(Object @other){
		return target_select.Disconnect(other);
	}

	void LeftClick(){
		while(true){
			select_state = select_states(select_state + 1);
			if(select_state > select_target_select_placeholder){
				select_state = select_hotspot;
			}

			if(select_state == select_hotspot){
				placeholder.SetSelected(false);
				this_hotspot.SetSelected(true);
				target_select.SetSelected(false);
				target_select.box_select_placeholder.SetSelected(false);
				break;
			}else if(select_state == select_target_select_placeholder && target_select.box_select_placeholder.Exists()){
				placeholder.SetSelected(false);
				this_hotspot.SetSelected(false);
				target_select.SetSelected(false);
				target_select.box_select_placeholder.SetSelected(true);
				break;
			}else if(select_state == select_placeholder && placeholder.Exists()){
				placeholder.SetSelected(true);
				this_hotspot.SetSelected(false);
				target_select.SetSelected(false);
				target_select.box_select_placeholder.SetSelected(false);
				break;
			}else if(select_state == select_target){
				placeholder.SetSelected(false);
				this_hotspot.SetSelected(false);
				target_select.SetSelected(true);
				target_select.box_select_placeholder.SetSelected(false);
				break;
			}
		}
	}

	JSONValue GetSaveData(){
		return JSONValue();
	}

	JSONValue GetCheckpointData(){
		return JSONValue();
	}

	void SetCheckpointData(JSONValue data = JSONValue()){

	}

	void StartEdit(){
		placeholder.SetSelectable(true);
		target_select.StartEdit();
	}

	void EditDone(){
		select_state = select_hotspot;
		placeholder.SetSelectable(false);
		target_select.EditDone();
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

	void AttemptRegisterReference(string new_reference_string){
		// If the new reference string is empty then remove the reference.
		if(new_reference_string == ""){
			RemoveReference(this);
			reference_string = new_reference_string;
			reference_already_taken = false;
		}else if(GetReferenceElement(new_reference_string) !is null){
			// Check if the reference string is already taken.
			reference_already_taken = true;
			reference_string = new_reference_string;
		}else{
			reference_already_taken = false;
			reference_string = new_reference_string;
			RegisterReference(this);
		}
	}

	void DrawSetReferenceUI(){
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Set Reference");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);

		// If the reference string is changed then update the reference.
		string new_reference_string = reference_string;
		if(ImGui_InputText("##Reference", new_reference_string, 64)){
			AttemptRegisterReference(new_reference_string);
		}

		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip("If a reference is set it can be used by other functions\nlike Set Object Param or Transform Object.");
			ImGui_PopStyleColor();
		}

		if(reference_already_taken){
			ImGui_NextColumn();
			ImGui_NextColumn();
			ImGui_PushStyleColor(ImGuiCol_Text, vec4(1.0, 0.0, 0.0, 1.0));
			ImGui_Text("This reference is already taken!");
			ImGui_PopStyleColor();
		}

		ImGui_PopItemWidth();
	}

	void DrawGizmo(vec3 translation, quaternion rotation, vec3 scale, bool selected){
		mat4 gizmo_transform_y;
		gizmo_transform_y.SetTranslationPart(translation);
		gizmo_transform_y.SetRotationPart(Mat4FromQuaternion(rotation));
		mat4 gizmo_transform_x = gizmo_transform_y;
		mat4 gizmo_transform_z = gizmo_transform_y;

		mat4 scale_mat_y;
		scale_mat_y[0] = 1.0;
		scale_mat_y[5] = scale.y;
		scale_mat_y[10] = 1.0;
		scale_mat_y[15] = 1.0f;
		gizmo_transform_y = gizmo_transform_y * scale_mat_y;

		mat4 scale_mat_x;
		scale_mat_x[0] = scale.x;
		scale_mat_x[5] = 1.0;
		scale_mat_x[10] = 1.0;
		scale_mat_x[15] = 1.0f;
		gizmo_transform_x = gizmo_transform_x * scale_mat_x;

		mat4 scale_mat_z;
		scale_mat_z[0] = 1.0;
		scale_mat_z[5] = 1.0;
		scale_mat_z[10] = scale.z;
		scale_mat_z[15] = 1.0f;
		gizmo_transform_z = gizmo_transform_z * scale_mat_z;

		float color_mult = 1.0;
		if(!selected){
			color_mult = 0.05;
		}

		DebugDrawWireMesh("Data/Models/drika_gizmo_y.obj", gizmo_transform_y, mix(vec4(), vec4(0.0f, 0.0f, 1.0f, 0.15f), color_mult), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_x.obj", gizmo_transform_x, mix(vec4(), vec4(1.0f, 0.0f, 0.0f, 0.15f), color_mult), _delete_on_update);
		DebugDrawWireMesh("Data/Models/drika_gizmo_z.obj", gizmo_transform_z, mix(vec4(), vec4(0.0f, 1.0, 0.0f, 0.15f), color_mult), _delete_on_update);
	}

	void DrawGizmo(Object@ target){
		DrawGizmo(target.GetTranslation(), target.GetRotation(), target.GetScale(), target.IsSelected());
	}

	vec3 GetTargetTranslation(Object@ target){
		if(target.GetType() == _movement_object){
			MovementObject@ char = ReadCharacterID(target.GetID());
			return char.position;
		}else if(target.GetType() == _item_object){
			ItemObject@ item = ReadItemID(target.GetID());
			return item.GetPhysicsPosition();
		}else{
			return target.GetTranslation();
		}
	}

	quaternion GetTargetRotation(Object@ target){
		if(target.GetType() == _movement_object){
			//GetFacing() is not available in hotspot scripts.
			MovementObject@ char = ReadCharacterID(target.GetID());
			/* vec3 facing = char.GetFacing();
	        float cur_rotation = atan2(facing.x, facing.z);
	        quaternion rotation(vec4(0, 1, 0, cur_rotation));
			return rotation; */

			RiggedObject@ rigged_object = char.rigged_object();
			Skeleton@ skeleton = rigged_object.skeleton();

			// Get relative chest transformation
			int chest_bone = skeleton.IKBoneStart("torso");
			BoneTransform chest_frame_matrix = rigged_object.GetFrameMatrix(chest_bone);

			/* return target.GetRotation(); */
			return chest_frame_matrix.rotation;
		}else if(target.GetType() == _item_object){
			ItemObject@ item = ReadItemID(target.GetID());
			mat4 physics_transform = item.GetPhysicsTransform();
			return QuaternionFromMat4(physics_transform.GetRotationPart());
		}else{
			return target.GetRotation();
		}
	}

	void SetTargetTranslation(Object@ target, vec3 translation){
		if(target.GetType() == _movement_object){
			MovementObject@ char = ReadCharacterID(target.GetID());
			char.position = translation;
			char.velocity = vec3(0.0, 0.0, 0.0);
		}else if(target.GetType() == _item_object){
			ItemObject@ item = ReadItemID(target.GetID());
			mat4 physics_transform = item.GetPhysicsTransform();
			physics_transform.SetTranslationPart(translation);
			item.SetPhysicsTransform(physics_transform);
			item.SetAngularVelocity(vec3());
			item.SetLinearVelocity(vec3());
			item.ActivatePhysics();
		}else{
			target.SetTranslation(translation);
		}
	}

	void SetTargetRotation(Object@ target, quaternion rotation){
		if(target.GetType() == _movement_object){
			MovementObject@ char = ReadCharacterID(target.GetID());
			vec3 facing = Mult(rotation, vec3(0,0,1));
			float rot = atan2(facing.x, facing.z) * 180.0f / PI;
			float new_rotation = floor(rot + 0.5f);
			vec3 new_facing = Mult(quaternion(vec4(0, 1, 0, new_rotation * PI / 180.0f)), vec3(1, 0, 0));
			char.SetRotationFromFacing(new_facing);
		}else if(target.GetType() == _item_object){
			ItemObject@ item = ReadItemID(target.GetID());
			mat4 physics_transform = item.GetPhysicsTransform();
			physics_transform.SetRotationPart(Mat4FromQuaternion(rotation));
			item.SetPhysicsTransform(physics_transform);
			item.SetAngularVelocity(vec3());
			item.SetLinearVelocity(vec3());
			item.ActivatePhysics();
		}else{
			target.SetRotation(rotation);
		}
	}

	void RelativeTransform(vec3 origin, vec3 translation_offset, mat4 before_mat, mat4 after_mat){
		placeholder.RelativeTranslate(translation_offset);
		placeholder.RelativeRotate(origin, before_mat, after_mat);
	}
}
