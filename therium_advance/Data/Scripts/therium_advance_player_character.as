#include "therium_advance_character.as"

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

	@jump_animation = Animation({	"Data/Objects/adventurer_jump_roll_right.xml"});
	@dead_animation = Animation({	"Data/Objects/adventurer_death.xml"});
	@hurt_animation = Animation({	"Data/Objects/adventurer_hurt_right.xml"});

	health = 1.0f;
	level.SendMessage("update_player_health " + health);
}

void UpdateControls(){
	if(this_mo.controlled){
		if(GetInputPressed(this_mo.controller_id, "attack") && on_ground && movement_state != attack){
			movement_state = attack;
			attack_timer = 1.0f;
			int sound_id = PlaySound("Data/Sounds/Attack02.wav", this_mo.position);
			SetSoundPitch(sound_id, RangedRandomFloat(0.9f, 1.2f));
			UpdateAttack(true);
		}

		if(GetInputDown(this_mo.controller_id, "mousescrollup") && camera_distance > 0.15){
			camera_distance -= 0.5f;
		} else if(GetInputDown(this_mo.controller_id, "mousescrolldown") && camera_distance < 10.0){
			camera_distance += 0.5f;
		}
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

	if(on_ground && movement_state != attack && this_mo.controlled && GetInputDown(this_mo.controller_id, "jump")){
		if(jump_wait <= 0.0f){
			jump_wait = 0.15;
			float jump_mult = 6.0f;
			vec3 jump_vel = vec3(0.0, 1.0, 0.0);
			this_mo.velocity += jump_vel * jump_mult;
		}
	}
}
