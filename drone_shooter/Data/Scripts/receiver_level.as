#include "threatcheck.as"
#include "music_load.as"
#include "menu_common.as"
#include "arena_meta_persistence.as"
#include "train_track_save_load.as"

//UI variables..----------------------------------------------------------------------------------------------------------------------------
FontSetup default_font("arial", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0f;

//Intersection, track and environment variables.----------------------------------------------------------------------------------------------
array<Intersection@> intersections;
string track_segment_path = "Data/Objects/track_segment.xml";
uint num_intersections = 75;
uint max_connections = 3;
float height_range = 200.0f;
float random_range = 400.0f;
float base_height;
float env_objects_mult = 1.0f;
int chosen_level_index = 0;
array<vec3> occupied_locations;
array<SignalAnimation@> signal_animations;
array<EnvironmentAsset@> environment_assets = {	EnvironmentAsset("Data/Prototypes/OG/elm_tree_large.xml", 25.0f, 75),
												EnvironmentAsset("Data/Prototypes/OG/elm_tree_small.xml", 25.0f, 75),
												EnvironmentAsset("Data/Prototypes/OG/PineTree1_A.xml", 15.0f, 80),
												EnvironmentAsset("Data/Prototypes/OG/PineTree1_B.xml", 15.0f, 80),
												EnvironmentAsset("Data/Prototypes/OG/PineTree2_A.xml", 15.0f, 80),
												EnvironmentAsset("Data/Prototypes/OG/PineTree2_B.xml", 15.0f, 80),
												EnvironmentAsset("Data/Objects/Plants/Trees/temperate/small_deciduous.xml", 10.0f, 40),
												EnvironmentAsset("Data/Objects/Plants/Trees/temperate/green_bush.xml", 2.0f, 75)};

vec3 signal_green = vec3(0.0f, 1.0f, 0.0f) * 2.0f;
vec3 signal_red = vec3(1.0f, 0.0f, 0.0f) * 0.5f;
int num_barrels = 10;
array<Object@> barrels;
enum signal_animation_types{
	turn_animation = 0,
	hide_animation = 1,
	show_animation = 2
}

//General script variables.-------------------------------------------------------------------------------------------------------------------
bool post_init_done = false;
const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);
IMContainer@ barrel_counter_holder;

//Camera control and player variables.---------------------------------------------------------------------------------------------------------
float cam_rotation_x = 0.0f;
float cam_rotation_y = 180.0f;
float cam_rotation_z = 0.0f;
float camera_shake = 0.0f;
float current_fov = 90.0f;
float zoomed_fov = 50.0f;
array<Bullet@> bullets;
float crosshair_length = 20.0f;
float crosshair_thickness = 1.0f;
vec4 crosshair_color = vec4(1.0f, 0.0f, 0.0f, 1.0f);
float mouse_sensitivity = 0.5f;
bool editor_mode_active = false;

class SignalAnimation{
	signal_animation_types signal_animation_type;
	Object@ target_object;
	vec3 original_location;
	quaternion original_rotation;
	bool done;
	float timer = 0.0f;
	bool init = false;

	SignalAnimation(Object@ _target_object, signal_animation_types _signal_animation_type){
		signal_animation_type = _signal_animation_type;
		@target_object = _target_object;
		//Cancel any animation that is using the same object, or else the rotation and/or the translation get messed up.
		for(uint i = 0; i < signal_animations.size(); i++){
			if(signal_animations[i].target_object.GetID() == target_object.GetID()){
				signal_animations[i].Cancel();
				signal_animations.removeAt(i);
				break;
			}
		}
		target_object.SetCollisionEnabled(false);
		original_location = target_object.GetTranslation();
		original_rotation = target_object.GetRotation();

		if(signal_animation_type == show_animation){
			int sound_id = PlaySound("Data/Sounds/signal_appear.wav", original_location + vec3(0.0f, 1.0f, 0.0f));
			SetSoundGain(sound_id, 2.0f);
		}else if(signal_animation_type == hide_animation){
			int sound_id = PlaySound("Data/Sounds/signal_disappear.wav", original_location + vec3(0.0f, 1.0f, 0.0f));
			SetSoundGain(sound_id, 2.0f);
		}else if(signal_animation_type == turn_animation){
			vec3 forward = normalize((original_location + vec3(0.0f, 1.0f, 0.0f)) - camera.GetPos());
			vec3 forward_offset = forward * 1.0;
			vec3 spawn_point = camera.GetPos() + forward_offset;
			int sound_id = PlaySound("Data/Sounds/ding.wav", spawn_point);
			SetSoundGain(sound_id, 2.0f);
		}
	}

