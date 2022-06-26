#include "therium_advance_character.as"

float enemy_sphere_timer = 0.0f;

void SetAnimations(){
	@walk_down_animation = 		Animation({	"Data/Objects/adventurer_walk_down.xml"});
	@walk_right_animation = 	Animation({	"Data/Objects/adventurer_walk_right.xml"});
	@walk_left_animation = 		Animation({	"Data/Objects/adventurer_walk_left.xml"});
	@walk_up_animation = 		Animation({	"Data/Objects/adventurer_walk_up.xml"});

	@idle_down_animation = 		Animation({	"Data/Objects/adventurer_idle_down.xml"});
	@idle_right_animation = 	Animation({	"Data/Objects/adventurer_idle_right.xml"});
	@idle_left_animation = 		Animation({	"Data/Objects/adventurer_idle_left.xml"});
	@idle_up_animation = 		Animation({	"Data/Objects/adventurer_idle_up.xml"});

	@attack_down_animation = 	Animation({	"Data/Objects/adventurer_attack_down.xml"});
	@attack_left_animation = 	Animation({	"Data/Objects/adventurer_attack_left.xml"});
	@attack_right_animation = 	Animation({	"Data/Objects/adventurer_attack_right.xml"});
	@attack_up_animation = 		Animation({	"Data/Objects/adventurer_attack_up.xml"});

	@roll_down_animation = 		Animation({	"Data/Objects/adventurer_jump_roll_down.xml"});
	@roll_left_animation = 		Animation({	"Data/Objects/adventurer_jump_roll_left.xml"});
	@roll_right_animation = 	Animation({	"Data/Objects/adventurer_jump_roll_right.xml"});
	@roll_up_animation = 		Animation({	"Data/Objects/adventurer_jump_roll_up.xml"});

	@dead_animation = Animation({	"Data/Objects/adventurer_death.xml"});
	@hurt_animation = Animation({	"Data/Objects/adventurer_hurt_right.xml"});

	health = 1.0f;
	level.SendMessage("update_player_health " + health);
}

void UpdateControls(){
	if(this_mo.controlled){
		if(GetInputPressed(this_mo.controller_id, "attack") && on_ground && movement_state != attack && movement_state != roll){
			SetMovementState(attack);
			attack_timer = 1.0f;
			int sound_id = PlaySound("Data/Sounds/Attack02.wav", this_mo.position);
			SetSoundPitch(sound_id, RangedRandomFloat(0.9f, 1.2f));
			Attack();
		}

		if(GetInputDown(this_mo.controller_id, "mousescrollup") && camera_distance > 0.15){
			camera_distance -= 0.5f;
		} else if(GetInputDown(this_mo.controller_id, "mousescrolldown") && camera_distance < 10.0){
			camera_distance += 0.5f;
		}
	}
}

void Attack(){
	if(close_enemy_id == -1){return;}

	MovementObject@ char = ReadCharacterID(close_enemy_id);

	vec3 target_position = char.position;
	float dist = distance(target_position, this_mo.position);
	target_position.y = this_mo.position.y;

	vec3 push_velocity = normalize(target_position - this_mo.position) * dist;

	if(dist < 1.0){
		vec3 hit_pos = vec3(0.0f);
		float damage = 0.25;
		char.Execute(	"vec3 impulse = vec3(" + push_velocity.x + ", " + push_velocity.y + ", " + push_velocity.z + ");" +
						"vec3 pos = vec3(" + hit_pos.x + ", " + hit_pos.y + ", " + hit_pos.z + ");" +
						"HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
	}
}

void UpdateCamera(const Timestep &in ts){
	if(!this_mo.controlled || !this_mo.is_player){
		return;
	}

	CheckForEnemies();

	SetGrabMouse(true);

	RiggedObject@ rigged_object = this_mo.rigged_object();
	Skeleton@ skeleton = rigged_object.skeleton();

	float camera_vibration_mult = 3.0f;
	float camera_vibration = camera_shake * camera_vibration_mult;
	float y_shake = RangedRandomFloat(-camera_vibration, camera_vibration);
	float x_shake = RangedRandomFloat(-camera_vibration, camera_vibration);
	/* camera.SetYRotation(cam_rotation_y + y_shake);
	camera.SetXRotation(cam_rotation_x + x_shake);
	camera.SetZRotation(cam_rotation_z); */


	float distance = 3.5f;

	distance -= intro_cam_offset;
	intro_cam_offset = max(0.0, intro_cam_offset - time_step * 2.0);

	vec3 center_position = this_mo.position;

	if(close_enemy_id != -1){
		MovementObject@ char = ReadCharacterID(close_enemy_id);
		center_position = (center_position + char.position) / 2.0f;

		if(enemy_sphere_timer >= 1.0f){
			vec3 color = vec3(1.0f, 0.0f, 1.0f);
			MakeParticle("Data/Particles/enemy_ring.xml", char.position - vec3(0.0f, 0.35f, 0.0f), vec3(0.0f), color);
			enemy_sphere_timer = 0.0f;
		}

		enemy_sphere_timer += time_step;
	}

	vec3 new_cam_position = center_position + vec3(0.0, distance / 2.0, 0.001f);
	vec3 new_look_position = center_position;

	if(last_cam_pos == vec3(0.0, 0.0, 0.0)){
		last_cam_pos = new_cam_position;
		last_look_pos = new_look_position;
	}

	vec3 cam_pos = mix(last_cam_pos, new_cam_position, time_step * 5.0);
	vec3 look_pos = mix(last_look_pos, new_look_position, time_step * 5.0);
	last_cam_pos = cam_pos;
	last_look_pos = look_pos;

	camera.SetXRotation(-90.0f);
	camera.SetYRotation(0.0f);
	camera.SetZRotation(0.0f);
	/* camera.CalcFacing(); */

	camera.SetFOV(current_fov);
	camera.SetPos(cam_pos);
	camera.SetDistance(camera_distance);

	if(knocked_out == _dead){
		camera.SetDOF(0.15, 4.0, 1.0, 0.15, 5.0, 1.0);
	}else{
		camera.SetDOF(0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
		/* camera.SetDOF(0.15, 4.0, 1.0, 0.15, 5.0, 1.0); */
	}

	if(this_mo.focused_character) {
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
	}

	camera.SetInterpSteps(ts.frames());
}

void CheckForEnemies(){
	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, 5.0, character_ids);
	close_enemy_id = -1;

	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		int char_state = char.GetIntVar("movement_state");

		if(!char.is_player && char_state != dead){
			close_enemy_id = character_ids[i];
		}
	}
}

// Converts the keyboard controls into a target velocity that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0f);

	if(!this_mo.controlled) {
		return target_velocity;
	}

	vec3 right;

	{
		right = camera.GetFlatFacing();
		float side = right.x;
		right.x = -right .z;
		right.z = side;
	}

	target_velocity -= GetMoveYAxis(this_mo.controller_id) * camera.GetFlatFacing();
	target_velocity += GetMoveXAxis(this_mo.controller_id) * right;

	if(GetInputDown(this_mo.controller_id, "walk")) {
		if(length_squared(target_velocity)>kWalkSpeed * kWalkSpeed) {
			target_velocity = normalize(target_velocity) * kWalkSpeed;
		}
	} else {
		if(length_squared(target_velocity)>1) {
			target_velocity = normalize(target_velocity);
		}
	}

	return target_velocity;
}