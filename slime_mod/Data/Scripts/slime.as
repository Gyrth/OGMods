#include "aschar_aux.as"
#include "situationawareness.as"

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
float p_attack_damage_mult;
float p_attack_knockback_mult;
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
const float _leg_sphere_size = 1.00f; // affects the size of a sphere collider used for leg collisions
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
const float _bumper_size = 0.5f;
const float _ground_normal_y_threshold = 0.5f;

bool balancing = false;
vec3 balance_pos;

bool show_debug = false;

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();
    ApplyPhysics(ts);
    HandleCollisions(ts);
    UpdateJumping();
}

float jump_wait = 0.0f;
bool allow_jumping = false;
void UpdateJumping(){
    if(on_ground && allow_jumping){
        jump_wait -= time_step;
        if(jump_wait < 0.0f){
            jump_wait = RangedRandomFloat(0.1f, 0.25f);
            float jump_mult = 5.0f;
            vec3 jump_vel;
            jump_vel.y = RangedRandomFloat(1.0f, 2.0f);
            jump_vel.x = RangedRandomFloat(-1.0f, 1.0f);
            jump_vel.z = RangedRandomFloat(-1.0f, 1.0f);
            this_mo.velocity += jump_vel * jump_mult;
            this_mo.SetRotationFromFacing(normalize(this_mo.velocity));
            Print("Jump\n");
        }
    }
}

void FinalAttachedItemUpdate(int num_frames) {
}

void HandleAnimationEvent(string event, vec3 world_pos){

}
void Reset() {
    this_mo.SetAnimation("Data/Animations/default.anm", 20.0f, _ANM_FROM_START);
}

void Init(string character_path) {
    this_mo.char_path = character_path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    this_mo.SetAnimation("Data/Animations/default.anm", 20.0f, 0);
}

void PostReset() {
}

void ApplyPhysics(const Timestep &in ts) {
    if(!on_ground){
        this_mo.velocity += physics.gravity_vector * ts.step();
    }
    bool feet_moving = false;
    float _walk_accel = 35.0f; // how fast characters accelerate when moving
    if(on_ground){
        if(!feet_moving){
            this_mo.velocity *= pow(0.95f,ts.frames());
        } else {
            const float e = 2.71828183f;
            if(max_speed == 0.0f){
                max_speed = true_max_speed;
            }
            float exp = _walk_accel*time_step*-1/max_speed;
            float current_movement_friction = pow(e,exp);
            this_mo.velocity *= pow(current_movement_friction, ts.frames());
        }
    }
}

void HandleCollisions(const Timestep &in ts) {
    vec3 initial_vel = this_mo.velocity;
    if(show_debug){
        DebugDrawWireSphere(this_mo.position,
                            _leg_sphere_size,
                            vec3(1.0f,1.0f,1.0f),
                            _delete_on_update);
    }
    if(on_ground){
        HandleGroundCollisions(ts);
    } else {
        HandleAirCollisions(ts);
    }
    last_col_pos = this_mo.position;
    // Flatten velocity against previous velocity
    if(dot(initial_vel, this_mo.velocity) < 0.0f){                              // If velocity is in opposite direction from old velocity,
        vec3 initial_dir = normalize(initial_vel);                              // flatten it against plane with normal of old velocity
        float wrong_dist = -dot(initial_dir, this_mo.velocity);
        this_mo.velocity += initial_dir * wrong_dist;
    }
    // Collisions should not increase speed
    if(length_squared(initial_vel) < length_squared(this_mo.velocity)){         // If speed is greater than before collision, set it to the
        this_mo.velocity = normalize(this_mo.velocity)*length(initial_vel);     // old speed
    }
}


void HandleGroundCollisions(const Timestep &in ts) {
    vec3 old_vel = this_mo.velocity;
    // Check if character has room to stand up
    float old_duck_amount = duck_amount;
    vec3 test_bumper_collision_response(0.0f, -10.0f, 0.0f);
    while(test_bumper_collision_response.y < -0.8f && duck_amount != 1.0f){
        vec3 offset;
        vec3 scale;
        float size;
        GetCollisionSphere(offset, scale, size);
        offset.y += 0.1f;
        if(scale.y > 1.0f){
            offset.y += size*(scale.y - 1.0f);
            scale.y = 1.0f;
        }
        col.GetSlidingScaledSphereCollision(this_mo.position+offset, size, scale);

        test_bumper_collision_response = normalize(sphere_col.adjusted_position - sphere_col.position);
        if(test_bumper_collision_response.y < -0.8f){
            duck_amount += 0.01f;
            duck_amount = min(1.0f, duck_amount);
        }
    }
    vec3 old_pos = this_mo.position;
    vec3 bumper_collision_response = HandleBumperCollision();
    if(normalize(bumper_collision_response).y < -0.8f){
        for(int i=0; i<10; ++i){
            col.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
            this_mo.position = sphere_col.adjusted_position;
            this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / ts.step();
            this_mo.velocity += bumper_collision_response / ts.step();
            bumper_collision_response = HandleBumperCollision();
        }
    }
    this_mo.position.y = min(old_pos.y, this_mo.position.y);
    bumper_collision_response.y = min(0.0, bumper_collision_response.y);
    this_mo.velocity += bumper_collision_response / ts.step(); // Push away from wall, and apply velocity change verlet style

    //Print("ground_normal " + ground_normal + "\n");

    bool in_air = HandleStandingCollision();
    if(in_air){
        on_ground = false;
    }else{
        this_mo.position = sphere_col.position;
    }

    for(int i=0; i<sphere_col.NumContacts(); i++){
        const CollisionPoint contact = sphere_col.GetContact(i);
        if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
            ground_normal = ground_normal * 0.9f +
                            contact.normal * 0.1f;
            ground_normal = normalize(ground_normal);
        }
    }
}

