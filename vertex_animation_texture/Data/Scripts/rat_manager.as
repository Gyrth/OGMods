#include "aschar_aux.as"
#include "situationawareness.as"
#include "interpdirection.as"

Situation situation;
int target_id = -1;
AttackScriptGetter attack_getter2;

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

const int _miss = 0;
const int _going_to_block = 1;
const int _hit = 2;
const int _block_impact = 3;
const int _invalid = 4;
const int _going_to_dodge = 5;

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

bool on_ground = true;
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
float duck_amount = 0.0f;
const float _bumper_size = 2.5f;
const float _ground_normal_y_threshold = 0.5f;

bool balancing = false;
vec3 balance_pos;

bool show_debug = true;
bool _draw_collision_spheres = false;
bool dialogue_control = false;
bool static_char = true;
int invisible_when_stationary = 0;
int species = 0;
enum Species {
    _rabbit = 0,
    _wolf = 1,
    _dog = 2,
    _rat = 3,
    _cat = 4
};
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

float blood_flash_time = 0.0;
const float kBloodFlashDuration = 0.2;

float hit_flash_time = 0.0;
float dark_hit_flash_time = 0.0;
const float kHitFlashDuration = 0.2;

float red_tint = 1.0;
float black_tint = 1.0;

float level_blackout = 0.0f;

float wiggle_wait = 0.0f;
float wave = 1.0f;
bool targeted_jump = false;

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){}

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
}

bool Init(string character_path) {
    this_mo.char_path = character_path;
    bool success = character_getter.Load(this_mo.char_path);
    if(success){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/r_combatidlethreat.anm", 20.0f, 0);
        this_mo.SetScriptUpdatePeriod(1);
    }
    return success;
}

void PostReset() {
}

void GetCollisionSphere(vec3 &out offset, vec3 &out scale, float &out size){
    offset = vec3(0.0f,0.0f,0.0f);
    scale = vec3(1.5f * character_scale, 1.4f, 1.5f * character_scale);
    size = 1.0;
}

int GetCharPrimaryWeapon(MovementObject@ mo){
    return mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
}

int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    if(attack_path == ""){
        return _invalid;
    }

    this_mo.rigged_object().anim_client().AddLayer("Data/Animations/r_painflinch.anm",8.0f,0);
    attack_getter2.Load(attack_path);

    if(type == "grabbed"){
        return _invalid;
    } else if(type == "attackblocked"){
        return _invalid;
    } else if(type == "blockprepare"){
        return _invalid;
    } else if(type == "attackimpact"){
        return _hit;
    } else {
        return _invalid;
    }
}

void HandleWeaponCuts(int attacker_id, vec3 pos, float attack_damage_mult, vec3 dir){}

void AddBloodToCutPlaneWeapon(int attacker_id, vec3 dir) {}

void AddBloodToStabWeapon(int attacker_id) {}

void LayerRemoved(int id) {}

void TakeSharpDamage(float sharp_damage, vec3 pos, int attacker_id, bool allow_heavy_cut) {}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    return _hit;
}

int AboutToBeHitByItem(int id){
    return 1;
}

void HitByItem(string material, vec3 point, int id, int type) {}

void ImpactSound(float magnitude, vec3 position) {}

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
        // FinalAnimationMatrixUpdate(1);
        queue_fix_discontinuity = false;
    }
}