	void Cancel(){
		target_object.SetTranslationRotationFast(original_location, original_rotation);
	}

	void Update(){
		timer += time_step;

		if(signal_animation_type == turn_animation){
			float duration = 0.5f;
			if(timer >= duration){
				done = true;
				target_object.SetTranslationRotationFast(original_location, original_rotation);
				target_object.SetCollisionEnabled(true);
				return;
			}

			vec3 facing = Mult(original_rotation, vec3(0,0,1));
			float rot = atan2(facing.x, facing.z) * 180.0f / PI;
			float initial_rotation = floor(rot + 0.5f);

			float y_rotation = 180.0f * sin(2 * PI * 1.0 * (timer / duration) + initial_rotation);
			quaternion rot_y(vec4(0, 1, 0, y_rotation * deg2rad));
			target_object.SetTranslationRotationFast(original_location, rot_y);
		}else if(signal_animation_type == hide_animation){
			float duration = 0.5f;
			if(timer >= duration){
				done = true;
				target_object.SetTranslationRotationFast(original_location, original_rotation);
				target_object.SetEnabled(false);
				return;
			}

			vec3 new_location = mix(original_location, original_location + vec3(0.0f, -5.0f, 0.0f), (timer / duration));
			target_object.SetTranslationRotationFast(new_location, original_rotation);
		}else if(signal_animation_type == show_animation){
			float duration = 0.5f;
			if(timer >= duration){
				done = true;
				target_object.SetCollisionEnabled(true);
				/* target_object.SetTranslationRotationFast(original_location, original_rotation); */
				target_object.SetTranslation(original_location);
				target_object.SetRotation(original_rotation);
				return;
			}

			vec3 new_location = mix(original_location + vec3(0.0f, -5.0f, 0.0f), original_location, (timer / duration));
			target_object.SetTranslationRotationFast(new_location, original_rotation);
			if(!init){
				target_object.SetEnabled(true);
				init = true;
			}
		}
	}
}


class EnvironmentAsset{
	string path;
	float min_object_distance;
	int amount;

	EnvironmentAsset(string _path, float _min_object_distance, int _amount){
		path = _path;
		min_object_distance = _min_object_distance;
		amount = _amount;
	}
}

class Intersection{
	vec3 position;
	Object@ rotating_track;
	array<Intersection@> connections;
	array<array<vec3>> paths;
	array<Object@> turn_signal_objects;
	int chosen_path;
	float min_intersection_distance = 50.0f;
	bool draw_debug = false;

	Intersection(){
		AttemptIntersectionPlacement();
	}

	void AttemptIntersectionPlacement(){
		float random_x = RangedRandomFloat(-random_range, random_range);
		float random_z = RangedRandomFloat(-random_range, random_range);

		position = col.GetRayCollision(vec3(random_x, base_height + height_range, random_z), vec3(random_x, base_height - height_range, random_z));
		for(uint i = 0; i < occupied_locations.size(); i++){
			//Try to place it again if the location is occupied.
			vec3 flat_location = vec3(occupied_locations[i].x, 0.0f, occupied_locations[i].z);
			if(distance(flat_location, vec3(position.x, 0.0f, position.z)) < min_intersection_distance){
				AttemptIntersectionPlacement();
				return;
			}
		}

		occupied_locations.insertLast(position);
		int rotating_track_id = CreateObject(track_segment_path);
		@rotating_track = ReadObjectFromID(rotating_track_id);
		rotating_track.SetCollisionEnabled(false);
		rotating_track.SetTranslation(position + vec3(0.0f, 0.25f, 0.0f));
		rotating_track.SetScale(vec3(2.0f));
	}

