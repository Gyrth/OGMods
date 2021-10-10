#include "2d_character.as"

void SetAnimations(){
	@walk_animation = Animation({	"Data/Objects/2d_character_walk_1.xml",
											"Data/Objects/2d_character_walk_2.xml",
											"Data/Objects/2d_character_walk_3.xml",
											"Data/Objects/2d_character_walk_4.xml",
											"Data/Objects/2d_character_walk_5.xml",
											"Data/Objects/2d_character_walk_6.xml",
											"Data/Objects/2d_character_walk_7.xml",
											"Data/Objects/2d_character_walk_8.xml",
											"Data/Objects/2d_character_walk_9.xml",
											"Data/Objects/2d_character_walk_10.xml",
											"Data/Objects/2d_character_walk_11.xml"
											});

	@idle_animation = Animation({	"Data/Objects/2d_character_idle.xml"});
	@jump_animation = Animation({	"Data/Objects/2d_character_jump.xml"});
	@dead_animation = Animation({	"Data/Objects/2d_character_dead.xml"});
	@hurt_animation = Animation({	"Data/Objects/2d_character_dead.xml"});

	health = 1.0f;
	level.SendMessage("update_player_health " + health);
}

void UpdateControls(){
	if(this_mo.controlled && GetInputPressed(this_mo.controller_id, "attack")){
		Shoot();
	}
}

void UpdateMovement(){
	float movement_speed = running?25.0f: 10.0f;
	vec3 target_velocity = GetTargetVelocity();

	if(!on_ground){
		movement_speed = 3.0;
	}

	this_mo.velocity += target_velocity * time_step * movement_speed;
}

void UpdateJumping(){
	if(jump_wait > 0.0f && on_ground){
		jump_wait -= time_step;
	}

	if(on_ground && GetInputDown(this_mo.controller_id, "jump")){
		if(movement_state != jump){
			movement_state = jump;
			SetAnimation(@jump_animation);
		}

		if(jump_wait <= 0.0f){
			jump_wait = 0.15;
			float jump_mult = 6.0f;
			vec3 jump_vel = vec3(0.0, 1.0, 0.0);
			this_mo.velocity += jump_vel * jump_mult;
		}
	}
}
