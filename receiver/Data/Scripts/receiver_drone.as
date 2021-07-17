#include "aschar_aux.as"
#include "situationawareness.as"
#include "interpdirection.as"

int light_id = CreateObject("Data/Objects/lights/dynamic_light.xml", true);

Object@ light = ReadObjectFromID(light_id);

Situation situation;
int target_id = -1;

float startle_time;

bool has_jump_target = false;
vec3 jump_target_vel;

float awake_time = 0.0f;
const float AWAKE_NOTICE_THRESHOLD = 1.0f;

float enemy_seen = 0.0f;

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target_id = -1;
int old_waypoint_target_id = -1;
const float _throw_counter_probability = 0.2f;
bool will_throw_counter;
int ground_punish_decision = -1;

float notice_target_aggression_delay = 0.0f;
int notice_target_aggression_id = 0.0f;

float target_attack_range = 0.0f;
float strafe_vel = 0.0f;
const float _block_reflex_delay_min = 0.1f;
const float _block_reflex_delay_max = 0.2f;
float block_delay;
bool going_to_block = false;
float dodge_delay;
bool going_to_dodge = false;
float roll_after_ragdoll_delay;
bool throw_after_active_block;
bool allow_active_block = true;
bool always_unaware = false;
bool always_active_block = false;

bool combat_allowed = true;
bool chase_allowed = false;

float body_bob_freq = 0.0f;
float body_bob_time_offset;

class InvestigatePoint {
	vec3 pos;
	float seen_time;
};
array<InvestigatePoint> investigate_points;

const float kGetWeaponDelay = 0.4f;
float get_weapon_delay = kGetWeaponDelay;

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still};
AIGoal goal = _patrol;

enum AISubGoal {_unknown = -1, _punish_fall, _provoke_attack, _avoid_jump_kick, _wait_and_attack, _rush_and_attack, _defend, _surround_target, _escape_surround,
	_investigate_slow, _investigate_urgent, _investigate_body, _investigate_around};
AISubGoal sub_goal = _wait_and_attack;

AIGoal old_goal;
AISubGoal old_sub_goal;

int investigate_target_id = -1;
vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int chase_target_id = -1;
int weapon_target_id = -1;

float investigate_body_time;
float patrol_wait_until = 0.0f;

enum PathFindType {_pft_nav_mesh, _pft_climb, _pft_drop, _pft_jump};
PathFindType path_find_type = _pft_nav_mesh;
vec3 path_find_point;
float path_find_give_up_time;

enum ClimbStage {_nothing, _jump, _wallrun, _grab, _climb_up};
ClimbStage trying_to_climb = _nothing;
vec3 climb_dir;

int num_ribbons = 1;
int fire_object_id = -1;
bool on_fire = false;
float flame_effect = 0.0f;

int shadow_id = -1;
int lf_shadow_id = -1;
int rf_shadow_id = -1;

// Parameter values
float p_aggression;
float p_ground_aggression;
float p_damage_multiplier;
float p_block_skill;
float p_block_followup;
float p_attack_speed_mult;
float p_speed_mult;
float p_fat;
float p_muscle;
float p_ear_size;
int p_lives;
int lives;

const float _base_run_speed = 8.0f; // used to calculate movement and jump velocities, change this instead of max_speed
const float _base_true_max_speed = 12.0f; // speed can never exceed this amount
float run_speed = _base_run_speed;
float true_max_speed = _base_true_max_speed;
float max_speed = run_speed; // this is recalculated constantly because actual max speed is affected by slopes

int tether_id = -1;

float breath_amount = 0.0f;
float breath_time = 0.0f;
float breath_speed = 0.9f;
array<float> resting_mouth_pose;
array<float> target_resting_mouth_pose;
float resting_mouth_pose_time = 0.0f;

float old_time = 0.0f;

