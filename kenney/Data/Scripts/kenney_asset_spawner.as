//General script variables.-------------------------------------------------------------------------------------------------------------------
bool post_init_done = false;
const float PI = 3.14159265359f;
double rad2deg = (180.0f / PI);
double deg2rad = (PI / 180.0f);

void Init(string str){

}

void SetWindowDimensions(int width, int height){
}

void PostScriptReload(){
}

void DrawGUI(){
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
		post_init_done = true;
	}
}

void PostInit(){
	array<ModID> mod_ids =  GetActiveModSids();
	int x_counter = 0;
	int y_counter = 0;

	for(uint i = 0; i < mod_ids.size(); i++){
		if(ModGetID(mod_ids[i]) == "kenney-assets"){
			array<SpawnerItem> spawner_items = ModGetSpawnerItems(mod_ids[i]);
			for(uint j = 0; j < spawner_items.size(); j++){
				string path = spawner_items[j].GetPath();
				int object_id = CreateObject(path, true);
				Object@ obj = ReadObjectFromID(object_id);

				obj.SetTranslation(vec3(15.0f * x_counter, 0.0f, 15.0f * y_counter));
				obj.SetSelectable(true);
				x_counter++;
				if(x_counter > spawner_items.size() / 2){
					x_counter = 0;
					y_counter++;
				}
			}
		}
	}
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return EditorModeActive()?false:true;
}
