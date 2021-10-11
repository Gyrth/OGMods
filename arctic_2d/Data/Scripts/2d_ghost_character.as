#include "2d_character.as"

float attack_timer = 0.0f;

void SetAnimations(){
	@walk_animation = Animation({	"Data/Objects/2d_ghost_walk_1.xml"});

	@idle_animation = Animation({	"Data/Objects/2d_ghost_idle.xml"});
	@jump_animation = Animation({	"Data/Objects/2d_ghost_idle.xml"});
	@dead_animation = Animation({	"Data/Objects/2d_ghost_dead.xml"});
	@hurt_animation = Animation({	"Data/Objects/2d_ghost_dead.xml"});

	flying_character = true;
	ghost_character = true;
	character_scale = 0.75;
	health = 3.0f;
}

void UpdateControls(){

}

void UpdateMovement(){
	vec3 target_velocity = vec3();
	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, 5.0, character_ids);

	if(attack_timer > 0.0){
		attack_timer -= time_step;
	}

	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		if(char.is_player){
			float dist = min(1.0, distance(char.position, this_mo.position));
			target_velocity = normalize(char.position - this_mo.position) * (dist * 0.5);

			if(dist < 0.5 && attack_timer <= 0.0f){
				attack_timer = 0.25;
				vec3 force = target_velocity * 0.5f;
				vec3 hit_pos = vec3(0.0f);
				float damage = 0.1;
				char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
							 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
							 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
			}
		}
	}

	float movement_speed = running?25.0f: 10.0f;

	this_mo.velocity += target_velocity * time_step * movement_speed;
}

void UpdateJumping(){

}
