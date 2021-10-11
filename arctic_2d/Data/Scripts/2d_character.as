#include "aschar_aux.as"
#include "situationawareness.as"
#include "interpdirection.as"

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
float mouse_sensitivity = 0.5;
string target_animation = "Data/Animations/r_idle.anm";

const float _ground_normal_y_threshold = 0.5f;
const float _leg_sphere_size = 0.45f;  // affects the size of a sphere collider used for leg collisions
const float _bumper_size = 0.5f;
vec3 old_vel;
float aiming_amount = 1.0;

class InvestigatePoint {
	vec3 pos;
	float seen_time;
};
array<InvestigatePoint> investigate_points;

const float kGetWeaponDelay = 0.4f;
float get_weapon_delay = kGetWeaponDelay;
const float kWalkSpeed = 0.2f;

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
float current_fov = 90.0f;
int rounds = 0;
float step_counter = 0.0f;

enum GunStates{
	MagazineOut,
	MagazineIn
}

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

int gun_state = MagazineOut;

int character_id = -1;
bool has_camera_control = false;
float camera_shake = 0.0f;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;

float orig_sensitivity = -1.0f;
float aim_sensitivity = 0.1f;
bool aiming = false;
int gun_aim_anim;
uint32 aim_particle;
float start_throwing_time = 0.0f;
array<Bullet@> bullets;

float trigger_time_out = 0.0f;
float time_out_length = 0.25f;
float bullet_speed = 433.0f;
float max_bullet_distance = 150.0f;
float cam_rotation_x = 0.0f;
float cam_rotation_y = 180.0f;
float cam_rotation_z = 0.0f;
bool running = true;
bool resetting = false;
Animation @current_animation = null;
vec3 last_cam_pos = vec3(0.0, 0.0, 0.0);
vec3 last_look_pos = vec3(0.0, 0.0, 0.0);
bool post_init_done = false;
vec3 last_char_pos = vec3(0.0, 0.0, 0.0);
const float WALK_THRESHOLD = 1.65;
const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);
vec3 old_target_velocity = vec3();
vec3 aim_direction = vec3(0.0, 0.0, 1.0);
float jump_wait = 0.1f;
bool flying_character = false;
float health = 1.0f;
float hurt_timer = 0.0f;

enum movement_states {idle, walk, jump, dead, hurt};
movement_states movement_state = idle;

class Animation {
	array<string> frame_paths = {};
	array<Object@> frame_objects = {};
	uint current_frame_index = 0;
	Object@ current_frame = null;
	float animation_framerate = 0.12f;
	float animation_timer = 0.0;

	Animation(array<string> new_frame_paths){
		/* Log(warning, "Initializing animation"); */
		frame_paths = new_frame_paths;
	}

	void Initialize(){
		for(uint i = 0; i < frame_paths.size(); i++){
			int frame_id = CreateObject(frame_paths[i], true);
			Object@ frame_obj = ReadObjectFromID(frame_id);
			frame_obj.SetEnabled(false);
			frame_obj.SetScale(vec3(character_scale));
			frame_objects.insertLast(frame_obj);
		}

		@current_frame = frame_objects[0];
		current_frame.SetEnabled(true);
	}

	void Reset(){
		/* Log(warning, "Resetting animation"); */

		for(uint i = 0; i < frame_objects.size(); i++){
			/* Log(warning, "Delete " + frame_objects[i].GetID()); */
			DeleteObjectID(frame_objects[i].GetID());
		}

		current_frame_index = 0;
		@current_frame = null;
		frame_objects.resize(0);
	}

	void Stop(){
		frame_objects[current_frame_index].SetEnabled(false);
	}

	void Start(){
		frame_objects[current_frame_index].SetEnabled(true);
	}

	void Update(){

		if(animation_timer >= animation_framerate){
			animation_timer = 0.0f;

			current_frame.SetEnabled(false);
			current_frame_index += 1;

			if(current_frame_index >= frame_objects.size()){
				current_frame_index = 0;
			}

			@current_frame = frame_objects[current_frame_index];
			current_frame.SetEnabled(true);
		}

		animation_timer += time_step;
	}
};

