array<int> shoot_player_ids;
float time = 0.0f;
int play_count = 0;
int turret_head_id = CreateObject("Data/Custom/gyrth/turret/Objects/turret_head.xml");
int turret_base_id = CreateObject("Data/Custom/gyrth/turret/Objects/turret_base.xml");
Object@ turret_head_obj = ReadObjectFromID(turret_head_id);
Object@ turret_base_obj = ReadObjectFromID(turret_base_id);
Object@ turret_hotspot = ReadObjectFromID(hotspot.GetID());

vec3 hotspot_pos = turret_hotspot.GetTranslation();
float head_offset = 0.8f;
float base_offset = 0.3f;
vec3 head_spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+head_offset, hotspot_pos.z);
vec3 base_spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+base_offset, hotspot_pos.z);

void Init() {
	turret_hotspot.SetScale(vec3(4.0f,1.0f,4.0f));
	turret_head_obj.SetScale(vec3(0.4f,0.4f,0.4f));
	turret_head_obj.SetTranslation(head_spawn_point);
	turret_base_obj.SetScale(vec3(0.4f,0.4f,0.4f));
	turret_base_obj.SetTranslation(base_spawn_point);
}

void SetParameters() {
	params.AddString("Knock back force Min", "1000");
	params.AddString("Knock back force Max", "30000");
	params.AddString("Damage with each shot", "0.4");	//The amount of damage applied to the target with each shot.
	params.AddIntCheckbox("Friendly", true);	//Whether the turret doesn't shoots the player.
	params.AddString("Time in between shots in sec", "0.2");
	params.AddIntCheckbox("Show turret radius sphere", false);
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
	if (params.GetFloat("Friendly") ==  1){
		if(!mo.controlled){
			if(shoot_player_ids.find(mo.GetID()) == -1){
				shoot_player_ids.insertLast(mo.GetID());
			}
		}
	}
	else{
		if(shoot_player_ids.find(mo.GetID()) == -1){
			shoot_player_ids.insertLast(mo.GetID());
		}
	}

}
void OnExit(MovementObject @mo) {
}


void Shoot(MovementObject @mo){
	string body_part;
	float random_picker = RangedRandomFloat(0,4);	//This case switch picks a random body part to shoot.
	switch(int(random_picker)){
		case 0: body_part = "head"; break;
		case 1: body_part = "leftarm";  break;
		case 2: body_part = "rightarm";  break;
		case 3: body_part = "left_leg";  break;
		case 4: body_part = "right_leg"; break;
		}
	vec3 player_pos = mo.rigged_object().GetIKChainPos(body_part,0);
	vec3 head_spawn_point = turret_head_obj.GetTranslation();
	vec3 direction = normalize(player_pos - head_spawn_point);
	vec3 particle_starting_point;

	mat4 turret_head_rotation;
	turret_head_rotation.SetRotationY(atan2(-direction.x, -direction.z));
	turret_head_obj.SetRotation(QuaternionFromMat4(turret_head_rotation));


	particle_starting_point = normalize(player_pos - head_spawn_point);

	MakeParticle("Data/Custom/gyrth/turret/Objects/bullet.xml", (head_spawn_point + particle_starting_point), direction);	//The extra particle_starting_point is so that the particle spawns in front of the turret.
	MakeParticle("Data/Custom/gyrth/turret/Objects/muzzle_flash.xml", (head_spawn_point + particle_starting_point), direction);	//This is because the particles collide, and if they spawned inside the turret they would collide inside the turret.
	MakeParticle("Data/Custom/gyrth/turret/Objects/muzzle_smoke.xml", (head_spawn_point + particle_starting_point), direction);

	vec3 force = normalize(player_pos - head_spawn_point) * RangedRandomFloat(params.GetFloat("Knock back force Min"),params.GetFloat("Knock back force Max"));
	PlaySound("Data/Custom/gyrth/turret/Sounds/gunshot.wav", head_spawn_point);	//Pew

	mo.Execute	(
					"GoLimp();" +	//Comment this line if you don't want an impact, but don't jump.
					"TakeDamage("+ params.GetFloat("Damage with each shot") +");"
				);
	mo.rigged_object().ApplyForceToRagdoll(force, mo.rigged_object().GetAvgIKChainPos(body_part));
}
void Update() {
	turret_head_obj.SetTranslation(head_spawn_point);
	turret_base_obj.SetTranslation(base_spawn_point);
	if(shoot_player_ids.size() >= 1){
		time += time_step;
		Object@ obj = ReadObjectFromID(hotspot.GetID());
		vec3 pos = obj.GetTranslation();
		int array_size = shoot_player_ids.size();

		if(time >= play_count*params.GetFloat("Time in between shots in sec")){
			int id = shoot_player_ids[0];
			array<int> is_target_nearby;
			GetCharactersInSphere(pos, 10.0f, is_target_nearby);
			if(params.GetFloat("Show turret radius sphere") == 1){
				DebugDrawWireSphere(pos, 10.0f, vec3(1.0f), _fade);
			}
			int num_nearby_char = is_target_nearby.size();
			bool is_taget_near_bool = false;
			for(int i=0; i<num_nearby_char; ++i){
				if(is_target_nearby[i] == id){
						is_taget_near_bool = true;
					}
			}
			if (is_taget_near_bool == true){
				Shoot(ReadCharacterID(shoot_player_ids[0]));
				play_count++;
				if (play_count == 50){
					time = 0.0f;
					play_count = 0;
				}
			}
			else{
				shoot_player_ids.removeAt(0);
			}
		}
	}
}
