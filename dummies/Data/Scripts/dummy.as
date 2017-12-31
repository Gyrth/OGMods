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

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();
    this_mo.position = ReadObjectFromID(this_mo.GetID()).GetTranslation();
}

float wiggle_wait = 0.0f;
float wave = 1.0f;
bool targeted_jump = false;

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
    if(knocked_out == _awake && other.GetIntVar("knocked_out") == _awake){
        float distance_threshold = 0.8f;
        vec3 this_com = this_mo.rigged_object().skeleton().GetCenterOfMass();
        vec3 other_com = other.rigged_object().skeleton().GetCenterOfMass();
        this_com.y = this_mo.position.y;
        other_com.y = other.position.y;
        if(distance_squared(this_com, other_com) < distance_threshold*distance_threshold){
            vec3 dir = other_com - this_com;
            float dist = length(dir);
            dir /= dist;
            dir *= distance_threshold - dist;
            other.Execute("
            if(!this_mo.static_char){
                this_mo.position += vec3("+dir.x+","+dir.y+","+dir.z+") * 1.0f;
                MindReceiveMessage(\"collided "+this_mo.GetID()+"\");
            }");
        }
    }
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
}

bool Init(string character_path) {
    this_mo.char_path = character_path;
    bool success = character_getter.Load(this_mo.char_path);
    if(success){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/r_combatidlethreat.anm", 20.0f, 0);
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
        PlaySoundGroup("Data/Sounds/hit/hit_medium.xml", pos, _sound_priority_high);
        MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
        MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
        HandleWeaponCuts(attacker_id, pos, attack_damage_mult, dir);
        return _hit;
    } else {
        return _invalid;
    }
}

void HandleWeaponCuts(int attacker_id, vec3 pos, float attack_damage_mult, vec3 dir){
    float sharp_damage = attack_getter2.GetSharpDamage();
    string attacking_weap_label = "";
    MovementObject@ char = ReadCharacterID(attacker_id);
    int attacker_is_wolf;
    if(char.GetIntVar("species") == _wolf){
        attacker_is_wolf = 1;
        this_mo.rigged_object().Stab(pos, dir, 1, 0);

    } else {
        attacker_is_wolf = 0;
    }
    bool blockable_weapon_attack = false;
    bool attacking_with_knife = false;
    bool attacking_with_sword = false;
    int enemy_primary_weapon_id = GetCharPrimaryWeapon(char);
    if(enemy_primary_weapon_id != -1){
        ItemObject@ weap = ReadItemID(enemy_primary_weapon_id);
        attacking_weap_label = weap.GetLabel();
        if(attacking_weap_label != "knife"){
            blockable_weapon_attack = true;
            if(attacking_weap_label == "sword" || attacking_weap_label == "rapier" || attacking_weap_label == "big_sword"){
                attacking_with_sword = true;
            }
        } else {
            attacking_with_knife = true;
        }
    }
    if(sharp_damage > 0.0f){
        level.SendMessage("cut "+this_mo.getID()+" "+attacker_id);
        if(species == _dog){
            sharp_damage *= 0.5;
            if(attacking_weap_label != "big_sword"){
                sharp_damage = min(0.5, sharp_damage);
            }
        } else if((species == _cat && weapon_slots[primary_weapon_slot] != -1) || ReadCharacterID(attacker_id).GetIntVar("species") == _cat){
            sharp_damage *= 0.5;
            if(attacking_weap_label != "big_sword"){
                sharp_damage = min(0.5, sharp_damage);
            }
        }
        TakeSharpDamage(sharp_damage * attack_damage_mult, pos, attacker_id, true);
    }
}

void AddBloodToCutPlaneWeapon(int attacker_id, vec3 dir) {
    MovementObject@ attacker = ReadCharacterID(attacker_id);
    int attacker_held_weapon = GetCharPrimaryWeapon(attacker);
    if(attacker_held_weapon != -1){
        ItemObject@ item_obj = ReadItemID(attacker_held_weapon);
        mat4 trans = item_obj.GetPhysicsTransform();
        mat4 torso_transform = this_mo.rigged_object().GetAvgIKChainTransform("head");
        vec3 char_pos = torso_transform * vec3(0.0f);
        vec3 point;
        vec3 col_point;
        float closest_dist = 0.0f;
        float closest_line = -1;
        vec3 start, end;
        float dist;
        int num_lines = item_obj.GetNumLines();
        for(int i=0; i<num_lines; ++i){
            if(item_obj.GetLineMaterial(i) != "metal"){
                continue;
            }
            start = trans * item_obj.GetLineStart(i);
            end = trans * item_obj.GetLineEnd(i);
            vec3 mu = LineLineIntersect(start, end, this_mo.position, char_pos);
            mu.x = min(1.0,max(0.0,mu.x));
            mu.y = min(1.0,max(0.0,mu.y));
            point = start + (end-start)*mu.x;
            dist = distance_squared(point, char_pos);
            //DebugDrawLine(start, end, vec3(1.0f), _persistent);
            if(closest_line == -1 || dist < closest_dist){
                closest_line = i;
                closest_dist = dist;
                col_point = point;
            }
        }
        if(item_obj.GetLabel() == "knife"){
            col_point = trans * item_obj.GetLineEnd(num_lines-1);
        }
        vec3 weap_dir = normalize(end-start);
        dir = normalize(dir - dot(dir, weap_dir) * weap_dir);
        //DebugDrawLine(this_mo.position, char_pos, vec3(0.0f,0.0f,1.0f), _persistent);
        //DebugDrawWireSphere(col_point, 0.1f, vec3(1.0f,0.0f,0.0f), _persistent);
        item_obj.AddBloodDecal(col_point, dir, 0.5f);
    }
}

void AddBloodToStabWeapon(int attacker_id) {
    MovementObject@ attacker = ReadCharacterID(attacker_id);
    vec3 char_pos = attacker.position;
    int attacker_held_weapon = GetCharPrimaryWeapon(attacker);
    if(attacker_held_weapon != -1){
        ItemObject@ item_obj = ReadItemID(attacker_held_weapon);
        mat4 trans = item_obj.GetPhysicsTransform();
        int num_lines = item_obj.GetNumLines();
        vec3 dist_point;
        bool found_dist_point = false;
        vec3 start, end;
        float dist, far_dist = 0.0f;
        for(int i=0; i<num_lines; ++i){
            start = trans * item_obj.GetLineStart(i);
            end = trans * item_obj.GetLineEnd(i);
            dist = distance_squared(start, char_pos);
            if(!found_dist_point || dist > far_dist){
                found_dist_point = true;
                dist_point = start;
                far_dist = dist;
            }
            dist = distance_squared(end, char_pos);
            if(dist > far_dist){
                dist_point = end;
                far_dist = dist;
            }
        }
        vec3 weap_dir = normalize(end-start);
        vec3 side = normalize(cross(weap_dir, vec3(RangedRandomFloat(-1.0f,1.0f),
                                                   RangedRandomFloat(-1.0f,1.0f),
                                                   RangedRandomFloat(-1.0f,1.0f))));
        item_obj.AddBloodDecal(dist_point, normalize(side + weap_dir*2.0f), 0.5f);
    }
}

void LayerRemoved(int id) {

}

void TakeSharpDamage(float sharp_damage, vec3 pos, int attacker_id, bool allow_heavy_cut) {
    if(this_mo.controlled){
        blood_flash_time = the_time;
    }
    int old_knocked_out = knocked_out;
    if(attack_getter2.HasCutPlane()){
        vec3 cut_plane_local = attack_getter2.GetCutPlane();
        int cut_plane_type = attack_getter2.GetCutPlaneType();
        if(!allow_heavy_cut){
            cut_plane_type = 0;
        }
        if(old_knocked_out == _awake && knocked_out != _awake){
            cut_plane_type = 1;
        }
        if(attack_getter2.GetMirrored() == 1){
            cut_plane_local.x *= -1.0f;
        }
        vec3 facing = ReadCharacterID(attacker_id).GetFacing();
        vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
        vec3 up(0.0f,1.0f,0.0f);
        vec3 cut_plane_world = facing * cut_plane_local.z +
            facing_right * cut_plane_local.x +
            up * cut_plane_local.y;

        vec3 avg_pos = this_mo.rigged_object().GetAvgPosition();
        float height_rel = avg_pos.y - (ReadCharacterID(attacker_id).position.y+0.45f);

        quaternion rotate(vec4(facing_right.x, facing_right.y, facing_right.z, height_rel*0.5f));
        cut_plane_world = Mult(rotate, cut_plane_world);
        facing = Mult(rotate, facing);
        up = Mult(rotate, up);
        this_mo.rigged_object().CutPlane(cut_plane_world, pos, facing, cut_plane_type, 0);
        bool _draw_cut_plane = false;
        vec3 cut_plane_z = normalize(cross(up, cut_plane_world));
        vec3 cut_plane_x = normalize(cross(cut_plane_world, cut_plane_z));
        if(_draw_cut_plane){
            for(int i=-10; i<=10; ++i){
                DebugDrawLine(pos-cut_plane_z*0.5f+cut_plane_x*(i*0.1f)+facing*0.5, pos+cut_plane_z*0.5f+cut_plane_x*(i*0.1f)+facing*0.5, vec3(1.0f,1.0f,1.0f), _fade);
                DebugDrawLine(pos-cut_plane_x*0.5f+cut_plane_z*(i*0.1f)+facing*0.5, pos+cut_plane_x*0.5f+cut_plane_z*(i*0.1f)+facing*0.5, vec3(1.0f,1.0f,1.0f), _fade);
            }
        }
        AddBloodToCutPlaneWeapon(attacker_id, cut_plane_x*0.8f+cut_plane_world*0.2f);
    }
    if(attack_getter2.HasStabDir()){
        int attack_weapon_id = GetCharPrimaryWeapon(ReadCharacterID(attacker_id));
        if(attack_weapon_id != -1){
            int stab_type = attack_getter2.GetStabDirType();
            ItemObject@ item_obj = ReadItemID(attack_weapon_id);
            mat4 trans = item_obj.GetPhysicsTransform();
            mat4 trans_rotate = trans;
            trans_rotate.SetColumn(3, vec3(0.0f));
            vec3 stab_pos = trans * vec3(0.0f,0.0f,0.0f);
            //vec3 stab_dir = trans_rotate * attack_getter2.GetStabDir();
            int num_lines = item_obj.GetNumLines();
            if(num_lines > 0){
                vec3 start = trans * item_obj.GetLineStart(num_lines-1);
                vec3 end = trans * item_obj.GetLineEnd(num_lines-1);
                vec3 stab_dir = normalize(end-start);
                stab_pos -= stab_dir * 5.0f;
                bool _draw_cut_line = false;
                if(_draw_cut_line){
                    DebugDrawLine(stab_pos,
                        stab_pos + stab_dir*10.0f,
                        vec3(1.0f),
                        _fade);
                }
                this_mo.rigged_object().Stab(stab_pos, stab_dir, stab_type, 0);
                AddBloodToStabWeapon(attacker_id);
            }
        }
    }
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    return _hit;
}

int AboutToBeHitByItem(int id){
    return 1;
}

void HitByItem(string material, vec3 point, int id, int type) {
    // Get force of object movement
    ItemObject@ io = ReadItemID(id);
    vec3 lin_vel = io.GetLinearVelocity();
    vec3 force = (lin_vel - this_mo.velocity) * io.GetMass() * 0.25f;
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

void SetParameters() {
    params.AddString("Teams","dummy");

    params.AddFloatSlider("Character Scale",1,"min:0.6,max:1.4,step:0.02,text_mult:100");
    character_scale = params.GetFloat("Character Scale");
    if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/r_combatidlethreat.anm", 20.0f, 0);
        FixDiscontinuity();
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