	void Update(){
		float y_rotation = 360.0f * sin(2 * PI * 0.15 * the_time + 0.0);
		quaternion rot_y(vec4(0, 1, 0, y_rotation * deg2rad));
		rotating_track.SetTranslationRotationFast(position, rot_y);
		if(draw_debug){
			DrawDebug();
		}
	}

	void SetConnected(){
		array<Intersection@> sorted_intersections;
		for(uint i = 0; i < intersections.size(); i++){
			bool added = false;

			//Do not allow the intersection to connect to itself.
			if(intersections[i] is this){continue;}

			for(uint j = 0; j < sorted_intersections.size(); j++){
				if(distance(intersections[i].position, position) <= distance(sorted_intersections[j].position, position)){
					sorted_intersections.insertAt(j, intersections[i]);
					added = true;
					break;
				}
			}
			if(!added){
				sorted_intersections.insertLast(intersections[i]);
			}
		}

		int connection_tries = max_connections;
		for(int i = 0; i < connection_tries && int(sorted_intersections.size()) > i && connections.size() < max_connections; i++){
			bool can_connect = sorted_intersections[i].RequestConnect(this);

			if(!can_connect){
				connection_tries += 1;
			}
		}
	}

	bool RequestConnect(Intersection@ peer){
		if(connections.size() == max_connections){
			return false;
		}

		for(uint i = 0; i < connections.size(); i++){
			//Check if this is already connected.
			if(connections[i] is peer){
				return true;
			}
		}

		//Add the peer to the list of connected intersections.
		CreateTrack(peer);

		connections.insertLast(peer);
		peer.connections.insertLast(this);

		array<vec3> reverse_path = paths[paths.size() - 1];
		reverse_path.reverse();
		peer.paths.insertLast(reverse_path);

		return true;
	}

	void DrawDebug(){
		vec3 extra_height = vec3(0.0, 10.0, 0.0);
		for(uint i = 0; i < connections.size(); i++){
			DebugDrawLine(connections[i].position + extra_height, position + extra_height, vec3(0.0, 0.0, 1.0), _delete_on_update);
		}
	}

	void CreateTrack(Intersection@ peer){
		float intersection_distance = distance(peer.position, position);
		int segments_needed = int(intersection_distance / 2.0f);
		array<vec3> new_path;

		for(int i = 1; i < segments_needed; i++){
			vec3 location = mix(peer.position, position, float(i) / float(segments_needed));
			location = col.GetRayCollision(vec3(location.x, base_height + height_range, location.z), vec3(location.x, base_height - height_range, location.z));
			if(draw_debug){
				DebugDrawWireSphere(location, 0.5, vec3(1.0, 0.0, 0.0), _persistent);
			}
			new_path.insertLast(location);
		}

		vec3 flat_direction = normalize(vec3(peer.position.x, position.y, peer.position.z) - position);
		vec3 left = normalize(cross(flat_direction, vec3(0.0f, 1.0f, 0.0f)));

		for(int i = 0; i < int(new_path.size()) - 1; i++){

			vec3 direction = normalize(new_path[i + 1] - new_path[i]);
			vec3 location = mix(new_path[i], new_path[i + 1], 0.5f);
			float track_length = distance(new_path[i], new_path[i + 1]);

			int obj_id = CreateObject(track_segment_path);
			Object@ track_obj = ReadObjectFromID(obj_id);

			float height_offset = 0.25f;
			track_obj.SetTranslation(location + vec3(0.0f, height_offset, 0.0f));
			occupied_locations.insertLast(location);

			vec3 up = normalize(cross(direction, left));
			vec3 front = direction;

			if(draw_debug){
				DebugDrawLine(location, location + up, vec3(1.0, 0.0, 0.0), _persistent);
				DebugDrawLine(location, location + front, vec3(0.0, 1.0, 0.0), _persistent);
			}

			vec3 new_rotation;
			new_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
			new_rotation.x = asin(front[1]) * -180.0f / PI;
			vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
			vec3 expected_up = normalize(cross(expected_right, front));
			new_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

			quaternion rot_y(vec4(0, 1, 0, new_rotation.y * deg2rad));
			quaternion rot_x(vec4(1, 0, 0, new_rotation.x * deg2rad));
			quaternion rot_z(vec4(0, 0, 1, new_rotation.z * deg2rad));
			track_obj.SetRotation(rot_y * rot_x * rot_z);
			track_obj.SetScale(vec3(1.0f, 1.0f, track_length / 2.0f));
		}

		paths.insertLast(new_path);
	}

