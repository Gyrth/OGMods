bool launched = false;
float flight_top;
int victim_id = 0;
vec3 starting_point = vec3(0.0f);
int rocket_id = -1;
float pi = 3.14159265f;
bool reached_peak = false;
int sound_id = -1;
bool post_init_done = false;
float limiter_timer = 0.0f;

void Init() {

}

void PostInit(){
	if(post_init_done){
		return;
	}
	array<int> all_objects = GetObjectIDsType(_env_object);
	for(uint i = 0; i < all_objects.size(); i++){
		Object@ obj = ReadObjectFromID(all_objects[i]);
		ScriptParams@ obj_params = obj.GetScriptParams();
		if(obj_params.HasParam("BelongsTo")){
			if(obj_params.GetInt("BelongsTo") == hotspot.GetID()){
				rocket_id = all_objects[i];
				break;
			}
		}
	}
	if(rocket_id == -1){
		rocket_id = CreateObject("Data/Objects/rocket_obj.xml", false);
		Object@ rocket_hotspot = ReadObjectFromID(hotspot.GetID());
		Object@ rocket_obj = ReadObjectFromID(rocket_id);
		ScriptParams@ rocket_params = rocket_obj.GetScriptParams();
		rocket_params.SetInt("BelongsTo", hotspot.GetID());
		rocket_obj.SetTranslation(rocket_hotspot.GetTranslation());
		rocket_obj.SetSelectable(true);
		rocket_obj.SetTranslatable(true);
	}
	post_init_done = true;
}

void SetParameters() {
    params.AddIntCheckbox("Friendly", false);
    params.AddIntSlider("Top height", 200, "min:-200,max:200,step:1,text_mult:1");
	params.AddFloatSlider("Damage dealt", 1.0, "min:0.0,max:10.0,step:1,text_mult:1");
	params.AddFloatSlider("Particle Limiter", 0.005, "min:0.001,max:1.0,step:1,text_mult:10");
	params.AddFloatSlider("Speed", 100.0, "min:0.5,max:1000.0,step:1,text_mult:1");
    params.AddFloatSlider("Cornering", 0.90, "min:0.1,max:0.99,step:1,text_mult:1");
    params.AddIntSlider("Force", 50000, "min:0,max:100000,step:1,text_mult:1");
    params.AddIntSlider("Smoke particle amount", 10, "min:0,max:200,step:1,text_mult:1");
    params.AddIntCheckbox("Show DebugLines", false);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
    else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	if(launched || rocket_id == -1){
		return;
	}
	Object@ rocket_obj = ReadObjectFromID(rocket_id);
    if (!mo.controlled || params.GetInt("Friendly") == 0 && mo.controlled){
		starting_point = rocket_obj.GetTranslation();
		victim_id = mo.GetID();
		launched = true;
		flight_top = rocket_obj.GetTranslation().y + float(params.GetInt("Top height"));
		sound_id = PlaySoundLoopAtLocation("Data/Sounds/rocket_flight.wav", starting_point, 5.0f);
    }
}

void OnExit(MovementObject @mo) {

}