Animation @walk_animation;
Animation @idle_animation;
Animation @jump_animation;
Animation @dead_animation;
Animation @hurt_animation;

void Update(int num_frames) {
	/* DebugDrawWireSphere(this_mo.position, 0.25, vec3(1.0, 0.0, 0.0), _delete_on_update); */

	if(!post_init_done){
		SetAnimations();
		PostInit();
		@current_animation = @idle_animation;
	}

	Timestep ts(time_step, num_frames);
	time += ts.step();

	RiggedObject@ rigged_object = this_mo.rigged_object();

	for(int i=0; i<num_frames; ++i){
		camera_shake *= 0.95f;
	}

	if(movement_state != dead && this_mo.position.y < 0.0){
		ApplyDamage(1.0);
	}

	/* DebugDrawWireSphere(this_mo.position, 0.1, vec3(1.0), _fade); */

	ApplyPhysics(ts);
	HandleCollisions(ts);
	UpdateCamera(ts);
	UpdateState();

	if(knocked_out != _dead){
		UpdateControls();
		UpdateJumping();
		UpdateMovement();
	}

	UpdateFootsteps();
	UpdateSpritePosition();

	old_vel = this_mo.velocity;
	last_col_pos = this_mo.position;
	resetting = false;
}

void UpdateSpritePosition(){
	if(@current_animation != null){

		current_animation.Update();

		vec3 alive_position = this_mo.position + vec3(0.0, -abs(1.0 - character_scale) / 2.0, 0.0);
		vec3 dead_position = alive_position + vec3(0.0, -(character_scale / 2.0) + 0.1, 0.0);

		vec3 new_position = mix(last_char_pos, movement_state == dead?dead_position:alive_position, time_step * 20.0);
		current_animation.current_frame.SetTranslation(new_position);
		last_char_pos = new_position;

		/* vec3 target_velocity = GetTargetVelocity(); */
		vec3 new_aim_direction = GetTargetVelocity();
		if(new_aim_direction != vec3(0.0, 0.0, 0.0)){
			aim_direction = new_aim_direction;
		}

		vec3 target_velocity = this_mo.velocity;
		/* DebugDrawLine(this_mo.position, this_mo.position + target_velocity, vec3(1.0, 1.0, 1.0), _delete_on_draw); */

		if(target_velocity == vec3(0.0, 0.0, 0.0)){
			target_velocity = old_target_velocity;
		}

		float dot_value = dot(target_velocity, vec3(1.0, 0.0, 0.0));
		vec3 up = vec3(0.0, 1.0, 0.0);
		/* Log(warning, "dot " + dot_value); */
		if(dot_value > 0.0){
			target_velocity = vec3(0.0, 0.0, 1.0);
		}else{
			target_velocity = vec3(0.0, 0.0, -1.0);
		}

		if(movement_state == dead){
			target_velocity = vec3(0.0, 1.0, 0.0);
			up = vec3(0.0, 0.0, -1.0);
		}

		vec3 new_target_velocity = mix(old_target_velocity, target_velocity, time_step * 25.0);
		old_target_velocity = new_target_velocity;


		vec3 front = mix(new_target_velocity, vec3(-1.0, 0.0, 0.0), 1.0 - length(new_target_velocity));
		/* DebugDrawLine(this_mo.position, this_mo.position + front, vec3(1.0, 1.0, 1.0), _delete_on_draw); */

		vec3 new_rotation;
		new_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
		new_rotation.x = asin(front[1]) * -180.0f / PI;
		vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
		vec3 expected_up = normalize(cross(expected_right, front));
		new_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

		quaternion rot_y(vec4(0, 1, 0, new_rotation.y * deg2rad));
		quaternion rot_x(vec4(1, 0, 0, new_rotation.x * deg2rad));
		quaternion rot_z(vec4(0, 0, 1, new_rotation.z * deg2rad));
		current_animation.current_frame.SetRotation(rot_y * rot_x * rot_z);

	}else{
		Log(warning, "Problem");
	}
}

