//UI variables..----------------------------------------------------------------------------------------------------------------------------
IMGUI@ imGUI;
FontSetup default_font("arial", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0f;

uint max_connections = 3;
float height_range = 200.0f;
float random_range = 400.0f;
float base_height;
float env_objects_mult;
int chosen_level_index = 0;
array<vec3> occupied_locations;

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


class Bullet{
	float bullet_speed = 20.0f;
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

		MakeParticle("Data/Particles/snowball.xml", start, vec3());

		/* DebugDrawLine(start, end, vec3(0.5), vec3(0.5), _fade); */
		SetStartingPoint(end);
	}
}

void Init(string str){
	@imGUI = CreateIMGUI();
	CreateIMGUIContainers();
}

void CreateIMGUIContainers(){
	imGUI.setHeaderHeight(200);
	imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
	imGUI.setup();

	imGUI.setBackgroundLayers(1);
	imGUI.getMain().setZOrdering(-1);
}

void BuildUI(){
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	imGUI.getHeader().setElement(header_divider);

	// Add it to the main panel of the GUI
	imGUI.getMain().setElement( @mainDiv );

	IMDivider barrel_counter_divider("barrel_counter_divider", DOHorizontal);
	barrel_counter_divider.setBorderColor(vec4(0,1,0,1));
	barrel_counter_divider.setAlignment(CACenter, CABottom);

	IMText barrel_counter("Barrels " + (num_barrels - barrels.size()) + "/" + num_barrels, default_font);
	barrel_counter.setName("barrel_counter");
	barrel_counter_divider.append(barrel_counter);

	@barrel_counter_holder = IMContainer("barrel_counter_holder", -1, -1);
	barrel_counter_holder.setElement(barrel_counter);

	imGUI.getFooter().setAlignment(CALeft, CACenter);
	imGUI.getFooter().setElement(barrel_counter_holder);
}

void SetWindowDimensions(int width, int height){
	imGUI.doScreenResize();
}

void PostScriptReload(){

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
	}
}


void Update(){
	if(!post_init_done){
		PostInit();
	}

	if(editor_mode_active != EditorModeActive()){
		editor_mode_active = EditorModeActive();
		if(!editor_mode_active){

		}
	}

	while(imGUI.getMessageQueueSize() > 0 ){
		IMMessage@ message = imGUI.getNextMessage();
	}

	imGUI.update();
	UpdateBullets();
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
		/* MakeParticle("Data/Particles/gun_decal.xml", point.position - facing, facing * 10.0f); */
		string path;
		switch(rand() % 5) {
			case 0:
				path = "Data/Sounds/footstep_snow_000.wav"; break;
			case 1:
				path = "Data/Sounds/footstep_snow_001.wav"; break;
			case 2:
				path = "Data/Sounds/footstep_snow_002.wav"; break;
			case 3:
				path = "Data/Sounds/footstep_snow_003.wav"; break;
			default:
				path = "Data/Sounds/footstep_snow_004.wav"; break;
		}
		PlaySound(path, point.position);
		colliding = true;
		end = point.position;
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

void MakeMetalSparks(vec3 pos) {
	int num_sparks = rand() % 20;

	for(int i = 0; i < num_sparks; ++i) {
		MakeParticle("Data/Particles/stepdust.xml", pos, vec3(RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f)));

		MakeParticle("Data/Particles/stepdust.xml", pos, vec3(RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f),
																RangedRandomFloat(-5.0f, 5.0f)));
	}
}

void PostInit(){
	//Get the base height of the terrain to minimize collision check length.
	vec3 collision_point = col.GetRayCollision(vec3(0.0f, 1000.0f, 0.0f), vec3(0.0f, -1000.0f, 0.0f));
	post_init_done = true;
	BuildUI();
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return false;
}
