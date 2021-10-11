//UI variables..----------------------------------------------------------------------------------------------------------------------------
IMGUI@ imGUI;
FontSetup default_font("arialbd", 100 , HexColor("#ffffff"), true);
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
IMContainer@ health_holder;

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
int total_coins = 0;
int total_gems = 0;
int total_stars = 0;
int collected_coins = 0;
int collected_gems = 0;
int collected_stars = 0;
float player_health = 1.0f;
float click_reset_timer = 0.0;
bool player_died = false;
bool flag_captured = false;
float update_music_timer = 0.0;

array<string> instruments = {	"banjo",
								"bass",
								"drums_heavy",
								"drums_light",
								"fiddle",
								"guitar_simple",
								"guitar_back",
								"piano",
								"vocals"
							};

class Bullet{
	float bullet_speed = 20.0f;
	float max_bullet_distance = 5.0f;
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

	AddMusic("Data/Music/arctic_2d_music.xml");
	SetSong("song");
}

void CreateIMGUIContainers(){
	imGUI.setHeaderHeight(300);
	imGUI.setFooterHeight(300);

	imGUI.setup();
	/* imGUI.getFooter().showBorder(); */

	imGUI.setBackgroundLayers(1);
	imGUI.getMain().setZOrdering(-1);
}

void BuildUI(){
	float heart_size = 150.0f;
	IMDivider @collected_divider = GetCollected();

	@barrel_counter_holder = IMContainer("barrel_counter_holder", -1, -1);
	barrel_counter_holder.showBorder(false);
	barrel_counter_holder.setElement(collected_divider);
	barrel_counter_holder.setAlignment(CALeft, CACenter);

	IMDivider health_divider("health_divider", DOVertical);
	health_divider.setBorderColor(vec4(0,1,0,1));
	health_divider.setAlignment(CACenter, CATop);
	health_divider.appendSpacer(50.0f);

	IMDivider health_horiz_divider("health_horiz_divider", DOHorizontal);

	for(int i = 1; i < 6; i++){
		string path = "Textures/Base pack/HUD/hud_heartFull.png";

		if((i / 5.0) > player_health){
			path = "Textures/Base pack/HUD/hud_heartEmpty.png";

			float bigger = (((i * 2) - 1) / 10.01);
			float smaller = (((i * 2)) / 10.01);

			if( bigger < player_health && smaller > player_health ){
				path = "Textures/Base pack/HUD/hud_heartHalf.png";
			}
		}

		IMImage health_image(path);
		health_image.scaleToSizeX(heart_size);
		health_horiz_divider.append(health_image);
	}

	health_divider.append(health_horiz_divider);

	@health_holder = IMContainer("health_holder", 2560, -1);
	health_holder.setElement(health_divider);

	if(!flag_captured){
		imGUI.getFooter().setAlignment(CACenter, CACenter);
		imGUI.getHeader().setAlignment(CALeft, CACenter);
		imGUI.getFooter().setElement(health_holder);
		imGUI.getHeader().setElement(barrel_counter_holder);
		imGUI.getMain().clear();
	}else{
		imGUI.getFooter().clear();
		imGUI.getHeader().clear();
	}
}