void UpdateState(){
	switch (movement_state) {
		case idle:
			UpdateIdle();
			break;
		case walk:
			UpdateWalk();
			break;
		case jump:
			UpdateJump();
			break;
		case dead:
			UpdateDead();
			break;
		case hurt:
			UpdateHurt();
			break;
	}
}

void UpdateHurt(){
	hurt_timer -= time_step;

	if(hurt_timer <= 0.0){
		movement_state = idle;
		SetAnimation(@idle_animation);
	}
}

void UpdateDead(){

}

void UpdateIdle(){
	if(length(this_mo.velocity) > WALK_THRESHOLD){
		movement_state = walk;
		SetAnimation(@walk_animation);
	}
}

void UpdateWalk(){
	float movement_speed = length(this_mo.velocity);
	float flat_movement_speed = (abs(this_mo.velocity.x + this_mo.velocity.z));

	if(movement_speed < WALK_THRESHOLD){
		movement_state = idle;
		SetAnimation(@idle_animation);
	}else if(!on_ground && !flying_character){
		movement_state = jump;
		SetAnimation(@jump_animation);
	}

	float speed = (1.0 - ((movement_speed - WALK_THRESHOLD) / 2.7));
	/* Log(warning, "speed " + movement_speed); */
	current_animation.animation_framerate = speed;
}

void SetAnimation(Animation@ new_animation){
	current_animation.Stop();
	@current_animation = @new_animation;
	current_animation.Start();
}

void UpdateJump(){
	if(on_ground && jump_wait <= 0.0){
		movement_state = idle;
		SetAnimation(idle_animation);
	}
}

void PostInit(){
	walk_animation.Initialize();
	idle_animation.Initialize();
	jump_animation.Initialize();
	dead_animation.Initialize();
	hurt_animation.Initialize();
	post_init_done = true;
}

float footstep_wait_timer = 0.0;

void UpdateFootsteps(){
	if(!on_ground || resetting){
		return;
	}

	if(footstep_wait_timer < 1.0f){
		footstep_wait_timer += time_step;
		return;
	}

	vec3 flat_current_position = this_mo.position;
	vec3 flat_last_position = last_col_pos;
	flat_current_position.y = 0.0;
	flat_last_position.y = 0.0;

	step_counter += distance(flat_current_position, flat_last_position);
	float step_threshold = 1.0f;
	if(step_counter > step_threshold){
		step_counter -= step_threshold;
		string path;
		switch(rand() % 5) {
			case 0:
				path = "Data/Sounds/footstep_concrete_000.wav"; break;
			case 1:
				path = "Data/Sounds/footstep_concrete_001.wav"; break;
			case 2:
				path = "Data/Sounds/footstep_concrete_002.wav"; break;
			case 3:
				path = "Data/Sounds/footstep_concrete_003.wav"; break;
			default:
				path = "Data/Sounds/footstep_concrete_004.wav"; break;
		}
		int id = PlaySound(path, this_mo.position + vec3(0.0, -1.0, 0.0));
		/* SetSoundGain(id, 0.5f); */
	}
}

float run_timer = 0.0f;

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