vec3 ground_normal(0,1,0);
vec3 flip_modifier_axis;
float flip_modifier_rotation;
vec3 tilt_modifier;
const float collision_radius = 1.0f; // affects the size of a sphere collider used for leg collisions
enum IdleType{_stand, _active, _combat};
IdleType idle_type = _active;

bool idle_stance = false;
float idle_stance_amount = 0.0f;

// the main timer of the script, used whenever anything has to know how much time has passed since something else happened.
float time = 0;

vec3 head_look;
vec3 torso_look;

string[] legs = { "left_leg", "right_leg" };
string[] arms = { "leftarm", "rightarm" };

bool on_ground = false;
string dialogue_anim = "Data/Animations/r_sweep.anm";
int knocked_out = _awake;

// States are used to differentiate between various widely different situations
const int _movement_state = 0; // character is moving on the ground
const int _ground_state = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2; // character is performing an attack
const int _hit_reaction_state = 3; // character was hit or dealt damage to and has to react to it in some manner
const int _ragdoll_state = 4; // character is falling in ragdoll mode
int state = _movement_state;

vec3 last_col_pos;
float duck_amount = 0.5f;
const float _bumper_size = 2.5f;
const float _ground_normal_y_threshold = 0.5f;

bool balancing = false;
vec3 balance_pos;

bool show_debug = false;
bool dialogue_control = false;
bool static_char = false;
int invisible_when_stationary = 0;
int species = 0;
float threat_amount = 0.0f;
float target_threat_amount = 0.0f;
float threat_vel = 0.0f;
int primary_weapon_slot = 0;
int secondary_weapon_slot = 1;
array<int> weapon_slots = {-1, -1};
int knife_layer_id = -1;
int throw_knife_layer_id = -1;
float land_magnitude = 0.0f;
float character_scale = 1.0f;
AttackScriptGetter attack_attacker;
float block_stunned = 1.0f;
int block_stunned_by_id = -1;


array<BoneTransform> skeleton_bind_transforms;
array<BoneTransform> inv_skeleton_bind_transforms;
array<int> ik_chain_elements;
enum IKLabel {kLeftArmIK, kRightArmIK, kLeftLegIK, kRightLegIK,
			  kHeadIK, kLeftEarIK, kRightEarIK, kTorsoIK,
			  kTailIK, kNumIK };
array<int> ik_chain_start_index;
array<int> ik_chain_length;
array<float> ik_chain_bone_lengths;
array<int> bone_children;
array<int> bone_children_index;
array<vec3> convex_hull_points;
array<int> convex_hull_points_index;

// Key transform enums
const int kHeadKey = 0;
const int kLeftArmKey = 1;
const int kRightArmKey = 2;
const int kLeftLegKey = 3;
const int kRightLegKey = 4;
const int kChestKey = 5;
const int kHipKey = 6;
const int kNumKeys = 7;

array<float> key_masses;
array<int> root_bone;

array<int> flash_obj_ids;

float last_changed_com = 0.0f;
vec3 com_offset;
vec3 com_offset_vel;
vec3 target_com_offset;

array<int> roll_check_bones;
array<BoneTransform> key_transforms;
array<float> target_leg_length;

vec3 push_velocity;

array<vec3> temp_old_ear_points;
array<vec3> old_ear_points;
array<vec3> ear_points;

array<float> target_ear_rotation;
array<float> ear_rotation;
array<float> ear_rotation_time;

int skip_ear_physics_counter = 0;

array<vec3> temp_old_tail_points;
array<vec3> old_tail_points;
array<vec3> tail_points;
array<vec3> tail_correction;
array<float> tail_section_length;

// Verlet integration for arm physics
array<vec3> temp_old_arm_points;
array<vec3> old_arm_points;
array<vec3> arm_points;
enum ChainPointLabels {kHandPoint, kWristPoint, kElbowPoint, kShoulderPoint, kCollarTipPoint, kCollarPoint, kNumArmPoints};