void Update() {
	PostInit();
	Object@ rocket_obj = ReadObjectFromID(rocket_id);
	Object@ rocket_hotspot = ReadObjectFromID(hotspot.GetID());
	if(EditorModeActive()){
		DebugDrawLine(rocket_hotspot.GetTranslation(), rocket_obj.GetTranslation(), vec3(0.5f), _delete_on_update);
	}

    if(launched){
		vec3 rocket_pos = rocket_obj.GetTranslation();
		vec3 fire_dir;
        vec3 target_pos = ReadCharacterID(victim_id).position + vec3(0.0f, 0.5f, 0.0f);
        vec3 direction;
		vec3 new_position;

		limiter_timer += time_step;
        if(!reached_peak){
			vec3 peak_position = vec3((starting_point.x + target_pos.x) / 2.0f, flight_top, (starting_point.z + target_pos.z) / 2.0f);
			direction = normalize(peak_position - rocket_pos);
			vec3 current_direction = rocket_obj.GetRotation() * vec3(0,1,0);
			float alpha = (params.GetFloat("Cornering"));
			vec3 average_direction = normalize(mix(direction, current_direction, alpha));

			direction = average_direction;
			new_position = rocket_pos + (average_direction * (params.GetFloat("Speed") * time_step));
			if(distance(peak_position, new_position) < 1.0f){
				reached_peak = true;
			}
		}else{
			direction = normalize(target_pos - rocket_pos);
			vec3 current_direction = rocket_obj.GetRotation() * vec3(0,1,0);
			float alpha = (params.GetFloat("Cornering"));
			vec3 average_direction = normalize(mix(direction, current_direction, alpha));

			direction = average_direction;
			new_position = rocket_pos + (average_direction * (params.GetFloat("Speed") * time_step));
		}
        rocket_obj.SetTranslation(new_position);
		SetSoundPosition(sound_id, new_position);

		quaternion new_rotation;
		GetRotationBetweenVectors(vec3(0,1,0), direction, new_rotation);
		rocket_obj.SetRotation(new_rotation);

		if(limiter_timer > params.GetFloat("Particle Limiter")){
			limiter_timer = 0.0f;
			vec3 smoke_point = rocket_pos - direction;
			MakeParticle("Data/Particles/rocket_flight_smoke.xml", smoke_point, direction * -10.0f);
			MakeParticle("Data/Particles/rocket_trail_fire.xml", smoke_point, direction * -10.0f);
		}

		MovementObject@ char = ReadCharacterID(victim_id);
		float radius = 0.35f;

		array<int> colliding_characters;
		GetCharactersInHull("Data/Models/rocket.obj", rocket_obj.GetTransform(), colliding_characters);
		if(colliding_characters.size() > 0){
			Explode(new_position, direction);
			return;
		}

		vec3 start = vec3(new_position + direction * 2.25f);
		vec3 end = vec3(new_position + direction * 2.75f);
		char.Execute(	"vec3 start = vec3(" + start.x + "," + start.y + "," + start.z + ");" +
						"vec3 end = vec3(" + end.x + "," + end.y + "," + end.z + ");" +
						"col.GetSweptSphereCollision(start, end, " + radius + ");" +
						"blinking = (sphere_col.NumContacts() != 0);");
		/*DebugDrawWireSphere(start, radius, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);
		DebugDrawWireSphere(end, radius, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);*/

		if(char.GetBoolVar("blinking")){
			Explode(new_position, direction);
		}
    }
}

void Explode(vec3 position, vec3 direction){
	Object@ rocket_obj = ReadObjectFromID(rocket_id);
	launched = false;
	reached_peak = false;
	rocket_obj.SetTranslation(starting_point);
	rocket_obj.SetRotation(quaternion(vec4(0,0,0,1)));

	array<int> nearby_characters;
	GetCharactersInSphere(position, 20.0f, nearby_characters);
	int num_chars = nearby_characters.size();
	for(int i = 0; i < num_chars; i++){
		MovementObject@ character = ReadCharacterID(nearby_characters[i]);
		vec3 explode_direction = normalize(character.position - position);
		float center_distance = distance(position, character.position);
		float distance_alpha = (1.0f - (center_distance / 20.0f));
		if(character.controlled){
			character.Execute("camera_shake += 10.0f;");
		}
		character.Execute("GoLimp(); TakeDamage("+ (params.GetFloat("Damage dealt") * distance_alpha) +");");
		character.rigged_object().ApplyForceToRagdoll(explode_direction * params.GetInt("Force") * distance_alpha, ReadCharacterID(nearby_characters[i]).rigged_object().GetAvgIKChainPos("torso"));
	}

	MakeMetalSparks(position);
	for(int j = 0; j < (params.GetFloat("Smoke particle amount")); j++){
		MakeParticle("Data/Particles/rocket_explosion_smoke.xml",position,
		vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
	}
	StopSound(sound_id);
	int boom = PlaySoundGroup("Data/Sounds/rocket_explosion.xml", position);
	SetSoundPitch(boom, RangedRandomFloat(0.5f, 1.0f));
}

void Reset(){
	Object@ rocket_obj = ReadObjectFromID(rocket_id);
	if(starting_point == vec3(0.0f)){
		starting_point = rocket_obj.GetTranslation();
	}
	reached_peak = false;
	launched = false;
	rocket_obj.SetTranslation(starting_point);
	rocket_obj.SetRotation(quaternion(vec4(0,0,0,1)));
	StopSound(sound_id);
}

void MakeMetalSparks(vec3 pos){
    int num_sparks = 60;
	float speed = 20.0f;
    for(int i=0; i<num_sparks; ++i){
        MakeParticle("Data/Particles/rocket_explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed)));
    }
}
