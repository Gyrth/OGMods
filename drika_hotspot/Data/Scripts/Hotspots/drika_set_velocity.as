class DrikaSetVelocity : DrikaElement{
	float velocity_magnitude;
	bool add_velocity;

	DrikaSetVelocity(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		velocity_magnitude = GetJSONFloat(params, "velocity_magnitude", 5);

		target_select.LoadIdentifier(params);
		target_select.target_option = id_option | name_option | character_option | reference_option | team_option;

		add_velocity = GetJSONBool(params, "add_velocity", true);

		placeholder_name = "Set Velocity Helper";
		drika_element_type = drika_set_velocity;
		connection_types = {_movement_object, _item_object};
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["velocity_magnitude"] = JSONValue(velocity_magnitude);
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["add_velocity"] = JSONValue(add_velocity);
		target_select.SaveIdentifier(data);
		return data;
	}

	void Delete(){
		RemovePlaceholder();
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	string GetDisplayString(){
		return "SetVelocity " + "vel:" + velocity_magnitude + " target:" + target_select.GetTargetDisplayText();
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){

		float option_name_width = 140.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Target");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		target_select.DrawSelectTargetUI();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Velocity");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_DragFloat("###Velocity", velocity_magnitude, 1.0f, 0.0f, 1000.0f);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Add Velocity");
		ImGui_NextColumn();
		ImGui_Checkbox("###Add Velocity", add_velocity);
		ImGui_NextColumn();
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			array<Object@> targets = target_select.GetTargetObjects();
			for(uint i = 0; i < targets.size(); i++){
				DebugDrawLine(targets[i].GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			mat4 gizmo_transform_y;
			gizmo_transform_y.SetTranslationPart(placeholder.GetTranslation());
			gizmo_transform_y.SetRotationPart(Mat4FromQuaternion(placeholder.GetRotation()));

			mat4 scale_mat_y;
			scale_mat_y[0] = 1.0;
			scale_mat_y[5] = velocity_magnitude / 10.0;
			scale_mat_y[10] = 1.0;
			scale_mat_y[15] = 1.0f;
			gizmo_transform_y = gizmo_transform_y * scale_mat_y;

			DebugDrawWireMesh("Data/Models/drika_gizmo_y.obj", gizmo_transform_y, vec4(1.0f, 0.0f, 0.0f, 1.0f), _delete_on_update);

			mat4 mesh_transform;
			mesh_transform.SetTranslationPart(placeholder.GetTranslation());
			mat4 rotation = Mat4FromQuaternion(placeholder.GetRotation());
			mesh_transform.SetRotationPart(rotation);

			mat4 scale_mat;
			scale_mat[0] = placeholder.GetScale().x;
			scale_mat[5] = placeholder.GetScale().y;
			scale_mat[10] = placeholder.GetScale().z;
			scale_mat[15] = 1.0f;
			mesh_transform = mesh_transform * scale_mat;

			vec4 color = placeholder.IsSelected()?vec4(0.0f, 0.85f, 0.0f, 0.75f):vec4(0.0f, 0.35f, 0.0f, 0.75f);
			DebugDrawWireMesh("Data/Models/drika_hotspot_cube.obj", mesh_transform, color, _delete_on_update);
		}else{
			CreatePlaceholder();
		}
	}

	bool Trigger(){
		ApplyVelocity();
		return true;
	}

	void ApplyVelocity(){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			vec3 up_direction = placeholder.GetRotation() * vec3(0, 1, 0);
			if(targets[i].GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(targets[i].GetID());
				if(char.GetIntVar("state") == _ragdoll_state){
					if(add_velocity){
						char.rigged_object().ApplyForceToRagdoll(char.rigged_object().GetAvgVelocity() + up_direction * velocity_magnitude * 1000.0, char.rigged_object().skeleton().GetCenterOfMass());
					}else{
						char.rigged_object().ApplyForceToRagdoll(up_direction * velocity_magnitude * 1000.0, char.rigged_object().skeleton().GetCenterOfMass());
					}
		        }else{
					if(add_velocity){
						char.velocity = char.velocity + up_direction * velocity_magnitude;
					}else{
						char.velocity = up_direction * velocity_magnitude;
					}
					char.Execute("SetOnGround(false);");
					char.Execute("pre_jump = false;");
				}
			}else if(targets[i].GetType() == _item_object){
				ItemObject@ io = ReadItemID(targets[i].GetID());
				io.ActivatePhysics();
				if(add_velocity){
					io.SetLinearVelocity(io.GetLinearVelocity() + up_direction * velocity_magnitude);
				}else{
					io.SetLinearVelocity(up_direction * velocity_magnitude);
				}
				io.ActivatePhysics();
			}
		}
	}
}
