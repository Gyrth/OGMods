#include "aschar_aux.as"

float notice_target_aggression_delay = 0.0f;
int notice_target_aggression_id = 0.0f;

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
string current_anim = "Data/Animations/r_bow.anm";
array <string> possible_anims = {	"Data/Animations/r_sweep.anm",
									"Data/Animations/r_bow.anm",
									"Data/Animations/r_archwrithe.anm",
									"Data/Animations/r_blockright.anm",
									"Data/Animations/r_grabface.anm",
									"Data/Animations/r_frontkick.anm",
									"Data/Animations/r_kneestrike.anm",
									"Data/Animations/r_pickup.anm",
									"Data/Animations/r_grabstomach.anm"};
int knocked_out = _awake;
float anim_change_timer;
float anim_threshold = 1.0f;

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();
	anim_change_timer += ts.step();
	
	if(anim_change_timer > anim_threshold){
		current_anim = possible_anims[rand() % possible_anims.size()];
		anim_change_timer = 0.0f;
		anim_threshold = RangedRandomFloat(0.1f, 1.0f);
		this_mo.SetAnimation(current_anim);
	}

    if( old_time > time )
        Log( error, "Sanity check failure, timer was reset in player character: " + this_mo.getID() + "\n");
    old_time = time;
}

int NeedsAnimFrames() {
    return 0;
}

void FinalAttachedItemUpdate(int num_frames) {
	
}

void RandomizeColors() {
    Object@ obj = ReadObjectFromID(this_mo.GetID());
    for(int i=0; i<4; ++i){
        const string channel = character_getter.GetChannel(i);
        if(channel == "fur"){
            obj.SetPaletteColor(i, GetRandomFurColor());
        } else if(channel == "cloth"){
            obj.SetPaletteColor(i, RandReasonableColor());
        }
    }
}

void Reset() {
}

void Init(string character_path) {
    Dispose();
    this_mo.char_path = character_path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    ResetLayers();
    PostReset();
	RandomizeColors();
	this_mo.SetAnimation(current_anim);
	this_mo.visible = true;
	this_mo.SetScriptUpdatePeriod(1);
	this_mo.rigged_object().SetAnimUpdatePeriod(1);
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

int IsUnaware() {
    return 0;
}

void ResetMind() {

}

int IsIdle() {
    return 1;
}

int IsAggressive() {
    return 0;
}

void Notice(int character_id){

}

void MindReceiveMessage(string msg){
}
void ReceiveMessage(string msg){
	Print("Received " + msg + "\n");
}

void HandleAnimationEvent(string event, vec3 world_pos){
	//Print("Received " + event + "\n");
}

bool IsAware(){
    return false;
}

void SetParameters() {

	params.AddString("Anim", "Data/Animations/r_flail.anm");
}