vec3 old_com;
vec3 old_com_vel;
vec3 old_hip_offset;
array<float> old_foot_offset;
array<quaternion> old_foot_rotate;

vec3 old_head_facing;
vec2 old_angle;
vec2 head_angle;
vec2 target_head_angle;
vec2 head_angle_vel;
vec2 head_angle_accel;
float old_head_angle;

vec3 old_chest_facing;
vec2 old_chest_angle_vec;
vec2 chest_angle;
vec2 target_chest_angle;
vec2 chest_angle_vel;
float old_chest_angle;
float ragdoll_fade_speed = 1000.0f;
float preserve_angle_strength = 0.0f;

quaternion total_body_rotation;

array<vec3> temp_old_weap_points;
array<vec3> old_weap_points;
array<vec3> weap_points;
string target_animation = "Data/Animations/receiver_drone_default.anm";

bool post_init = false;
float aim_speed = 8.0;
float shoot_interval = 0.15;
float shoot_timer = 0.0;
vec3 aim_direction = vec3(0.0);
vec3 current_direction = vec3(0.0);
quaternion drone_rotation;
int current_path_point_id = -1;
int starting_path_point_id = -1;
vec3 drone_translation;
float collision_sphere_size = 0.35;
float attack_sphere_size = 0.25;
float patrol_movement_speed = 2.0;
float attack_movement_speed = 5.5;

float patrol_turn_speed = 2.0;
float attack_turn_speed = 6.0;
vec3 velocity = vec3();
bool colliding = false;
float yaw = 0.0;
float target_yaw = 0.0;
float movement_speed = patrol_movement_speed;
float turn_speed = patrol_turn_speed;
float attack_timer = 0.0;
float attack_interval = 0.5;
int drone_sound_id = -1;
float electric_timer = 0.0;
float electric_interval = 0.05;
float flash_timer = 0.0;
bool active = false;
float active_check_timer = 0.0;
float activation_radius = 100.0;
float attack_radius = 100.0;
vec3 old_vel;
bool dead = false;

void Update(int num_frames) {
	if(!post_init){
		PostInit();
		post_init = true;
		return;
	}

	Timestep ts(time_step, num_frames);
	time += ts.step();
	ApplyPhysics(ts);
	HandleCollisions(ts);

	ActiveCheck();

	this_mo.velocity *= pow(0.95f,ts.frames());

	old_vel = this_mo.velocity;
	last_col_pos = this_mo.position;

	drone_translation = this_mo.position;
	current_direction = this_mo.GetFacing();

	if(flash_timer > 0.0){
		flash_timer -= time_step;
		if(flash_timer <= 0.0){
			light.SetTint(vec3(0.0));
		}
	}

	if(!active || dead){
		return;
	}

	SetSoundPosition(drone_sound_id, drone_translation);

	UpdatePatrolling();
	EnemyCheck();
	UpdateAttacking();
}

void PostInit(){
	drone_sound_id = PlaySoundLoopAtLocation("Data/Sounds/drone.wav", drone_translation, 0.25);
	SetSoundPitch(drone_sound_id, 1.5);
	light.SetTint(vec3(0.0));
	light.SetScale(vec3(4.0));
}

void SetScale(float new_character_scale){
	character_scale = new_character_scale;
	vec3 old_facing = this_mo.GetFacing();
	params.SetFloat("Character Scale", character_scale);
	this_mo.RecreateRiggedObject(this_mo.char_path);
	this_mo.SetAnimation(target_animation, 20.0f, 0);
	this_mo.SetRotationFromFacing(old_facing);
	FixDiscontinuity();
}

