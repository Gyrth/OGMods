float x_rotation = 0.0f;
float y_rotation = 180.0f;
float z_distance = 1.0f;
ScriptParams@ params = level.GetScriptParams();
bool post_init_done = false;
array<GUISpawnerItem@> all_items;
int current_index = -1;
int spawned_id = -1;
JSON data;
JSONValue screenshot_links;
int screenshot_counter = 1;
float object_x_rotation = 0.0f;
float object_y_rotation = 0.0f;
float object_z_rotation = 0.0f;
IMGUI@ imGUI;
IMContainer@ main_container;
vec3 look_at_position = vec3();
int set_position = -1;

class GUISpawnerItem{
	string title;
	string category;
	string path;
	int id;
	TextureAssetRef icon;
	SpawnerItem spawner_item;
	bool has_thumbnail = false;
	string thumbnail_path;

	GUISpawnerItem(string _category, string _title, string _path, int _id, string _thumbnail_path, SpawnerItem _spawner_item){
		category = _category;
		thumbnail_path = _thumbnail_path;
		spawner_item = _spawner_item;
		title = _title;
		path = _path;
		id = _id;
	}

	void SetThumbnail(){
		//If no thumbnail was set, use the default one.
		if(spawner_item.GetThumbnail() == "" || !FileExists(spawner_item.GetThumbnail())){
			return;
		}else{
			icon = LoadTexture(spawner_item.GetThumbnail(), TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
		}
	}
}

void Init(string level_name){
	GetAllSpawnerItems();
	@imGUI = CreateIMGUI();
	@main_container = IMContainer(1440, 1440);
	main_container.showBorder();
	main_container.setBorderSize(5.0f);

	imGUI.setup();
	imGUI.getMain().setZOrdering(-1);
	imGUI.getMain().setElement(main_container);
}

void GetAllSpawnerItems(){
	array<SpawnerItem> spawner_items = ModGetAllSpawnerItems();
	for(uint i = 0; i < spawner_items.size(); i++){
		string thumbnail_path = spawner_items[i].GetThumbnail();
		if(thumbnail_path == "" || thumbnail_path == "Data/Textures/ui/t2/spawner.jpg" || thumbnail_path == "Data/UI/spawner/thumbs/Utility/empty_placeholder.png"){
			string category = spawner_items[i].GetCategory();
			string path = spawner_items[i].GetPath();
			array<string> split_path = path.split("/");
			string expected_thumbnail_path = "Data/UI/spawner/thumbs/extra/" + split_path[split_path.size() - 1];
			expected_thumbnail_path = join(expected_thumbnail_path.split(".xml"), ".png");

			if(FileExists(expected_thumbnail_path)){
				Log(warning, "Skipping " + expected_thumbnail_path);
				continue;
			}

			if(category == "Hotspot"){
				string image_path = GetStringFromXML(path, "<BillboardColorMap>", "</BillboardColorMap>");
				screenshot_links[path] = JSONValue(image_path);
			}else if(category == "Decal"){
				string image_path = GetStringFromXML(path, "<ColorMap>", "</ColorMap>");
				screenshot_links[path] = JSONValue(image_path);
			}else{
				GUISpawnerItem @new_item = GUISpawnerItem(category, spawner_items[i].GetTitle(), path, i, thumbnail_path, spawner_items[i]);
				all_items.insertLast(new_item);
			}
		}else if(!FileExists(thumbnail_path)){
			Log(warning, "Thumbnail doesn't exist : " + thumbnail_path);
		}
	}
	Log(warning, "Items that don't have a thumbnail : " + all_items.size());
}

string GetStringFromXML(string target_path, string first, string second){
	string return_value = "";
	string data;

	if(LoadFile(target_path)){
		while(true){
			string line = GetFileLine();
			if(line == "end"){
				break;
			}else{
				data += line + "\n";
			}
		}

		//Remove all spaces to eliminate style differences.
		string xml_content = join(data.split(" "), "");
		return_value = GetStringBetween(xml_content, first, second);
	}else{
		Log(error, "Error loading file: " + target_path);
	}

	return return_value;
}

string GetStringBetween(string source, string first, string second){
	array<string> first_cut = source.split(first);
	if(first_cut.size() <= 1){
		return "";
	}
	array<string> second_cut = first_cut[1].split(second);

	if(second_cut.size() <= 1){
		return "";
	}
	return second_cut[0];
}

void PostInit(){
	if(post_init_done){
		return;
	}
	post_init_done = true;
	MovementObject@ char = ReadCharacter(0);
	Object@ obj = ReadObjectFromID(char.GetID());
	obj.SetEnabled(false);
}

void Update(int is_paused){
	if(GetNumCharacters() == 0){
		return;
	}
	PostInit();
	MovementObject@ char = ReadCharacter(0);

	if(set_position > 0){
		set_position -= 1;
	}else if(set_position == 0){
		Object@ obj = ReadObjectFromID(spawned_id);
		obj.SetTranslation(vec3());
		set_position -= 1;
		AddObjectRotation(0.0f, 0.0f, 0.0f);
		SetLookAtPosition();

		vec3 bounds = obj.GetBoundingBox();
		z_distance = max(1.0f, (bounds.x + bounds.y + bounds.z) / 3.0f);
	}

	if(GetInputDown(char.controller_id, "attack")){
		vec3 forward = camera.GetFacing();
		vec3 up = camera.GetUpVector();
		vec3 right = cross(forward, up);
		float tilt_speed = max(0.001, 0.002 * z_distance);

		look_at_position += GetLookXAxis(char.controller_id) * right * tilt_speed;
		look_at_position -= GetLookYAxis(char.controller_id) * up * tilt_speed;
	}else{
		float look_speed = 0.5f;
		x_rotation = max(-70.0f, min(70.0f, x_rotation - (GetLookYAxis(char.controller_id) * look_speed)));
		y_rotation += GetLookXAxis(char.controller_id) * look_speed;
		if(y_rotation > 180.0f){
			y_rotation -= 360.0f;
		}else if(y_rotation < -180.0f){
			y_rotation += 360.0f;
		}
	}

	float step_size = max(0.01, 0.04 * z_distance) * (GetInputDown(char.controller_id, "lctrl")?4.0f:1.0f);
	if(GetInputDown(char.controller_id, "mousescrollup")){
		z_distance = max(0.01f, z_distance - step_size);
	} else if(GetInputDown(char.controller_id, "mousescrolldown")){
		z_distance += step_size;
	}

	vec3 sun_pos = GetSunPosition();
	if(GetInputDown(char.controller_id, "n")){
		sun_pos.y = min(0.9f, sun_pos.y + 0.01);
		SetSunPosition(sun_pos);
	}else if(GetInputDown(char.controller_id, "m")){
		sun_pos.y = max(-0.9f, sun_pos.y - 0.01);
		SetSunPosition(sun_pos);
	}else if(GetInputDown(char.controller_id, ",")){
		sun_pos.z = sun_pos.z + 0.01;
		SetSunPosition(sun_pos);
	}else if(GetInputDown(char.controller_id, ".")){
		sun_pos.z = sun_pos.z - 0.01;
		SetSunPosition(sun_pos);
	}

	if(GetInputPressed(char.controller_id, "pageup")){
		if(current_index < int(all_items.size() - 1)){
			current_index += 1;
			Log(error, "Create : " + all_items[current_index].path);
			DeleteObjectID(spawned_id);
			spawned_id = CreateObject(all_items[current_index].path);
			set_position = 2;
			Object@ obj = ReadObjectFromID(spawned_id);
			obj.SetTranslation(vec3());
			object_x_rotation = 0.0f;
			object_y_rotation = 0.0f;
			object_z_rotation = 0.0f;
		}else{
			Log(warning, "No more items available.");
		}
	}else if(GetInputPressed(char.controller_id, "pagedown")){
		if(current_index > 0){
			current_index -= 1;
			Log(error, "Create : " + all_items[current_index].path);
			DeleteObjectID(spawned_id);
			spawned_id = CreateObject(all_items[current_index].path);
			set_position = 2;
			Object@ obj = ReadObjectFromID(spawned_id);
			obj.SetTranslation(vec3());
			object_x_rotation = 0.0f;
			object_y_rotation = 0.0f;
			object_z_rotation = 0.0f;
		}
	}else if(GetInputPressed(char.controller_id, "home")){
		WriteScreenshotData();
	}else if(GetInputPressed(char.controller_id, "f8")){
		LinkScreenshot();
	}

	mat4 rotationY_mat, rotationX_mat;
	rotationY_mat.SetRotationY(y_rotation * 3.1415f / 180.0f);
	rotationX_mat.SetRotationX(x_rotation * 3.1415f / 180.0f);
	mat4 rotation_mat = rotationY_mat * rotationX_mat;
	vec3 facing = rotation_mat * vec3(0.0f, 0.0f, -1.0f);
	vec3 camera_position = vec3(0.0) + (facing * z_distance);

	if(spawned_id != -1){
		float rotate_speed = 0.25;

		if(!EditorModeActive()){
			if(GetInputDown(char.controller_id, "left")){
				AddObjectRotationY(rotate_speed);
			}else if(GetInputDown(char.controller_id, "right")){
				AddObjectRotationY(-rotate_speed);
			}
			if(GetInputDown(char.controller_id, "down")){
				AddObjectRotationX(rotate_speed);
			}else if(GetInputDown(char.controller_id, "up")){
				AddObjectRotationX(-rotate_speed);
			}

			if(GetInputDown(char.controller_id, "q")){
				AddObjectRotationZ(rotate_speed);
			}else if(GetInputDown(char.controller_id, "e")){
				AddObjectRotationZ(-rotate_speed);
			}
		}

		/* DebugDrawWireSphere(vec3(0.0), 0.5, vec3(1.0), _delete_on_update);
		DebugDrawWireSphere(camera_position, 0.5, vec3(1.0), _delete_on_update);
		DebugDrawLine(vec3(0.0), camera_position, vec3(1.0), _delete_on_update); */
	}

	if(!EditorModeActive()){
		camera.SetPos(camera_position);
		camera.LookAt(look_at_position);
		camera.SetDistance(0.0f);
	}
	imGUI.update();
}

void SetLookAtPosition(){
	Object@ obj = ReadObjectFromID(spawned_id);

	if(obj.GetType() == _movement_object){
		MovementObject@ target_char = ReadCharacterID(obj.GetID());
		RiggedObject@ rigged_object = target_char.rigged_object();
		Skeleton@ skeleton = rigged_object.skeleton();
		// Get relative chest transformation
		int chest_bone = skeleton.IKBoneStart("pelvis");
		BoneTransform chest_frame_matrix = rigged_object.GetFrameMatrix(chest_bone);
		look_at_position = chest_frame_matrix.origin;
	}else if(obj.GetType() == _item_object){
		ItemObject@ io = ReadItemID(obj.GetID());
		look_at_position = io.GetPhysicsPosition();
	}else{
		look_at_position = obj.GetTranslation();
	}
}

void AddObjectRotationX(float added_x){
	AddObjectRotation(added_x, 0.0f, 0.0f);
}

void AddObjectRotationY(float added_y){
	AddObjectRotation(0.0f, added_y, 0.0f);
}

void AddObjectRotationZ(float added_z){
	AddObjectRotation(0.0f, 0.0f, added_z);
}

void AddObjectRotation(float added_x, float added_y, float added_z){
	Object@ obj = ReadObjectFromID(spawned_id);
	mat4 objectrotationY_mat, objectrotationX_mat, objectrotationZ_mat;
	objectrotationY_mat.SetRotationY(object_y_rotation * 3.1415f / 180.0f);
	objectrotationX_mat.SetRotationX(object_x_rotation * 3.1415f / 180.0f);
	objectrotationZ_mat.SetRotationZ(object_z_rotation * 3.1415f / 180.0f);
	mat4 object_rotation_mat = objectrotationY_mat * objectrotationX_mat * objectrotationZ_mat;

	object_x_rotation += added_x;
	object_y_rotation += added_y;
	object_z_rotation += added_z;

	obj.SetRotation(QuaternionFromMat4(object_rotation_mat));
}

void DrawGUI(){
	if(!GetInputDown(0, "f8")){
		imGUI.render();
	}
}

void LinkScreenshot(){
	int counter_length = ("" + screenshot_counter).length();
	string number = "";
	for(int i = 0; i < (5 - counter_length); i++){
		number += "0";
	}
	number += screenshot_counter;
	screenshot_links[all_items[current_index].path] = JSONValue("OvergrowthScreenshot" + number + ".png");
	screenshot_counter += 1;
}

void WriteScreenshotData(){
	data.getRoot()["screenshot_links"] = screenshot_links;
	StartWriteFile();
	AddFileString(data.writeString(true));
	WriteFileToWriteDir("screenshot_data.json");
}

bool DialogueCameraControl(){
	return true;
}

void SetWindowDimensions(int width, int height){
	imGUI.doScreenResize();
}
