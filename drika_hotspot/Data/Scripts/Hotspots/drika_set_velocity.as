class DrikaSetVelocity : DrikaElement{

	float velocity_magnitude;

	DrikaSetVelocity(string _placeholder_id = "-1", string _target_id = "-1", string _velocity_magnitude = "1"){
		placeholder_id = atoi(_placeholder_id);
		connection_types = {_movement_object, _item_object};
		object_id = atoi(_target_id);
		placeholder_name = "Set Velocity Helper";
		drika_element_type = drika_set_velocity;
		velocity_magnitude = atof(_velocity_magnitude);
		has_settings = true;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	array<string> GetSaveParameters(){
		return {"set_velocity", placeholder_id, object_id, velocity_magnitude};
	}

	string GetDisplayString(){
		return "SetVelocity " + velocity_magnitude;
	}

	void DrawSettings(){
		ImGui_DragFloat("Velocity", velocity_magnitude, 1.0f, 0.0f, 1000.0f);
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			if(object_id != -1 && ObjectExists(object_id)){
				Object@ target_object = ReadObjectFromID(object_id);
				DebugDrawLine(target_object.GetTranslation(), placeholder.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
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
		}else{
			CreatePlaceholder();
		}
	}

	bool Trigger(){
		ApplyVelocity();
		return true;
	}

	void ApplyVelocity(){
		if(ObjectExists(placeholder_id) && ObjectExists(object_id)){
			Object@ target = ReadObjectFromID(object_id);
			vec3 up_direction = placeholder.GetRotation() * vec3(0, 1, 0);
			if(target.GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(object_id);
				char.velocity = up_direction * velocity_magnitude;
				char.Execute("SetOnGround(false);");
				char.Execute("pre_jump = false;");
			}else if(target.GetType() == _item_object){
				ItemObject@ io = ReadItemID(object_id);
				io.ActivatePhysics();
				io.SetLinearVelocity(up_direction * velocity_magnitude);
				io.ActivatePhysics();
			}
		}
	}
}