float wiggle_wait = 0.0f;
float wave = 1.0f;
bool targeted_jump = false;

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
	float distance_threshold = character_scale * 1.25f;
	vec3 this_com = this_mo.rigged_object().skeleton().GetCenterOfMass();
	vec3 other_com = other.rigged_object().skeleton().GetCenterOfMass();
	this_com.y = this_mo.position.y;
	other_com.y = other.position.y;
	if(distance(this_com, other_com) < distance_threshold){
		vec3 dir = other_com - this_com;
		float dist = length(dir);
		dir /= dist;
		dir *= distance_threshold - dist;
		vec3 other_push = dir * 0.5f / (time_step) * 0.15f;
		/* this_mo.velocity -= other_push; */
		other.Execute("
		if(!static_char){
			push_velocity += vec3("+other_push.x+","+other_push.y+","+other_push.z+");
			MindReceiveMessage(\"collided "+this_mo.GetID()+"\");
		}");
	}
}

string attack_path = "Data/Attacks/knifeslash.xml";
float p_attack_damage_mult = 1.0;
float p_attack_knockback_mult = 1.0;

void CheckAttack(){
	int player_id = GetPlayerCharacterID();
	if(player_id == -1){
		return;
	}
	MovementObject@ char = ReadCharacterID(player_id);
	/* DebugDrawLine(this_mo.position, this_mo.position + normalize(char.position - this_mo.position) * (character_scale * 2.0) , vec3(1.0), _fade); */
	if(distance(char.position, this_mo.position) < (character_scale * 1.75)){
		vec3 direction = normalize(this_mo.velocity);
		int hit = char.WasHit("attackimpact", attack_path, direction, this_mo.position, this_mo.getID(), p_attack_damage_mult, p_attack_knockback_mult);
	}
}

void FinalAttachedItemUpdate(int num_frames) {
}

void HandleAnimationEvent(string event, vec3 world_pos){

}

void Flash(vec3 position){
	light.SetTranslation(position);
	flash_timer = 0.05;
	light.SetTint(vec3(0.5));
}

void Reset() {
	this_mo.rigged_object().anim_client().RemoveAllLayers();
	this_mo.DetachAllItems();
	this_mo.rigged_object().CleanBlood();
	this_mo.rigged_object().SetWet(0.0);
	this_mo.rigged_object().Extinguish();
	ClearTemporaryDecals();
	this_mo.rigged_object().ClearBoneConstraints();
}

bool Init(string character_path) {
	this_mo.char_path = character_path;
	bool success = character_getter.Load(this_mo.char_path);
	if(success){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 20.0f, 0);
	}
	return success;
}


void EnemyCheck(){
	if(target_id == -1){
		array<int> character_ids;
		GetCharactersInSphere(this_mo.position, activation_radius, character_ids);

		for(uint i = 0; i < character_ids.size(); i++){
			MovementObject@ char = ReadCharacterID(character_ids[i]);
			vec3 target_position = char.position;
			vec3 target_direction = normalize(target_position - drone_translation);

			DebugDrawLine(target_position, target_position + current_direction, vec3(1.0), _fade);
			DebugDrawLine(target_position, target_position + target_direction, vec3(1.0), _fade);

			if(character_ids[i] == this_mo.GetID()){
				continue;
			}


			if(!ObstructionCheck(character_ids[i]) && dot(current_direction, target_direction) > 0.75){
				//Check if the current target is closer.
				if(target_id != -1){
					MovementObject@ current_target_char = ReadCharacterID(target_id);
					if(distance(this_mo.position, current_target_char.position) < distance(this_mo.position, char.position)){
						continue;
					}
				}
				target_id = character_ids[i];
			}
		}
	}else{
		MovementObject@ char = ReadCharacterID(target_id);
		if(ObstructionCheck(target_id) || distance(drone_translation, char.position) > attack_radius){
			target_id = -1;
		}
	}
}

bool ObstructionCheck(int char_id){
	vec3 raycast_start = drone_translation + vec3(0.0, 0.25, 0.0);
	MovementObject@ char = ReadCharacterID(char_id);
	vec3 raycast_end = char.rigged_object().GetAvgIKChainPos("torso");
	col.GetObjRayCollision(raycast_start, raycast_end);

	/* DebugDrawLine(raycast_start, raycast_end, vec3(1.0), _fade); */

	if(sphere_col.NumContacts() == 0){
		return false;
	}else{
		return true;
	}
}

