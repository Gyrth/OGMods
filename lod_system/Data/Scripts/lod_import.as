void DrawGUI() {
	Display();
}

bool show = true;
int terrain_size = 3050;

class LOD{
	int subdivide;
	array<Object@> chunks;
	array<string> paths;

	LOD(int subdivide){
		this.subdivide = subdivide;
	}

	void AddLOD(string path){
		paths.insertLast(path);
	}

	void CreateChunks(){

		for(uint i = 0; i < paths.size(); i++){
			int chunk_id = CreateObject(paths[i]);
			Object@ chunk = ReadObjectFromID(chunk_id);
			chunks.insertLast(@chunk);
		}

		int nr_cunks = int(pow(2, subdivide));
		Log(warning, "nr cunks " + nr_cunks);
		float chunk_size = (terrain_size / nr_cunks);
		float position_x = (-terrain_size / 2.0) + (chunk_size / 2.0);
		float position_z = (-terrain_size / 2.0) + (chunk_size / 2.0);

		int chunk_counter = 0;

		for(int direction_x = 0; direction_x < nr_cunks; direction_x++){
			for(int direction_z = 0; direction_z < nr_cunks; direction_z++){

				if(chunk_counter >= int(chunks.size())){
					return;
				}

				chunks[chunk_counter].SetTranslation(vec3(position_z, 0.0, position_x));
				Log(warning, "SetTranslation " + position_x + " " + position_z);

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
}

LOD lod_0(6);
LOD lod_1(5);
LOD lod_2(4);
LOD lod_3(3);
LOD lod_4(2);
LOD lod_5(1);

void Init(string str){
}

void Update(int paused){

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
				}else if(i == 5){
					lod_5.AddLOD(chunk_path);
				}

				found += 1;
				lod_counter += 1;
			}else{
				break;
			}
		}
		Log(warning, "Found " + found + " at lod " + i);
	}

	lod_5.CreateChunks();
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