IMDivider@ GetCollected(){
	float image_size = 100.0f;
	float spacer = 50.0f;

	IMDivider collected_divider("collected_divider", DOVertical);
	collected_divider.setBorderColor(vec4(0,1,0,1));
	collected_divider.setAlignment(CALeft, CATop);
	collected_divider.appendSpacer(50.0f);

	IMDivider coins_counter_divider("coins_counter_divider", DOHorizontal);
	IMImage coin_image("Textures/Base pack/HUD/hud_coins.png");
	coin_image.scaleToSizeX(image_size);
	coins_counter_divider.append(coin_image);
	coins_counter_divider.appendSpacer(spacer);
	IMText coin_counter(collected_coins + "/" + total_coins, default_font);
	coin_counter.setName("coin_counter");
	coins_counter_divider.append(coin_counter);
	collected_divider.append(coins_counter_divider);

	IMDivider gem_counter_divider("gem_counter_divider", DOHorizontal);
	IMImage gem_image("Textures/Base pack/HUD/hud_gem_red.png");
	gem_image.scaleToSizeX(image_size);
	gem_counter_divider.append(gem_image);
	gem_counter_divider.appendSpacer(spacer);
	IMText gem_counter(collected_gems + "/" + total_gems, default_font);
	gem_counter.setName("gem_counter");
	gem_counter_divider.append(gem_counter);
	collected_divider.append(gem_counter_divider);

	IMDivider star_counter_divider("star_counter_divider", DOHorizontal);
	IMImage star_image("Textures/Base pack/HUD/star.png");
	star_image.scaleToSizeX(image_size);
	star_counter_divider.append(star_image);
	star_counter_divider.appendSpacer(spacer);
	IMText star_counter(collected_stars + "/" + total_stars, default_font);
	star_counter.setName("gem_counter");
	star_counter_divider.append(star_counter);
	collected_divider.append(star_counter_divider);

	return @collected_divider;
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
	}else if(token == "reset"){
		Reset();
		BuildUI();
	}else if(token == "register_coin"){
		total_coins += 1;
		BuildUI();
	}else if(token == "register_gem"){
		total_gems += 1;
		BuildUI();
	}else if(token == "register_star"){
		total_stars += 1;
		BuildUI();
	}else if(token == "collect_coin"){
		collected_coins += 1;
		BuildUI();
	}else if(token == "collect_gem"){
		collected_gems += 1;
		BuildUI();
	}else if(token == "collect_star"){
		collected_stars += 1;
		BuildUI();
	}else if(token == "update_player_health"){
		token_iter.FindNextToken(msg);
		player_health = atof(token_iter.GetToken(msg));
		BuildUI();
		if(player_health <= 0.0){
			PlayerDied();
		}
	}else if(token == "flag_captured"){
		if(!player_died){
			FlagCaptured();
			BuildUI();
		}
	}
}

void Reset() {
	total_coins = 0;
	total_gems = 0;
	total_stars = 0;
	collected_coins = 0;
	collected_gems = 0;
	collected_stars = 0;
	player_died = false;
	flag_captured = false;
}

void FlagCaptured(){
	PlaySound("Data/Sounds/powerUp9.ogg");
	flag_captured = true;
	click_reset_timer = 3.0;

	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);
		if(char.is_player){
			char.ReceiveMessage("stop_controls");
		}
	}

	IMContainer win_holder("win_holder", 2560, 1000);
	IMDivider win_divider("win_divider", DOHorizontal);
	IMImage star_image("Textures/Base pack/HUD/star.png");
	star_image.scaleToSizeX(800.0f);
	star_image.setColor(vec4(1.0, 1.0, 1.0, 0.75));
	imGUI.getMain().addFloatingElement(star_image, "star_image", vec2(2560 / 2.0 - 400, 1000 / 2.0 - 450));

	IMDivider @collected_divider = GetCollected();
	collected_divider.addUpdateBehavior(IMMoveIn( 1000, vec2(0.0, -500.0), outBounceTween ), "");
	win_divider.append(collected_divider);

	star_image.addUpdateBehavior(IMFadeIn( 3500, inSineTween ), "");
	star_image.addUpdateBehavior(IMMoveIn( 1000, vec2(0.0, -500.0), outBounceTween ), "");

	for(int i = 0; i < 100; i++){
		IMImage small_star_image("Textures/Base pack/HUD/star.png");
		small_star_image.scaleToSizeX(RangedRandomFloat(25.0, 75.0));
		small_star_image.setRotation(RangedRandomFloat(0.0, 360.0f));
		small_star_image.addUpdateBehavior(IMFadeIn( int(RangedRandomFloat(1000.0, 2000)), inSineTween ), "");
		/* small_star_image.addUpdateBehavior(IMMoveIn( 1000, vec2(0.0, -840.0), outSineTween ), ""); */
		small_star_image.setClip(false);
		small_star_image.setColor(vec4(RangedRandomFloat(0.5, 1.0), RangedRandomFloat(0.5, 1.0), RangedRandomFloat(0.5, 1.0), 1.0));
		imGUI.getMain().addFloatingElement(small_star_image, "small_star_image" + i, vec2(RangedRandomFloat(0.0, 2500), RangedRandomFloat(0.0, 840)));
	}

	star_image.setClip(false);
	win_divider.setClip(false);
	win_holder.setClip(false);
	win_holder.setElement(win_divider);
	imGUI.getMain().setAlignment(CACenter, CACenter);
	imGUI.getMain().showBorder(false);
	imGUI.getMain().setElement(win_holder);
}