	void PrepareSignals(Intersection@ exclude){
		int exclude_index = connections.findByRef(exclude);
		array<int> choices;


		for(int i = 0; i < int(turn_signal_objects.size()); i++){
			turn_signal_objects[i].SetTint(signal_red);
			if(exclude_index == i){
				turn_signal_objects[i].SetEnabled(false);
			}else{
				signal_animations.insertLast(SignalAnimation(turn_signal_objects[i], show_animation));
				choices.insertLast(i);
			}
		}

		//One path is chosen by default.
		chosen_path = choices[rand() % choices.size()];
		turn_signal_objects[chosen_path].SetTint(signal_green);
	}

	void HideSignals(){
		for(uint i = 0; i < turn_signal_objects.size(); i++){
			signal_animations.insertLast(SignalAnimation(turn_signal_objects[i], hide_animation));
		}
	}

	void SignalCheck(int id){
		bool change_path = false;
		//Check if the id is one of the signal objects.
		for(uint i = 0; i < turn_signal_objects.size(); i++){
			if(turn_signal_objects[i].GetID() == id){
				chosen_path = i;
				change_path = true;
				signal_animations.insertLast(SignalAnimation(turn_signal_objects[i], turn_animation));
				break;
			}
		}

		if(change_path){
			for(int i = 0; i < int(turn_signal_objects.size()); i++){
				if(i == chosen_path){
					turn_signal_objects[i].SetTint(signal_green);
				}else{
					turn_signal_objects[i].SetTint(signal_red);
				}
			}
		}
	}
}

IMGUI@ imGUI;
bool reset_allowed = true;
bool show_ui = false;
float time = 0.0f;
float no_win_time = 0.0f;
string level_name;
int in_victory_trigger = 0;
const float _reset_delay = 4.0f;
float reset_timer = _reset_delay;
IMContainer@ top_ribbon;
IMContainer@ bottom_ribbon;
array<string> mission_objectives;
array<string> mission_objective_colors;
bool success = true;
int controller_id = 0;
bool show_red = false;

float fade_out_start;
float fade_out_end = -1.0f;

float fade_in_start;
float fade_in_end = -1.0f;

bool resetting = false;

FontSetup greenValueFont("edosz", 65, HexColor("#0f0"));
FontSetup redValueFont("edosz", 65, HexColor("#f00"));
FontSetup tealValueFont("edosz", 65, HexColor("#028482"));

MusicLoad ml("Data/Music/receiver_music.xml");

class Bullet{
	float bullet_speed = 433.0f;
	float max_bullet_distance = 150.0f;
	float distance_done = 0.0f;
	vec3 direction;
	vec3 starting_position;
	float timer;
	bool done;

	Bullet(vec3 _starting_point, vec3 _direction){
		starting_position = _starting_point;
		direction = _direction;
	}

	void SetStartingPoint(vec3 new_starting_point){
		distance_done += distance(starting_position, new_starting_point);
		starting_position = new_starting_point;
	}

