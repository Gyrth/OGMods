string level_name = "";
uint64 last_time;
IMGUI@ imGUI;

FontSetup small_font("arial", 25, HexColor("#ffffff"), true);
FontSetup normal_font("arial", 35, HexColor("#ffffff"), true);
FontSetup black_small_font("arial", 25, HexColor("#000000"), false);
FontSetup big_font("arial", 55, HexColor("#ffffff"), true);
FontSetup huge_font("arial", 75, HexColor("#ffffff"), true);

string connected_icon = "Images/connected.png";
string disconnected_icon = "Images/disconnected.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string custom_address_icon = "Textures/ui/menus/main/icon-lock.png";
IMMouseOverPulseColor mouseover_fontcolor(vec4(1), vec4(1), 5.0f);

bool post_init_done = false;
bool has_camera_control = true;
int player_id = -1;
float camera_movement_speed = 20.0f;
vec3 camera_position;
vec3 camera_facing = vec3(1.0, -1.0, 0.0);
float camera_ground_distance = 10.0;
array<int> ground_decals;

bool selecting = false;
IMContainer@ selection_box;

void Initialize(){
	Init("this_level");
}

void Reset(){
	for(uint i = 0; i < ground_decals.size(); i++){
		Log(warning, "deleting " + ground_decals[i]);
		DeleteObjectID(ground_decals[i]);
	}
	imGUI.clear();
	imGUI.setup();
	ground_decals.resize(0);
	selected_character_ids.resize(0);
	/* ResetCharacters(); */
	post_init_done = false;
}

void ResetCharacters(){
	array<int> character_ids;
	GetCharacters(character_ids);
	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		char.Execute("ResetAOOCharacter();");
	}
}

void Init(string p_level_name) {
	@imGUI = CreateIMGUI();
	level_name = p_level_name;
	imGUI.setup();
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	/* Log(warning, "received " + token); */
	if(token == "reset"){
		Reset();
	}else if(token == "Back"){

	}else if(token == "register_ground_decal"){
		token_iter.FindNextToken(msg);
		int obj_id = atoi(token_iter.GetToken(msg));
		ground_decals.insertLast(obj_id);
	} else if(token == "start_dialogue"){
		has_camera_control = false;
	}
}

void DrawGUI() {
	imGUI.render();
}

void Update(int paused) {
	Update();
}

void PostInit(){
	if(post_init_done){
		return;
	}
	array<int> characters = GetObjectIDsType(_movement_object);
	for(uint i = 0; i < characters.size(); i++){
		MovementObject@ char = ReadCharacterID(characters[i]);
		if(char.controlled){
			player_id = characters[i];
			break;
		}
	}
	@selection_box = IMContainer(20.0, 20.0);
	selection_box.showBorder();
	selection_box.setVisible(false);
	imGUI.getMain().addFloatingElement(selection_box, "selection_box", vec2(0,0));
	post_init_done = true;
	level.Execute("has_gui = true;");
	SetInitialCameraPosition();
}

void SetInitialCameraPosition(){
	MovementObject@ player = ReadCharacterID(player_id);
	vec3 initial_camera_offset = vec3(5.0, 0.0, 5.0);
	camera_position = player.position + vec3(0.0, camera_ground_distance, 0.0) + initial_camera_offset;
}

void Update() {
	PostInit();
	imGUI.update();
	if(!has_camera_control && !level.DialogueCameraControl()){
		has_camera_control = true;
	}
	if(EditorModeActive() || !has_camera_control){
		return;
	}
	UpdateCameraControls();
	UpdateSelectionControls();
}

vec2 selection_starting_point;
vec3 physical_selection_starting_point;
float selection_sphere_radius = 1.0;
array<uint> selected_character_ids;
float select_timer = 0.0;
float select_threshold = 0.2;