void UpdateCamera(const Timestep &in ts){
	if(!this_mo.controlled){
		return;
	}

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
	vec3 new_cam_position = this_mo.position + vec3(0.0, distance / 2.0, distance);
	vec3 new_look_position = this_mo.position;

	if(last_cam_pos == vec3(0.0, 0.0, 0.0)){
		last_cam_pos = new_cam_position;
		last_look_pos = new_look_position;
	}

	vec3 cam_pos = mix(last_cam_pos, new_cam_position, time_step * 15.0);
	vec3 look_pos = mix(last_look_pos, new_look_position, time_step * 15.0);
	last_cam_pos = cam_pos;
	last_look_pos = look_pos;

	camera.LookAt(look_pos);
	camera.CalcFacing();

	camera.SetFOV(current_fov);
	camera.SetPos(cam_pos);
	camera.SetDistance(0.5f);

	if(knocked_out == _dead){
		camera.SetDOF(0.15, 4.0, 1.0, 0.15, 5.0, 1.0);
	}else{
		camera.SetDOF(0.15, 4.0, 1.0, 0.15, 5.0, 1.0);
	}

	if(this_mo.focused_character) {
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
	}

	camera.SetInterpSteps(ts.frames());
}

void Shoot(){
	vec3 forward = aim_direction;
	vec3 muzzle_offset = forward * 0.15;
	vec3 spawn_point = this_mo.position + (aim_direction * 0.15);

	int smoke_particle_amount = 5;
	for(int i = 0; i < smoke_particle_amount; i++){
		vec3 smoke_velocity = forward + vec3(RangedRandomFloat(-0.25, 0.25), RangedRandomFloat(-0.25, 0.25), RangedRandomFloat(-0.25, 0.25)) * 2.0f;
		MakeParticle("Data/Particles/stepdust.xml", spawn_point + muzzle_offset, smoke_velocity);
	}

	int sound_id = PlaySound("Data/Sounds/footstep_snow_002.wav", spawn_point);
	SetSoundPitch(sound_id, RangedRandomFloat(0.9f, 1.2f));

	camera_shake += 0.25f;
	/* bullets.insertLast(Bullet(spawn_point, forward)); */
	/* DebugDrawWireSphere(spawn_point, 0.1, vec3(1.0), _fade); */
	level.SendMessage("add_bullet " + spawn_point.x + " " + spawn_point.y + " " + spawn_point.z + " " + forward.x + " " + forward.y + " " + forward.z);
}

void MakeMetalSparks(vec3 pos) {
	int num_sparks = rand() % 20;

	for(int i = 0; i < num_sparks; ++i) {
		MakeParticle("Data/Particles/metalspark.xml", pos, vec3(RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f)));

		MakeParticle("Data/Particles/metalflash.xml", pos, vec3(RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f)));
	}
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

void FinalAttachedItemUpdate(int num_frames) {
}

void HandleAnimationEvent(string event, vec3 world_pos){
}

void Reset() {
	this_mo.rigged_object().anim_client().RemoveAllLayers();
	this_mo.DetachAllItems();
	this_mo.rigged_object().CleanBlood();
	this_mo.rigged_object().SetWet(0.0);
	this_mo.rigged_object().Extinguish();
	ClearTemporaryDecals();
	this_mo.rigged_object().ClearBoneConstraints();
	this_mo.SetAnimation(target_animation, 20.0f, _ANM_FROM_START);
	SetGrabMouse(true);
	gun_state = MagazineOut;
	rounds = 0;
	last_col_pos = this_mo.position;
	step_counter = 0.0f;
	resetting = true;
	footstep_wait_timer = 0.0;
	walk_animation.Reset();
	idle_animation.Reset();
	jump_animation.Reset();
	dead_animation.Reset();
	hurt_animation.Reset();
}

bool Init(string character_path) {
	this_mo.char_path = character_path;
	bool success = character_getter.Load(this_mo.char_path);
	if(success){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 10.0f, _ANM_FROM_START);
		this_mo.SetScriptUpdatePeriod(1);
		/* this_mo.rigged_object().SetAnimUpdatePeriod(1); */
		CacheSkeletonInfo();
		return true;
	}else {
		Log(error, "Failed at loading character " + character_path);
		return false;
	}
}

int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
	attack_attacker.Load(attack_path);
	if(type == "attackimpact"){
		PlaySoundGroup("Data/Sounds/hit/hit_hard.xml", pos, _sound_priority_high);
		return HitByAttack(dir, pos, attacker_id, attack_damage_mult, attack_knockback_mult);
	}
	return 2;
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
	return 2;
}

