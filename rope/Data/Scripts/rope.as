#include "aschar_aux.as"

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
const float _leg_sphere_size = 0.45f; // affects the size of a sphere collider used for leg collisions
enum IdleType{_stand, _active, _combat};
IdleType idle_type = _active;

bool idle_stance = false;
float idle_stance_amount = 0.0f;

// the main timer of the script, used whenever anything has to know how much time has passed since something else happened.
float time = 0;

vec3 head_look;
vec3 torso_look;

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

vec3 gravity_vector = vec3(0.0, -9.81, 0.0);
bool resetting = false;
int num_segments = 20;

class RopeSegment{
	bool static_segment = false;
	vec3 position;
	float radius = 0.1;
	vec3 velocity;
	vec3 momentum;
	RopeSegment@ previous_segment;
	int id;

	RopeSegment(vec3 initial_position, bool is_static, RopeSegment@ _previous_segment){
		position = initial_position;
		static_segment = is_static;
		@previous_segment = @_previous_segment;
		id = rope_segments.size();
	}

	void DrawDebug(){
		DebugDrawWireSphere(position, radius, vec3(0.5), _delete_on_update);
		if(!static_segment){
			DebugDrawLine(position, previous_segment.position, vec3(5.0, 0.0, 0.0), _delete_on_update);
		}
	}

	void UpdateCollisions(){
		if(static_segment){
			position = this_mo.position;
		}else{
			vec3 gravity_applied_position = position + (gravity_vector * time_step);

			if(@previous_segment != null){
				//Adjust the segment position if it's too far away from the previous one.
				if(distance(gravity_applied_position, previous_segment.position) > (radius * 2.0)){
					vec3 direction = normalize(gravity_applied_position - previous_segment.position);
					gravity_applied_position = previous_segment.position + (direction * (radius * 2.0));
				}
			}

			float repel_amount = 0.5;

			for(uint i = 0; i < rope_segments.size(); i++){
				RopeSegment@ segment = rope_segments[i];
				if(segment.id != id){
					float segment_distance = distance(segment.position, position);
					if(segment_distance < (radius * 2.0) * 0.7){
						vec3 repel_direction = normalize(position - segment.position);
						DebugDrawLine(position, position + repel_direction, vec3(0.0, 1.0, 0.0), _delete_on_update);
						gravity_applied_position += repel_direction * repel_amount * time_step;
					}
				}
			}

			col.GetSweptSphereCollision(position, gravity_applied_position, radius);
			if(sphere_col.NumContacts() != 0){
				gravity_applied_position = sphere_col.adjusted_position;
				momentum *= 0.96;
			}
			/* col.GetSweptSphereCollisionCharacters(position, gravity_applied_position, radius);
			for(int i = 0; i < sphere_col.NumContacts(); i++){
				CollisionPoint contact = sphere_col.GetContact(0);
				if(contact.id != this_mo.GetID()){
					Log(warning, "Contact id  " + contact.id);
					gravity_applied_position = sphere_col.adjusted_position;
				}
			} */

			velocity = (gravity_applied_position - position) / time_step;
			/* velocity *= 0.999; */
			momentum += velocity * 0.02;
			/* momentum *= 0.4; */
			position += velocity * time_step;
			position += momentum * time_step;
			/* position = gravity_applied_position; */
		}
	}
}

array<RopeSegment@> rope_segments;

void UpdateRope(){
	if(resetting){return;}

	if(num_segments > int(rope_segments.size())){
		if(rope_segments.size() == 0){
			rope_segments.insertLast(RopeSegment(this_mo.position, true, null));
		}else{
			rope_segments.insertLast(RopeSegment(this_mo.position, false, rope_segments[rope_segments.size() - 1]));
		}
	}else if(num_segments > 0 && num_segments < int(rope_segments.size())){
		rope_segments.removeAt(rope_segments.size() - 1);
	}

	gravity_vector = vec3(0.0, -9.81, 0.0);
	for(uint i = 0; i < rope_segments.size(); i++){
		RopeSegment@ segment = rope_segments[i];
		segment.UpdateCollisions();
		segment.DrawDebug();
	}
}

void Reset(){
	resetting = true;
}

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();

    if( old_time > time )
        Log( error, "Sanity check failure, timer was reset in player character: " + this_mo.getID() + "\n");
    old_time = time;

    if(resting_mouth_pose.size() == 0){
        resting_mouth_pose.resize(4);
        target_resting_mouth_pose.resize(4);
        for(int i=0; i<4; ++i){
            resting_mouth_pose[i] = 0.0f;
            target_resting_mouth_pose[i] = 0.0f;
        }
    }
    for(int i=0; i<4; ++i){
        resting_mouth_pose[i] = mix(target_resting_mouth_pose[i], resting_mouth_pose[i], pow(0.97f, num_frames));
    }

    // Cinematic posing
	on_ground = true;
	tilt_modifier = vec3(0.0f,1.0f,0.0f);
	flip_modifier_rotation = 0.0f;
	string newAnim = params.GetString("Anim");
	if(dialogue_anim != newAnim && FileExists(newAnim)){
		dialogue_anim = params.GetString("Anim");
		this_mo.SetAnimation(dialogue_anim, 3.0f, 0);
	}
	idle_stance_amount = 0.2f;
	UpdateRope();
}