void UpdateSelectionControls(){
	MovementObject@ player = ReadCharacterID(player_id);
	if(GetInputDown(0, "mouse0")){
		if(!selecting){
			selection_box.setVisible(true);
			player.Execute("selecting = true");
			selection_starting_point = imGUI.guistate.mousePosition;
			imGUI.getMain().moveElement("selection_box", selection_starting_point);
			physical_selection_starting_point = camera.GetMouseRay();
		}
		selecting = true;
		select_timer += time_step;
	}else if(GetInputPressed(0, "grab")){
		DeselectAllCharacters();
	}else{
		if(selecting){
			player.Execute("selecting = false");
			selection_box.setVisible(false);
			if(select_timer < select_threshold){
				Log(warning, "click");
				if(!CheckForEnemy() && !CheckForWeapons()){
					CharactersMarch();
				}
			}
		}
		selecting = false;
		select_timer = 0.0;
	}

	if(selecting){
		vec2 box_size = imGUI.guistate.mousePosition - selection_starting_point;

		selection_box.setSize(vec2(abs(box_size.x), abs(box_size.y)));

		if(box_size.x < 0.0 || box_size.y < 0.0){
			vec2 negative_position = imGUI.guistate.mousePosition;
			vec2 current_position = imGUI.getMain().getElementPosition("selection_box");

			if(box_size.x > 0.0){
				negative_position.x = current_position.x;
			}
			if(box_size.y > 0.0){
				negative_position.y = current_position.y;
			}

			imGUI.getMain().moveElement("selection_box", negative_position);
		}

		if(select_timer > select_threshold){
			vec3 current_physical_selection_point = camera.GetMouseRay();
			vec3 selection_center = (physical_selection_starting_point + current_physical_selection_point ) / 2.0f;
			selection_sphere_radius = min(abs(box_size.x), abs(box_size.y));

			vec3 collision_point = col.GetRayCollision(camera.GetPos(), camera.GetPos() + selection_center * 200.0);
			float collision_distance = distance(camera.GetPos(), collision_point);

			/* DebugDrawWireScaledSphere(collision_point, selection_sphere_radius / 1500.0f * collision_distance, vec3(1.0), vec3(1.0), _delete_on_draw); */

			array<int> character_ids;
			GetCharactersInSphere(collision_point, selection_sphere_radius / 1500.0f * collision_distance, character_ids);
			for(uint i = 0; i < character_ids.size(); i++){
				//Add a selected character when not already selected.
				if(selected_character_ids.find(character_ids[i]) == -1){
					MovementObject@ char = ReadCharacterID(character_ids[i]);
					char.Execute("SetDecalColor(true);");
					selected_character_ids.insertLast(character_ids[i]);
				}
			}
			for(uint j = 0; j < selected_character_ids.size(); j++){
				//A selected character is no longer inside selection sphere.
				if(character_ids.find(selected_character_ids[j]) == -1){
					MovementObject@ char = ReadCharacterID(selected_character_ids[j]);
					char.Execute("SetDecalColor(false);");
					selected_character_ids.removeAt(j);
					return;
				}
			}
		}
	}
}

void DeselectAllCharacters(){
	for(uint i = 0; i < selected_character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(selected_character_ids[i]);
		char.Execute("SetDecalColor(false);");
	}
	selected_character_ids.resize(0);
}

bool CheckForWeapons(){
	vec3 location = col.GetRayCollision(camera.GetPos(), camera.GetPos() + camera.GetMouseRay() * 200.0);
	int num_items = GetNumItems();
	int closest_id = -1;
	float max_dist = 2.0;
	float closest_dist = 0.0f;
	for(int i=0; i<num_items; i++){
		ItemObject@ item_obj = ReadItem(i);
		if(IsItemPickupable(item_obj)){
			vec3 item_pos = item_obj.GetPhysicsPosition();
			Log(warning, "dist " + distance(location, item_pos));
			if(closest_id == -1 || distance(location, item_pos) < closest_dist){
				closest_dist = distance(location, item_pos);
				closest_id = item_obj.GetID();
			}
		}
	}
	if(closest_dist < max_dist && closest_id != -1){
		GetWeapon(closest_id);
		return true;
	} else {
		return false;
	}
}

bool IsItemPickupable(ItemObject@ item_obj) {
	if(item_obj.GetType() == _misc){
		return false;
	}
	if(item_obj.IsHeld()){
		int holder_id = item_obj.HeldByWhom();
		if(holder_id == -1){
			return false;
		}
		MovementObject@ holder = ReadCharacterID(holder_id);
		if(holder.GetIntVar("knocked_out") == _awake){
			return false;
		}
	}
	return true;
}