int AboutToBeHitByItem(int id){
	return 1;
}

void HitByItem(string material, vec3 point, int id, int type) {

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

	vec3 location = vec3(0.0, 0.0, 0.0);
	/* vec3 location = this_mo.position; */

	vec3 facing = this_mo.GetFacing();
	vec3 flat_facing = normalize(vec3(facing.x, 0.0f, facing.z));
	float target_rotation =  atan2(-flat_facing.x, flat_facing.z) / 3.1417f * 180.0f;
	float target_rotation2 =  asin(facing.y) / 3.1417f * 180.0f;

	quaternion rot = 	quaternion(vec4(0.0f, -1.0f, 0.0f, target_rotation  * 3.1417f / 180.0f)) *
						quaternion(vec4(-1.0f, 0.0f, 0.0f, target_rotation2 * 3.1417f / 180.0f));

	/* local_to_world.rotation = rot; */
	local_to_world.origin = location + vec3(0.0, -0.25, 0.0);
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

void MindReceiveMessage(string msg){

}

void ReceiveMessage(string msg){
	/* Log(warning, msg); */
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
	string team_str;
	character_getter.GetTeamString(team_str);
	params.AddString("Teams",team_str);

	params.AddFloatSlider("Character Scale",0.5,"min:0.25,max:2.0,step:0.02,text_mult:100");
	character_scale = params.GetFloat("Character Scale");
	if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 20.0f, 0);
		FixDiscontinuity();
		CacheSkeletonInfo();
	}
}

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
	float distance_threshold = 0.3f;
	/* vec3 this_com = this_mo.rigged_object().skeleton().GetCenterOfMass();
	vec3 other_com = other.rigged_object().skeleton().GetCenterOfMass(); */

	vec3 this_com = this_mo.position;
	vec3 other_com = other.position;

	this_com.y = this_mo.position.y;
	other_com.y = other.position.y;
	if(distance(this_com, other_com) < distance_threshold){
		vec3 dir = other_com - this_com;
		float dist = length(dir);
		dir /= dist;
		dir *= distance_threshold - dist;
		vec3 other_push = dir * 0.5f / (time_step) * 0.15f;
		this_mo.velocity -= other_push;
		/* other.Execute("
		if(!static_char){
			push_velocity += vec3("+other_push.x+","+other_push.y+","+other_push.z+");
			MindReceiveMessage(\"collided "+this_mo.GetID()+"\");
		}"); */
	}
}


void ApplyPhysics(const Timestep &in ts) {
	bool collision_below = false;

	for(int i = 0; i < sphere_col.NumContacts(); i++){
		vec3 collision_point = sphere_col.GetContact(i).position;
		// False positives.
		if(collision_point == vec3(0.0, 0.0, 0.0)){
			continue;
		}

		if(collision_point.y < this_mo.position.y - 0.25){
			collision_below = true;
			/* DebugDrawWireSphere(this_mo.position, 0.25, vec3(), _fade); */
			/* DebugDrawLine(this_mo.position, sphere_col.GetContact(i).position, vec3(), _fade); */
			/* DebugDrawWireSphere(sphere_col.GetContact(i).position, 0.25, vec3(), _fade); */
			break;
		}
	}

	if(sphere_col.NumContacts() > 0 && collision_below){
		if(!on_ground){
			PlaySound("Data/Sounds/impactWood_medium_001.wav", this_mo.position + vec3(0.0, -1.0, 0.0));
		}
		on_ground = true;
	}else{
		on_ground = false;
	}

	if(!on_ground){
	}

	if(!flying_character || movement_state == dead){
		this_mo.velocity += physics.gravity_vector * ts.step();
	}

	bool feet_moving = false;
	float _walk_accel = 35.0f; // how fast characters accelerate when moving

	if(on_ground){
		this_mo.velocity *= pow(0.95f,ts.frames());
	}
}

