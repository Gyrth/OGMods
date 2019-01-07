class DrikaCreateParticle : DrikaElement{
	string particle_path;
	int amount;
	vec3 tint;
	float velocity;
	float spread = 0.0f;
	bool use_blood_tint;
	bool connect_particles = false;
	int previous_particle_id = -1;

	DrikaCreateParticle(JSONValue params = JSONValue()){
		placeholder_id = GetJSONInt(params, "placeholder_id", -1);
		placeholder_name = "Create Particle Helper";
		particle_path = GetJSONString(params, "particle_path", "Data/Particles/blooddrop.xml");
		drika_element_type = drika_create_particle;

		amount = GetJSONInt(params, "amount", 5);
		tint = GetJSONVec3(params, "tint", vec3(1.0f));
		velocity = GetJSONFloat(params, "velocity", 0.0f);
		spread = GetJSONFloat(params, "spread", 0.0f);
		use_blood_tint = GetJSONBool(params, "use_blood_tint", true);
		connect_particles = GetJSONBool(params, "connect_particles", false);
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("create_particle");
		data["placeholder_id"] = JSONValue(placeholder_id);
		data["particle_path"] = JSONValue(particle_path);
		data["amount"] = JSONValue(amount);
		data["velocity"] = JSONValue(velocity);
		data["spread"] = JSONValue(spread);
		data["use_blood_tint"] = JSONValue(use_blood_tint);
		data["connect_particles"] = JSONValue(connect_particles);
		data["tint"] = JSONValue(JSONarrayValue);
		data["tint"].append(tint.x);
		data["tint"].append(tint.y);
		data["tint"].append(tint.z);
		return data;
	}

	void PostInit(){
		RetrievePlaceholder();
	}

	void Delete(){
		QueueDeleteObjectID(placeholder_id);
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
			ImGui_ColorEdit3("Particle Tint", tint);
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
