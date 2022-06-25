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
		if(GetInputPressed(this_mo.controller_id, "attack") && on_ground && movement_state != attack){
			SetMovementState(attack);
			attack_timer = 1.0f;
			int sound_id = PlaySound("Data/Sounds/Attack02.wav", this_mo.position);
			SetSoundPitch(sound_id, RangedRandomFloat(0.9f, 1.2f));
		}

		if(GetInputDown(this_mo.controller_id, "mousescrollup") && camera_distance > 0.15){
			camera_distance -= 0.5f;
		} else if(GetInputDown(this_mo.controller_id, "mousescrolldown") && camera_distance < 10.0){
			camera_distance += 0.5f;
		}
	}
}