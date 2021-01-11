
IMGUI@ imGUI;
FontSetup default_font("arial", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0f;
array<Intersection@> intersections;
string debug_cube_path = "Data/Objects/block.xml";
string track_segment_path = "Data/Objects/track_segment.xml";
bool post_init_done = false;
uint num_intersections = 50;
float height_range = 1000.0f;
float random_range = 400.0f;

const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);

class Intersection{
	uint max_connections = 3;
	vec3 position;
	int num_paths;
	array<vec3> paths;
	Object@ debug_cube;

	array<Intersection@> connections;

	Intersection(){
		float random_x = RangedRandomFloat(-random_range, random_range);
		float random_z = RangedRandomFloat(-random_range, random_range);

		position = col.GetRayCollision(vec3(random_x, height_range, random_z), vec3(random_x, -height_range, random_z));
		int debug_cube_id = CreateObject(debug_cube_path);
		@debug_cube = ReadObjectFromID(debug_cube_id);
		debug_cube.SetTranslation(position + vec3(0.0, 2.0, 0.0));
		debug_cube.SetTint(vec3());
		debug_cube.SetScale(vec3(1.0, 10.0, 1.0));
	}

	void SetConnected(){
		array<Intersection@> sorted_intersections;
		for(uint i = 0; i < intersections.size(); i++){
			bool added = false;

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
			}else{
				connections.insertLast(sorted_intersections[i]);
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
		CreateTrack(peer, this);
		connections.insertLast(peer);
		return true;
	}

	void DrawDebug(){
		vec3 extra_height = vec3(0.0, 10.0, 0.0);
		for(uint i = 0; i < connections.size(); i++){
			DebugDrawLine(connections[i].position + extra_height, position + extra_height, vec3(0.0, 0.0, 1.0), _delete_on_update);
		}
	}
}

void CreateTrack(Intersection@ a, Intersection@ b){
	float intersection_distance = distance(a.position, b.position);
	int segments_needed = int(intersection_distance / 2.0f) + 1;
	/* Log(warning, "segments_needed " + segments_needed); */

	for(int i = 0; i < segments_needed; i++){
		vec3 location = mix(a.position, b.position, float(i) / float(segments_needed));
		location = col.GetRayCollision(vec3(location.x, height_range, location.z), vec3(location.x, -height_range, location.z));
		col.GetSweptSphereCollision(vec3(location.x, height_range, location.z), vec3(location.x, -height_range, location.z), 0.001f);
		int obj_id = CreateObject(track_segment_path);
		Object@ track_obj = ReadObjectFromID(obj_id);

		track_obj.SetTranslation(location);

		for(int j = 0; j < sphere_col.NumContacts(); j++){
			CollisionPoint point = sphere_col.GetContact(j);

			if(length(point.normal) < 0.1f){continue;}

			vec3 up = point.normal;
			vec3 front = cross(up, normalize(b.position - a.position));

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
		intersections[i].DrawDebug();
	}
}

void PostInit(){
	CreateTrack();
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

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return false;
}