void GetWeapon(int weapon_id){
	for(uint i = 0; i < selected_character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(selected_character_ids[i]);
		Log(warning, i + "get wepaon " + weapon_id);
		char.Execute("wants_to_get_weapon = true; weapon_target_id = " + weapon_id + ";");
	}
}

bool CheckForEnemy(){
	vec3 location = col.GetRayCollision(camera.GetPos(), camera.GetPos() + camera.GetMouseRay() * 200.0);
	array<int> character_ids;
	/* DebugDrawWireScaledSphere(location, 2.0, vec3(1.0), vec3(1.0), _fade); */
	GetCharactersInSphere(location, 2.0, character_ids);
	MovementObject@ player = ReadCharacterID(player_id);

	for(uint i = 0; i < character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(character_ids[i]);
		if(!char.OnSameTeam(player) and char.GetIntVar("knocked_out") == _awake){
			AttackCharacter(character_ids[i]);
			Log(warning, "enemy");
			return true;
		}
	}
	return false;
}

void AttackCharacter(int character_id){
	for(uint i = 0; i < selected_character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(selected_character_ids[i]);
		char.Execute("Notice(" + character_id + ");");
		char.Execute("SetGoal(_attack);");
	}
}

void CharactersMarch(){
	Log(warning, "march");
	vec3 march_location = col.GetRayCollision(camera.GetPos(), camera.GetPos() + camera.GetMouseRay() * 200.0);
	for(uint i = 0; i < selected_character_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(selected_character_ids[i]);
		char.Execute("goal = _navigate;" +
					"nav_target = vec3(" + march_location.x + "," + march_location.y + "," + march_location.z + ");");

	}
}

void UpdateCameraControls(){
	float minimum_camera_height = GetMinimumCameraHeight();

	float extra_speed = 1.0;
	if(GetInputDown(0, "lshift")){
		extra_speed = 2.0;
	}

	vec3 facing = camera.GetFlatFacing();
	if(GetInputDown(0, "move_left")){
		vec3 left = vec3(facing.z, 0.0f, -facing.x);
		camera_position += left * time_step * camera_movement_speed * extra_speed;
	}else if(GetInputDown(0, "move_right")){
		//Right
		vec3 right = vec3(-facing.z, 0.0f, facing.x);
		camera_position += right * time_step * camera_movement_speed * extra_speed;
	}

	if(GetInputDown(0, "move_up")){
		//Forward
		vec3 forward = vec3(facing.x, 0.0f, facing.z);
		camera_position += forward * time_step * camera_movement_speed * extra_speed;
	}else if(GetInputDown(0, "move_down")){
		//Backward
		vec3 backward = vec3(-facing.x, 0.0f, -facing.z);
		camera_position += backward * time_step * camera_movement_speed * extra_speed;
	}

	if(GetInputDown(0, "mousescrollup")){
		if(camera_position.y > minimum_camera_height){
			vec3 up = vec3(0.0f, -5.0f, 0.0f);
			camera_position += up * time_step * camera_movement_speed;
		}
	}else if(GetInputDown(0, "mousescrolldown")){
		vec3 down = vec3(0.0f, 5.0f, 0.0f);
		camera_position += down * time_step * camera_movement_speed;
	}

	vec3 new_facing = vec3(-1.0, -2.0, -1.0);

	if(camera_position.y < minimum_camera_height){
		vec3 camera_position_override = vec3(camera_position.x, minimum_camera_height, camera_position.z);
		camera.SetPos(camera_position_override);
		camera.LookAt(camera_position_override + new_facing);
	}else{
		camera.SetPos(camera_position);
		camera.LookAt(camera_position + new_facing);
	}
	UpdateListener(camera.GetPos(),vec3(0,0,0),camera.GetFacing(),camera.GetUpVector());
}

float GetMinimumCameraHeight(){
	MovementObject@ player = ReadCharacterID(player_id);
	return player.GetFloatVar("minimum_camera_height");
}

void SetWindowDimensions(int w, int h){
	Print("SetWindowDimensions\n");
}

void Resize() {
	Print("Resize\n");
}

void ScriptReloaded() {
	Print("ScriptReloaded\n");
}

void Dispose() {
	Log(warning, "Dispose!");
	imGUI.clear();
}

bool DialogueCameraControl() {
	return has_camera_control;
}

bool HasFocus(){
	return false;
}