bool Init(string character_path) {
	Dispose();
	this_mo.char_path = character_path;
	character_getter.Load(this_mo.char_path);
	this_mo.RecreateRiggedObject(this_mo.char_path);
	ResetLayers();
	PostReset();
	this_mo.SetScriptUpdatePeriod(1);
	this_mo.rigged_object().SetAnimUpdatePeriod(0);
	return true;
}

vec3 GetRandomFurColor() {
    vec3 fur_color_byte;
    int rnd = rand()%6;
    switch(rnd){
    case 0: fur_color_byte = vec3(255); break;
    case 1: fur_color_byte = vec3(34); break;
    case 2: fur_color_byte = vec3(137); break;
    case 3: fur_color_byte = vec3(105,73,54); break;
    case 4: fur_color_byte = vec3(53,28,10); break;
    case 5: fur_color_byte = vec3(172,124,62); break;
    }
    return FloatTintFromByte(fur_color_byte);
}

void PostReset() {
	resetting = false;
    CacheSkeletonInfo();
    if(body_bob_freq == 0.0f){
        body_bob_freq = RangedRandomFloat(0.9f,1.1f);
        body_bob_time_offset = RangedRandomFloat(0.0f,100.0f);
    }
}

// Create a random color tint, avoiding excess saturation
vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return FloatTintFromByte(color);
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
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