void UpdateAttacking(){

	if(target_id != -1){
		MovementObject@ char = ReadCharacterID(target_id);
		vec3 attack_target = char.position;
		movement_speed = attack_movement_speed;
		turn_speed = attack_turn_speed;

		MoveTowards(attack_target);

		if(attack_timer > 0.0){
			attack_timer -= time_step;
		}

		if(electric_timer > 0.0){
			electric_timer -= time_step;
		}

		float target_distance = distance(attack_target, drone_translation);
		if(target_distance < 2.5 && electric_timer <= 0.0){
			vec3 forward = drone_rotation * vec3(0.0, 0.0, 1.0);
			electric_timer = electric_interval;
			float max_offset = 0.2;
			for(int i = 0; i < 20; i++){
				vec3 random_offset = vec3(RangedRandomFloat(-max_offset, max_offset), RangedRandomFloat(-max_offset, max_offset), RangedRandomFloat(-max_offset, max_offset));
				MakeParticle("Data/Particles/drone_electric.xml", drone_translation + random_offset + (forward * 0.15), vec3(0.0));
			}

			Flash(drone_translation + (forward * 0.15));

			for(int i = 0; i < 3; i++){
				int sound_id = PlaySound("Data/Sounds/electric.wav", drone_translation);
				SetSoundPitch(sound_id, RangedRandomFloat(0.5, 1.0));
			}
		}

		if(attack_timer <= 0.0){
			array<int> character_ids;
			GetCharactersInSphere(drone_translation, attack_sphere_size, character_ids);
			attack_timer = attack_interval;

			int this_char_id_index = character_ids.find(this_mo.GetID());
			if(this_char_id_index != -1){
				character_ids.removeAt(this_char_id_index);
			}

			if(character_ids.size() > 0){
				velocity *= -1.0;
			}

			for(uint i = 0; i < character_ids.size(); i++){
				MovementObject@ victim = ReadCharacterID(character_ids[i]);
				vec3 force = current_direction * 5000.0f;
				vec3 hit_pos = drone_translation;
				victim.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
							 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
							 "HandleRagdollImpactImpulse(impulse, pos, 5.0f);");
			}
		}
	}
}

void UpdatePatrolling(){
	if(target_id == -1 && current_path_point_id != -1){

		Object@ path_point = ReadObjectFromID(current_path_point_id);
		movement_speed = patrol_movement_speed;
		turn_speed = patrol_turn_speed;

		MoveTowards(path_point.GetTranslation());

		//Go to the next pathpoint when close enough.
		if(distance(path_point.GetTranslation(), this_mo.position) < 0.2){
			int temp_waypoint_target_id = current_path_point_id;
			PathPointObject@ path_point_object = cast<PathPointObject>(path_point);
			int num_connections = path_point_object.NumConnectionIDs();

			if(num_connections != 0) {
				current_path_point_id = path_point_object.GetConnectionID(0);
			}

			for(int i = 0; i < num_connections; ++i) {
				if(path_point_object.GetConnectionID(i) != old_waypoint_target_id) {
					current_path_point_id = path_point_object.GetConnectionID(i);
					break;
				}
			}
			old_waypoint_target_id = temp_waypoint_target_id;
		}
	}
}