	void UpdateFlight(){
		vec3 start = starting_position;
		vec3 end = starting_position + (direction * bullet_speed * time_step);
		done = CheckBulletCollisions(start, end);

		if(distance_done > max_bullet_distance){
			done = true;
		}

		SetStartingPoint(end);
	}
}

void Init(string p_level_name) {
	level_name = p_level_name;
	@imGUI = CreateIMGUI();
}

void SetWindowDimensions(int w, int h)
{
	imGUI.doScreenResize();
}

void AddRibbonElements(IMContainer@ container, int amount, bool flip){
	float starting_x = -600;
	for(int i = 0; i < amount; i++){
		IMImage ribbon_element("Textures/ui/challenge_mode/red_gradient_border_c.tga");
		ribbon_element.setClip(false);
		ribbon_element.setSize(vec2(600.0, 600.0));
		if (flip){
			ribbon_element.setRotation(180.0f);
		}
		container.addFloatingElement(ribbon_element, "element" + i, vec2(starting_x + 600.0f * i, 0.0f));
	}
}

void ScriptReloaded() {
	Log(info, "Script reloaded!\n");
}

SavedLevel@ GetSave() {
	SavedLevel @saved_level;
	if(save_file.GetLoadedVersion() == 1 && save_file.SaveExist("","",level_name)) {
		@saved_level = save_file.GetSavedLevel(level_name);
		saved_level.SetKey(GetCurrentLevelModsourceID(),"challenge_level",level_name);
	} else {
		@saved_level = save_file.GetSave(GetCurrentLevelModsourceID(),"challenge_level",level_name);
	}
	return saved_level;
}

class Achievements {
	bool flawless_;
	bool no_first_strikes_;
	bool no_counter_strikes_;
	bool no_kills_;
	bool no_alert_;
	bool injured_;
	float total_block_damage_;
	float total_damage_;
	float total_blood_loss_;
	void Init() {
		flawless_ = true;
		no_first_strikes_ = true;
		no_counter_strikes_ = true;
		no_kills_ = true;
		no_alert_ = true;
		injured_ = false;
		total_block_damage_ = 0.0f;
		total_damage_ = 0.0f;
		total_blood_loss_ = 0.0f;
	}
	Achievements() {
		Init();
	}
	void UpdateDebugText() {
		DebugText("achmt0", "Flawless: "+flawless_, 0.5f);
		DebugText("achmt1", "No Injuries: "+!injured_, 0.5f);
		DebugText("achmt2", "No First Strikes: "+no_first_strikes_, 0.5f);
		DebugText("achmt3", "No Counter Strikes: "+no_counter_strikes_, 0.5f);
		DebugText("achmt4", "No Kills: "+no_kills_, 0.5f);
		DebugText("achmt5", "No Alerts: "+no_alert_, 0.5f);
		DebugText("achmt6", "Time: "+no_win_time, 0.5f);
		//DebugText("achmt_damage0", "Block damage: "+total_block_damage_, 0.5f);
		//DebugText("achmt_damage1", "Impact damage: "+total_damage_, 0.5f);
		//DebugText("achmt_damage2", "Blood loss: "+total_blood_loss_, 0.5f);

		SavedLevel @level = GetSave();
		DebugText("saved_achmt0", "Saved Flawless: "+(level.GetValue("flawless")=="true"), 0.5f);
		DebugText("saved_achmt1", "Saved No Injuries: "+(level.GetValue("no_injuries")=="true"), 0.5f);
		DebugText("saved_achmt2", "Saved No Kills: "+(level.GetValue("no_kills")=="true"), 0.5f);
		DebugText("saved_achmt3", "Saved No Alert: "+(level.GetValue("no_alert")=="true"), 0.5f);
		DebugText("saved_achmt4", "Saved Time: "+level.GetValue("time"), 0.5f);
	}
	void Save() {
		SavedLevel @saved_level = GetSave();
		if(flawless_) saved_level.SetValue("flawless","true");
		if(!injured_) saved_level.SetValue("no_injuries","true");
		if(no_kills_) saved_level.SetValue("no_kills","true");
		if(no_alert_) saved_level.SetValue("no_alert","true");
		string time_str = saved_level.GetValue("time");
		if(time_str == "" || no_win_time < atof(saved_level.GetValue("time"))){
			saved_level.SetValue("time", ""+no_win_time);
		}
		save_file.WriteInPlace();
	}
	void PlayerWasHit() {
		flawless_ = false;
	}
	void PlayerWasInjured() {
		injured_ = true;
		flawless_ = false;
	}
	void PlayerAttacked() {
		no_first_strikes_ = false;
	}
	void PlayerSneakAttacked() {
		no_first_strikes_ = false;
	}
	void PlayerCounterAttacked() {
		no_counter_strikes_ = false;
	}
	void EnemyDied() {
		no_kills_ = false;
	}
	void EnemyAlerted() {
		no_alert_ = false;
	}
	void PlayerBlockDamage(float val) {
		total_block_damage_ += val;
		PlayerWasHit();
	}
	void PlayerDamage(float val) {
		total_damage_ += val;
		PlayerWasInjured();
	}
	void PlayerBloodLoss(float val) {
		total_blood_loss_ += val;
		PlayerWasInjured();
	}
	bool GetValue(const string &in key){
		if(key == "flawless"){
			return flawless_;
		} else if(key == "no_kills"){
			return no_kills_;
		} else if(key == "no_injuries"){
			return !injured_;
		}
		return false;
	}
};

