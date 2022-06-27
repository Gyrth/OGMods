#include "therium_advance_character.as"

void SetAnimations(){
	@walk_down_animation = 		Animation({	"Data/Objects/princess_walk_down.xml"});
	@walk_right_animation = 	Animation({	"Data/Objects/princess_walk_right.xml"});
	@walk_left_animation = 		Animation({	"Data/Objects/princess_walk_left.xml"});
	@walk_up_animation = 		Animation({	"Data/Objects/princess_walk_up.xml"});

	@idle_down_animation = 		Animation({	"Data/Objects/princess_idle_down.xml"});
	@idle_right_animation = 	Animation({	"Data/Objects/princess_idle_right.xml"});
	@idle_left_animation = 		Animation({	"Data/Objects/princess_idle_left.xml"});
	@idle_up_animation = 		Animation({	"Data/Objects/princess_idle_up.xml"});

	@attack_down_animation = 	Animation({	"Data/Objects/princess_attack_down.xml"});
	@attack_left_animation = 	Animation({	"Data/Objects/princess_attack_left.xml"});
	@attack_right_animation = 	Animation({	"Data/Objects/princess_attack_right.xml"});
	@attack_up_animation = 		Animation({	"Data/Objects/princess_attack_up.xml"});

	@roll_down_animation = 		Animation({	"Data/Objects/princess_hurt_down.xml"});
	@roll_left_animation = 		Animation({	"Data/Objects/princess_hurt_left.xml"});
	@roll_right_animation = 	Animation({	"Data/Objects/princess_hurt_right.xml"});
	@roll_up_animation = 		Animation({	"Data/Objects/princess_hurt_up.xml"});

	@dead_animation = Animation({	"Data/Objects/princess_death.xml"});
	@hurt_animation = Animation({	"Data/Objects/princess_hurt_down.xml"});

	health = 1.0f;
}

void UpdateControls(){

}

vec3 GetTargetVelocity() {
	vec3 target_velocity = vec3();
	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, 5.0, character_ids);

	return target_velocity;
}

void UpdateCamera(const Timestep &in ts){

}