bool HandleStandingCollision() {
    vec3 upper_pos = this_mo.position+vec3(0,0.1f,0);
    vec3 lower_pos = this_mo.position+vec3(0,-0.2f,0);
    col.GetSweptSphereCollision(upper_pos,
                                 lower_pos,
                                 _leg_sphere_size);
    if(show_debug){
        DebugDrawWireSphere(upper_pos,_leg_sphere_size,vec3(0.0f,0.0f,1.0f),_delete_on_update);
        DebugDrawWireSphere(lower_pos,_leg_sphere_size,vec3(0.0f,0.0f,1.0f),_delete_on_update);
    }
    float balance_num = 0.0;
    balance_pos = vec3(0.0);
    for(int i=0, len=sphere_col.NumContacts(); i<len; ++i){
        CollisionPoint contact = sphere_col.GetContact(i);
        if(contact.custom_normal[1] >= 2.0 && contact.custom_normal[1] < 3.0){
            balance_pos += contact.position;
            balance_num += 1.0;
        }
    }
    balancing = false;
    if(balance_num > 0.0){
        balancing = true;
        balance_pos /= balance_num;
    }
    return (sphere_col.position == lower_pos);
}

void HandleAirCollisions(const Timestep &in ts) {
    vec3 initial_vel = this_mo.velocity;
    vec3 offset = this_mo.position - last_col_pos;
    this_mo.position = last_col_pos;
    bool landing = false;
    vec3 old_vel = this_mo.velocity;
    for(int i=0; i<ts.frames(); ++i){                                        // Divide movement into multiple pieces to help prevent surface penetration
        if(on_ground){
            break;
        }
        this_mo.position += offset/ts.frames();
        vec3 col_offset;
        vec3 col_scale;
        float size;
        GetCollisionSphere(col_offset, col_scale, size);
        col.GetSlidingScaledSphereCollision(this_mo.position+col_offset, _leg_sphere_size, col_scale);
        if(show_debug){
            DebugDrawWireScaledSphere(this_mo.position+col_offset, _leg_sphere_size, col_scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
        }

        vec3 closest_point;
        float closest_dist = -1.0f;
        for(int j=0; j<sphere_col.NumContacts(); j++){
            const CollisionPoint contact = sphere_col.GetContact(j);
            if(contact.normal.y > _ground_normal_y_threshold ||
                (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f) ||
                (contact.custom_normal.y >= 1.0 && contact.custom_normal.y < 4.0))
                {                                                               // If collision with a surface that can be walked on, then land
                    landing = true;
                }
        }
    }
    if(landing){
        Print("Land\n");
        on_ground = true;
    }
}

void GetCollisionSphere(vec3 &out offset, vec3 &out scale, float &out size){
    offset = vec3(0.0f,mix(0.3f,0.15f,duck_amount),0.0f);
    scale = vec3(1.0f,mix(1.4f,0.6f,duck_amount),1.0f);
    size = _bumper_size;
}

vec3 HandleBumperCollision(){
    vec3 offset;
    vec3 scale;
    float size;
    GetCollisionSphere(offset, scale, size);
    col.GetSlidingScaledSphereCollision(this_mo.position+offset, size, scale);
    if(show_debug){
        DebugDrawWireScaledSphere(this_mo.position+offset,size,scale,vec3(0.0f,1.0f,0.0f),_delete_on_update);
    }
    this_mo.position = sphere_col.adjusted_position-offset;
    return (sphere_col.adjusted_position - sphere_col.position);
}

void ImpactSound(float magnitude, vec3 position) {
    this_mo.MaterialEvent("bodyfall", position);
}

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

void ResetLayers() {

}

void Dispose() {
}

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
}

void DisplayMatrixUpdate(){
}

void MovementObjectDeleted(int id){
}

void FinalAnimationMatrixUpdate(int num_frames) {
    float scale = 0.5f;

    RiggedObject@ rigged_object = this_mo.rigged_object();
    BoneTransform local_to_world;
    vec3 offset = this_mo.position;
    offset.y -= _leg_sphere_size;
    vec3 facing = this_mo.GetFacing();
    float cur_rotation = atan2(facing.x, facing.z);
    quaternion rotation(vec4(0,1,0,cur_rotation));
    local_to_world.rotation = rotation;
    local_to_world.origin = offset;
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
    return 0;
}

void Notice(int character_id){

}

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

void SetParameters() {
}
