void DrawGUI() {
	Display();
}

bool show = true;
int terrain_size = 3050;

class LOD{
	int subdivide;
	array<Object@> chunks;
	array<string> paths;
	float min;
	float max;

	LOD(int subdivide, float min, float max){
		this.subdivide = subdivide;
		this.min = min;
		this.max = max;
	}

	void AddLOD(string path){
		paths.insertLast(path);
	}

	void CreateChunks(vec3 tint){

		for(uint i = 0; i < paths.size(); i++){
			int chunk_id = CreateObject(paths[i]);
			Object@ chunk = ReadObjectFromID(chunk_id);
			/* chunk.SetTint(vec3(RangedRandomFloat(0.0, 1.0))); */
			chunk.SetTint(tint);
			chunks.insertLast(@chunk);
		}

		float nr_cunks = pow(2, subdivide);
		float chunk_size = terrain_size / nr_cunks;
		Log(warning, terrain_size + " divided " + nr_cunks + " = chunk_size " + chunk_size);
		float position_x = (-terrain_size / 2.0) + (chunk_size / 2.0);
		float position_z = (-terrain_size / 2.0) + (chunk_size / 2.0);

		int chunk_counter = 0;

		for(int direction_x = 0; direction_x < nr_cunks; direction_x++){
			for(int direction_z = 0; direction_z < nr_cunks; direction_z++){

				if(chunk_counter >= int(chunks.size())){
					return;
				}

				float y_offset = atof(chunks[chunk_counter].GetLabel());
				chunks[chunk_counter].SetTranslation(vec3(position_z, y_offset, position_x));
				/* chunks[chunk_counter].SetScale(vec3(1.0, 0.1, 1.0)); */
				/* Log(warning, "SetTranslation " + position_z + " " + position_x); */

				position_z += chunk_size;
				chunk_counter += 1;
			}
			position_x += chunk_size;
			position_z = (-terrain_size / 2.0) + (chunk_size / 2.0);
		}
	}

	void Clear(){
		for(uint i = 0; i < chunks.size(); i++){
			DeleteObjectID(chunks[i].GetID());
			chunks.resize(0);
			paths.resize(0);
		}
	}

	void Update(){
		for(uint i = 0; i < chunks.size(); i++){
			float dist = distance(chunks[i].GetTranslation(), player_position);
			/* Log(warning, "dist " + dist); */
			chunks[i].SetEnabled((dist < max && dist > min));
		}
	}
}

LOD lod_0(5, 0.0, 200.0);
LOD lod_1(4, 200.0, 400.0);
LOD lod_2(3, 400.0, 800.0);
LOD lod_3(2, 800, 1200);
LOD lod_4(1, 1200, 1000000);

void PostInit(){
	LoadLODs("Data/Objects/impressive_mountains_hole/lod_5_000.xml");
}

vec3 grid_position = vec3(0.0);
vec3 player_position = vec3(0.0);
float threshold = 100.0;

void Init(string str){

}

bool post_init_done = false;

void Update(int paused){
	if(!post_init_done){
		PostInit();
		post_init_done = true;
		return;
	}
	int player_id = -1;
	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);

		if(char.controlled){
			player_id = char.GetID();
			break;
		}
	}

	if(player_id != -1 || EditorModeActive()){
		vec3 current_player_position;
		if(EditorModeActive()){
			current_player_position = camera.GetPos();
		}else{
			MovementObject@ player = ReadCharacterID(player_id);
			current_player_position = player.position;
		}

		current_player_position.y = 0.0;

		vec3 new_grid_position = vec3(floor(current_player_position.x / (threshold)), floor(current_player_position.y / (threshold)), floor(current_player_position.z / (threshold)));

		if(grid_position != new_grid_position){
			grid_position = new_grid_position;
			player_position = (grid_position * threshold) + (threshold / 2.0);
			UpdateLOD();
		}
	}
}

void UpdateLOD(){
	lod_0.Update();
	lod_1.Update();
	lod_2.Update();
	lod_3.Update();
	lod_4.Update();
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "notify_deleted"){

		}
	}
}

void Display(){
	if(show){
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(550,450));
		ImGui_Begin("Import LODs", show, ImGuiWindowFlags_NoScrollbar);
		ImGui_PopStyleVar(1);

		if(ImGui_Button("Load LOD")){
			string path = GetUserPickedReadPath("xml", "Data/Objects");
			LoadLODs(path);
		}

		if(ImGui_Button("Default LOD")){
			LoadLODs("Data/Objects/impressive_mountains_hole/lod_5_000.xml");
		}

		ImGui_End();
	}
}

void LoadLODs(string path){
	array<string> split_path = path.split("/");
	split_path.removeAt(split_path.size() - 1);
	string lod_path = join(split_path, "/");
	Log(warning, "path " + lod_path);

	for(uint i = 0; i <= 5; i++){
		int lod_counter = 0;
		int found = 0;
		while(true){
			string chunk_path = lod_path + "/lod_" + i + "_" + zero_pad(lod_counter) + ".xml";
			/* Log(warning, "Checking " + chunk_path); */
			if(FileExists(chunk_path)){
				if(i == 0){
					lod_0.AddLOD(chunk_path);
				}else if(i == 1){
					lod_1.AddLOD(chunk_path);
				}else if(i == 2){
					lod_2.AddLOD(chunk_path);
				}else if(i == 3){
					lod_3.AddLOD(chunk_path);
				}else if(i == 4){
					lod_4.AddLOD(chunk_path);
				}

				found += 1;
				lod_counter += 1;
			}else{
				break;
			}
		}
		Log(warning, "Found " + found + " at lod " + i);
	}

	float nr_cunks_smalest = pow(2, 5);
	threshold = terrain_size / nr_cunks_smalest;
	Log(warning, "threshold = " + threshold);

	lod_0.CreateChunks(vec3(1.0, 0.0, 0.0));
	lod_1.CreateChunks(vec3(0.0, 1.0, 0.0));
	lod_2.CreateChunks(vec3(0.0, 0.0, 1.0));
	lod_3.CreateChunks(vec3(1.0, 1.0, 0.0));
	lod_4.CreateChunks(vec3(0.0, 1.0, 1.0));
}

string zero_pad(int i){
	string padded = i;
	if(i < 10){
		padded = "00" + padded;
	}else if(i < 100){
		padded = "0" + padded;
	}
	return padded;
}

void Menu(){
	ImGui_Checkbox("Load LODs", show);
}