Achievements achievements;

bool HasFocus(){
	return show_ui;
}

void Reset(){
	time = 0.0f;
	reset_allowed = true;
	show_red = false;
	fade_in_start = the_time;
	fade_in_end = the_time+0.4f;
	reset_timer = _reset_delay;

	/* const float fade_time = 0.2f;
	fade_out_start = the_time;
	fade_out_end = the_time+fade_time;
	fade_in_start = the_time+fade_time;
	fade_in_end = the_time+fade_time*2.0f; */

	achievements.Init();
}

void DrawGUI() {
	if(EditorModeActive()){
		return;
	}

	if(show_red){
		fade_in_start = the_time;
		fade_in_end = the_time + 0.2;
	}

	if(fade_out_end != -1.0f){
		float blackout_amount = min(1.0, 1.0 - ((fade_out_end - the_time) / (fade_out_end - fade_out_start)));
		HUDImage @blackout_image = hud.AddImage();
		blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
		blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
		blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
		blackout_image.position.z = -2.0f;
		blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
		blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
		if(fade_out_end <= the_time){
			fade_out_end = -1.0f;
		}
	} else if(fade_in_end != -1.0f && show_red){
		float blackout_amount = min(0.5, ((fade_in_end - the_time) / (fade_in_end - fade_in_start)));
		HUDImage @blackout_image = hud.AddImage();
		blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
		blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
		blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
		blackout_image.position.z = -2.0f;
		blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
		blackout_image.color = vec4(1.0f,0.0f,0.0f,blackout_amount);
		if(fade_in_end <= the_time){
			fade_in_end = -1.0f;
		}
	}
}

void AchievementEvent(string event_str){
	if(event_str == "player_was_hit"){
		achievements.PlayerWasHit();
	} else if(event_str == "player_was_injured"){
		achievements.PlayerWasInjured();
	} else if(event_str == "player_attacked"){
		achievements.PlayerAttacked();
	} else if(event_str == "player_sneak_attacked"){
		achievements.PlayerSneakAttacked();
	} else if(event_str == "player_counter_attacked"){
		achievements.PlayerCounterAttacked();
	} else if(event_str == "enemy_died"){
		achievements.EnemyDied();
	} else if(event_str == "enemy_alerted"){
		achievements.EnemyAlerted();
	}
}

