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
    rat_manager_id = this_mo.GetID();
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

void MovementObjectDeleted(int id){
}

void DisplayMatrixUpdate() {
}

void FinalAttachedItemUpdate(int num_frames){
    
}

void PreDrawCamera(float curr_game_time){
}

void FinalAnimationMatrixUpdate(int num_frames) {
    Timestep ts(time_step, max(1, num_frames));

    for(uint i = 0; i < rats.size(); i++){
        rats[i].SlowUpdate(ts);
    }

    RiggedObject@ rigged_object = this_mo.rigged_object();
    BoneTransform local_to_world;
    vec3 offset = this_mo.position;
    offset.y -= 100.0f;
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

enum RatAnimations{
    Idle,
    Walk,
    Run,
    Flail,
    Look,
    Attack,
    Jump
}

enum RatStates{
    Roam,
    Lookout,
    Follow,
    Charge,
    Strike,
    Attached
}

// Rat model released by AIUM2 under the CC Attribution License.

bool post_init = true;
array<Rat@> rats;
int rat_amount = 0;
int spawned_amount = 0;
int rat_manager_id = -1;
bool super_speed = false;
int update_frequency = 1;
bool push_character = false;
bool push_rat = false;
float max_random_nav = 15.0;
int rat_king_id = -1;
MovementObject@ rat_king;
bool follow_use_nav = false;
array<KilledCharacter@> killed_characters;
float last_attack_time = 0;

const float PI = 3.141592653589;

const int ATTACK_ANIMATION_START = 0;
const int ATTACK_ANIMATION_END = 24;
const float ATTACK_ANIMATION_SPEED = 1.0;

const int FLAIL_ANIMATION_START = 25;
const int FLAIL_ANIMATION_END = 49;
const float FLAIL_ANIMATION_SPEED = 1.0;

const int IDLE_ANIMATION_START = 50;
const int IDLE_ANIMATION_END = 74;
const float IDLE_ANIMATION_SPEED = 1.0;

const int JUMP_ANIMATION_START = 75;
const int JUMP_ANIMATION_END = 99;
const float JUMP_ANIMATION_SPEED = 1.0;

const int LOOK_ANIMATION_START = 100;
const int LOOK_ANIMATION_END = 124;
const float LOOK_ANIMATION_SPEED = 1.0;

const int RUN_ANIMATION_START = 125;
const int RUN_ANIMATION_END = 149;
const float RUN_ANIMATION_SPEED = 1.0;

const int WALK_ANIMATION_START = 150;
const int WALK_ANIMATION_END = 174;
const float WALK_ANIMATION_SPEED = 2.0;

const float IDLE_THRESHOLD = 0.08;
const float WALK_THRESHOLD = 3.0;
const float RUN_THRESHOLD = 3.1;

class Rat{

    bool ENABLE_SHADOW = true;

    vec3 offset = vec3(0.0, 0.0, 0.0);
    vec3 scale = vec3(1.0);
    float size = 0.125f;
    int id = -1;

    vec3 position;
    vec3 velocity;
    quaternion rotation = quaternion(0.0, 0.0, 0.0, 1.0);
    Object@ model;
    Object@ blob_model;
    vec3 movement_direction = vec3(1.0, 0.0, 0.0);
    vec3 nav_target_direction = vec3(1.0, 0.0, 0.0);
    vec3 ground_normal(0.0, 1.0, 0.0);
    vec3 wall_normal(0.0, 1.0, 0.0);
    bool on_wall = false;
    vec3 push_force = vec3(0.0, 0.0, 0.0);
    float movement_speed = 50.0f;
    float random_size;
    int aabb_counter = 0;

    vec3 last_col_pos;
    float flat_movement_velocity = 0.0f;
    float vertical_movement_velocity = 0.0f;
    float in_air_timer = 0.0f;
    bool deleted = false;
    int current_animation = Idle;
    int current_state = Follow;
    int attack_target = -1;
    float animation_progress;
    float random_tint_value;
    float lookout_timer;
    bool at_nav_target = false;
    vec3 follow_position;
    float random_noise_timer;
    int attached_bone = 0;
    float blood_amount = 0.0f;

    NavPath path;
    int current_path_point = 0;
    uint16 inclusive_flags = POLYFLAGS_ALL;
    uint16 exclusive_flags = POLYFLAGS_NONE;

    Rat(){
        position = this_mo.position;
        random_size = RangedRandomFloat(0.75, 1.25);
        size *= random_size;

        animation_progress = RangedRandomFloat(0.0, 1.0);
        random_tint_value = RangedRandomFloat(0.0, 1.0);
        lookout_timer = RangedRandomFloat(0.5, 5.0);
        random_noise_timer = RangedRandomFloat(0.0, 100.0);

        if(ENABLE_SHADOW){
            int blob_id = CreateObject("Data/Objects/Decals/blob_shadow.xml");
            @blob_model = ReadObjectFromID(blob_id);
            blob_model.SetTranslation(position);
            blob_model.SetTint(vec3(0.1, 0.1, 0.1));
            blob_model.SetScale(vec3(size * 5.0 * random_size));
        }

        int model_id = CreateObject("Data/objects/vat_mouse.xml");
        @model = ReadObjectFromID(model_id);
        model.SetTranslation(position);
        model.SetRotation(rotation);
        model.SetScale(vec3(0.5 * random_size));
        GetRandomNavTarget();
    }

    ~Rat(){
        deleted = true;
        QueueDeleteObjectID(model.GetID());
        QueueDeleteObjectID(blob_model.GetID());
    }

    void Update(const Timestep &in ts){
        if(deleted){return;}

        HandleGroundCollisions();
        ApplyPhysics(ts);

        if(!super_speed){
            UpdateModelTransform(ts);
            UpdateAnimations(ts);
            UpdateStates(ts);
        }

        last_col_pos = position;
    }

    void SlowUpdate(const Timestep &in ts){
        if(deleted){return;}

        if(super_speed){
            UpdateModelTransform(ts);
            UpdateAnimations(ts);
            UpdateStates(ts);
        }
    }

    void UpdateStates(const Timestep &in ts){

        switch(current_state){
            case Roam:
                UpdateRoaming(ts);
                break;
            case Lookout:
                UpdateLookout(ts);
                break;
            case Follow:
                UpdateFollowing(ts);
                break;
            case Charge:
                UpdateCharging(ts);
                break;
            case Strike:
                UpdateStriking(ts);
                break;
            case Attached:
                UpdateAttached(ts);
                break;
        }
    }

    float attached_timer = 0.0f;
    float check_killed_timer = 0.0f;

    void UpdateAttached(const Timestep &in ts){
        attached_timer -= ts.step();

        MovementObject@ victim = ReadCharacterID(attack_target);
        Skeleton @skeleton = victim.rigged_object().skeleton();

        vec3 target_pos = skeleton.GetBoneTransform(attached_bone).GetTranslationPart();

        if(target_alive_before && check_killed_timer < 1.0f){
            check_killed_timer += ts.step();

            bool target_alive_after = victim.GetIntVar("knocked_out") == _awake;

            if(!target_alive_after){
                AddKilledCharacter(victim.GetID());
            }
        }

        velocity *= pow(0.95f, ts.frames());
        position += velocity * ts.step();
        position = mix(position, target_pos, time_step * 50.0);
        
        if(attached_timer <= 0.0){
            current_state = Follow;
            current_animation = Idle;
        }
    }

    float strike_timer = 0.0f;
    bool target_alive_before = false;

    void UpdateStriking(const Timestep &in ts){

        strike_timer += ts.step();

        MovementObject@ target = ReadCharacterID(attack_target);
        // DebugDrawLine(position, target.position, vec3(0.0, 1.0, 0.0), _delete_on_update);

        vec3 velocity_direction = normalize(velocity);
        col.CheckRayCollisionCharacters(position, position + (velocity_direction * 0.25f));

        for(int i = 0; i < sphere_col.NumContacts(); i++){
            CollisionPoint contact = sphere_col.GetContact(i);

            MovementObject@ victim = ReadCharacterID(contact.id);
            target_alive_before = victim.GetIntVar("knocked_out") == _awake;
            check_killed_timer = 0.0f;
            victim.rigged_object().Stab(contact.position, velocity_direction, 2, 0);

            velocity *= 0.1;
            current_state = Attached;
            current_animation = Attack;
            attached_timer = RangedRandomFloat(1.5, 2.5);
            blood_amount = min(0.482352941, blood_amount + RangedRandomFloat(0.05, 0.1));

            vec3 force = velocity_direction * 1800.0f;
            vec3 hit_pos = contact.position;
            int sound_id = PlaySoundGroup("Data/Sounds/weapon_foley/cut/flesh_hit.xml", hit_pos, _sound_priority_med);
            SetSoundPitch(sound_id, RangedRandomFloat(0.9, 1.2));

            victim.Execute( "vec3 impulse = vec3(" + force.x + ", " + force.y + ", " + force.z + ");" +
                            "vec3 pos = vec3(" + hit_pos.x + ", " + hit_pos.y + ", " + hit_pos.z + ");" +
                            "HandleRagdollImpactImpulse(impulse, pos, 0.0f);" +
                            "TakeDamage(0.03);");
            
            return;
        }

        if(strike_timer > 0.5 || (strike_timer > 0.15 && on_ground)){
            current_state = Follow;
            current_animation = Idle;
        }

        movement_direction = vec3(0.0);
    }

    void UpdateCharging(const Timestep &in ts){
        RandomNoise(ts);
        movement_speed = 75.0f;
        float interpolate_speed = 50.0;

        MovementObject@ target = ReadCharacterID(attack_target);

        if(target.GetIntVar("knocked_out") != _awake){
            current_state = Follow;
            return;
        }

        if(on_ground){
            vec3 target_position;

            if(follow_use_nav){
                GetNavPath(target.position);
                vec3 nav_target = GetNextPathPoint();
                target_position = vec3(nav_target.x, position.y, nav_target.z);
            }else{
                target_position = vec3(target.position.x, position.y, target.position.z);
            }

            float dist = xz_distance(target_position, position);
            nav_target_direction = normalize(target_position - position) * min(1.0, dist);

            // DebugDrawLine(position, nav_target, vec3(1.0, 0.0, 0.0), _delete_on_update);
            movement_direction = mix(movement_direction, nav_target_direction, ts.step() * interpolate_speed);

            if(xz_distance(target.position, position) < 2.0 * random_size){
                current_state = Strike;

                Skeleton @skeleton = target.rigged_object().skeleton();

                while(true){
                    int rand_bone = rand() % skeleton.NumBones();

                    if(skeleton.HasPhysics(rand_bone)) {
                        attached_bone = rand_bone;
                        break;
                    }
                }

                vec3 target_pos = skeleton.GetBoneTransform(attached_bone).GetTranslationPart();
                target_pos += target.velocity * 0.1;

                vec3 target_dir = normalize(target_pos - position);
                current_animation = Jump;
                velocity = target_dir * 10.0f;
                int sound_id = PlaySoundGroup("Data/Sounds/voice/animal3/voice_rat_attack.xml", position, _sound_priority_med);
                SetSoundPitch(sound_id, RangedRandomFloat(0.9, 1.2));
                SetSoundGain(sound_id, 0.75);
                strike_timer = 0.0f;
            }
        }
    }

    void RandomNoise(const Timestep &in ts){
        random_noise_timer -= ts.step();

        if(random_noise_timer <= 0.0){
            int sound_id = PlaySoundGroup("Data/Sounds/voice/animal3/voice_rat_idle.xml", position, _sound_priority_low);
            SetSoundPitch(sound_id, RangedRandomFloat(0.9, 1.2));
            random_noise_timer = RangedRandomFloat(50.0f, 100.0f);
        }
    }

    void UpdateRoaming(const Timestep &in ts){
        RandomNoise(ts);
        vec3 nav_target = GetNextPathPoint();
        movement_speed = 50.0f;
        float interpolate_speed = 50.0;

        if(on_ground){

            // DebugDrawLine(position, nav_target, vec3(1.0, 0.0, 0.0), _delete_on_update);
            float dist = xz_distance(nav_target, position);
            nav_target_direction = normalize(nav_target - position) * min(1.0, dist);
            movement_direction = mix(movement_direction, nav_target_direction, ts.step() * interpolate_speed);
        }

        if(at_nav_target){
            if(rand() % 30 == 0){
                current_state = Lookout;
                current_animation = Look;
                lookout_timer = RangedRandomFloat(0.5, 5.0);
            }else{
                GetRandomNavTarget();
            }
        }
    }

    void UpdateFollowing(const Timestep &in ts){
        RandomNoise(ts);
        movement_speed = 75.0f;
        float interpolate_speed = 50.0;

        LookWhenIdle(ts);

        if(on_ground){
            vec3 target_position;

            if(follow_use_nav){
                GetNavPath(follow_position);
                vec3 nav_target = GetNextPathPoint();
                target_position = vec3(nav_target.x, position.y, nav_target.z);
            }else{
                target_position = vec3(follow_position.x, position.y, follow_position.z);
            }

            // DebugDrawLine(position, target_position, vec3(1.0), _delete_on_update);
            float dist = length(target_position - position);
            nav_target_direction = normalize(target_position - position) * min(1.0, dist);

            if(on_wall){
                nav_target_direction = mix(nav_target_direction, vec3(0.0, 1.0, 0.0), 0.98f);
            }

            movement_direction = mix(movement_direction, nav_target_direction, ts.step() * interpolate_speed);
            // DebugDrawLine(position, position + movement_direction, vec3(1.0, 0.0, 0.0), _delete_on_update);
        }
    }

    void LookWhenIdle(const Timestep &in ts){
        if(current_animation == Idle){
            lookout_timer -= ts.step();
            
            if(lookout_timer <= 0.0){
                lookout_timer = RangedRandomFloat(0.5, 5.0);

                if(rand() % 60 == 0){
                    current_animation = Look;
                }
            }
        }else if(current_animation == Look){
            float velocity_length = length(velocity);
            lookout_timer -= ts.step();

            if(velocity_length > IDLE_THRESHOLD || lookout_timer <= 0.0){
                current_animation = Walk;
            }
        }
    }

    void UpdateLookout(const Timestep &in ts){
        lookout_timer -= time_step;

        if(lookout_timer <= 0.0){
            current_state = Roam;
            current_animation = Idle;
        }

        movement_direction = vec3(0.0);
    }

    void UpdateAnimations(const Timestep &in ts){

        switch(current_animation){
            case Idle:
                UpdateIdleAnimation(ts);
                break;
            case Walk:
                UpdateWalkAnimation(ts);
                break;
            case Run:
                UpdateRunAnimation(ts);
                break;
            case Flail:
                UpdateFlailAnimation(ts);
                break;
            case Look:
                UpdateLookAnimation(ts);
                break;
            case Attack:
                UpdateAttackAnimation(ts);
                break;
            case Jump:
                UpdateJumpingAnimation(ts);
                break;
        }
    }

    void UpdateJumpingAnimation(const Timestep &in ts){
        animation_progress += ts.step() * JUMP_ANIMATION_SPEED;

        if(animation_progress > 1.0){
            animation_progress -= 1.0;
        }

        float current_frame = mix(JUMP_ANIMATION_START, JUMP_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }

    void UpdateAttackAnimation(const Timestep &in ts){
        animation_progress += ts.step() * ATTACK_ANIMATION_SPEED;

        if(animation_progress > 1.0){

            if(id % max(1, (rats.size() / 50)) == 0){
                int sound_id = PlaySoundGroup("Data/Sounds/voice/animal3/voice_rat_attack.xml", position, _sound_priority_low);
                SetSoundGain(sound_id, 0.2);
                SetSoundPitch(sound_id, RangedRandomFloat(1.75, 2.0));

            }

            MakeParticle("Data/Particles/bloodcloud.xml", position, normalize(velocity) * 2.0, GetBloodTint());

            animation_progress -= 1.0;
        }

        float current_frame = mix(ATTACK_ANIMATION_START, ATTACK_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }


    void UpdateWalkAnimation(const Timestep &in ts){
        float velocity_length = length(velocity);
        animation_progress += ts.step() * velocity_length * WALK_ANIMATION_SPEED;

        if(velocity_length < IDLE_THRESHOLD){
            current_animation = Idle;
        }else if(velocity_length > RUN_THRESHOLD){
            current_animation = Run;
        }

        if(animation_progress > 1.0){

            if(id % max(1, (rats.size() / 50)) == 0){
                int sound_id = PlaySoundGroup("Data/Sounds/hit/hit_block.xml", position, _sound_priority_low);
                SetSoundGain(sound_id, 0.022);
                SetSoundPitch(sound_id, RangedRandomFloat(1.75, 2.0));
            }

            animation_progress -= 1.0;
        }

        float current_frame = mix(WALK_ANIMATION_START, WALK_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }

    void UpdateLookAnimation(const Timestep &in ts){
        animation_progress += ts.step() * LOOK_ANIMATION_SPEED;

        if(animation_progress > 1.0){
            animation_progress -= 1.0;
        }

        float current_frame = mix(LOOK_ANIMATION_START, LOOK_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }

    void UpdateFlailAnimation(const Timestep &in ts){
        float velocity_length = abs(vertical_movement_velocity);
        animation_progress += ts.step() * velocity_length * FLAIL_ANIMATION_SPEED;

        if(animation_progress > 1.0){
            animation_progress -= 1.0;
        }

        if(on_ground){
            current_animation = Idle;
        }

        float current_frame = mix(FLAIL_ANIMATION_START, FLAIL_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }
    
    void UpdateRunAnimation(const Timestep &in ts){

        float velocity_length = length(velocity);
        animation_progress += ts.step() * velocity_length * RUN_ANIMATION_SPEED;

        if(velocity_length < RUN_THRESHOLD){
            current_animation = Walk;
        }

        if(animation_progress > 1.0){

            if(id % max(1, (rats.size() / 50)) == 0){
                int sound_id = PlaySoundGroup("Data/Sounds/hit/hit_block.xml", position, _sound_priority_low);
                SetSoundGain(sound_id, 0.02);
                SetSoundPitch(sound_id, RangedRandomFloat(1.75, 2.0));
            }

            animation_progress -= 1.0;
        }

        float current_frame = mix(RUN_ANIMATION_START, RUN_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }

    void UpdateIdleAnimation(const Timestep &in ts){

        float velocity_length = length(velocity);
        animation_progress += ts.step() * IDLE_ANIMATION_SPEED;

        if(velocity_length > IDLE_THRESHOLD){
            current_animation = Walk;
        }

        if(animation_progress > 1.0){
            animation_progress -= 1.0;
        }

        float current_frame = mix(IDLE_ANIMATION_START, IDLE_ANIMATION_END, animation_progress);
        model.SetTint(vec3(random_tint_value, current_frame / 1000.0, blood_amount));
    }

    void UpdateModelTransform(const Timestep &in ts){

        vec3 flat_vel = vec3(velocity.x, 0, velocity.z);

        // DebugDrawLine(position, position + flat_vel, vec3(1.0, 0.0, 0.0), _delete_on_update);

        if(length(flat_vel) > IDLE_THRESHOLD){
            flat_vel = normalize(flat_vel);
            float target_rotation = atan2(-flat_vel.z, flat_vel.x);
            target_rotation += 3.1417f * 0.5f;

            rotation = mix(rotation, quaternion(vec4(ground_normal, target_rotation)), ts.step() * 5.0);
        }

        if(aabb_counter % max(1, (rats.size() / 50)) == 0){
            aabb_counter = 1;

            model.SetRotation(rotation);
            model.SetTranslation(position);
        }else{
            model.SetTranslationRotationFast(position, rotation);
            aabb_counter += 1;

            if(ENABLE_SHADOW){
                blob_model.SetTranslation(position);
            }
        }
    }

    void GetRandomNavTarget(){
        vec3 collision_check_position = this_mo.position;

        collision_check_position.x += RangedRandomFloat(-max_random_nav, max_random_nav);
        collision_check_position.z += RangedRandomFloat(-max_random_nav, max_random_nav);

        vec3 collision_position = col.GetRayCollision(collision_check_position + vec3(0.0f, max_random_nav, 0.0f), collision_check_position + vec3(0.0f, -max_random_nav, 0.0f));
        
        GetNavPath(collision_position);
    }

    void GetNavPath(vec3 target_pos){
        vec3 nav_from = GetNavPointPos(position);
        vec3 nav_to = GetNavPointPos(target_pos);

        at_nav_target = false;

        path = GetPath(nav_from,
                        nav_to,
                        inclusive_flags,
                        exclusive_flags);
        
        current_path_point = 0;

        // int num_points = path.NumPoints();

        // for(int i = 0; i < num_points - 1; i++) {
        //     DebugDrawLine(path.GetPoint(i),
        //                   path.GetPoint(i + 1),
        //                   vec3(1.0f, 1.0f, 1.0f),
        //                   _delete_on_update);
        // }
    }

    vec3 GetNextPathPoint(){
        int num_points = path.NumPoints();

        if(num_points == current_path_point){
            at_nav_target = true;
            return position;
        }

        vec3 next_point;

        while(current_path_point < num_points){
            next_point = path.GetPoint(current_path_point);

            if(xz_distance_squared(position, next_point) < 1.0f){
                current_path_point += 1;
            }else{
                break;
            }
        }

        return next_point;
    }

    void HandleGroundCollisions(){
        // DebugDrawWireScaledSphere(position + offset, size, scale, vec3(0.0f, 1.0f, 0.0f), _delete_on_update);

        col.GetSlidingScaledSphereCollision(position + offset, size, scale);
        position = sphere_col.adjusted_position - offset;
    }

    void ApplyPhysics(const Timestep &in ts) {
        if(current_state == Attached){return;}
        bool collision_below = false;

        on_ground = false;
        on_wall = false;

        vec3 flat_current_position = position;
        vec3 flat_last_position = last_col_pos;
        vec3 last_normal = ground_normal;
        vec3 last_wall_normal = vec3(0.0f, 0.0f, 0.0f);
        flat_current_position.y = 0.0;
        flat_last_position.y = 0.0;
        // The vertical and flat movement velocity is used later on to drive the animations and offset the camera.
        vertical_movement_velocity = (position.y - last_col_pos.y) / ts.step();
        flat_movement_velocity = distance(flat_current_position, flat_last_position) / ts.step();
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
                on_ground = true;
            }else if(dot_product < 0.5){
                wall_normal = sphere_col.GetContact(i).normal;
                on_wall = true;
            }
        }

        ground_normal = mix(ground_normal, last_normal, ts.step() * 20.0f);
        // DebugDrawLine(position, position + ground_normal, vec3(0.0, 1.0, 0.0), _delete_on_update);
        wall_normal = mix(wall_normal, last_wall_normal, ts.step() * 20.0f);

        if(collision_below){
            // When the character has found a collision below and was previously off the ground
            // then start landing. Keeping an air timer prevents small bumps from triggering a land.
            if(!on_ground && in_air_timer > 0.5){
                Land();
            }

            vec3 push_adjusted_movement_direction = mix(movement_direction, push_force, min(1.0, length(push_force)));
            push_force *= pow(0.8f, ts.frames());
            in_air_timer = 0.0f;

            velocity += push_adjusted_movement_direction * ts.step() * movement_speed;
            // Reduce the velocity when standing on the ground, as if affected by friction.
            velocity *= pow(0.9f, ts.frames());

        }else{
            in_air_timer += ts.step();
            
            if(in_air_timer > 0.15 && current_state != Strike){
                current_animation = Flail;
            }

            // Keep adding velocity in the gravity direction to speed up faling.
            velocity += physics.gravity_vector * ts.step();
        }

        position += velocity * ts.step();
    }

    void Land(){
        // Create a landing sound effect at the feet of the character.
        vec3 sound_position = position + vec3(0.0f, 0.0f, 0.0);
        int sound_id = PlaySound("Data/Sounds/Footsteps-Rock5.wav", sound_position);
        SetSoundPitch(sound_id, RangedRandomFloat(0.9, 1.2));
        // DebugDrawWireSphere(position + vec3(0.0f, -1.0f, 0.0), 0.5, vec3(1.0), _fade);
    }

    void AvoidRat(Rat@ rat, const Timestep &in ts){
        if(on_ground){
            vec3 difference = rat.position - position;
            vec3 push_direction = normalize(difference) * -1.0;
            float dist = length(difference);

            float push_length = max(0.0, 1.0 - dist);
            vec3 added_force = push_length * 10.0 * push_direction * ts.step();
            push_force += added_force;
            rat.push_force -= added_force;
        }
    }

    void AvoidCharacter(MovementObject@ char, const Timestep &in ts){

        vec3 difference = char.position - position;
        vec3 character_direction = normalize(difference);
        vec3 up_down = cross(nav_target_direction, character_direction);

        vec3 push_direction = cross(character_direction, up_down);
        push_direction = normalize(vec3(push_direction.x, 0.0, push_direction.z));

        // DebugDrawLine(position, position + character_direction, vec3(0.0, 1.0, 0.0), _delete_on_update);
        // DebugDrawLine(position, position + push_direction, vec3(1.0, 1.0, 0.0), _delete_on_update);
        // DebugDrawLine(position, position + movement_direction, vec3(1.0, 0.0, 0.0), _delete_on_update);

        float dist = length(difference);
        float push_length = max(0.0, 2.0 - dist);

        push_force += push_length * 3.0 * push_direction * ts.step();
    }

}

float spiral_degrees = 5.0;
float spiral_A = 7.0;
float spiral_angle_offset = 65.0;

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();

    PostInit();

    if(EditorModeActive()){
        DebugDrawBillboard("Data/Textures/ui/eye_widget.tga", this_mo.position, 0.5, vec4(0.25, 1.0, 0.25, 1.0), _delete_on_update);
    }

    this_mo.position = ReadObjectFromID(this_mo.GetID()).GetTranslation();

    UpdateRatKing(ts);
    UpdateRats(ts);
    UpdateKilledCharacters(ts);

    if(spawned_amount < rat_amount){
        Rat rat();
        rats.insertLast(rat);
        rat.id = rats.size();
        spawned_amount += 1;
    }else if(spawned_amount > rat_amount){
        rats.removeAt(rats.size() - 1);
        spawned_amount -= 1;
    }
}

void UpdateRats(const Timestep &in ts){
    for(uint i = 0; i < rats.size(); i++){
        rats[i].Update(ts);
        
        // DebugDrawLine(last_position, rats[i].follow_position, vec3(1.0, 0.0, 0.0), _delete_on_update);
        // last_position = rats[i].follow_position;
    }

    UpdatePushRat(ts);
    UpdatePushCharacter(ts);
}

enum RatKingStates{
    Lead,
    OrderAttack,
    AttackEnemy
}

int rat_king_state = Lead;
ItemObject@ rat_king_weapon = null;

void UpdateRatKing(const Timestep &in ts){
    switch(rat_king_state){
        case Lead:
            UpdateLeading(ts);
            break;
        case AttackEnemy:
            UpdateAttackEnemy(ts);
            break;
    }
}

float attack_timer = 0.0f;

void UpdateLeading(const Timestep &in ts){

    if(!EditorModeActive() && GetInputDown(rat_king.controller_id, "attack")){
        attack_timer += time_step;
    }else{
        attack_timer = 0.0f;
    }

    if(attack_timer > 0.15){
        attack_timer = 0.0f;
        if(rat_king.GetIntVar("state") == _attack_state){return;}

        int target_id = -1;
        float last_dot = -1.0f;
        vec3 camera_direction = camera.GetFacing();

        for(int i = 0; i < GetNumCharacters(); i++){
            MovementObject@ char = ReadCharacter(i);

            if(char.GetID() != this_mo.GetID() && !rat_king.OnSameTeam(char) && char.GetIntVar("knocked_out") == _awake){

                vec3 torso_pos = char.rigged_object().GetAvgIKChainPos("torso");

                if(xz_distance(torso_pos, camera.GetPos()) > 25.0f){
                    continue;
                }

                col.GetObjRayCollision(camera.GetPos(), torso_pos);
                if(sphere_col.NumContacts() != 0){
                    continue;
                }

                vec3 target_dir = normalize(torso_pos - camera.GetPos());
                float dot_product = dot(target_dir, camera_direction);
                
                if(dot_product > max(0.75, last_dot)){
                    last_dot = dot_product;
                    target_id = char.GetID();
                }
            }
        }

        if(target_id != -1){
            rat_king_state = AttackEnemy;
            order_cooldown = 3.0f;

            string animation = "Data/Animations/rat_king_charge.anm";
            int8 flags = _ANM_MOBILE | _ANM_FROM_START;
            rat_king.rigged_object().anim_client().AddLayer(animation, 8.0f, flags);

            shouted = false;

            for(uint i = 0; i < rats.size(); i++){
                rats[i].attack_target = target_id;
                rats[i].current_state = Charge;
            }
        }
    }

    for(uint i = 0; i < rats.size(); i++){
        vec2 spiral_offset = GetSpiralOffset(i);

        rats[i].follow_position = rat_king.position;
        rats[i].follow_position.y = rats[i].position.y;
        rats[i].follow_position += vec3(spiral_offset.x, 0.0, spiral_offset.y);
    }

    UpdateSpiralOffset(ts);
    UpdateCircling(ts);
}

float order_cooldown;
bool shouted = false;

void UpdateAttackEnemy(const Timestep &in ts){

    order_cooldown -= ts.step();

    if(!shouted && order_cooldown <= 2.75){
        rat_king.Execute("resting_mouth_pose[3] = 5.0f;");
                
        vec3 head_pos = rat_king.rigged_object().GetAvgIKChainPos("head");
        int sound_id = PlaySoundGroup("Data/Sounds/voice/animal3/voice_rat_attack.xml", head_pos, _sound_priority_med);
        SetSoundPitch(sound_id, 0.75f);

        shouted = true;
    }

    if(order_cooldown <= 0.0){
        rat_king_state = Lead;
    }
}

const float SPIRAL_OFFSET_BASE = 0.05f;
const float SPIRAL_OFFSET_DUCK = 0.015f;
const float SPIRAL_OFFSET_VELOCITY = 0.005f;
const float SPIRAL_OFFSET_INTERPOLATION = 1.0f;

void UpdateSpiralOffset(const Timestep &in ts){
    float spiral_A_target = SPIRAL_OFFSET_BASE;

    if(rat_king.GetFloatVar("duck_amount") > 0.25f){
        spiral_A_target -= SPIRAL_OFFSET_DUCK;
    }

    spiral_A_target += length(rat_king.velocity) * SPIRAL_OFFSET_VELOCITY;

    spiral_A = mix(spiral_A, max(0.01f, min(1.0f, spiral_A_target)), ts.step() * SPIRAL_OFFSET_INTERPOLATION);
}

const float CIRCLE_THRESHOLD = 15.0f;
float circle_timer = 0.0f;

void UpdateCircling(const Timestep &in ts){

    if(length(rat_king.velocity) < 0.1){
        circle_timer += ts.step();

        if(circle_timer > CIRCLE_THRESHOLD){

            spiral_angle_offset += ts.step() * min(0.5f, (circle_timer - CIRCLE_THRESHOLD) * 0.25f);

            if(spiral_angle_offset > 360.0){
                spiral_angle_offset -= 360.0;
            }
        }
    }else{
        circle_timer = 0.0f;
    }
}

vec2 GetSpiralOffset(int offset){
    float dtheta = spiral_degrees * PI / 180.0; // Five degrees.
    int skip = 50;
    float theta = dtheta * (skip + offset);

    // Calculate r.
    float r = spiral_A * theta;

    // Convert to Cartesian coordinates.
    vec2 spiral_offset = PolarToCartesian(r, theta + spiral_angle_offset);

    // Create the point.
    return spiral_offset;
}

// Convert polar coordinates into Cartesian coordinates.
vec2 PolarToCartesian(float r, float theta){
    vec2 result;
    result.x = r * cos(theta);
    result.y = r * sin(theta);
    return result;
}

void PostInit(){
    if(post_init == false){return;}

    for(int i = 0; i < GetNumCharacters(); i++){
        MovementObject@ char = ReadCharacter(i);

        if(char.is_player){
            rat_king_id = char.GetID();
            @rat_king = char;
        }
    }

    post_init = false;
}

void UpdatePushRat(const Timestep &in ts){
    if(!push_rat){return;}

    array<Rat@> push_queue;
    push_queue.insertAt(0, rats);

    while(push_queue.size() > 0){
        for(uint i = 1; i < push_queue.size(); i++){
            push_queue[0].AvoidRat(push_queue[i], ts);
        }
        push_queue.removeAt(0);
    }
}

void UpdatePushCharacter(const Timestep &in ts){
    if(!push_character){return;}

    for(int i = 0; i < GetNumCharacters(); i++){
        MovementObject@ char = ReadCharacter(i);

        if(char.GetID() != rat_manager_id){
            for(uint j = 0; j < rats.size(); j++){
                rats[j].AvoidCharacter(char, ts);
            }
        }
    }
}

void UpdateKilledCharacters(const Timestep &in ts){
    for(uint i = 0; i < killed_characters.size(); i++){
        killed_characters[i].Update(ts);

        if(killed_characters[i].done){
            killed_characters.removeAt(i);
            i--;
        }
    }
}

void AddKilledCharacter(int char_id){
    for(uint i = 0; i < killed_characters.size(); i++){
        if(char_id == killed_characters[i].character_id){
            return;
        }
    }

    // DebugDrawWireSphere(ReadCharacterID(char_id).position, 1.0, vec3(1.0), _fade);
    killed_characters.insertLast(KilledCharacter(char_id));
}

class KilledCharacter{
    int character_id;
    bool done = false;
    int progress = 0;
    float killed_character_timer;

    KilledCharacter(int character_id){
        this.character_id = character_id;
    }

    void Update(const Timestep &in ts){
        killed_character_timer -= ts.step();

        if(killed_character_timer <= 0.0){
            MovementObject@ char = ReadCharacterID(character_id);

            switch(progress){
                case 0:
                    killed_character_timer = RangedRandomFloat(2.0, 3.0);
                    ApplyImpulse(char);
                    progress += 1;
                    break;
                case 1:
                    killed_character_timer = RangedRandomFloat(1.5, 2.0);
                    ApplyImpulse(char);
                    progress += 1;
                    break;
                case 2:
                    killed_character_timer = RangedRandomFloat(1.5, 2.0);
                    ApplyImpulse(char);
                    progress += 1;
                    break;
                case 3:
                    killed_character_timer = RangedRandomFloat(1.5, 2.0);
                    ApplyImpulse(char);
                    progress += 1;
                    break;
                case 4:
                    {
                        vec3 torso_pos = char.rigged_object().GetAvgIKChainPos("torso");
                        int sound_id = PlaySoundGroup("Data/Sounds/hit/spear_hit_flesh.xml", torso_pos, _sound_priority_med);
                        SetSoundPitch(sound_id, RangedRandomFloat(0.9, 1.2));
                        SetSoundGain(sound_id, 1.5);
                        ApplyImpulse(char);

                        for(int i = 0; i < 5; ++i){
                            Rat rat();

                            vec3 rand_vel = vec3(RangedRandomFloat(-0.5f, 0.5f), RangedRandomFloat(1.0f, 2.0f), RangedRandomFloat(-0.5f, 0.5f)) * 3.0f;
                            rat.position = torso_pos;
                            rat.velocity = rand_vel;

                            rats.insertLast(rat);
                            rat.id = rats.size();
                        }

                        for(int i = 0; i < 50; ++i){

                            vec3 mist_vel = vec3(RangedRandomFloat(-0.5f, 0.5f), RangedRandomFloat(0.0f, 2.0f), RangedRandomFloat(-0.5f, 0.5f)) * 2.0f;
                            MakeParticle("Data/Particles/bloodcloud.xml", torso_pos, (mist_vel + this_mo.velocity), GetBloodTint());
                            if(rand() % 5 == 0)MakeParticle("Data/Particles/bloodsplat.xml", torso_pos, (mist_vel + this_mo.velocity), GetBloodTint());

                        }

                        done = true;
                    }
                    
                    break;
            }
        }
    }

    void ApplyImpulse(MovementObject@ char){
        vec3 torso_pos = char.rigged_object().GetAvgIKChainPos("torso");
        vec3 random_force = vec3(RangedRandomFloat(-5.0f, 5.0f), RangedRandomFloat(0.0f, 5.0f), RangedRandomFloat(-5.0f, 5.0f)) * 3000.0f;

        char.Execute(   "vec3 impulse = vec3(" + random_force.x + ", " + random_force.y + ", " + random_force.z + ");" +
                        "vec3 pos = vec3(" + torso_pos.x + ", " + torso_pos.y + ", " + torso_pos.z + ");" +
                        "HandleRagdollImpactImpulse(impulse, pos, 0.0f);");
    }
}

void SetParameters() {
    params.AddString("Teams","turner");

    params.AddIntSlider("Rat Amount", 100, "min:0,max:25");
    rat_amount = max(0, params.GetInt("Rat Amount"));

    params.AddIntSlider("Update Frequency", 1, "min:1,max:10");
    if(update_frequency != max(1, params.GetInt("Update Frequency"))){
        update_frequency = max(1, params.GetInt("Update Frequency"));
        this_mo.SetScriptUpdatePeriod(update_frequency);
    }

    params.AddIntCheckbox("Super Speed", false);
    super_speed = params.GetInt("Super Speed") == 1;

    params.AddIntCheckbox("Push Rat", false);
    push_rat = params.GetInt("Push Rat") == 1;

    params.AddIntCheckbox("Push Character", false);
    push_character = params.GetInt("Push Character") == 1;

    params.AddIntCheckbox("Follow Use Nav", false);
    follow_use_nav = params.GetInt("Follow Use Nav") == 1;

    params.AddFloatSlider("Max Random Nav", 15.0, "min:1.0,max:50.0,step:1.0,text_mult:1");
    max_random_nav = params.GetFloat("Max Random Nav");

    params.AddFloatSlider("Spiral A", 0.1, "min:0.01, max:1.0,step:0.01,text_mult:1");
    spiral_A = max(0.01, params.GetFloat("Spiral A"));

    params.AddFloatSlider("Spiral Angle Offset", 65.0, "min:0.0, max:100.0,step:0.1,text_mult:1");
    spiral_angle_offset = params.GetFloat("Spiral Angle Offset");

    params.AddFloatSlider("Spiral Degrees", 5.0, "min:0.1, max:90.0,step:0.1,text_mult:1");
    spiral_degrees = params.GetFloat("Spiral Degrees");

    params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    character_scale = params.GetFloat("Character Scale");
    if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/r_combatidlethreat.anm", 20.0f, 0);
    }
}