void MoveTowards(vec3 position){
	vec3 velocity_direction = normalize(velocity);
	vec3 target_direction = normalize(position - drone_translation);


	float dot_product = dot(velocity_direction, target_direction);
	vec3 direction;

	if(dot_product > 0.0){
		direction = reflect(velocity_direction * -1.0, target_direction);
	}else{
		direction = target_direction;
	}

	float adjusted_turn_speed = max(0.15, (1.0 - (length(velocity) / movement_speed)) * turn_speed);
	/* Log(warning, "turn speed " + turn_speed); */

	DebugDrawLine(this_mo.position, this_mo.position + target_direction, vec3(), _delete_on_draw);

	vec3 current_facing = this_mo.GetFacing();
	this_mo.SetRotationFromFacing(mix(current_facing, direction, time_step * 20.0));
	velocity += current_direction * movement_speed * time_step;

	col.GetSlidingScaledSphereCollision(drone_translation, collision_sphere_size, 1.0);

	/* DebugDrawWireSphere(drone_translation, collision_sphere_size, vec3(0.0f, 0.0f, 1.0f), _delete_on_update); */
	/* DebugDrawLine(drone_translation, drone_translation + current_direction, vec3(), _delete_on_draw); */

	if(sphere_col.NumContacts() > 0) {
		PlaySoundGroup("Data/Sounds/weapon_foley/impact/weapon_metal_hit_metal.xml", drone_translation, 0.25);
		MakeMetalSparks(sphere_col.GetContact(0).position);

		for(int j=0; j<sphere_col.NumContacts(); j++){
			const CollisionPoint contact = sphere_col.GetContact(j);
			velocity = reflect(velocity, contact.normal);
			vec3 offset = sphere_col.adjusted_position - sphere_col.position;
			this_mo.position = drone_translation + offset;
			colliding = true;
		}
	}else{
		colliding = false;
	}

	this_mo.velocity += velocity;
	velocity *= 0.98;
}

void ActiveCheck(){
	if(active_check_timer > 0.0){
		active_check_timer -= time_step;
		return;
	}else{
		active_check_timer = 1.0;
	}

	array<int> character_ids;
	GetCharactersInSphere(this_mo.position, activation_radius, character_ids);
	/* DebugDrawWireSphere(this_mo.position, activation_radius, vec3(0.0f, 0.0f, 1.0f), _fade); */

	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		Log(warning, "Found " + char.is_player);
		if(char.is_player){
			active = true;
			return;
		}
	}
	active = false;
}

void ApplyPhysics(const Timestep &in ts) {
	bool collision_below = false;
	for(int i = 0; i < sphere_col.NumContacts(); i++){
		if(sphere_col.GetContact(i).position.y < this_mo.position.y){
			collision_below = true;
			break;
		}
	}
	if(sphere_col.NumContacts() > 0 && collision_below){
		on_ground = true;
	}else{
		on_ground = false;
	}

	if(dead){
		this_mo.velocity += physics.gravity_vector * ts.step();
	}
}

void HandleCollisions(const Timestep &in ts) {
	HandleGroundCollisions(ts);
}

