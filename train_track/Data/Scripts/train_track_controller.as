//UI variables..----------------------------------------------------------------------------------------------------------------------------
IMGUI@ imGUI;
FontSetup default_font("arial", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0f;

//Intersection, track and environment variables.----------------------------------------------------------------------------------------------
array<Intersection@> intersections;
string track_segment_path = "Data/Objects/track_segment.xml";
uint num_intersections = 75;
float height_range = 500.0f;
float random_range = 400.0f;
array<vec3> occupied_locations;
MineCart@ player = MineCart();
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

class MineCart{
	Object@ cart;
	string cart_path = "Data/Objects/mine_cart.xml";
	Intersection@ next_intersection;
	Intersection@ previous_intersection;
	array<vec3> track_positions;
	int track_index = 0;
	float base_speed = 15.0f;
	float speed = base_speed;
	float max_subtracted_speed = base_speed - 7.0f;
	float max_added_speed = 10.0f;
	vec3 position;
	int wheel_sound_id;

	MineCart(){

	}

	void PostInit(){
		@next_intersection = intersections[0];
		track_positions = next_intersection.paths[0];
		@previous_intersection = next_intersection.connections[0];
		next_intersection.PrepareSignals(previous_intersection);
		int cart_id = CreateObject(cart_path);
		@cart = ReadObjectFromID(cart_id);
		cart.SetCollisionEnabled(false);
		cart.SetEnabled(false);

		position = track_positions[track_index];
		cart.SetTranslation(position + vec3(0.0f, -3.0f, 0.0f));
		wheel_sound_id = PlaySoundLoopAtLocation("Data/Sounds/wheels_turning.wav", position, 1.0);
	}

	void Update(){
		if((track_index > 0 && distance(track_positions[track_index - 1], position) > distance(track_positions[track_index - 1], track_positions[track_index])) ||
			distance(position, track_positions[track_index]) < 0.1f){
			track_index += 1;
			//Check if the cart is at the end of the track.
			if(track_index == int(track_positions.size())){
				track_index = 0;
				next_intersection.RequestNextIntersection(this);
				previous_intersection.HideSignals();
				next_intersection.PrepareSignals(previous_intersection);
			}
		}

		//Increase or decrease speed based on steepness.
		float target_speed = ((position.y - track_positions[track_index].y) * 50.0f);
		float clamped_speed = base_speed + max(-max_subtracted_speed, min(max_added_speed, target_speed));
		Log(warning, "clamped_speed " + clamped_speed);
		speed = mix(speed, clamped_speed, time_step * 0.22f);
		Log(warning, "speed " + speed);

		vec3 direction = normalize(track_positions[track_index] - position);
		position += direction * speed * time_step;
		/* cart.SetTranslation(position); */

		vec3 up = vec3(0.0f, 1.0f, 0.0f);
		vec3 front = direction;

		vec3 new_rotation;
		new_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
		new_rotation.x = asin(front[1]) * -180.0f / PI;
		vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
		vec3 expected_up = normalize(cross(expected_right, front));
		new_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

		quaternion rot_y(vec4(0, 1, 0, new_rotation.y * deg2rad));
		quaternion rot_x(vec4(1, 0, 0, new_rotation.x * deg2rad));
		quaternion rot_z(vec4(0, 0, 1, new_rotation.z * deg2rad));
		quaternion slerped_rotation = mix(cart.GetRotation(), rot_y * rot_x * rot_z, time_step * 5.0f);
		/* cart.SetRotation(slerped_rotation); */

		cart.SetTranslationRotationFast(position, slerped_rotation);

		float gain = (speed - base_speed) * 0.15 + 1.0f;
		SetSoundGain(wheel_sound_id, gain);
		/* SetSoundPitch(wheel_sound_id, gain); */
		SetSoundPosition(wheel_sound_id, camera.GetPos() + vec3(0.0f, -3.0f, 0.0f));
	}

	void DrawDebug(){
		for(uint i = 0; i < track_positions.size(); i++){
			DebugDrawWireSphere(track_positions[i], 1.0, vec3(1.0, 0.0, 0.0), _delete_on_update);
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
	uint max_connections = 3;
	vec3 position;
	Object@ rotating_track;
	array<Intersection@> connections;
	array<array<vec3>> paths;
	array<Object@> turn_signal_objects;
	string turn_signal_path = "Data/Objects/signal.xml";
	int chosen_path;
	float min_intersection_distance = 50.0f;

	Intersection(){
		AttemptIntersectionPlacement();
	}

	void AttemptIntersectionPlacement(){
		float random_x = RangedRandomFloat(-random_range, random_range);
		float random_z = RangedRandomFloat(-random_range, random_range);

		vec3 chosen_position;

		col.GetSweptCylinderCollisionDoubleSided(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z), 0.1f, 1.0f);
		for(int j = 0; j < sphere_col.NumContacts(); j++){
			CollisionPoint point = sphere_col.GetContact(j);

			if(length(point.normal) < 0.1f){continue;}
			chosen_position = sphere_col.position;
			for(uint i = 0; i < occupied_locations.size(); i++){
				//Try to place it again if the location is occupied.
				vec3 flat_location = vec3(occupied_locations[i].x, 0.0f, occupied_locations[i].z);
				if(distance(flat_location, vec3(chosen_position.x, 0.0f, chosen_position.z)) < min_intersection_distance){
					AttemptIntersectionPlacement();
					return;
				}
			}
			break;
		}


		position = col.GetRayCollision(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z));
		occupied_locations.insertLast(position);
		int rotating_track_id = CreateObject(track_segment_path);
		@rotating_track = ReadObjectFromID(rotating_track_id);
		rotating_track.SetCollisionEnabled(false);
		rotating_track.SetTranslation(position);
	}

	void Update(){
		float y_rotation = 360.0f * sin(2 * PI * 0.15 * the_time + 0.0);
		quaternion rot_y(vec4(0, 1, 0, y_rotation * deg2rad));
		rotating_track.SetTranslationRotationFast(position, rot_y);
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

		CreateTurnSignal();
		peer.CreateTurnSignal();

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
		/* Log(warning, "segments_needed " + segments_needed); */
		array<vec3> new_path;

		for(int i = 1; i < segments_needed; i++){
			vec3 location = mix(peer.position, position, float(i) / float(segments_needed));
			location = col.GetRayCollision(vec3(location.x, height_range, location.z), vec3(location.x, -height_range, location.z));
			col.GetSweptSphereCollision(vec3(location.x, height_range, location.z), vec3(location.x, -height_range, location.z), 0.001f);
			int obj_id = CreateObject(track_segment_path);
			Object@ track_obj = ReadObjectFromID(obj_id);

			track_obj.SetTranslation(location);
			occupied_locations.insertLast(location);
			new_path.insertLast(location);

			for(int j = 0; j < sphere_col.NumContacts(); j++){
				CollisionPoint point = sphere_col.GetContact(j);

				if(length(point.normal) < 0.1f){continue;}

				vec3 up = point.normal;
				vec3 front = cross(up, normalize(position - peer.position));

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
			}
		}

		paths.insertLast(new_path);
	}

	void CreateTurnSignal(){
		int turn_signal_id = CreateObject(turn_signal_path);
		Object@ turn_signal_obj = ReadObjectFromID(turn_signal_id);
		turn_signal_objects.insertLast(turn_signal_obj);
		vec3 up = vec3(0.0f, 1.0f, 0.0);

		vec3 direction = normalize(connections[connections.size() - 1].position - position);
		vec3 offset = cross(direction, up);
		turn_signal_obj.SetTranslation(position + offset + (direction * 4.0f) + vec3(0.0f, 1.0f, 0.0f));
		turn_signal_obj.SetCollisionEnabled(false);
		turn_signal_obj.SetEnabled(false);

		vec3 front = vec3(direction.x, 0.0f, direction.z);

		vec3 new_rotation;
		new_rotation.y = atan2(front.x, front.z) * 180.0f / PI;
		new_rotation.x = asin(front[1]) * -180.0f / PI;
		vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
		vec3 expected_up = normalize(cross(expected_right, front));
		new_rotation.z = atan2(dot(up,expected_right), dot(up, expected_up)) * 180.0f / PI;

		quaternion rot_y(vec4(0, 1, 0, new_rotation.y * deg2rad));
		quaternion rot_x(vec4(1, 0, 0, new_rotation.x * deg2rad));
		quaternion rot_z(vec4(0, 0, 1, new_rotation.z * deg2rad));
		turn_signal_obj.SetRotation(rot_y * rot_x * rot_z);
	}

	void RequestNextIntersection(MineCart@ cart){
		@cart.next_intersection = connections[chosen_path];
		@cart.previous_intersection = @this;

		for(uint i = 0; i < cart.next_intersection.connections.size(); i++){
			if(cart.next_intersection.connections[i] is this){
				cart.track_positions = cart.next_intersection.paths[i];
				break;
			}
		}
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

class Bullet{
	float bullet_speed = 433.0f;
	float max_bullet_distance = 1500.0f;
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
		done = CheckCollisions(start, end);
		if(distance_done > max_bullet_distance){
			done = true;
		}
		DebugDrawLine(start, end, vec3(0.5), vec3(0.5), _fade);
		SetStartingPoint(end);
	}
}

void Init(string str){
	@imGUI = CreateIMGUI();
	CreateIMGUIContainers();
}

void CreateIMGUIContainers(){
	imGUI.setup();
	imGUI.setBackgroundLayers(1);
	imGUI.getMain().setZOrdering(-1);
}

void SetWindowDimensions(int width, int height){
	imGUI.clear();
	CreateIMGUIContainers();
}

void PostScriptReload(){
	imGUI.clear();
	CreateIMGUIContainers();
	SetGrabMouse(true);
}

void DrawGUI(){
	imGUI.render();
	HUDImage @blackout_image = hud.AddImage();
	blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
	blackout_image.position.y = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.x = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.z = -2.0f;
	blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight()) * 2.0f;
	blackout_image.color = vec4(0.0f, 0.0f, 0.0f, blackout_amount);

	vec2 metrics = screenMetrics.getMetrics();
	vec2 middle_screen = vec2(metrics.x / 2.0f, metrics.y / 2.0f);

	//Vertical line.
	imGUI.drawBox(middle_screen - vec2(crosshair_thickness / 2.0f, crosshair_length / 2.0f), vec2(crosshair_thickness, crosshair_length), crosshair_color, 0);
	//Horizontal line.
	imGUI.drawBox(middle_screen - vec2(crosshair_length / 2.0f, crosshair_thickness / 2.0f), vec2(crosshair_length, crosshair_thickness), crosshair_color, 0);
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);

	/* Log(warning, token); */
	if(token == "animating_camera"){
		token_iter.FindNextToken(msg);
		string enable = token_iter.GetToken(msg);
		token_iter.FindNextToken(msg);
		string hotspot_id = token_iter.GetToken(msg);
	}
}