void AchievementEventFloat(string event_str, float val){
	if(event_str == "player_block_damage"){
		achievements.PlayerBlockDamage(val);
	} else if(event_str == "player_damage"){
		achievements.PlayerDamage(val);
	} else if(event_str == "player_blood_loss"){
		achievements.PlayerBloodLoss(val);
	}
}

string StringFromFloatTime(float time){
	string time_str;
	int minutes = int(time) / 60;
	int seconds = int(time)-minutes*60;
	time_str += minutes + ":";
	if(seconds < 10){
		time_str += "0";
	}
	time_str += seconds;
	return time_str;
}

void Update() {
	if(!post_init_done){
		PostInit();
	}

	time += time_step;

	for(uint i = 0; i < intersections.size(); i++){
		intersections[i].Update();
	}

	ProcessMessages();
	UpdateBullets();
	UpdateMusic();
	// Do the general GUI updating
	imGUI.update();
	resetting = false;
}

void UpdateBullets(){
	for(uint i = 0; i < bullets.size(); i++){
		Bullet@ bullet = bullets[i];

		bullet.UpdateFlight();

		if(bullet.done){
			bullets.removeAt(i);
			return;
		}
	}
}

bool CheckBulletCollisions(vec3 start, vec3 &inout end){
	CollisionPoint barrel_point;
	col.GetObjRayCollision(start, end);

	if(sphere_col.NumContacts() != 0){
		barrel_point = sphere_col.GetContact(sphere_col.NumContacts() - 1);
		Log(warning, "found id " + barrel_point.id);
		BarrelCheck(barrel_point.id);
	}

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
		point = sphere_col.GetContact(sphere_col.NumContacts() - 1);
		char_id = point.id;
	}

	if(char_id != -1){
		MovementObject@ char = ReadCharacterID(char_id);

		if(!char.is_player){
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
	}

	return colliding;
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

void ProcessMessages(){
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "quit" ) {

		} else if( message.name == "retry" ) {
			imGUI.clear();
			show_ui = false;
		}
	}
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "reset"){
		resetting = true;
		Reset();
	}else if(token == "add_bullet"){
		vec3 spawn_point;
		vec3 forward;

		token_iter.FindNextToken(msg);
		spawn_point.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		spawn_point.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		spawn_point.z = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		forward.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		forward.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		forward.z = atof(token_iter.GetToken(msg));

		/* Log(warning, "Adding bullet"); */
		bullets.insertLast(Bullet(spawn_point, forward));
	}else if(token == "show_red"){
		token_iter.FindNextToken(msg);
		show_red = token_iter.GetToken(msg) == "true";
	}
}

vec2 top_ribbon_position(0.0f, 0.0f);
vec2 bottom_ribbon_position(0.0f, 0.0f);
float move_speed = 50.0f;

void UpdateRibbons(){
	if(!show_ui){
		return;
	}
	top_ribbon_position.x = top_ribbon_position.x + time_step * move_speed;
	bottom_ribbon_position.x = bottom_ribbon_position.x - time_step * move_speed;

	if(top_ribbon_position.x > 600.0){
		top_ribbon_position.x = 0.0f;
	}
	if(bottom_ribbon_position.x < -600.0){
		bottom_ribbon_position.x = 0.0f;
	}
	top_ribbon.moveElement("top_ribbon_holder", top_ribbon_position);
	bottom_ribbon.moveElement("bottom_ribbon_holder", bottom_ribbon_position);
}

void UpdateMusic() {
	int player_id = GetPlayerCharacterID();
	if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
		PlaySong("receiver_death");
		return;
	}
	PlaySong("receiver_music");
}

void PostInit(){
	//Get the base height of the terrain to minimize collision check length.
	vec3 collision_point = col.GetRayCollision(vec3(0.0f, 1000.0f, 0.0f), vec3(0.0f, -1000.0f, 0.0f));
	base_height = collision_point.y;
	CreateTrack();
	CreateEnvironment();
	SpawnBarrels();
	post_init_done = true;
}