void PlayerDied(){
	PlaySound("Data/Sounds/lowDown.ogg");
	click_reset_timer = 3.0;
	player_died = true;

	IMContainer lose_holder("lose_holder", 2560, 1000);
	IMDivider lose_divider("lose_divider", DOHorizontal);
	IMImage lose_image("Textures/Base pack/HUD/hud_x.png");
	lose_image.scaleToSizeX(700.0f);
	lose_image.setColor(vec4(1.0, 0.0, 0.0, 0.5));
	lose_divider.append(lose_image);

	lose_image.addUpdateBehavior(IMFadeIn( 3500, inSineTween ), "");
	lose_image.addUpdateBehavior(IMMoveIn( 1000, vec2(0.0, -500.0), outBounceTween ), "");

	lose_image.setClip(false);
	lose_divider.setClip(false);
	lose_holder.setClip(false);
	lose_holder.setElement(lose_divider);
	imGUI.getMain().setAlignment(CACenter, CACenter);
	/* imGUI.getMain().showBorder(); */
	imGUI.getMain().setElement(lose_holder);
}


void Update(){
	if(!post_init_done){
		PostInit();
	}

	if(player_died || flag_captured){
		if(click_reset_timer <= 0.0){
			if(!EditorModeActive() && GetInputPressed(0, "attack")){
				Reset();
				ResetLevel();
			}
		}else{
			click_reset_timer -= time_step;
		}
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
	UpdateMusic();
}

void UpdateMusic(){
	if(update_music_timer <= 0.0f){
		update_music_timer = RangedRandomFloat(25.0, 35.0);

		for(uint i = 0; i < instruments.size(); i++){
			SetLayerGain(instruments[i], 0.0);
		}

		// At least 2 instruments and max 5;
		int random_instrument_amount = int(RangedRandomFloat(2.0, 5.0));
		for(int i = 0; i < random_instrument_amount; i++){
			string instrument_name = instruments[rand() % instruments.size()];
			SetLayerGain(instrument_name, 0.25);
		}
	}else{
		update_music_timer -= time_step;
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
		/* MakeParticle("Data/Particles/gun_decal.xml", point.position - facing, facing * 10.0f); */
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

	array<int> character_ids;
	GetCharactersInSphere(start, 0.25, character_ids);
	/* DebugDrawWireSphere(start, 0.25, vec3(1.0), _delete_on_update); */
	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		float character_scale = 1.0;
		if(char.HasVar("character_scale")){
			character_scale = char.GetFloatVar("character_scale") / 2.0;
		}
		float dist = distance(start, char.position);

		if(!char.is_player && dist < character_scale){
			colliding = true;
			MakeMetalSparks(start);

			vec3 force = direction * 15000.0f;
			vec3 hit_pos = vec3(0.0f);
			float damage = 1.0;
			char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
						 "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
						 "HandleRagdollImpactImpulse(impulse, pos, " + damage + ");");

			break;
		}
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
	PlaySound(path, pos);
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