void Update(){
	if(!post_init_done){
		PostInit();
	}

	while(imGUI.getMessageQueueSize() > 0 ){
		IMMessage@ message = imGUI.getNextMessage();
	}

	imGUI.update();

	for(uint i = 0; i < intersections.size(); i++){
		intersections[i].Update();
		/* intersections[i].DrawDebug(); */
	}

	for(uint i = 0; i < signal_animations.size(); i++){
		signal_animations[i].Update();
		if(signal_animations[i].done){
			signal_animations.removeAt(i);
			i--;
		}
	}

	player.Update();
	/* player.DrawDebug(); */
	UpdateCamera();
	UpdateShooting();
	UpdateBullets();
}

void UpdateShooting(){
	if(!DialogueCameraControl()){return;}
	if(GetInputPressed(0, "attack")){
		Shoot();
	}
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

bool CheckCollisions(vec3 start, vec3 &inout end){
	bool colliding = false;
	col.GetObjRayCollision(start, end);
	vec3 direction = normalize(end - start);
	CollisionPoint point;

	if(sphere_col.NumContacts() != 0){
		point = sphere_col.GetContact(sphere_col.NumContacts() - 1);
		MakeMetalSparks(point.position);
		vec3 facing = camera.GetFacing();
		MakeParticle("Data/Particles/gun_decal.xml", point.position - facing, facing * 10.0f);
		string path;
		switch(rand() % 3) {
			case 0:
				path = "Data/Sounds/rico1.wav"; break;
			case 1:
				path = "Data/Sounds/rico2.wav"; break;
			default:
				path = "Data/Sounds/rico3.wav"; break;
		}
		PlaySound(path, point.position);
		colliding = true;
		end = point.position;
		player.next_intersection.SignalCheck(point.id);
	}

	col.CheckRayCollisionCharacters(start, end);
	int char_id = -1;
	if(sphere_col.NumContacts() != 0){
		point = sphere_col.GetContact(0);
		char_id = point.id;
	}

	if(char_id != -1){
		MovementObject@ char = ReadCharacterID(char_id);
		char.rigged_object().Stab(sphere_col.GetContact(0).position, direction, 1, 0);
		vec3 force = direction * 15000.0f;
		vec3 hit_pos = vec3(0.0f);
		TimedSlowMotion(0.1f, 0.7f, 0.05f);
		float damage = 0.1;
		char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
					 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
					 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");
		 colliding = true;
		 end = point.position;
	}
	return colliding;
}

void Shoot(){
	camera.FixDiscontinuity();
	vec3 forward = camera.GetFacing();
	vec3 forward_offset = forward * 1.0;
	vec3 spawn_point = camera.GetPos() + forward_offset;

	int smoke_particle_amount = 5;
	vec3 smoke_velocity = forward * 5.0f;
	for(int i = 0; i < smoke_particle_amount; i++){
		MakeParticle("Data/Particles/gun_smoke.xml", spawn_point, smoke_velocity);
	}
	MakeParticle("Data/Particles/gun_fire.xml", spawn_point, forward);
	int sound_id = PlaySound("Data/Sounds/Revolver.wav", spawn_point);
	SetSoundGain(sound_id, 0.15f);

	camera_shake += 0.15f;
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

void PostInit(){
	CreateTrack();
	CreateEnvironment();
	player.PostInit();
	post_init_done = true;
	SetGrabMouse(true);
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
		for(int j = 0; j < environment_assets[i].amount; j++){
			AttemptAssetPlacement(environment_assets[i].path, environment_assets[i].min_object_distance);
		}
	}
}

void AttemptAssetPlacement(string path, float min_object_distance){
	float random_x = RangedRandomFloat(-random_range, random_range);
	float random_z = RangedRandomFloat(-random_range, random_range);

	/* vec3 chosen_position = col.GetRayCollision(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z)); */
	vec3 chosen_position;

	col.GetSweptCylinderCollisionDoubleSided(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z), 0.1f, 1.0f);
	for(int j = 0; j < sphere_col.NumContacts(); j++){
		CollisionPoint point = sphere_col.GetContact(j);

		if(length(point.normal) < 0.1f){continue;}
		chosen_position = sphere_col.position;
		for(uint i = 0; i < occupied_locations.size(); i++){
			//Try to place it again if the location is occupied.
			vec3 flat_location = vec3(occupied_locations[i].x, 0.0f, occupied_locations[i].z);
			if(distance(flat_location, vec3(chosen_position.x, 0.0f, chosen_position.z)) < min_object_distance){
				AttemptAssetPlacement(path, min_object_distance);
				return;
			}
		}
		break;
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
}

void UpdateCamera(){
	if(!DialogueCameraControl()){return;}

	if(GetInputDown(0, "grab")){
		mouse_sensitivity = 0.15f;
	}else{
		mouse_sensitivity = 0.3f;
	}

	cam_rotation_y -= GetLookXAxis(0) * mouse_sensitivity;
	cam_rotation_x -= GetLookYAxis(0) * mouse_sensitivity;

	cam_rotation_x = min(50.0f, max(-50.0f, cam_rotation_x));

	float camera_vibration_mult = 3.0f;
    float camera_vibration = camera_shake * camera_vibration_mult;
	float y_shake = RangedRandomFloat(-camera_vibration, camera_vibration);
	float x_shake = RangedRandomFloat(-camera_vibration, camera_vibration);
	camera.SetYRotation(cam_rotation_y + y_shake);
	camera.SetXRotation(cam_rotation_x + x_shake);
	camera.SetZRotation(cam_rotation_z);
	camera.CalcFacing();

	camera.SetFOV(GetInputDown(0, "grab")?zoomed_fov:current_fov);
	camera.SetPos(player.position + vec3(0.0f, 2.0f, 0.0f));
	camera.SetDistance(0.0f);

	/* ReadCharacter(0).Execute("UpdateCartListener();"); */
	camera_shake *= 0.95f;
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return EditorModeActive()?false:true;
}
