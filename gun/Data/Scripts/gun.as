
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

class Gun{
	int character_id = -1;
	bool has_camera_control = false;
	float target_rotation = 0.0f;
	float target_rotation2 = 0.0f;

	float orig_sensitivity = -1.0f;
	float aim_sensitivity = 0.1f;
	bool init_done = Init();
	bool aiming = false;
	int gun_aim_anim;
	uint32 aim_particle;
	float start_throwing_time = 0.0f;
	array<Bullet@> bullets;

	float trigger_time_out = 0.0f;
	float time_out_length = 0.25f;
	float bullet_speed = 433.0f;
	float max_bullet_distance = 500.0f;

	bool Init(){
		orig_sensitivity = GetConfigValueFloat("mouse_sensitivity");
		return true;
	}

	void UpdateGun(){
		UpdateBullets();
		if (GetInputDown(this_mo.controller_id, "grab")){
			aiming = true;
		}else{
			aiming = false;
		}
		DebugText("key", "aiming " + aiming, _fade);
		bool can_trigger = true;
		if(trigger_time_out > 0.0){
			trigger_time_out -= time_step;
			can_trigger = false;
		}

		if(aiming && weapon_slots[primary_weapon_slot] != -1){
			ItemObject@ gun_item = ReadItemID(weapon_slots[primary_weapon_slot]);
			vec3 cam_facing = camera.GetFacing();
			Object@ charObject = ReadObjectFromID(this_mo.GetID());

			if(GetInputDown(this_mo.controller_id, "attack") && can_trigger){
				trigger_time_out = time_out_length;
				PlaySound("Data/Sounds/Revolver.wav", this_mo.position);
				bullets.insertLast(Bullet(gun_item.GetPhysicsPosition(), cam_facing));
			}

			vec3 facing = camera.GetFacing();
			vec3 start = facing * 5.0f;
			//Limited aim enabled.
			vec3 end = vec3(facing.x, max(-0.9, min(0.5f, facing.y)), facing.z) * 30.0f;
			//Collision check for non player objects
			vec3 hit = col.GetRayCollision(camera.GetPos(), camera.GetPos() + end);
			//Collision check for player objects.
			col.CheckRayCollisionCharacters(camera.GetPos(), camera.GetPos() + end);
			SetConfigValueFloat("mouse_sensitivity", aim_sensitivity);

			throw_target_pos = hit;
			if(sphere_col.NumContacts() != 0){
				for(int i = 0; i < sphere_col.NumContacts(); i++){
					const CollisionPoint contact = sphere_col.GetContact(i);
					if(contact.id != this_mo.GetID() && contact.position != vec3(0,0,0) && distance(camera.GetPos(), throw_target_pos) > distance(camera.GetPos() ,contact.position)){
						throw_target_pos = contact.position;
					}
				}
			}

			aim_particle = MakeParticle("Data/Particles/gun_aim.xml", throw_target_pos, vec3(0));
			fov = max(fov - ((time - start_throwing_time)), 40.0f);

			cam_pos_offset = vec3(cam_facing.z * -0.5, 0, cam_facing.x * 0.5);
			DebugText("key1", "offset " + cam_pos_offset, _fade);
			int8 flags = 0;

			if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
				this_mo.SetAnimation("Data/Animations/gun_aim_middle.anm", 20.0f, flags);
				this_mo.rigged_object().anim_client().RemoveLayer(gun_aim_anim, 20.0f);
				if(this_mo.GetFacing().y > 0){
					gun_aim_anim = this_mo.rigged_object().anim_client().AddLayer("Data/Animations/gun_aim_up.anm",(60*cam_facing.y),flags);
				}else{
					gun_aim_anim = this_mo.rigged_object().anim_client().AddLayer("Data/Animations/gun_aim_down.anm",-(60*cam_facing.y),flags);
				}
				if(cam_facing.y > -1.0f){
					this_mo.SetRotationFromFacing(normalize(cam_facing + vec3(cam_facing.z * -0.5, 0, cam_facing.x * 0.5)));
				}
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
		bool colliding = false;
		col.GetObjRayCollision(start, end);
		if(sphere_col.NumContacts() != 0){
			CollisionPoint point = sphere_col.GetContact(0);
			MakeMetalSparks(point.position);
			vec3 facing = camera.GetFacing();
			MakeParticle("Data/Particles/explosion_decal.xml", point.position - facing, facing * 10.0f);
			colliding = true;
		}

		col.CheckRayCollisionCharacters(start, end);
		int char_id = -1;
		if(sphere_col.NumContacts() != 0){
			CollisionPoint point = sphere_col.GetContact(0);
			char_id = point.id;
		}

		if (char_id != -1 && char_id != this_mo.GetID()){
			MovementObject@ char = ReadCharacterID(char_id);
			vec3 force = camera.GetFacing() * 10000.0f;
			vec3 hit_pos = vec3(0.0f);
			char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
						 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
						 "HandleRagdollImpactImpulse(impulse, pos, 5.0f);");
			 colliding = true;
		}
		return colliding;
	}
	void Shoot(){

	}
}
