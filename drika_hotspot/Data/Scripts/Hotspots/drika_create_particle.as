class DrikaCreateParticle : DrikaElement{
	string particle_path;
	int amount;
	vec3 tint;
	float velocity;
	float spread = 0.0f;
	bool use_blood_tint;
	bool connect_particles = false;
	int previous_particle_id = -1;

	DrikaCreateParticle(string _placeholder_id = "-1", string _amount = "5", string _particle_path = "Data/Particles/blooddrop.xml", string _velocity = "0.0", string _tint = "1,1,1", string _use_blood_tint = "true", string _spread = "0.0", string _connect_particles = "false"){
		amount = atoi(_amount);
		placeholder_id = atoi(_placeholder_id);
		placeholder_name = "Create Particle Helper";
		particle_path = _particle_path;
		tint = StringToVec3(_tint);
		velocity = atof(_velocity);
		spread = atof(_spread);
		use_blood_tint = (_use_blood_tint == "true");
		connect_particles = (_connect_particles == "true");

		drika_element_type = drika_create_particle;
		has_settings = true;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
	}

	array<string> GetSaveParameters(){
		return {"create_particle", placeholder_id, amount, particle_path, velocity, Vec3ToString(tint), use_blood_tint, spread, connect_particles};
	}

	string GetDisplayString(){
		return "CreateParticle " + particle_path;
	}
	
	void DrawSettings(){
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
		ImGui_DragFloat("Spread", spread, 0.001f, 0.0f, 1.0f, "%.3f");
		ImGui_Checkbox("Connect Particles", connect_particles);
		ImGui_Checkbox("Use Blood Tint", use_blood_tint);
		if(!use_blood_tint){
			ImGui_ColorPicker3("Particle Tint", tint, 0);
		}
	}

	void DrawEditing(){
		if(ObjectExists(placeholder_id)){
			vec3 forward_direction = placeholder.GetRotation() * vec3(1, 0, 0);
			DebugDrawLine(placeholder.GetTranslation(), placeholder.GetTranslation() + (forward_direction * (velocity / 10.0)), vec3(1, 0, 0), _delete_on_update);
			DebugDrawLine(placeholder.GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			DebugDrawBillboard("Data/Textures/ui/stealth_debug/zzzz.tga", placeholder.GetTranslation(), 0.25, vec4(1.0), _delete_on_update);
		}else{
			CreatePlaceholder();
			StartEdit();
		}
	}

	void Reset(){
		previous_particle_id = -1;
	}

	bool Trigger(){
		if(ObjectExists(placeholder_id)){
			vec3 particle_tint = GetBloodTint();
			if(!use_blood_tint){
				particle_tint = tint;
			}
			vec3 forward_direction = placeholder.GetRotation() * vec3(1, 0, 0);
			for(int i = 0; i < amount; i++){
				vec3 added_spread = vec3(RangedRandomFloat(-spread,spread), RangedRandomFloat(-spread,spread), RangedRandomFloat(-spread,spread));
				vec3 particle_velocity = normalize(forward_direction + added_spread) * velocity;
				int new_particle_id = MakeParticle(particle_path, placeholder.GetTranslation(), particle_velocity + added_spread, particle_tint);

				//Connecting particles are used to create bloodspurts.
				if(connect_particles){
					if(previous_particle_id != -1){
						ConnectParticles(previous_particle_id, new_particle_id);
					}
					previous_particle_id = new_particle_id;
				}
			}
			return true;
		}else{
			CreatePlaceholder();
			return false;
		}
	}
}
