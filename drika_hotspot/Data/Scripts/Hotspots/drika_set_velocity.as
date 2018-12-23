class DrikaSetVelocity : DrikaElement{
	float velocity_magnitude;

	DrikaSetVelocity(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		velocity_magnitude = GetJSONFloat(params, "velocity_magnitude", 5);
		InterpIdentifier(params);

		placeholder_name = "Set Velocity Helper";
		drika_element_type = drika_set_velocity;
		connection_types = {_movement_object, _item_object};
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_velocity");
		data["velocity_magnitude"] = JSONValue(velocity_magnitude);
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}
		return data;
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	string GetDisplayString(){
		string display_identifier;
		if(identifier_type == id){
			display_identifier = "" + object_id;
		}else if(identifier_type == reference){
			display_identifier = "" + reference_string;
		}
		return "SetVelocity " + "vel:" + velocity_magnitude + " target:" + display_identifier;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		ImGui_DragFloat("Velocity", velocity_magnitude, 1.0f, 0.0f, 1000.0f);
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			if(identifier_type == id && object_id != -1 && ObjectExists(object_id)){
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
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			return;
		}
		vec3 up_direction = placeholder.GetRotation() * vec3(0, 1, 0);
		if(target_object.GetType() == _movement_object){
			MovementObject@ char = ReadCharacterID(target_object.GetID());
			char.velocity = up_direction * velocity_magnitude;
			char.Execute("SetOnGround(false);");
			char.Execute("pre_jump = false;");
		}else if(target_object.GetType() == _item_object){
			ItemObject@ io = ReadItemID(target_object.GetID());
			io.ActivatePhysics();
			io.SetLinearVelocity(up_direction * velocity_magnitude);
			io.ActivatePhysics();
		}
	}
}