void FinalAnimationMatrixUpdate(int num_frames) {

    for(uint i = 0; i < rats.size(); i++){
        rats[i].Draw();
    }

    vec3 offset2;
    vec3 scale;
    float size;
    GetCollisionSphere(offset2, scale, size);

    RiggedObject@ rigged_object = this_mo.rigged_object();
    BoneTransform local_to_world;
    vec3 offset = this_mo.position;
    offset.y -= size;
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

void ResetSecondaryAnimation(bool include_tail) {
    ear_rotation.resize(0);
    if(include_tail){
        tail_points.resize(0);
    }
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

array<Rat@> rats;
uint rat_amount = 0;

class Rat{

    float UPDATE_AABB_INTERVAL = 5.0;

    vec3 position;
    vec3 position_lerped;
    vec3 velocity;
    quaternion rotation = quaternion(0.0, 0.0, 0.0, 1.0);
    Object@ model;
    float update_aabb_timer = RangedRandomFloat(0.0, UPDATE_AABB_INTERVAL);
    vec3 movement_direction = vec3(1.0, 0.0, 0.0);
    vec3 nav_target;
    vec3 ground_normal(0.0, 1.0, 0.0);
    vec3 wall_normal(0.0, 1.0, 0.0);
    bool on_wall = false;

    vec3 last_col_pos;
    float flat_movement_velocity = 0.0f;
    float vertical_movement_velocity = 0.0f;
    float in_air_timer = 0.0f;
    bool deleted = false;

    Rat(){
        position = this_mo.position;
        position_lerped = position;
        Log(warning, "Add rat");

        int model_id = CreateObject("Data/objects/vat_mouse.xml");
        @model = ReadObjectFromID(model_id);
        model.SetTranslation(position);
        model.SetRotation(rotation);
        GetRandomNavTarget();
    }

    ~Rat(){
        deleted = true;
        // QueueDeleteObjectID(model.GetID());
    }

    void Update(const Timestep &in ts){
        if(deleted){return;}

        HandleGroundCollisions();
        ApplyPhysics(ts);
        ApplyControl();
        UpdateModelTransform(ts);
        
        last_col_pos = position;
    }

    void UpdateModelTransform(const Timestep &in ts){
        update_aabb_timer += time_step;

        vec3 flat_vel = vec3(velocity.x, 0, velocity.z);
        flat_vel = normalize(flat_vel);

        DebugDrawLine(position, position + flat_vel, vec3(1.0, 0.0, 0.0), _delete_on_update);

        float target_rotation = atan2(-flat_vel.z, flat_vel.x);
        target_rotation += 3.1417f * 0.5f;

        rotation = mix(rotation, quaternion(vec4(0.0, 1.0, 0.0, target_rotation)), ts.step() * 10.0);
        position_lerped = mix(position_lerped, position, ts.step() * 10.0);
        model.SetTranslationRotationFast(position_lerped, rotation);
        
        if(update_aabb_timer >= UPDATE_AABB_INTERVAL){
            model.SetRotation(rotation);
            model.SetTranslation(position);

            update_aabb_timer = 0.0f;
        }
    }

    void GetRandomNavTarget(){
        vec3 collision_check_position = this_mo.position;

        collision_check_position.x += RangedRandomFloat(-10.0f, 10.0f);
        collision_check_position.z += RangedRandomFloat(-10.0f, 10.0f);

        vec3 collision_position = col.GetRayCollision(collision_check_position + vec3(0.0f, 10.0f, 0.0f), collision_check_position + vec3(0.0f, -10.0f, 0.0f));
        nav_target = collision_position;
    }

    void Draw(){
        
    }

    void HandleGroundCollisions(){
        vec3 offset = vec3(0.0, 0.0, 0.0);
        vec3 scale = vec3(1.0);
        float size = 0.25f;

        // DebugDrawWireScaledSphere(position + offset, size, scale, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);

        col.GetSlidingScaledSphereCollision(position + offset, size, scale);
        position = sphere_col.adjusted_position - offset;
    }

    void ApplyPhysics(const Timestep &in ts) {
        bool collision_below = false;

        vec3 flat_current_position = position;
        vec3 flat_last_position = last_col_pos;
        vec3 last_normal = vec3(0.0f, 1.0f, 0.0f);
        vec3 last_wall_normal = vec3(0.0f, 0.0f, 0.0f);
        flat_current_position.y = 0.0;
        flat_last_position.y = 0.0;
        // The vertical and flat movement velocity is used later on to drive the animations and offset the camera.
        vertical_movement_velocity = (position.y - last_col_pos.y) / time_step;
        flat_movement_velocity = distance(flat_current_position, flat_last_position) / time_step;
        // Check every collision to see if the character is standing on the ground.
        for(int i = 0; i < sphere_col.NumContacts(); i++){
            vec3 collision_point = sphere_col.GetContact(i).position;
            if(collision_point == vec3(0.0, 0.0, 0.0)){
                continue;
            }
            // The dot product would be 1.0 if the collision was directly below the character.
            vec3 collision_direction = normalize(collision_point - position);
            float dot_product = dot(collision_direction, vec3(0.0, -1.0, 0.0));
            // But to allow some margin of error, a higher value than 0.9 should be enough.
            if(dot_product > 0.9){
                collision_below = true;
                last_normal = sphere_col.GetContact(i).normal;
                break;
            }else{
                wall_normal = sphere_col.GetContact(i).normal;
                on_wall = true;
            }
        }

        ground_normal = mix(ground_normal, last_normal, time_step * 20.0f);
        wall_normal = mix(wall_normal, last_wall_normal, time_step * 20.0f);

        if(collision_below){
            // When the character has found a collision below and was previously off the ground
            // then start landing. Keeping an air timer prevents small bumps from triggering a land.
            if(!on_ground && in_air_timer > 0.5){
                Land();
            }
            on_ground = true;
            on_wall = false;
            in_air_timer = 0.0f;
            // Reduce the velocity when standing on the ground, as if affected by friction.
            velocity *= pow(0.95f, ts.frames());

        }else{
            on_ground = false;
            if(length(wall_normal) > 0.1){on_wall = true;}
            in_air_timer += time_step;
            // Keep adding velocity in the gravity direction to speed up faling.
            velocity += physics.gravity_vector * ts.step();
        }

        position += velocity * time_step;
    }

    void Land(){
        // Create a landing sound effect at the feet of the character.
        vec3 sound_position = position + vec3(0.0f, -1.0f, 0.0);
        PlaySound("Data/Sounds/fps_gun_land.wav", sound_position);
        // DebugDrawWireSphere(position + vec3(0.0f, -1.0f, 0.0), 0.5, vec3(1.0), _fade);
    }

    void ApplyControl(){

        if(distance(position, nav_target) < 0.35){
            GetRandomNavTarget();
        }

        DebugDrawLine(position, position + ground_normal, vec3(0.0, 1.0, 0.0), _delete_on_update);
        DebugDrawLine(position, position + wall_normal, vec3(1.0, 1.0, 0.0), _delete_on_update);
        DebugDrawLine(position, nav_target, vec3(0.0, 0.0, 1.0), _delete_on_update);
        DebugDrawWireSphere(nav_target, 0.25, vec3(0.0, 0.0, 1.0), _delete_on_update);

        vec3 nav_target_direction = normalize(nav_target - position);
        movement_direction = mix(movement_direction, nav_target_direction, time_step * 15.0f);

        velocity += movement_direction * time_step * 50.0f;
    }

}


void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();
    this_mo.position = ReadObjectFromID(this_mo.GetID()).GetTranslation();

    for(uint i = 0; i < rats.size(); i++){
        rats[i].Update(ts);
    }

    if(rats.size() < rat_amount){
        rats.insertLast(Rat());
    }else if(rats.size() > rat_amount){
        rats.removeAt(rats.size() - 1);
    }
}

void SetParameters() {
    params.AddString("Teams","turner");

    params.AddIntSlider("Rat Amount", 100, "min:0,max:10");
    rat_amount = max(0, params.GetInt("Rat Amount"));

    params.AddFloatSlider("Character Scale",1,"min:0.6,max:1.4,step:0.02,text_mult:100");
    character_scale = params.GetFloat("Character Scale");
    if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/r_combatidlethreat.anm", 20.0f, 0);
        FixDiscontinuity();
    }
}