void CacheSkeletonInfo() {
    Log(info, "Caching skeleton info");
    RiggedObject@ rigged_object = this_mo.rigged_object();
    Skeleton@ skeleton = rigged_object.skeleton();
    int num_bones = skeleton.NumBones();
    skeleton_bind_transforms.resize(num_bones);
    inv_skeleton_bind_transforms.resize(num_bones);
    for(int i=0; i<num_bones; ++i){
        skeleton_bind_transforms[i] = BoneTransform(skeleton.GetBindMatrix(i));
        inv_skeleton_bind_transforms[i] = invert(skeleton_bind_transforms[i]);
    }

    ik_chain_elements.resize(0);
    ik_chain_bone_lengths.resize(0);
    ik_chain_start_index.resize(kNumIK);
    ik_chain_length.resize(kNumIK);
    for(int i=0; i<kNumIK; ++i) {
        string bone_label;
        switch(i){
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
        while(bone != -1 && count < ik_chain_length[i]){
            ik_chain_bone_lengths.push_back(distance(skeleton.GetPointPos(skeleton.GetBonePoint(bone, 0)), skeleton.GetPointPos(skeleton.GetBonePoint(bone, 1))));
            ik_chain_elements.push_back(bone);
            bone = skeleton.GetParent(bone);
            ++count;
        }
    }
    ik_chain_start_index.push_back(ik_chain_elements.size());
    bone_children.resize(0);
    bone_children_index.resize(num_bones);
    for(int bone=0; bone<num_bones; ++bone){
        bone_children_index[bone] = bone_children.size();
        for(int i=0; i<num_bones; ++i){
            int temp_bone = i;
            while(skeleton.GetParent(temp_bone) != -1 && skeleton.GetParent(temp_bone) != bone){
                temp_bone = skeleton.GetParent(temp_bone);
            }
            if(skeleton.GetParent(temp_bone) == bone){
                bone_children.push_back(i);
            }
        }
    }
    bone_children_index.push_back(bone_children.size());

    convex_hull_points.resize(0);
    convex_hull_points_index.resize(num_bones);
    for(int bone=0; bone<num_bones; ++bone){
        convex_hull_points_index[bone] = convex_hull_points.size();
        array<float> @hull_points = skeleton.GetConvexHullPoints(bone);
        for(int i=0, len=hull_points.size(); i<len; i+=3){
            convex_hull_points.push_back(vec3(hull_points[i], hull_points[i+1], hull_points[i+2]));
        }
    }
    convex_hull_points_index.push_back(convex_hull_points.size());

    key_masses.resize(kNumKeys);
    root_bone.resize(kNumKeys);
    for(int j=0; j<2; ++j){
        int bone = skeleton.IKBoneStart(j==0?"left_leg":"right_leg");
        for(int i=0, len=skeleton.IKBoneLength(j==0?"left_leg":"right_leg"); i<len; ++i){
            key_masses[kLeftLegKey+j] += skeleton.GetBoneMass(bone);
            if(i<len-1){
                bone = skeleton.GetParent(bone);
            }
        }
        root_bone[kLeftLegKey+j] = bone;
    }
    for(int j=0; j<2; ++j){
        int bone = skeleton.IKBoneStart(j==0?"leftarm":"rightarm");
        for(int i=0, len=skeleton.IKBoneLength(j==0?"leftarm":"rightarm"); i<len; ++i){
            key_masses[kLeftArmKey+j] += skeleton.GetBoneMass(bone);
            if(i<len-1){
                bone = skeleton.GetParent(bone);
            }
        }
        root_bone[kLeftArmKey+j] = bone;
    }
    {
        int bone = skeleton.IKBoneStart("torso");
        for(int i=0, len=skeleton.IKBoneLength("torso"); i<len; ++i){
            key_masses[kChestKey] += skeleton.GetBoneMass(bone);
            if(i<len-1){
                bone = skeleton.GetParent(bone);
            }
        }
        root_bone[kChestKey] = bone;
    }
    {
        int bone = skeleton.IKBoneStart("head");
        for(int i=0, len=skeleton.IKBoneLength("head"); i<len; ++i){
            key_masses[kHeadKey] += skeleton.GetBoneMass(bone);
            if(i<len-1){
                bone = skeleton.GetParent(bone);
            }
        }
        root_bone[kHeadKey] = bone;
    }
}


void Dispose() {
    if(fire_object_id != -1){
        DeleteObjectID(fire_object_id);
        fire_object_id = -1;
    }
    if(shadow_id != -1){
        DeleteObjectID(shadow_id);
        shadow_id = -1;
    }
    if(lf_shadow_id != -1){
        DeleteObjectID(lf_shadow_id);
        lf_shadow_id = -1;
    }
    if(rf_shadow_id != -1){
        DeleteObjectID(rf_shadow_id);
        rf_shadow_id = -1;
    }
    for(int i=0; i<int(flash_obj_ids.size());){
        if(ObjectExists(flash_obj_ids[i])){
            DeleteObjectID(flash_obj_ids[i]);
        }
        flash_obj_ids.removeAt(i);
    }
}


void FinalAnimationMatrixUpdate(int num_frames) {
    // Convenient shortcuts
    RiggedObject@ rigged_object = this_mo.rigged_object();
    Skeleton@ skeleton = rigged_object.skeleton();

    // Get local to world transform
    BoneTransform local_to_world;
    {
        EnterTelemetryZone("get local_to_world transform");
        vec3 offset;
        offset = this_mo.position;
        offset.y -= _leg_sphere_size;
        vec3 facing = this_mo.GetFacing();
        float cur_rotation = atan2(facing.x, facing.z);
        quaternion rotation(vec4(0,1,0,cur_rotation));
        local_to_world.rotation = rotation;
        local_to_world.origin = offset;
        rigged_object.TransformAllFrameMats(local_to_world);
        LeaveTelemetryZone();
    }
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

void SetParameters() {
    params.AddFloatSlider("Character Scale",1,"min:0.6,max:1.4,step:0.02,text_mult:100");
    float new_char_scale = params.GetFloat("Character Scale");
    if(new_char_scale != this_mo.rigged_object().GetRelativeCharScale()){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        ResetSecondaryAnimation();
        ResetLayers();
        CacheSkeletonInfo();
    }

    params.AddFloatSlider("Fat",0.5f,"min:0.0,max:1.0,step:0.05,text_mult:200");
    p_fat = params.GetFloat("Fat")*2.0f-1.0f;

    params.AddFloatSlider("Muscle",0.5f,"min:0.0,max:1.0,step:0.05,text_mult:200");
    p_muscle = params.GetFloat("Muscle")*2.0f-1.0f;

    params.AddFloatSlider("Ear Size",1.0f,"min:0.0,max:3.0,step:0.1,text_mult:100");
    p_ear_size = params.GetFloat("Ear Size")*0.5f+0.5f;

    string team_str;
    character_getter.GetTeamString(team_str);
    params.AddString("Teams",team_str);

	params.AddString("Anim", "Data/Animations/r_flail.anm");

	params.AddIntSlider("Num Segments", 20, "min:0,max:100");
	num_segments = params.GetInt("Num Segments");
}

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){}
void DisplayMatrixUpdate(){}
void MovementObjectDeleted(int id){}
void ResetLayers(){}
void HandleAnimationEvent(string event, vec3 world_pos){}
int IsUnaware(){return 0;}
void ResetMind(){}
int IsIdle(){return 1;}
int IsAggressive(){return 0;}
void Notice(int character_id){}
void MindReceiveMessage(string msg){}
void ReceiveMessage(string msg){}
bool IsAware(){return hostile;}
int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult){return 2;}
int AboutToBeHitByItem(int id){return 1;}
void HitByItem(string material, vec3 point, int id, int type) {}
int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult){return 2;}
int NeedsAnimFrames(){return 0;}
int IsPassive(){return 0;}
int IsOnLedge(){return 0;}
int IsDodging(){return 0;}
int IsAggro(){return 1;}
void FinalAttachedItemUpdate(int num_frames) {}
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
