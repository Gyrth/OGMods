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
	int z_counter = 0;
	string category = "";
	int number_of_assets;

	array<array<SpawnerItem>> categories;

	for(uint i = 0; i < mod_ids.size(); i++){
		if(ModGetID(mod_ids[i]) == "kenney-assets"){
			array<SpawnerItem> spawner_items = ModGetSpawnerItems(mod_ids[i]);
			number_of_assets = spawner_items.size();
			for(uint j = 0; j < spawner_items.size(); j++){
				bool added_to_existing_category = false;

				for(uint k = 0; k < categories.size(); k++){
					if(categories[k][0].GetCategory() == spawner_items[j].GetCategory()){
						added_to_existing_category = true;
						categories[k].insertLast(spawner_items[j]);
						break;
					}
				}

				if(!added_to_existing_category){
					categories.insertLast({spawner_items[j]});
				}
			}
		}
	}

	for(uint i = 0; i < categories.size(); i++){
		int row_size = int(sqrt(categories[i].size() - 1));
		x_counter = 0;
		y_counter = 0;

		for(uint j = 0; j < categories[i].size(); j++){
			SpawnerItem spawner_item = categories[i][j];
			string path = spawner_item.GetPath();
			int object_id = CreateObject(path, true);
			Object@ obj = ReadObjectFromID(object_id);

			obj.SetTranslation(vec3(15.0f * x_counter, 15.0f * z_counter, 15.0f * y_counter));
			obj.SetSelectable(true);
			obj.SetTranslatable(true);
			obj.SetRotatable(true);
			obj.SetScalable(true);

			vec3 bounds = obj.GetBoundingBox();

			float over_scale = ((bounds.x + bounds.y + bounds.z) / 3.0f);
			obj.SetScale(vec3((1.0f / over_scale) * 5.0f));

			x_counter++;
			if(x_counter > row_size){
				x_counter = 0;
				y_counter++;
			}
		}
		z_counter++;
	}

	Log(warning, "Number of assets : " + number_of_assets);
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	return EditorModeActive()?false:true;
}