void HandleAirCollisions(const Timestep &in ts) {
	vec3 offset = this_mo.position - last_col_pos;
	this_mo.position = last_col_pos;
	bool landing = false;
	vec3 old_vel = this_mo.velocity;
	for(int i = 0; i < ts.frames(); ++i){ // Divide movement into multiple pieces to help prevent surface penetration
		if(on_ground) {
			break;
		}

		this_mo.position += offset/ts.frames();
		vec3 scale = vec3(1.0);
		float size = 0.25f;

		col.GetSlidingScaledSphereCollision(this_mo.position, size, scale);
		if(false){
			DebugDrawWireScaledSphere(this_mo.position, size, scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
		}

		vec3 closest_point;
		float closest_dist = -1.0f;
		for(int j=0; j<sphere_col.NumContacts(); j++){
			const CollisionPoint contact = sphere_col.GetContact(j);
			land_magnitude = length(this_mo.velocity);
			float bounciness = 0.3f;

			if(GetInputDown(this_mo.controller_id, "walk")){
				bounciness = 0.1;
			}

			if(contact.normal.y > _ground_normal_y_threshold ||
				(this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f) ||
				(contact.custom_normal.y >= 1.0 && contact.custom_normal.y < 4.0))
				{  // If collision with a surface that can be walked on, then land
					landing = true;
					//The charater is pushed back when colliding with the ground.
					if(length(this_mo.velocity) > 3.0f){
						this_mo.velocity = reflect(this_mo.velocity, contact.normal) * bounciness;
					}
				}
		}
	}
}

void HandleGroundCollisions(const Timestep &in ts) {
	vec3 offset= vec3(0.0, -0.0, 0.0);
	vec3 scale = vec3(1.0);
	float size = 0.25f;

	col.GetSlidingScaledSphereCollision(this_mo.position + offset, size, scale);

	bool _draw_collision_spheres = false;
	if(_draw_collision_spheres) {
		DebugDrawWireScaledSphere(sphere_col.adjusted_position, size, scale, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);
	}

	// the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
	this_mo.position = sphere_col.adjusted_position - offset;
}

bool HandleStandingCollision() {
	vec3 lower_pos = this_mo.position - vec3(0.0f, 0.05f, 0.0f);
	vec3 scale;
	float size;
	GetCollisionSphere(scale, size);
	col.GetSweptSphereCollision(this_mo.position, lower_pos, size);
	if(show_debug){
		DebugDrawWireSphere(this_mo.position, size, vec3(0.0f,0.0f,1.0f), _delete_on_update);
		DebugDrawWireSphere(lower_pos, size, vec3(0.0f,0.0f,1.0f), _delete_on_update);
	}
	return (sphere_col.position == lower_pos);
}

void GetCollisionSphere(vec3 &out scale, float &out size){
	scale = vec3(1.0f);
	size = character_scale;
}

int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
	attack_attacker.Load(attack_path);
	if(type == "attackimpact"){
		PlaySoundGroup("Data/Sounds/hit/hit_block.xml", pos, _sound_priority_high);
		return HitByAttack(dir, pos, attacker_id, attack_damage_mult, attack_knockback_mult);
	}
	return 2;
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
	Died();
	return 2;
}

int AboutToBeHitByItem(int id){
	return 1;
}

void Died(){
	if(dead){
		return;
	}

	dead = true;
	SetSoundGain(drone_sound_id, 0.0f);

	PlaySound("Data/Sounds/receiver_drone_arc.wav", this_mo.position);
	PlaySound("Data/Sounds/receiver_drone_hit.wav", this_mo.position);

	vec3 color(0.0f, 0.0f, 0.0);
	for(uint i = 0; i < 5; i++){
		vec3 direction = vec3(RangedRandomFloat(-1.0, 1.0), RangedRandomFloat(-1.0, 1.0), RangedRandomFloat(-1.0, 1.0));
		MakeParticle("Data/Particles/bloodcloud.xml", this_mo.position, direction, color);
	}
	string path;
	switch(rand()%3){
		case 0:
			path = "Data/Sounds/hit/hit_splatter_1.wav"; break;
		case 1:
			path = "Data/Sounds/hit/hit_splatter_2.wav"; break;
		default:
			path = "Data/Sounds/hit/hit_splatter_3.wav"; break;
	}
	PlaySound(path, this_mo.position);
	/* QueueDeleteObjectID(this_mo.GetID()); */
}

void HandleRagdollImpactImpulse(const vec3 &in impulse, const vec3 &in pos, float damage) {
	Died();
}

void HitByItem(string material, vec3 point, int id, int type) {
	Died();
}

void ImpactSound(float magnitude, vec3 position) {
	this_mo.MaterialEvent("bodyfall", position);
}

void ResetLayers() {

}

void Dispose() {
}

void DisplayMatrixUpdate(){
}

void MovementObjectDeleted(int id){
}

bool queue_fix_discontinuity = false;
void FixDiscontinuity() {
	queue_fix_discontinuity = true;
}

void PreDrawCameraNoCull(float curr_game_time) {
	if(queue_fix_discontinuity){
		this_mo.FixDiscontinuity();
		FinalAnimationMatrixUpdate(1);
		queue_fix_discontinuity = false;
	}
}

