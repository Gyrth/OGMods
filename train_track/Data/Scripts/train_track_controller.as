
IMGUI@ imGUI;
FontSetup default_font("arial", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0f;
array<Intersection@> intersections;
string debug_cube_path = "Data/Objects/block.xml";
string track_segment_path = "Data/Objects/track_segment.xml";
bool post_init_done = false;
uint num_intersections = 50;
float height_range = 100.0f;
float random_range = 400.0f;

const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);

array<vec3> occupied_locations;
array<EnvironmentAsset@> environment_assets = {	EnvironmentAsset("Data/Prototypes/OG/elm_tree_large.xml", 25.0f, 50),
												EnvironmentAsset("Data/Prototypes/OG/elm_tree_small.xml", 25.0f, 50),
												EnvironmentAsset("Data/Prototypes/OG/PineTree1_A.xml", 15.0f, 60),
												EnvironmentAsset("Data/Prototypes/OG/PineTree1_B.xml", 15.0f, 60),
												EnvironmentAsset("Data/Prototypes/OG/PineTree2_A.xml", 15.0f, 60),
												EnvironmentAsset("Data/Prototypes/OG/PineTree2_B.xml", 15.0f, 60),
												EnvironmentAsset("Data/Objects/Plants/Trees/temperate/small_deciduous.xml", 10.0f, 30),
												EnvironmentAsset("Data/Objects/Plants/Trees/temperate/green_bush.xml", 2.0f, 75)};

MineCart@ player = MineCart();

class MineCart{
	Object@ cart;
	string cart_path = "Data/Objects/mine_cart.xml";
	Intersection@ next_intersection;
	Intersection@ previous_intersection;
	array<vec3> track_positions;
	int track_index = 0;
	float base_speed = 10.0f;
	float speed = base_speed;
	float max_subtracted_speed = base_speed - 0.5f;
	float max_added_speed = base_speed * 15.0f;
	vec3 position;

	MineCart(){

	}

	void PostInit(){
		@next_intersection = intersections[0];
		track_positions = next_intersection.paths[0];
		@previous_intersection = next_intersection.connections[0];
		int cart_id = CreateObject(cart_path);
		@cart = ReadObjectFromID(cart_id);
		cart.SetCollisionEnabled(false);

		position = track_positions[track_index];
		cart.SetTranslation(position);
	}

	void Update(){
		//Increase or decrease speed based on steepness.

		speed = mix(speed, base_speed + max(-max_subtracted_speed, min(max_added_speed, ((position.y - track_positions[track_index].y) * 25.0f))), time_step * 3.0f);

		if(distance(position, track_positions[track_index]) < 0.1f){
			track_index += 1;
			//Check if the cart is at the end of the track.
			if(track_index == int(track_positions.size())){
				track_index = 0;
				next_intersection.RequestNextIntersection(this, previous_intersection);
			}
		}

		vec3 direction = normalize(track_positions[track_index] - position);
		DebugDrawWireSphere(track_positions[track_index], 1.5, vec3(0.0, 0.0, 1.0), _delete_on_update);
		position += direction * speed * time_step;
		cart.SetTranslation(position);

		/* cart.SetTranslationRotationFast(position, quaternion()); */

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
		cart.SetRotation(mix(cart.GetRotation(), rot_y * rot_x * rot_z, time_step * 5.0f));
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
	string turn_signal_path = "Data/Objects/block.xml";

	Intersection(){
		float random_x = RangedRandomFloat(-random_range, random_range);
		float random_z = RangedRandomFloat(-random_range, random_range);

		position = col.GetRayCollision(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z));
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

		/* Log(warning, "sorted_intersections " + sorted_intersections.size());
		for(uint j = 0; j < sorted_intersections.size(); j++){
			Log(warning, "distance " + distance(position, sorted_intersections[j].position));
		} */

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
				/* Log(warning, "Num contacts " + sphere_col.NumContacts());
				Log(warning, "x " + point.normal.x + " y " + point.normal.y + " z " + point.normal.z); */
				/* break; */
			}
		}

		paths.insertLast(new_path);
	}

	void CreateTurnSignal(){
		int turn_signal_id = CreateObject(turn_signal_path);
		Object@ turn_signal_obj = ReadObjectFromID(turn_signal_id);
		turn_signal_objects.insertLast(turn_signal_obj);

		vec3 direction = normalize(connections[connections.size() - 1].position - position);
		turn_signal_obj.SetTranslation(position + (direction * 4.0f) + vec3(0.0f, 4.0f, 0.0f));
		turn_signal_obj.SetCollisionEnabled(false);
	}

	void RequestNextIntersection(MineCart@ cart, Intersection@ exclude){
		array<Intersection@> choices = connections;
		for(uint i = 0; i < choices.size(); i++){
			if(choices[i] is exclude){
				choices.removeAt(i);
				Log(warning, "Remove at " + i);
				break;
			}
		}

		@cart.next_intersection = choices[rand() % choices.size()];
		@cart.previous_intersection = @this;

		for(uint i = 0; i < cart.next_intersection.connections.size(); i++){
			if(cart.next_intersection.connections[i] is this){
				cart.track_positions = cart.next_intersection.paths[i];
				break;
			}
		}
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

	for(uint i = 0; i < intersections.size() - 1; i++){
		intersections[i].Update();
		intersections[i].DrawDebug();
	}

	player.Update();
	player.DrawDebug();
	UpdateCamera();
}

void PostInit(){
	CreateTrack();
	/* CreateEnvironment(); */
	player.PostInit();
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
	camera.SetPos(player.position + vec3(15.0f, 10.0f, 0.0f));
	camera.LookAt(player.position);
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return EditorModeActive()?false:true;
}