void HandleCollisions(const Timestep &in ts) {
	HandleGroundCollisions(ts);
}

void HandleGroundCollisions(const Timestep &in ts) {
	vec3 offset= vec3(0.0, -0.0, 0.0);
	vec3 scale = vec3(1.0);
	float size = 0.5f;

	col.GetSlidingScaledSphereCollision(this_mo.position + offset, size, scale);

	bool _draw_collision_spheres = false;
	if(_draw_collision_spheres) {
		if(on_ground){
			DebugDrawWireScaledSphere(sphere_col.adjusted_position, size, scale, vec3(0.0f, 0.0f, 1.0f), _delete_on_update);
		}else{
			DebugDrawWireScaledSphere(sphere_col.adjusted_position, size, scale, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);
		}
	}

	// the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
	this_mo.position = sphere_col.adjusted_position - offset;
}

void HandleAirCollisions(const Timestep &in ts) {
	vec3 offset = this_mo.position - last_col_pos;
	this_mo.position = last_col_pos;
	bool landing = false;
	vec3 old_vel = this_mo.velocity;
	for(int i=0; i<ts.frames(); ++i){ // Divide movement into multiple pieces to help prevent surface penetration
		this_mo.position += offset/ts.frames();
		vec3 scale = vec3(1.0);
		float size = 0.75f;

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

void CacheSkeletonInfo() {
	Log(info, "Caching skeleton info");
	RiggedObject@ rigged_object = this_mo.rigged_object();
	Skeleton@ skeleton = rigged_object.skeleton();
	int num_bones = skeleton.NumBones();
	skeleton_bind_transforms.resize(num_bones);
	inv_skeleton_bind_transforms.resize(num_bones);
	for(int i = 0; i < num_bones; ++i) {
		skeleton_bind_transforms[i] = BoneTransform(skeleton.GetBindMatrix(i));
		inv_skeleton_bind_transforms[i] = invert(skeleton_bind_transforms[i]);
	}
}

void HandleRagdollImpactImpulse(const vec3 &in impulse, const vec3 &in pos, float damage) {
	this_mo.velocity += normalize(impulse) * 1.0;

	if(movement_state == dead){
		return;
	}

	ApplyDamage(damage);
}

void ApplyDamage(float damage){
	if(this_mo.is_player){
		return;
	}

	health -= damage;

	string path;
	switch(rand() % 5) {
		case 0:
			path = "Data/Sounds/impactPlate_light_000.wav"; break;
		case 1:
			path = "Data/Sounds/impactPlate_light_001.wav"; break;
		case 2:
			path = "Data/Sounds/impactPlate_light_002.wav"; break;
		case 3:
			path = "Data/Sounds/impactPlate_light_003.wav"; break;
		default:
			path = "Data/Sounds/impactPlate_light_004.wav"; break;
	}

	if(health <= 0.0){
		Died();
		switch(rand() % 5) {
			case 0:
				path = "Data/Sounds/impactPunch_medium_000.wav"; break;
			case 1:
				path = "Data/Sounds/impactPunch_medium_001.wav"; break;
			case 2:
				path = "Data/Sounds/impactPunch_medium_002.wav"; break;
			case 3:
				path = "Data/Sounds/impactPunch_medium_003.wav"; break;
			default:
				path = "Data/Sounds/impactPunch_medium_004.wav"; break;
		}
	}else{
		movement_state = hurt;
		SetAnimation(@hurt_animation);
		hurt_timer = 0.15f;
		UpdateSpritePosition();
	}

	if(this_mo.is_player){
		level.SendMessage("update_player_health " + health);
	}

	int id = PlaySound(path, this_mo.position);
}

void Died(){
	aiming_amount = 0.0;
	knocked_out = _dead;
	movement_state = dead;
	SetAnimation(dead_animation);
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
void PostReset(){
	last_char_pos = this_mo.position;
	CacheSkeletonInfo();
}
