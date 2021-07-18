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
string target_animation = "Data/Animations/gun_default.anm";

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
float character_scale = 2.0f;
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
bool tick = false;

void Update(int num_frames) {
	Timestep ts(time_step, num_frames);
	time += ts.step();

	RiggedObject@ rigged_object = this_mo.rigged_object();

	for(int i=0; i<num_frames; ++i){
		camera_shake *= 0.95f;
	}

	/* DebugDrawWireSphere(this_mo.position, 0.1, vec3(1.0), _fade); */

	ApplyPhysics(ts);
	HandleCollisions(ts);
	UpdateCamera(ts);
	UpdateCharacterRotation();
	UpdateBullets();

	if(this_mo.controlled){
		UpdateControls();
		UpdateJumping();
		UpdateMovement();
		UpdateAiming();
	}

	old_vel = this_mo.velocity;
	last_col_pos = this_mo.position;
}

void UpdateAiming(){
	aiming_amount = mix(aiming_amount, GetInputDown(this_mo.controller_id, "grab")?1.0:0.0, time_step * 7.0);
}

void UpdateMovement(){
	float movement_speed = 25.0;
	if(!on_ground){
		movement_speed = 3.0;
	}
	this_mo.velocity += GetTargetVelocity() * time_step * movement_speed;
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

void UpdateCharacterRotation(){
	if(this_mo.controlled){
		vec3 down_direction = mix(camera.GetFacing(), (camera.GetUpVector() * -1.0), 0.85f);
		vec3 facing = mix(down_direction, camera.GetFacing(), max(0.5f, aiming_amount));
		vec3 current_facing = this_mo.GetFacing();
		this_mo.SetRotationFromFacing(mix(current_facing, facing, time_step * 20.0));
	}
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
	camera.SetYRotation(cam_rotation_y + y_shake);
	camera.SetXRotation(cam_rotation_x + x_shake);
	camera.SetZRotation(cam_rotation_z);
	camera.CalcFacing();

	int bone = skeleton.IKBoneStart("pelvis");
	vec3 bone_pos = skeleton.GetBoneTransform(bone).GetTranslationPart();
	quaternion bone_quat = QuaternionFromMat4(skeleton.GetBoneTransform(bone));

	mat4 translate_mat;
	translate_mat.SetTranslationPart(bone_pos);
	mat4 rotation_mat;
	rotation_mat = Mat4FromQuaternion(bone_quat);
	mat4 mat = translate_mat * rotation_mat;

	/* DebugDrawLine(mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)),
				  mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1)),
				  vec4(1.0f), vec4(1.0f), _delete_on_draw); */

	vec3 cam_pos = this_mo.position;

	camera.SetFOV(current_fov);
	camera.SetPos(cam_pos);
	camera.SetDistance(0.4f);

	if(this_mo.focused_character) {
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
	}

	camera.SetInterpSteps(ts.frames());
}

void UpdateControls(){

	cam_rotation_y -= GetLookXAxis(this_mo.controller_id) * mouse_sensitivity;
	cam_rotation_x -= GetLookYAxis(this_mo.controller_id) * mouse_sensitivity;
	cam_rotation_x = max(-70.0f, min(cam_rotation_x, 70.0f));

	if(GetInputPressed(this_mo.controller_id, "b")){
		this_mo.SetAnimation("Data/Animations/gun_animation.anm", 20.0f, _ANM_FROM_START);
	}else if(gun_state == MagazineIn && GetInputPressed(this_mo.controller_id, "attack")){
		this_mo.SetAnimation("Data/Animations/gun_shoot.anm", 20.0f, _ANM_FROM_START);
		Shoot();
	}else if(gun_state == MagazineOut && GetInputPressed(this_mo.controller_id, "r")){
		this_mo.SetAnimation("Data/Animations/gun_magazine_insert.anm", 20.0f, _ANM_FROM_START);
		gun_state = MagazineIn;
	}else if(gun_state == MagazineIn && GetInputPressed(this_mo.controller_id, "r")){
		this_mo.SetAnimation("Data/Animations/gun_magazine_remove.anm", 20.0f, _ANM_FROM_START);
		gun_state = MagazineOut;
	}
}

void UpdateBullets(){
	for(uint i = 0; i < bullets.size(); i++){

		Bullet@ bullet = bullets[i];

		vec3 start = bullet.starting_position;
		vec3 end = bullet.starting_position + (bullet.direction * bullet_speed * time_step);
		bool done = CheckBulletCollisions(start, end, bullet);
		/* DebugDrawLine(start, end, vec3(0.5), vec3(0.5), _fade); */
		bullet.SetStartingPoint(end);

		if(bullet.distance_done > max_bullet_distance || done){
			bullets.removeAt(i);
			return;
		}
	}
}

bool CheckBulletCollisions(vec3 start, vec3 &inout end, Bullet@ bullet){
	bool colliding = false;
	vec3 position = col.GetRayCollision(start, end);
	vec3 direction = normalize(end - start);

	/* DebugDrawWireSphere(start, 0.01, vec3(1.0), _fade);
	DebugDrawWireSphere(end, 0.01, vec3(1.0), _fade); */

	if(position != end){
		MakeMetalSparks(position);
		vec3 facing = camera.GetFacing();
		MakeParticle("Data/Particles/gun_decal.xml", position - facing, facing * 10.0f);
		string path;
		switch(rand() % 3) {
			case 0:
				path = "Data/Sounds/rico1.wav"; break;
			case 1:
				path = "Data/Sounds/rico2.wav"; break;
			default:
				path = "Data/Sounds/rico3.wav"; break;
		}
		PlaySound(path, position);
		colliding = true;
		end = position;
	}

	CollisionPoint point;

	col.CheckRayCollisionCharacters(start, end);
	int char_id = -1;
	if(sphere_col.NumContacts() != 0){
		point = sphere_col.GetContact(0);
		char_id = point.id;
	}

	if(char_id != -1 && char_id != this_mo.GetID()){
		MovementObject@ char = ReadCharacterID(char_id);
		char.rigged_object().Stab(sphere_col.GetContact(0).position, direction, 1, 0);
		vec3 force = direction * 30000.0f;
		vec3 hit_pos = vec3(0.0f);
		TimedSlowMotion(0.1f, 0.7f, 0.05f);
		float damage = 0.5;
		char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
					 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
					 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
		 colliding = true;
		 end = point.position;
	}

	return colliding;
}

void Shoot(){
	vec3 forward = this_mo.GetFacing();
	vec3 muzzle_offset = forward * 0.15;
	vec3 spawn_point = this_mo.position + vec3(0.0, -0.01, 0.0) + ((1.0 - aiming_amount) * (vec3(0.0, -0.25, 0.0)));

	int smoke_particle_amount = 5;
	vec3 smoke_velocity = forward * 5.0f;
	for(int i = 0; i < smoke_particle_amount; i++){
		MakeParticle("Data/Particles/gun_smoke.xml", spawn_point + muzzle_offset, smoke_velocity);
	}

	MakeParticle("Data/Particles/gun_fire.xml", spawn_point + muzzle_offset, forward * 5.0);

	int sound_id = PlaySound("Data/Sounds/Revolver.wav", spawn_point);
	SetSoundPitch(sound_id, RangedRandomFloat(0.9f, 1.2f));

	camera_shake += 0.25f;
	bullets.insertLast(Bullet(spawn_point, forward));
	/* DebugDrawWireSphere(spawn_point, 0.01, vec3(1.0), _fade); */
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
}

bool Init(string character_path) {
	this_mo.char_path = character_path;
	bool success = character_getter.Load(this_mo.char_path);
	if(success){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 10.0f, _ANM_FROM_START);
		this_mo.SetScriptUpdatePeriod(1);
		/* this_mo.rigged_object().SetAnimUpdatePeriod(1); */

		/* RiggedObject@ rigged_object = this_mo.rigged_object();
		Skeleton@ skeleton = rigged_object.skeleton();
		int num_bones = skeleton.NumBones();
		skeleton_bind_transforms.resize(num_bones);
		inv_skeleton_bind_transforms.resize(num_bones);

		for(int i = 0; i < num_bones; ++i) {
			skeleton_bind_transforms[i] = BoneTransform(skeleton.GetBindMatrix(i));
			inv_skeleton_bind_transforms[i] = invert(skeleton_bind_transforms[i]);
		} */
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
	/* RiggedObject@ rigged_object = this_mo.rigged_object();
	Skeleton@ skeleton = rigged_object.skeleton();

	int bone = skeleton.IKBoneStart("head");
	BoneTransform transform = BoneTransform(skeleton.GetBoneTransform(bone));
	vec3 start = transform * (skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)));
	vec3 end = transform * (skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1)));

	DebugDrawLine(start, end, vec3(1.0f), _delete_on_draw); */
}

void FinalAnimationMatrixUpdate(int num_frames) {
	RiggedObject@ rigged_object = this_mo.rigged_object();
	BoneTransform local_to_world;

	vec3 location = this_mo.position;

	vec3 facing = this_mo.GetFacing();
	vec3 flat_facing = normalize(vec3(facing.x, 0.0f, facing.z));
	float target_rotation =  atan2(-flat_facing.x, flat_facing.z) / 3.1417f * 180.0f;
	float target_rotation2 =  asin(facing.y) / 3.1417f * 180.0f;

	quaternion rot = 	quaternion(vec4(0.0f, -1.0f, 0.0f, target_rotation  * 3.1417f / 180.0f)) *
						quaternion(vec4(-1.0f, 0.0f, 0.0f, target_rotation2 * 3.1417f / 180.0f));

	local_to_world.rotation = rot;
	local_to_world.origin = location + vec3(0.0, -0.01, 0.0) + ((1.0 - aiming_amount) * (vec3(0.0, -0.25, 0.0)));
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

	params.AddFloatSlider("Long", 0.0, "min:0.0,max:1.0,step:0.01,text_mult:1");
	params.AddFloatSlider("Wide", 0.0, "min:0.0,max:1.0,step:0.01,text_mult:1");
	params.AddFloatSlider("Deep", 0.0, "min:0.0,max:1.0,step:0.01,text_mult:1");

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
		this_mo.velocity -= other_push;
		other.Execute("
		if(!static_char){
			push_velocity += vec3("+other_push.x+","+other_push.y+","+other_push.z+");
			MindReceiveMessage(\"collided "+this_mo.GetID()+"\");
		}");
	}
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

	if(!on_ground){
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
	/* if(on_ground){
	} else {
		HandleAirCollisions(ts);
	} */
}

void HandleGroundCollisions(const Timestep &in ts) {
	vec3 offset= vec3(0.0, -0.75, 0.0);
	vec3 scale = vec3(1.0);
	float size = 0.5f;

    col.GetSlidingScaledSphereCollision(this_mo.position + offset, size, scale);

	bool _draw_collision_spheres = false;
    if(_draw_collision_spheres) {
        DebugDrawWireScaledSphere(sphere_col.adjusted_position, size, scale, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);
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

float jump_wait = 0.1f;

void UpdateJumping(){
	if(jump_wait > 0.0f){
		jump_wait -= time_step;
	}

	if(on_ground && GetInputDown(this_mo.controller_id, "jump")){
		if(jump_wait < 0.0f){
			jump_wait = 0.5;
			float jump_mult = 5.0f;
			vec3 jump_vel = vec3(0.0, 1.0, 0.0);
			this_mo.velocity += jump_vel * jump_mult;
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

    ik_chain_elements.resize(0);
    ik_chain_bone_lengths.resize(0);
    ik_chain_start_index.resize(kNumIK);
    ik_chain_length.resize(kNumIK);

    for(int i = 0; i < kNumIK; ++i) {
        string bone_label;

        switch(i) {
            case kLeftArmIK: bone_label = "leftarm"; break;
            case kRightArmIK: bone_label = "rightarm"; break;
            case kLeftLegIK: bone_label = "left_leg"; break;
            case kRightLegIK: bone_label = "right_leg"; break;
            case kHeadIK: bone_label = "head"; break;
            case kLeftEarIK: bone_label = "leftear"; break;
            case kRightEarIK: bone_label = "rightear"; break;
            case kTorsoIK: bone_label = "torso"; break;
            case kTailIK: bone_label = "tail"; break;
        }

        int bone = skeleton.IKBoneStart(bone_label);
        ik_chain_length[i] = skeleton.IKBoneLength(bone_label);
        ik_chain_start_index[i] = ik_chain_elements.size();
        int count = 0;

        while(bone != -1 && count < ik_chain_length[i]) {
            ik_chain_bone_lengths.push_back(distance(skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)), skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1))));
            ik_chain_elements.push_back(bone);
            bone = skeleton.GetParent(bone);
            ++count;
        }
    }

    ik_chain_start_index.push_back(ik_chain_elements.size());
    bone_children.resize(0);
    bone_children_index.resize(num_bones);

    for(int bone = 0; bone < num_bones; ++bone) {
        bone_children_index[bone] = bone_children.size();

        for(int i = 0; i < num_bones; ++i) {
            int temp_bone = i;

            while(skeleton.GetParent(temp_bone) != -1 && skeleton.GetParent(temp_bone) != bone) {
                temp_bone = skeleton.GetParent(temp_bone);
            }

            if(skeleton.GetParent(temp_bone) == bone) {
                bone_children.push_back(i);
            }
        }
    }

    bone_children_index.push_back(bone_children.size());

    convex_hull_points.resize(0);
    convex_hull_points_index.resize(num_bones);

    for(int bone = 0; bone < num_bones; ++bone) {
        convex_hull_points_index[bone] = convex_hull_points.size();
        array<float> @hull_points = skeleton.GetConvexHullPoints(bone);

        for(int i = 0, len = hull_points.size(); i < len; i += 3) {
            convex_hull_points.push_back(vec3(hull_points[i], hull_points[i + 1], hull_points[i + 2]));
        }
    }

    convex_hull_points_index.push_back(convex_hull_points.size());

    key_masses.resize(kNumKeys);
    root_bone.resize(kNumKeys);

    for(int j = 0; j < 2; ++j) {
        int bone = skeleton.IKBoneStart(legs[j]);

        for(int i = 0, len = skeleton.IKBoneLength(legs[j]); i < len; ++i) {
            key_masses[kLeftLegKey + j] += skeleton.GetBoneMass(bone);

            if(i < len - 1) {
                bone = skeleton.GetParent(bone);
            }
        }

        root_bone[kLeftLegKey + j] = bone;
    }

    for(int j = 0; j < 2; ++j) {
        int bone = skeleton.IKBoneStart(arms[j]);

        for(int i = 0, len = skeleton.IKBoneLength(arms[j]); i < len; ++i) {
            key_masses[kLeftArmKey + j] += skeleton.GetBoneMass(bone);

            if(i < len - 1) {
                bone = skeleton.GetParent(bone);
            }
        }

        root_bone[kLeftArmKey + j] = bone;
    }

    {
        int bone = skeleton.IKBoneStart("torso");

        for(int i = 0, len = skeleton.IKBoneLength("torso"); i < len; ++i) {
            key_masses[kChestKey] += skeleton.GetBoneMass(bone);

            if(i < len - 1) {
                bone = skeleton.GetParent(bone);
            }
        }

        root_bone[kChestKey] = bone;
    }

    {
        int bone = skeleton.IKBoneStart("head");

        for(int i = 0, len = skeleton.IKBoneLength("head"); i < len; ++i) {
            key_masses[kHeadKey] += skeleton.GetBoneMass(bone);

            if(i < len - 1) {
                bone = skeleton.GetParent(bone);
            }
        }

        root_bone[kHeadKey] = bone;
    }
}

void HandleRagdollImpactImpulse(const vec3 &in impulse, const vec3 &in pos, float damage) {
	Log(warning, "damage " + damage);
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
	CacheSkeletonInfo();
}