void CreateTrack(){
	for(uint i = 0; i < num_intersections; i++){
		intersections.insertLast(Intersection());
	}

	for(uint i = 0; i < intersections.size(); i++){
		intersections[i].SetConnected();
	}
}

void CreateEnvironment(){
	for(uint i = 0; i < environment_assets.size(); i++){
		for(int j = 0; j < int(environment_assets[i].amount * env_objects_mult); j++){
			AttemptAssetPlacement(environment_assets[i].path, environment_assets[i].min_object_distance);
		}
	}
}

void SpawnBarrels(){
	for(int i = 0; i < num_barrels; i++){
		Object@ new_barrel = AttemptAssetPlacement("Data/Objects/barrel.xml", 10.0f);
		barrels.insertLast(new_barrel);
	}
}


Object@ AttemptAssetPlacement(string path, float min_object_distance){
	float random_x = RangedRandomFloat(-random_range, random_range);
	float random_z = RangedRandomFloat(-random_range, random_range);

	vec3 chosen_position = col.GetRayCollision(vec3(random_x, base_height + height_range, random_z), vec3(random_x, base_height - height_range, random_z));
	for(uint i = 0; i < occupied_locations.size(); i++){
		//Try to place it again if the location is occupied.
		vec3 flat_location = vec3(occupied_locations[i].x, 0.0f, occupied_locations[i].z);
		if(distance(flat_location, vec3(chosen_position.x, 0.0f, chosen_position.z)) < min_object_distance){
			return AttemptAssetPlacement(path, min_object_distance);
		}
	}

	int asset_id = CreateObject(path);
	Object@ asset_object = ReadObjectFromID(asset_id);
	vec3 bounds = asset_object.GetBoundingBox();
	//Make sure the bounds are not zero.
	if(bounds == vec3()){bounds = vec3(1.0);}
	float random_size = RangedRandomFloat(0.5f, 1.5f);
	asset_object.SetTranslation(chosen_position + vec3(0.0, (bounds.y * 0.4f) * random_size, 0.0));
	asset_object.SetScale(vec3(random_size));
	occupied_locations.insertLast(chosen_position);
	quaternion new_rotation = quaternion(vec4(0.0f,1.0,0.0f, RangedRandomFloat(-1, 1)));
	asset_object.SetRotation(new_rotation);

	return asset_object;
}

void BarrelCheck(int id){
	Log(warning, "id  " + id);
	for(uint i = 0; i < barrels.size(); i++){
		if(barrels[i].GetID() == id){
			vec3 explosion_point = barrels[i].GetTranslation();

			int num_sparks = 60;
			float speed = 20.0f;
			for(int j = 0; j < num_sparks; j++){
				MakeParticle("Data/Particles/explosion_fire.xml", explosion_point, vec3(RangedRandomFloat(-speed,speed),
																						RangedRandomFloat(-speed,speed),
																						RangedRandomFloat(-speed,speed)));
			}

			int num_smoke = 10;
			for(int j = 0; j < num_smoke; j++){
				MakeParticle("Data/Particles/explosion_smoke.xml", explosion_point, vec3(	RangedRandomFloat(-speed,speed),
																							RangedRandomFloat(-speed,speed),
																							RangedRandomFloat(-speed,speed)));
			}

			vec3 forward = normalize(explosion_point - camera.GetPos());
			vec3 forward_offset = forward * 5.0;
			vec3 spawn_point = camera.GetPos() + forward_offset;
			PlaySound("Data/Sounds/explosion.wav", spawn_point);
			TimedSlowMotion(0.1f, 0.7f, 0.05f);

			barrels.removeAt(i);
			QueueDeleteObjectID(id);
			IMText @barrel_counter = cast<IMText>(barrel_counter_holder.getContents());
			if(barrels.size() == 0){
				barrel_counter.setText("You won a turkey dinner or whatever!");
			}else{
				barrel_counter.setText("Barrels " + (num_barrels - barrels.size()) + "/" + num_barrels);
			}
			break;
		}
	}
}
