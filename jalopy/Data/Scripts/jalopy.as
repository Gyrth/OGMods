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
string target_animation = "Data/Animations/jalopy_default.anm";

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
float character_scale = 2.0f;
AttackScriptGetter attack_attacker;
float block_stunned = 1.0f;
int block_stunned_by_id = -1;

const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);

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

int character_id = -1;
bool has_camera_control = false;
float camera_shake = 0.0f;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;

float orig_sensitivity = -1.0f;
float aim_sensitivity = 0.1f;
bool aiming = false;
uint32 aim_particle;
float start_throwing_time = 0.0f;

float trigger_time_out = 0.0f;
float time_out_length = 0.25f;
float bullet_speed = 433.0f;
float max_bullet_distance = 1500.0f;
float cam_rotation_x = 0.0f;
float cam_rotation_y = 90.0f;
float cam_rotation_z = 0.0f;

void Update(int num_frames) {
	Timestep ts(time_step, num_frames);
	time += ts.step();

	RiggedObject@ rigged_object = this_mo.rigged_object();

	for(int i=0; i<num_frames; ++i){
		camera_shake *= 0.95f;
	}

	UpdateCamera(ts);
	ApplyPhysics(ts);
	HandleCollisions(ts);
	UpdateControls(ts);

	Skeleton@ skeleton = rigged_object.skeleton();
	int num_bones = skeleton.NumBones();

	bool draw_bones = false;

	if(draw_bones){
		for(int i = 0; i < num_bones; i++){
			int bone = i;
			if(skeleton.HasPhysics(i)){
				vec3 bone_pos = skeleton.GetBoneTransform(i).GetTranslationPart();
				quaternion bone_quat = QuaternionFromMat4(skeleton.GetBoneTransform(i));

				mat4 translate_mat;
				translate_mat.SetTranslationPart(bone_pos);
				mat4 rotation_mat;
				rotation_mat = Mat4FromQuaternion(bone_quat);
				mat4 mat = translate_mat * rotation_mat;

				DebugDrawLine(mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)),
							  mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1)),
							  vec4(1.0f), vec4(1.0f), _delete_on_draw);

			}
		}
	}
}

void UpdateControls(const Timestep &in ts){
	if(!this_mo.controlled || !on_ground){return;}

	vec3 facing = this_mo.GetFacing();
	vec3 up_direction = vec3(0.0f, 1.0f, 0.0f);
	vec3 right_direction = normalize(cross(facing, up_direction));
	float movement_speed = 25.0f;

	vec3 forward_velocity = facing * ((GetMoveYAxis(this_mo.controller_id) * -1.0f) + 0.0f) * ts.step() * movement_speed;
	vec3 sideways_velocity = right_direction * GetMoveXAxis(this_mo.controller_id) * ts.step() * movement_speed;

	vec3 added_velocity = forward_velocity + sideways_velocity;
	vec3 slerped_direction = mix(facing, normalize(added_velocity), time_step);
	this_mo.SetRotationFromFacing(slerped_direction);
	this_mo.velocity += added_velocity;
}

float cam_distance = 1.0f;

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

	cam_rotation_y -= GetLookXAxis(this_mo.controller_id);
	cam_rotation_x -= GetLookYAxis(this_mo.controller_id);

	cam_distance += GetInputPressed(this_mo.controller_id, "grab")?0.5f:0.0f;
	cam_distance -= GetInputPressed(this_mo.controller_id, "attack")?0.5f:0.0f;

	int bone = skeleton.IKBoneStart("pelvis");
	vec3 bone_pos = skeleton.GetBoneTransform(bone).GetTranslationPart();
	quaternion bone_quat = QuaternionFromMat4(skeleton.GetBoneTransform(bone));

	mat4 translate_mat;
	translate_mat.SetTranslationPart(bone_pos);
	mat4 rotation_mat;
	rotation_mat = Mat4FromQuaternion(bone_quat);
	mat4 mat = translate_mat * rotation_mat;

	DebugDrawLine(mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)),
				  mat * skeleton.GetBindMatrix(bone) * skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1)),
				  vec4(1.0f), vec4(1.0f), _delete_on_draw);

	vec3 cam_pos = this_mo.position + vec3(0.0f, 0.0f, 0.0f);

	camera.SetFOV(current_fov);
	camera.SetPos(cam_pos);
	camera.SetDistance(cam_distance);

	if(this_mo.focused_character) {
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
	}

	camera.SetInterpSteps(ts.frames());
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
		this_mo.SetAnimation(target_animation, 20.0f, 0);
		this_mo.SetScriptUpdatePeriod(1);
		this_mo.rigged_object().SetAnimUpdatePeriod(1);
		/* RiggedObject@ rigged_object = this_mo.rigged_object();
		Skeleton@ skeleton = rigged_object.skeleton();
		int num_bones = skeleton.NumBones();
		skeleton_bind_transforms.resize(num_bones);
		inv_skeleton_bind_transforms.resize(num_bones);

		for(int i = 0; i < num_bones; ++i) {
			skeleton_bind_transforms[i] = BoneTransform(skeleton.GetBindMatrix(i));
			inv_skeleton_bind_transforms[i] = invert(skeleton_bind_transforms[i]);
		} */
	}
	return success;
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

quaternion old_rotation;

