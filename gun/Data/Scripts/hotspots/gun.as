int gun_id = CreateObject("Data/Items/gun.xml", true);
Object@ gun = ReadObjectFromID(gun_id);
Object@ gun_hotspot = ReadObjectFromID(hotspot.GetID());
vec3 hotspot_pos = gun_hotspot.GetTranslation();
float time = 0.0f;
float gun_time = 0.0f;
float delay = 5.0f;
int char_id = -1;
int primary_id = -1;
int secondary_id = -1;
float bullet_speed = 433.0f;
float max_bullet_distance = 500.0f;
int no_attack_value;
int no_aim_value;
float trigger_time_out = 0.0f;
float time_out_length = 0.25f;
bool is_aiming = false;

array<Bullet@> bullets;

class Bullet{
	float distance_done = 0.0f;
	vec3 direction;
	vec3 starting_position;
	float timer;
	Bullet(vec3 _starting_point, vec3 _direction){
		starting_position = _starting_point;
		direction = _direction;
	}
	void SetStartingPoint(vec3 new_starting_point){
		distance_done += distance(starting_position, new_starting_point);
		starting_position = new_starting_point;
	}
}

void Init() {
	vec3 spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+0.2f, hotspot_pos.z);
	gun.SetTranslation(spawn_point);
	gun.SetSelectable(true);
	gun.SetTranslatable(true);
	gun_hotspot.SetScale(vec3(0.1f,0.1f,0.1f));
}

void SetParameters() {

}

void Reset(){
}

void Update() {
	time += time_step;
	UpdateBullets();
	UpdateUser();
}

void UpdateUser(){
	if (char_id == -1){
		ItemObject@ gun_item = ReadItemID(gun_id);
		char_id = gun_item.HeldByWhom();
		if (char_id != -1){
			level.SendMessage("gun_event gun_owner " + char_id);
			MovementObject@ mo = ReadCharacterID(char_id);
			no_attack_value = mo.QueryIntFunction("bool WantsToAttack()");
			no_aim_value = mo.QueryIntFunction("bool WantsToDragBody()");
		}
	}else{

		if(trigger_time_out > 0.0){
			trigger_time_out -= time_step;
			return;
		}

		MovementObject@ mo = ReadCharacterID(char_id);
		ItemObject@ gun_item = ReadItemID(gun_id);

		primary_id = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
		//For some reason WantsToAttack doesn't return 0 or 1 but an arbitrary int value.
		if( primary_id == gun_id && mo.QueryIntFunction("bool WantsToAttack()") != no_attack_value){
			trigger_time_out = time_out_length;
			PlaySound("Data/Sounds/Revolver.wav", mo.position);
			vec3 facing = camera.GetFacing();
			bullets.insertLast(Bullet(gun_item.GetPhysicsPosition(), facing));
		}

		if(mo.QueryIntFunction("bool WantsToDragBody()") != no_aim_value && !is_aiming){
			is_aiming = true;
			level.SendMessage("gun_event gun_aiming on");
		}else if(mo.QueryIntFunction("bool WantsToDragBody()") == no_aim_value && is_aiming){
			is_aiming = false;
			level.SendMessage("gun_event gun_aiming off");
		}

		if(gun_item.HeldByWhom() == 0){
			//The gun is no longer held by anyone.
			char_id = -1;
		}
	}
}

void UpdateBullets(){
	for(uint i = 0; i < bullets.size(); i++){

		Bullet@ bullet = bullets[i];

		vec3 start = bullet.starting_position;
		vec3 end = bullet.starting_position + (bullet.direction * bullet_speed * time_step);
		bool colliding = CheckCollisions(start, end);
		DebugDrawLine(start, end, vec3(1), _fade);
		bullet.SetStartingPoint(end);
		if (bullet.distance_done > max_bullet_distance || colliding){
			bullets.removeAt(i);
			return;
		}
	}
}

bool CheckCollisions(vec3 start, vec3 end){
	MovementObject@ mo = ReadCharacterID(char_id);
	mo.Execute("vec3 start = vec3(" + start.x + "," + start.y + "," + start.z + ");" +
				"vec3 end = vec3(" + end.x + "," + end.y + "," + end.z + ");" +
				"col.GetObjRayCollision(start, end);" +
				"if(sphere_col.NumContacts() != 0){"+
					"CollisionPoint point = sphere_col.GetContact(0);" +
					/*"DebugDrawWireSphere(point.position, 0.4, vec3(1,0,0), _fade);"+*/
					"blinking = true;" +
					"MakeMetalSparks(point.position);"+
					"vec3 facing = camera.GetFacing();" +
					"MakeParticle(\"Data/Particles/explosion_decal.xml\", point.position - facing, facing * 10.0f);}" +
				"else{"+
					"blinking = false;}");

	mo.Execute("vec3 start = vec3(" + start.x + "," + start.y + "," + start.z + ");" +
				"vec3 end = vec3(" + end.x + "," + end.y + "," + end.z + ");" +
				"col.CheckRayCollisionCharacters(start, end);" +
				"if(sphere_col.NumContacts() != 0){"+
					"CollisionPoint point = sphere_col.GetContact(0);" +
					"roll_count = point.id;}" +
				"else{"+
					"roll_count = 0;}");
	bool colliding = mo.GetBoolVar("blinking");
	int char_hit = mo.GetIntVar("roll_count");
	if (char_hit != 0 && char_hit != char_id){
		MovementObject@ char = ReadCharacterID(char_hit);
		vec3 force = camera.GetFacing() * 10000.0f;
		vec3 hit_pos = vec3(0.0f);
		char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
					 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
					 "HandleRagdollImpactImpulse(impulse, pos, 5.0f);");
	}
	return colliding;
}

void MakeMetalSparks(vec3 pos){
  int num_sparks = 60;
	float speed = 20.0f;
	for(int i=0; i<num_sparks; ++i){
		MakeParticle("Data/Particles/explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
																  RangedRandomFloat(-speed,speed),
																  RangedRandomFloat(-speed,speed)));
	}
}
