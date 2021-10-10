#include "2d_character.as"

float attack_timer = 0.0f;
bool has_enemy = false;
float frog_jump_timer = 0.0f;

void SetAnimations(){
	@walk_animation = Animation({	"Data/Objects/2d_frog_walk_1.xml", "Data/Objects/2d_frog_walk_1.xml"});
	@idle_animation = Animation({	"Data/Objects/2d_frog_idle.xml"});
	@jump_animation = Animation({	"Data/Objects/2d_frog_jump.xml"});
	@dead_animation = Animation({	"Data/Objects/2d_frog_dead.xml"});
	@hurt_animation = Animation({	"Data/Objects/2d_frog_dead.xml"});

	flying_character = false;
	character_scale = 0.5;
}

void UpdateControls(){

}

void UpdateMovement(){
	vec3 target_velocity = vec3();
	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, 5.0, character_ids);
	bool found_enemy = false;

	if(attack_timer > 0.0){
		attack_timer -= time_step;
	}

	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		if(char.is_player){
			float dist = min(1.0, distance(char.position, this_mo.position));
			vec3 target_position = char.position;
			target_position.y = this_mo.position.y;

			if(!on_ground){
				target_velocity = normalize(target_position - this_mo.position) * (dist * 0.25);
			}

			if(dist < 0.25 && attack_timer <= 0.0f){
				attack_timer = 0.25;
				vec3 force = target_velocity * 15000.0f;
				vec3 hit_pos = vec3(0.0f);
				float damage = 0.1;
				char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
							 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
							 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
			}
			found_enemy = true;
		}
	}

	has_enemy = found_enemy;

	float movement_speed = running?25.0f: 10.0f;

	this_mo.velocity += target_velocity * time_step * movement_speed;
}

void UpdateJumping(){
	if(has_enemy && movement_state == idle && frog_jump_timer <= 0.0f){
		frog_jump_timer = RangedRandomFloat(0.15f, 2.0f);
		jump_wait = 0.15;

		float jump_mult = 6.0f;
		vec3 jump_vel = vec3(0.0, 1.0, 0.0);
		this_mo.velocity += jump_vel * jump_mult;
	}

	jump_wait -= time_step;

	if(on_ground){
		frog_jump_timer -= time_step;
	}
}