void FinalAnimationMatrixUpdate(int num_frames) {
	RiggedObject@ rigged_object = this_mo.rigged_object();
	BoneTransform local_to_world;
	Object@ obj = ReadObjectFromID(this_mo.GetID());

	vec3 offset = this_mo.position;
	offset.y -= character_scale;

	vec3 facing = this_mo.GetFacing();
	DebugDrawLine(this_mo.position, this_mo.position + facing * 2.0f, vec3(1.0f), _delete_on_draw);
	vec3 up_direction = vec3(0.0f, 1.0f, 0.0f);
	vec3 right_direction = normalize(cross(facing, up_direction));
	/* vec3 facing = obj.GetRotation() * vec3(0.0f, 0.0f, 1.0f); */
	vec3 car_direction = normalize(cross(ground_normal, right_direction));

	vec3 new_rotation;
	new_rotation.y = atan2(car_direction.x, car_direction.z) * 180.0f / PI;
	new_rotation.x = asin(car_direction[1]) * -180.0f / PI;
	vec3 expected_right = normalize(cross(car_direction, vec3(0,1,0)));
	vec3 expected_up = normalize(cross(expected_right, car_direction));
	new_rotation.z = atan2(dot(up_direction, expected_right), dot(up_direction, expected_up)) * 180.0f / PI;

	quaternion rot_y(vec4(0, 1, 0, new_rotation.y * deg2rad));
	quaternion rot_x(vec4(1, 0, 0, new_rotation.x * deg2rad));
	quaternion rot_z(vec4(0, 0, 1, new_rotation.z * deg2rad));

	quaternion slerped_rotation = mix(old_rotation, rot_y * rot_x * rot_z, time_step * 5.0f);
	old_rotation = slerped_rotation;
	local_to_world.rotation = slerped_rotation;

	local_to_world.origin = offset;
	rigged_object.TransformAllFrameMats(local_to_world);
	vec3 flat_direction = car_direction;
	flat_direction.y = 0.0f;
	flat_direction = normalize(flat_direction);
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

	params.AddFloatSlider("Character Scale",1.0,"min:0.25,max:2.0,step:0.02,text_mult:100");
	character_scale = params.GetFloat("Character Scale");
	if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.SetAnimation(target_animation, 20.0f, 0);
		FixDiscontinuity();
	}
}

void ApplyPhysics(const Timestep &in ts) {
	if(!on_ground){
	}
	this_mo.velocity += physics.gravity_vector * ts.step();
	bool feet_moving = false;
	float _walk_accel = 35.0f; // how fast characters accelerate when moving
	if(on_ground){
		this_mo.velocity *= pow(0.95f,ts.frames());
	}else{
		/* this_mo.velocity *= pow(0.90f,ts.frames()); */
	}
}

void HandleCollisions(const Timestep &in ts) {
	vec3 scale;
	float size;
	GetCollisionSphere(scale, size);
	if(show_debug){
		DebugDrawWireSphere(this_mo.position, size, vec3(1.0f,1.0f,1.0f), _delete_on_update);
	}
	if(on_ground){
		HandleGroundCollisions(ts);
	} else {
		HandleAirCollisions(ts);
	}
}

void HandleGroundCollisions(const Timestep &in ts) {
	// Check if character has room to stand up
	vec3 old_pos = this_mo.position;
	vec3 scale;
	float size;
	GetCollisionSphere(scale, size);
	col.GetSlidingScaledSphereCollision(this_mo.position, size, scale);
	if(show_debug){
		DebugDrawWireScaledSphere(this_mo.position, size, scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
	}

	if(sphere_col.NumContacts() > 0){
		CollisionPoint point = sphere_col.GetContact(0);
		ground_normal = point.normal;
	}

	this_mo.position = sphere_col.adjusted_position;
	bool in_air = HandleStandingCollision();
	if(in_air){
		on_ground = false;
	}
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

void HandleAirCollisions(const Timestep &in ts) {
	vec3 offset = this_mo.position - last_col_pos;
	this_mo.position = last_col_pos;
	bool landing = false;
	vec3 old_vel = this_mo.velocity;
	for(int i=0; i<ts.frames(); ++i){ // Divide movement into multiple pieces to help prevent surface penetration
		if(on_ground){
			break;
		}
		this_mo.position += offset/ts.frames();
		vec3 scale;
		float size;
		GetCollisionSphere(scale, size);
		col.GetSlidingScaledSphereCollision(this_mo.position, size, scale);
		if(show_debug){
			DebugDrawWireScaledSphere(this_mo.position, size, scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
		}

		vec3 closest_point;
		float closest_dist = -1.0f;
		for(int j=0; j<sphere_col.NumContacts(); j++){
			const CollisionPoint contact = sphere_col.GetContact(j);
			land_magnitude = length(this_mo.velocity);
			float bounciness = 0.2f;
			if(contact.normal.y > _ground_normal_y_threshold ||
				(this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f) ||
				(contact.custom_normal.y >= 1.0 && contact.custom_normal.y < 4.0))
				{  // If collision with a surface that can be walked on, then land
					landing = true;
					PlaySoundGroup("Data/Sounds/weapon_foley/impact/weapon_drop_light_dirt.xml", this_mo.position, 1.0f);
					//The charater is pushed back when colliding with the ground.
					if(length(this_mo.velocity) > 3.0f){
						this_mo.velocity = reflect(this_mo.velocity, contact.normal) * bounciness;
					}
				}else{
					//A wall
					this_mo.velocity = reflect(this_mo.velocity, contact.normal);
				}
		}
	}
	if(landing){
		on_ground = true;
	}
}

void GetCollisionSphere(vec3 &out scale, float &out size){
	scale = vec3(1.0f);
	size = character_scale;
}

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){}
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
