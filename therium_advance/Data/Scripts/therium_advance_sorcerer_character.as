#include "therium_advance_character.as"

void SetAnimations(){
	@walk_down_animation = 		Animation({	"Data/Objects/sorcerer_walk_down.xml"});
	@walk_right_animation = 	Animation({	"Data/Objects/sorcerer_walk_right.xml"});
	@walk_left_animation = 		Animation({	"Data/Objects/sorcerer_walk_left.xml"});
	@walk_up_animation = 		Animation({	"Data/Objects/sorcerer_walk_up.xml"});

	@idle_down_animation = 		Animation({	"Data/Objects/sorcerer_idle_down.xml"});
	@idle_right_animation = 	Animation({	"Data/Objects/sorcerer_idle_right.xml"});
	@idle_left_animation = 		Animation({	"Data/Objects/sorcerer_idle_left.xml"});
	@idle_up_animation = 		Animation({	"Data/Objects/sorcerer_idle_up.xml"});

	@attack_down_animation = 	Animation({	"Data/Objects/sorcerer_attack_down.xml"});
	@attack_left_animation = 	Animation({	"Data/Objects/sorcerer_attack_left.xml"});
	@attack_right_animation = 	Animation({	"Data/Objects/sorcerer_attack_right.xml"});
	@attack_up_animation = 		Animation({	"Data/Objects/sorcerer_attack_up.xml"});

	@roll_down_animation = 		Animation({	"Data/Objects/sorcerer_hurt_down.xml"});
	@roll_left_animation = 		Animation({	"Data/Objects/sorcerer_hurt_left.xml"});
	@roll_right_animation = 	Animation({	"Data/Objects/sorcerer_hurt_right.xml"});
	@roll_up_animation = 		Animation({	"Data/Objects/sorcerer_hurt_up.xml"});

	@dead_animation = Animation({	"Data/Objects/sorcerer_death.xml"});
	@hurt_animation = Animation({	"Data/Objects/sorcerer_hurt_down.xml"});

	health = 1.0f;
	level.SendMessage("update_player_health " + health);
}

void UpdateControls(){

}

vec3 GetTargetVelocity() {
	vec3 target_velocity = vec3();
	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, 5.0, character_ids);

	// for(uint i = 0; i < character_ids.size(); i++){
	// 	MovementObject@ char = ReadCharacterID(character_ids[i]);
	// 	if(char.is_player){
	// 		float dist = min(1.0, distance(char.position, this_mo.position)) * 1.25f;
	// 		vec3 target_position = char.position;
	// 		target_position.y = this_mo.position.y;

	// 		if(on_ground){
	// 			target_velocity = normalize(target_position - this_mo.position) * dist;
	// 		}

	// 		if(dist < 0.65 && attack_timer <= 0.0f){
	// 			attack_timer = 0.25;
	// 			vec3 force = target_velocity * 0.5f;
	// 			vec3 hit_pos = vec3(0.0f);
	// 			float damage = 0.1;
	// 			char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
	// 						 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
	// 						 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
	// 		}
	// 	}
	// }

	return target_velocity;
}

void UpdateCamera(const Timestep &in ts){

}