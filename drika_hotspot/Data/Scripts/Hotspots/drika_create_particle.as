class DrikaCreateParticle : DrikaElement{
	string particle_path;
	int amount;
	vec3 tint;
	float velocity;
	bool use_blood_tint;

	DrikaCreateParticle(string _placeholder_id = "-1", string _amount = "5", string _particle_path = "Data/Particles/blooddrop.xml", string _velocity = "0.0", string _tint = "1,1,1", string _use_blood_tint = "true"){
		amount = atoi(_amount);
		placeholder_id = atoi(_placeholder_id);
		particle_path = _particle_path;
		tint = StringToVec3(_tint);
		velocity = atof(_velocity);
		use_blood_tint = (_use_blood_tint == "true");

		drika_element_type = drika_create_particle;
		has_settings = true;

		if(ObjectExists(placeholder_id)){
			@placeholder = ReadObjectFromID(placeholder_id);
		}else{
			CreatePlaceholder();
		}
		placeholder.SetEditorLabel("Drika Particle Helper");
		placeholder.SetSelectable(false);
	}

	string GetSaveString(){
		return "create_particle" + param_delimiter + placeholder_id + param_delimiter + amount + param_delimiter + particle_path + param_delimiter + velocity + param_delimiter + Vec3ToString(tint) + param_delimiter + use_blood_tint;
	}

	string GetDisplayString(){
		return "CreateParticle " + particle_path;
	}
	void AddSettings(){
		ImGui_Text("Particle Path : ");
		ImGui_SameLine();
		ImGui_Text(particle_path);
		if(ImGui_Button("Set Particle Path")){
			string new_path = GetUserPickedReadPath("xml", "Data/Particles");
			if(new_path != ""){
				particle_path = new_path;
			}
		}
		ImGui_InputInt("Amount", amount);
		ImGui_DragFloat("Velocity", velocity, 1.0f, 0.0f, 1000.0f);
		ImGui_Checkbox("Use Blood Tint", use_blood_tint);
		if(!use_blood_tint){
			ImGui_ColorPicker3("Particle Tint", tint, 0);
		}
	}

	void Editing(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelectable(true);
		}else{
			CreatePlaceholder();
		}
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			vec3 forward_direction = placeholder.GetRotation() * vec3(1, 0, 0);
			DebugDrawLine(placeholder.GetTranslation(), placeholder.GetTranslation() + (forward_direction * (velocity / 10.0)), vec3(1, 0, 0), _delete_on_update);
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
			DebugDrawBillboard("Data/Textures/ui/stealth_debug/zzzz.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_update);
		}
	}

	void EditDone(){
		if(ObjectExists(placeholder_id)){
			placeholder.SetSelected(false);
			placeholder.SetSelectable(false);
		}
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			vec3 particle_tint = GetBloodTint();
			if(!use_blood_tint){
				particle_tint = tint;
			}
			vec3 forward_direction = placeholder.GetRotation() * vec3(1, 0, 0);
			vec3 particle_velocity = forward_direction * velocity;
			for(int i = 0; i < amount; i++){
				MakeParticle(particle_path, placeholder.GetTranslation(), particle_velocity, particle_tint);
			}
			return true;
		}else{
			CreatePlaceholder();
			return false;
		}
	}
}