void FinalAnimationMatrixUpdate(int num_frames) {
	RiggedObject@ rigged_object = this_mo.rigged_object();
	BoneTransform local_to_world;

	vec3 location = this_mo.position + vec3(0.0, 0.5, 0.0);

	vec3 facing = this_mo.GetFacing();
	vec3 flat_facing = normalize(vec3(facing.x, 0.0f, facing.z));
	float target_rotation =  atan2(-flat_facing.x, flat_facing.z) / 3.1417f * 180.0f;
	float target_rotation2 =  asin(facing.y) / 3.1417f * 180.0f;

	quaternion rot = 	quaternion(vec4(0.0f, -1.0f, 0.0f, target_rotation  * 3.1417f / 180.0f)) *
						quaternion(vec4(-1.0f, 0.0f, 0.0f, target_rotation2 * 3.1417f / 180.0f));

	local_to_world.rotation = rot;
	local_to_world.origin = location;
	rigged_object.TransformAllFrameMats(local_to_world);
}

int IsUnaware() {
	return 0;
}

void ResetMind() {

}

int IsIdle() {
	if(goal == _patrol){
		return 1;
	} else {
		return 0;
	}
}

int IsAggressive() {
	return 1;
}

void Notice(int character_id){

}

void ResetSecondaryAnimation() {
	ear_rotation.resize(0);
	tail_points.resize(0);
	arm_points.resize(0);
	ear_points.resize(0);
	old_foot_offset.resize(0);
	old_foot_rotate.resize(0);
	weap_points.resize(0);
	old_hip_offset = vec3(0.0f);
}

float move_delay = 0.0f;
float repulsor_delay = 0.0f;

void MindReceiveMessage(string msg){
}
void ReceiveMessage(string msg){
}

bool IsAware(){
	return hostile;
}

int NeedsAnimFrames(){
	return 0;
}

int IsPassive() {
	return 0;
}

int IsOnLedge(){
	return 0;
}

int IsDodging(){
	return 0;
}

int IsAggro() {
	return 1;
}

int GetPlayerCharacterID() {
	int num = GetNumCharacters();
	for(int i=0; i<num; ++i){
		MovementObject@ char = ReadCharacter(i);
		if(char.controlled){
			return char.GetID();
		}
	}
	return -1;
}

void SetParameters() {
	params.AddIntCheckbox("Follow Player", true);
	targeted_jump = (params.GetInt("Follow Player") != 0);

	string team_str;
	character_getter.GetTeamString(team_str);
	params.AddString("Teams",team_str);

	params.AddFloatSlider("Character Scale",0.25,"min:0.25,max:2.0,step:0.02,text_mult:100");
	character_scale = params.GetFloat("Character Scale");
	if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 20.0f, 0);
		FixDiscontinuity();
	}
}

void MakeMetalSparks(vec3 pos){
	int num_sparks = rand()%20;
	for(int i=0; i<num_sparks; ++i){
		MakeParticle("Data/Particles/metalspark.xml",pos,vec3(RangedRandomFloat(-5.0f,5.0f),
														 RangedRandomFloat(-5.0f,5.0f),
														 RangedRandomFloat(-5.0f,5.0f)));

		MakeParticle("Data/Particles/metalflash.xml",pos,vec3(RangedRandomFloat(-5.0f,5.0f),
														 RangedRandomFloat(-5.0f,5.0f),
														 RangedRandomFloat(-5.0f,5.0f)));
	}
}

void NotifyItemDetach(int idex){}
void HandleEditorAttachment(int x, int y, bool mirror){}
void Contact(){}
void Collided(float x, float y, float z, float o, float p){}
void ScriptSwap(){}
void ForceApplied(vec3 force){}
float GetTempHealth(){return 1.0f;}
void AttachWeapon(int id){}
void SetEnabled(bool on){}
void UpdatePaused(){}
void LayerRemoved(int id){}
void PostReset(){}
