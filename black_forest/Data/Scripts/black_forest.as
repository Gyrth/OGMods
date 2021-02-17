#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

//Parameters for user to change
int world_size = 4;
float block_size = 10.0f;
bool rain = false;
//Variables not to be manually changed
int rain_sound_id = -1;
string level_name;
int player_id = -1;
float floor_height;
vec2 grid_position;
bool rebuild_world = false;
EntityType _group = EntityType(29);
bool post_init_done = false;
IMGUI@ imGUI;
IMContainer@ text_container;
FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);

MusicLoad ml("Data/Music/black_forest.xml");

World world;

array<BlockType@> block_types = {
									BlockType("Data/Objects/block_house_1.xml", 1.0f),
									BlockType("Data/Objects/block_house_2.xml", 1.0f),
									BlockType("Data/Objects/block_house_3.xml", 1.0f),
									BlockType("Data/Objects/block_trees_falen.xml", 1.0f),

									BlockType("Data/Objects/block_wolf_den_1.xml", 0.25f),
									BlockType("Data/Objects/block_wolf_den_2.xml", 0.25f),
									BlockType("Data/Objects/block_wolf_den_3.xml", 0.25f),
									BlockType("Data/Objects/block_wolf_den_4.xml", 0.25f),

									BlockType("Data/Objects/block_lake_1.xml", 0.5f),
									BlockType("Data/Objects/block_lake_2.xml", 0.5f),
									BlockType("Data/Objects/block_lake_3.xml", 0.5f),
									BlockType("Data/Objects/block_lake_4.xml", 0.5f),
									BlockType("Data/Objects/block_lake_5.xml", 0.5f),
									BlockType("Data/Objects/block_lake_6.xml", 0.5f),
									BlockType("Data/Objects/block_lake_7.xml", 0.5f),

									BlockType("Data/Objects/block_guard_patrol.xml", 1.0f),
									BlockType("Data/Objects/block_camp_1.xml", 1.0f),
									BlockType("Data/Objects/block_camp_2.xml", 1.0f),
									BlockType("Data/Objects/block_camp_3.xml", 1.0f),
									BlockType("Data/Objects/block_camp_4.xml", 1.0f),
									BlockType("Data/Objects/block_camp_5.xml", 1.0f),
									BlockType("Data/Objects/block_camp_6.xml", 1.0f),

									BlockType("Data/Objects/block_ruins_1.xml", 3.0f),
									BlockType("Data/Objects/block_ruins_2.xml", 3.0f),
									BlockType("Data/Objects/block_ruins_3.xml", 3.0f),
									BlockType("Data/Objects/block_ruins_4.xml", 3.0f),
									BlockType("Data/Objects/block_ruins_5.xml", 3.0f),
									BlockType("Data/Objects/block_ruins_6.xml", 3.0f),

									BlockType("Data/Objects/block_trees_1.xml", 10.0f),
									BlockType("Data/Objects/block_trees_2.xml", 10.0f),
									BlockType("Data/Objects/block_trees_3.xml", 10.0f),
									BlockType("Data/Objects/block_trees_4.xml", 10.0f),
									BlockType("Data/Objects/block_trees_5.xml", 10.0f),
									BlockType("Data/Objects/block_trees_6.xml", 10.0f),
									BlockType("Data/Objects/block_trees_7.xml", 10.0f),
									BlockType("Data/Objects/block_trees_8.xml", 10.0f),
									BlockType("Data/Objects/block_trees_9.xml", 10.0f),
									BlockType("Data/Objects/block_trees_10.xml", 10.0f),
									BlockType("Data/Objects/block_trees_11.xml", 10.0f),
									BlockType("Data/Objects/block_trees_12.xml", 10.0f),
									BlockType("Data/Objects/block_trees_13.xml", 10.0f),
									BlockType("Data/Objects/block_trees_14.xml", 10.0f),
									BlockType("Data/Objects/block_trees_15.xml", 10.0f),
									BlockType("Data/Objects/block_trees_16.xml", 10.0f),
									BlockType("Data/Objects/block_trees_17.xml", 10.0f),
									BlockType("Data/Objects/block_trees_18.xml", 10.0f),
									BlockType("Data/Objects/block_trees_19.xml", 10.0f),
									BlockType("Data/Objects/block_trees_20.xml", 10.0f)};

class BlockType{
	string path;
	float probability;
	Object@ original;
	array<int> children_ids;
	vec3 target_translation = vec3(0.0f, -10000.0f, 0.0f);

	BlockType(string _path, float _probability){
		path = _path;
		probability = _probability;
	}

	void Preload(){
		int id = CreateObject(path);
		@original = ReadObjectFromID(id);
		GetBlockChildrenIds(original);
		original.SetEnabled(false);
	}

	void SetFinalTranslation(){
		if(original.GetTranslation() != target_translation){
			original.SetTranslation(target_translation);
			for(uint i = 0; i < children_ids.size(); i++){
				Object@ obj = ReadObjectFromID(children_ids[i]);
				obj.SetTranslation(obj.GetTranslation());
			}
		}
	}

	void GetBlockChildrenIds(Object@ start_at){
		array<int> ids = start_at.GetChildren();

		for(uint i = 0; i < ids.size(); i++){
			children_ids.insertLast(ids[i]);
			Object@ obj = ReadObjectFromID(ids[i]);
			obj.SetEnabled(false);
			if(obj.GetType() == _group){
				GetBlockChildrenIds(obj);
			}
		}
	}
}

float preload_progress = 0.0f;
int preload_counter = 0;

void PreloadBlocks(){
	if(!post_init_done || preload_done){return;}

	if(preload_counter < int(block_types.size())){
		preload_progress = (preload_counter + 1) * 100.0f / block_types.size();
		block_types[preload_counter].Preload();
		preload_counter += 1;
		ShowPreloadProgress();
	}else{
		preload_done = true;
		text_container.clear();
		MovementObject@ player = ReadCharacterID(player_id);
		player.static_char = false;
	}
}

bool final_translation_done = false;

void SetBlockFinalTranslation(){
	if(!post_init_done || !preload_done || final_translation_done){return;}

	for(uint i = 0; i < block_types.size(); i++){
		block_types[i].SetFinalTranslation();
	}
	final_translation_done = true;
}

BlockType@ GetRandomBlockType(){
	float sum = 0.0f;
	for(uint i = 0; i < block_types.size(); i++){
		sum += block_types[i].probability;
	}
	float random = RangedRandomFloat(0.0f, sum);
	for(uint i = 0; i < block_types.size(); i++){
		if(random < block_types[i].probability){
			return block_types[i];
		}
		random -= block_types[i].probability;
	}
	DisplayError("Ohno", "Random block did not return anything.");
	return block_types[0];
}

void ForgetCharacter(int id){
	array<int> mos = GetObjectIDsType(_movement_object);
	for(uint i = 0; i < mos.size(); i++){
		MovementObject@ char = ReadCharacterID(mos[i]);
		char.Execute("situation.MovementObjectDeleted(" + id + ");");
	}
}

class Garbage{
	array<int> item_objects;
	array<int> movement_objects;
	int group = -1;
	Garbage(){}
}

class Block{
	array<int> obj_ids;
	int main_block_id = -1;
	vec3 position;
	array<SpawnObject@> objects_to_spawn;
	bool deleted = false;

	Block(vec3 _position){
		position = _position;
		SpawnObject new_spawn(GetRandomBlockType(), position, this);
		objects_to_spawn.insertLast(@new_spawn);
	}

	array<SpawnObject@> GetObjectsToSpawn(){
		return objects_to_spawn;
	}

	Garbage Delete(){
		deleted = true;
		Garbage garbage();
		array<int> groups;
		for(uint i = 0; i < obj_ids.size(); i++){
			if(!ObjectExists(obj_ids[i])){
				continue;
			}
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(obj_ids[i]);
				MovementObject@ player = ReadCharacterID(player_id);
				if(distance(char.position, player.position) < (world_size * block_size / 2.0f)){
					garbage.movement_objects.insertLast(obj_ids[i]);
					continue;
				}else{
					//MovementObject need to be queued or else the ItemObject they hold is going to reset position in the same update.
					QueueDeleteObjectID(obj_ids[i]);
					ForgetCharacter(obj_ids[i]);
					continue;
				}
			}else if(obj.GetType() == _item_object){
				MovementObject@ player = ReadCharacterID(player_id);
				ItemObject@ item = ReadItemID(obj_ids[i]);
				vec3 color = vec3(RangedRandomFloat(0.0f, 1.0f), RangedRandomFloat(0.0f, 1.0f), RangedRandomFloat(0.0f, 1.0f));
				if(distance(item.GetPhysicsPosition(), player.position) < (world_size * block_size / 2.0f)){
					garbage.item_objects.insertLast(obj_ids[i]);
					continue;
				}
			}else if(obj.GetType() == _group){
				//The first group is the only one to delete, the rest will be inside this group, so ignore those.
				if(garbage.group == -1){
					garbage.group = obj_ids[i];
				}
				continue;
			}
			DeleteObjectID(obj_ids[i]);
		}
		obj_ids.resize(0);
		return garbage;
	}

	void AddObjectID(int id){
		obj_ids.insertLast(id);
	}

	void ConnectAll(){
		int char_id = -1;
		int item_id = -1;
		array<int> pathpoints;
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _path_point_object){
				pathpoints.insertLast(obj_ids[i]);
			}else if(obj.GetType() == _movement_object){
				char_id = obj_ids[i];
			}else if(obj.GetType() == _item_object){
				item_id = obj_ids[i];
			}
		}
		if(char_id != -1){
			Object@ char = ReadObjectFromID(char_id);
			for(uint i = 0; i < pathpoints.size(); i++){
				Object@ pathpoint = ReadObjectFromID(pathpoints[i]);
				if(i == 0){
					pathpoint.ConnectTo(char);
				}
				if(i == (pathpoints.size() - 1)){
					/*Object@ next_pathpoint = ReadObjectFromID(pathpoints[0]);
					pathpoint.ConnectTo(next_pathpoint);*/
				}else{
					Object@ next_pathpoint = ReadObjectFromID(pathpoints[i + 1]);
					pathpoint.ConnectTo(next_pathpoint);
				}
			}
			if(item_id != -1){
				Object@ item = ReadObjectFromID(item_id);
				char.AttachItem(item, _at_grip, false);
			}
		}
	}
}

class SpawnObject{
	BlockType@ block_type;
	vec3 position;
	Block@ owner;

	SpawnObject(BlockType _block_type, vec3 _position, Block@ _owner){
		position = _position;
		@owner = @_owner;
		@block_type = @_block_type;
	}
}

class World{
	array<array<Block@>> blocks;
	array<SpawnObject@> objects_to_spawn;
	array<Garbage> garbages;

	World(){}

	void Reset(){
		for(uint i = 0; i < blocks.size(); i++){
			for(uint j = 0; j < blocks[i].size(); j++){
				//Delete all the existing blocks and their garbage.
				Garbage garbage = blocks[i][j].Delete();
				if(garbage.group != -1){
					DeleteObjectID(garbage.group);
				}
			}
		}
		//Delete all the garbage that's already collected.
		for(uint i = 0; i < garbages.size(); i++){
			if(garbages[i].group != -1){
				DeleteObjectID(garbages[i].group);
			}
		}
		blocks.resize(0);
		garbages.resize(0);
	}

	void MoveXUp(){
		for(uint i = 0; i < blocks.size(); i++){
			garbages.insertAt(0, blocks[i][0].Delete());
			blocks[i].removeAt(0);
		}
		for(uint i = 0; i < blocks.size(); i++){
			Block@ new_block = CreateBlock(blocks[i][blocks[i].size() - 1], vec3(block_size * 2.0f, 0.0f, 0.0f));
			blocks[i].insertLast(new_block);
		}
	}

	void MoveXDown(){
		//Remove all the blocks on the left side so we can move to the right.
		for(uint i = 0; i < blocks.size(); i++){
			garbages.insertAt(0, blocks[i][blocks[i].size() - 1].Delete());
			blocks[i].removeAt(blocks[i].size() - 1);
		}
		for(uint i = 0; i < blocks.size(); i++){
			Block@ new_block = CreateBlock(blocks[i][0], vec3(-block_size * 2.0f, 0.0f, 0.0f));
			blocks[i].insertAt(0, new_block);
		}
	}

	void MoveZUp(){
		for(uint i = 0; i < blocks[0].size(); i++){
			garbages.insertAt(0, blocks[0][i].Delete());
		}
		blocks.removeAt(0);
		array<Block@> new_row;
		for(uint i = 0; i < blocks[blocks.size() - 1].size(); i++){
			Block@ new_block = CreateBlock(blocks[blocks.size() - 1][i], vec3(0.0f, 0.0f, block_size * 2.0f));
			new_row.insertLast(new_block);
		}
		blocks.insertLast(new_row);
	}

	void MoveZDown(){
		//Remove the bottom row.
		for(uint i = 0; i < blocks[blocks.size() - 1].size(); i++){
			garbages.insertAt(0, blocks[blocks.size() - 1][i].Delete());
		}
		blocks.removeLast();
		array<Block@> new_row;
		for(uint i = 0; i < blocks[0].size(); i++){
			Block@ new_block = CreateBlock(blocks[0][i], vec3(0.0f, 0.0f, -block_size * 2.0f));
			new_row.insertLast(new_block);
		}
		blocks.insertAt(0, new_row);
	}

	Block@ CreateBlock(Block@ adjacent_block, vec3 offset){
		Block new_block(adjacent_block.position + offset);
		objects_to_spawn.insertAt((objects_to_spawn.size()), new_block.GetObjectsToSpawn());
		return @new_block;
	}

	void CreateFloor(){
		Object@ player_obj = ReadObjectFromID(player_id);
		vec3 player_pos = vec3(floor(player_obj.GetTranslation().x),floor(player_obj.GetTranslation().y),floor(player_obj.GetTranslation().z));
		//Combine the player position, block size and player scale to create the floor height.
		floor_height = player_pos.y - (block_size * 2.0f) - 1.0f;

		//Looking top town, we start in the left top corner with builing.
		vec3 starting_pos = vec3(player_pos.x - (world_size * block_size) + (block_size), floor_height, player_pos.z - (world_size * block_size) + (block_size));
		for(uint i = 0; i < uint(world_size); i++){
			array<Block@> new_row;
			for(uint j = 0; j < uint(world_size); j++){
				vec3 new_block_pos = vec3(starting_pos.x + (block_size * float(j) * 2.0f), floor_height, starting_pos.z + (block_size * float(i) * 2.0f));
				Block new_block(new_block_pos);
				objects_to_spawn.insertAt((objects_to_spawn.size()), new_block.GetObjectsToSpawn());
				new_row.insertLast(@new_block);
			}
			blocks.insertLast(new_row);
		}
	}

	bool new_block = false;
	void UpdateSpawning(){
		if(objects_to_spawn.size() > 0){
			SpawnObject@ spawn_obj = objects_to_spawn[0];
			if(!spawn_obj.owner.deleted){
				//In the first update we create the object.
				if(!new_block){
					int id = DuplicateObject(spawn_obj.block_type.original);
					Object@ obj = ReadObjectFromID(id);
					obj.SetEnabled(true);
					obj.SetSelectable(true);
					obj.SetDeletable(true);
					obj.SetTranslatable(true);
					spawn_obj.owner.AddObjectID(id);
					AddNewBlockObjects(spawn_obj.owner, obj);

					RotateBlock(id);
					new_block = true;
				}else{
					//In the second update we translate the object to the correct spot.
					Block@ owner = spawn_obj.owner;
					int id = owner.obj_ids[0];
					Object@ obj = ReadObjectFromID(id);
					if(IsGroupDerived(id)){
						TransposeNewBlock(spawn_obj.owner, spawn_obj.block_type.path);
					}else{
						obj.SetTranslation(spawn_obj.position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f));
					}
					spawn_obj.owner.ConnectAll();
					new_block = false;
					objects_to_spawn.removeAt(0);
				}
			}else{
				objects_to_spawn.removeAt(0);
				new_block = false;
			}
		}
	}

	void AddNewBlockObjects(Block@ owner, Object@ obj){
		array<int> ids = obj.GetChildren();

		for(uint i = 0; i < ids.size(); i++){
			owner.AddObjectID(ids[i]);
			Object@ child_obj = ReadObjectFromID(ids[i]);
			if(child_obj.GetType() == _group){
				AddNewBlockObjects(owner, child_obj);
			}
		}
	}

	void RotateBlock(int id){
		Object@ obj = ReadObjectFromID(id);
		ScriptParams@ params = obj.GetScriptParams();
		if(obj.GetType() == _group){
			float x;
			float z;
			switch(rand() % 4){
				case 0:
					x = 1.0f;
					z = 0.0f;
					break;
				case 1:
					x = 0.0f;
					z = 1.0f;
					break;
				case 2:
					x = -1.0f;
					z = 0.0f;
					break;
				default:
					x = 0.0f;
					z = -1.0f;
					break;
			}
			float cur_rotation = atan2(x, z);
			quaternion rotation(vec4(0,1,0,cur_rotation));
			obj.SetRotation(rotation);
		}else{
			DisplayError("Ohno!", "First block is not a group!");
		}
	}

	void TransposeNewBlock(Block@ owner, string path){
		vec3 offset = vec3(0.0f);
		vec3 position = owner.position;
		vec3 base_pos = vec3(0.0f);
		bool block_base_found = false;
		array<int> obj_ids = owner.obj_ids;

		//Find the main base.
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			ScriptParams@ params = obj.GetScriptParams();
			if(params.HasParam("BlockBase")){
				offset = offset - obj.GetTranslation();
				base_pos = position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f);
				params.Remove("BlockBase");
				block_base_found = true;
				break;
			}
		}
		if(!block_base_found){
			DisplayError("Ohno", "No blockbase found in " + path);
		}
		//Now set all children with the offset.
		array<EntityType> transpose_types = {_env_object, _movement_object, _item_object, _hotspot_object, _decal_object, _dynamic_light_object, _path_point_object};
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(transpose_types.find(obj.GetType()) != -1){
				ScriptParams@ params = obj.GetScriptParams();
				if(obj_ids[i] != player_id){

					if(obj.GetType() == _movement_object){
						MovementObject@ char = ReadCharacterID(obj_ids[i]);
						char.Execute("Reset();");
						/* char.QueueScriptMessage("full_revive"); */
					}

					obj.SetTranslation(obj.GetTranslation() + base_pos + offset);
				}
			}
		}
	}

	float garbage_timer = 1.0f;
	void RemoveGarbage(){
		garbage_timer -= time_step;
		if(garbage_timer < 0.0f){
			garbage_timer = 1.0f;
			for(uint i = 0; i < garbages.size(); i++){
				MovementObject@ player = ReadCharacterID(player_id);
				Garbage@ current_garbage = garbages[i];

				for(uint j = 0; j < current_garbage.item_objects.size(); j++){
					ItemObject@ item = ReadItemID(current_garbage.item_objects[j]);
					if(distance(item.GetPhysicsPosition(), player.position) > (world_size * block_size)){
						if(ObjectExists(current_garbage.item_objects[j])){
							DeleteObjectID(current_garbage.item_objects[j]);
							current_garbage.item_objects.removeAt(j);
						}
						j--;
					}
				}

				for(uint j = 0; j < current_garbage.movement_objects.size(); j++){
					MovementObject@ char = ReadCharacterID(current_garbage.movement_objects[j]);
					if(distance(char.position, player.position) > (world_size * block_size)){
						//MovementObject need to be queued or else the ItemObject they hold is going to reset position in the same update.
						if(ObjectExists(current_garbage.movement_objects[j])){
							QueueDeleteObjectID(current_garbage.movement_objects[j]);
							ForgetCharacter(current_garbage.movement_objects[j]);
						}
						current_garbage.movement_objects.removeAt(j);
						j--;
					}
				}

				if (current_garbage.movement_objects.size() == 0 && current_garbage.item_objects.size() == 0) {
					if(current_garbage.group != -1 && ObjectExists(current_garbage.group)){
						QueueDeleteObjectID(current_garbage.group);
					}
					garbages.removeAt(i);
					i--;
				}
			}
		}
	}
}

void Init(string p_level_name){
	@imGUI = CreateIMGUI();
	@text_container = IMContainer(2560, 1440);
	CreateIMGUIContainers();
	text_container.setAlignment(CACenter, CACenter);
	IMText@ load_progress = IMText("Progress");
	load_progress.setFont(default_font);
	load_progress.setText("Preloading assets.");
	IMImage@ background = IMImage("Textures/error.tga");
	background.setSize(vec2(2560, 1440));
	background.setColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
	text_container.addFloatingElement(background, "background", vec2(0.0f, 0.0f));
	text_container.setElement(load_progress);
	level_name = p_level_name;
	PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
	ReadScriptParameters();
}

void CreateIMGUIContainers(){
	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	imGUI.getMain().setZOrdering(-1);
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));
}

void SetWindowDimensions(int width, int height){
	imGUI.doScreenResize();
}

void ShowPreloadProgress(){
	IMText @load_progress = cast<IMText>(text_container.getContents());
	/* IMText @load_progress = cast<IMText>(text_container.findElement("Progress")); */
	load_progress.setText("Progress : " + floor(preload_progress) + "%");
}

void ReadScriptParameters(){
	ScriptParams@ level_params = level.GetScriptParams();
	rain = level_params.GetInt("Rain") == 1;
	if(rain){
	  level_params.SetString("GPU Particle Field", "#RAIN");
	  level_params.SetString("Custom Shader", "#RAINY #ADD_MOON");
	  if(rand() % 2 == 0){
		  PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
	  }
	  if(rain_sound_id != -1){
		  StopSound(rain_sound_id);
		  rain_sound_id = -1;
	  }
	  rain_sound_id = PlaySoundLoop("Data/Sounds/weather/rain.wav", 1.0f);
	}else{
	  if(rain_sound_id != -1){
		  StopSound(rain_sound_id);
		  rain_sound_id = -1;
	  }
	  level_params.SetString("GPU Particle Field", "#BUGS");
	  level_params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
	}
	if(world_size != level_params.GetInt("World Size")){
		/* world_size = level_params.GetInt("World Size"); */
		rebuild_world = true;
	}
	if(block_size != level_params.GetInt("Block Size")){
		block_size = level_params.GetInt("Block Size");
		rebuild_world = true;
	}
}

bool HasFocus(){
	return false;
}

void Reset(){
	ReadScriptParameters();
	ResetLevel();
}

bool created_world = false;

void BuildWorld(){
	if((post_init_done && preload_done && final_translation_done && !created_world) || rebuild_world){
		world.Reset();
		world.CreateFloor();
		created_world = true;
		rebuild_world = false;
	}
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "reset"){
		Reset();
	}
}

void DrawGUI() {
	imGUI.render();
}

int update_counter = 0;
void PostInit(){
	if(!post_init_done){
		if(update_counter > 100){
			post_init_done = true;
		}
		update_counter += 1;
	}
}

bool preload_done = false;

void Update() {
	PostInit();
	PreloadBlocks();
	SetBlockFinalTranslation();
	GetPlayerID();
	BuildWorld();

	UpdateMovement();
	world.UpdateSpawning();
	world.RemoveGarbage();

	UpdateMusic();
	UpdateSounds();
	UpdateReviving();
	imGUI.update();
}

void GetPlayerID(){
	if(player_id == -1){
		uint num_chars = GetNumCharacters();
		for(uint a=0; a<num_chars; ++a){
			MovementObject@ char = ReadCharacter(a);
			if(char.controlled){
			  player_id = char.GetID();
			  break;
			}
		}
		if(player_id == -1){
		  player_id = ReadCharacter(0).GetID();
		}
		MovementObject@ player = ReadCharacterID(player_id);
		grid_position = vec2(floor(player.position.x / (block_size)), floor(player.position.z / (block_size)));
		player.static_char = true;
	}
}

void UpdateMovement(){
	if(!post_init_done || !preload_done || !final_translation_done || !created_world || rebuild_world){
		return;
	}

	MovementObject@ player = ReadCharacterID(player_id);
	vec2 new_grid_position = vec2(floor(player.position.x / (2.0f * block_size)), floor(player.position.z / (2.0f * block_size)));
	vec2 moved = vec2(0.0f);
	if(grid_position != new_grid_position){
	  if(new_grid_position.y > grid_position.y){
		  world.MoveZUp();
		  moved += vec2(0.0f, 1.0f);
	  }
	  if(new_grid_position.y < grid_position.y){
		  world.MoveZDown();
		  moved += vec2(0.0f, -1.0f);
	  }
	  if(new_grid_position.x > grid_position.x){
		  world.MoveXUp();
		  moved += vec2(1.0f, 0.0f);
	  }
	  if(new_grid_position.x < grid_position.x){
		  world.MoveXDown();
		  moved += vec2(-1.0f, 0.0f);
	  }
	  grid_position = grid_position + moved;
	}
}

void UpdateMusic() {
	int player_id = GetPlayerCharacterID();
	if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
		PlaySong("sad");
		return;
	}
	if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
		PlaySong("combat");
		return;
	}
	PlaySong("ambient-tense");
}

float delay = 5.0f;
float radius = 5.0f;
array<string> sounds = {"Data/Sounds/ambient/amb_forest_wood_creak_1.wav",
						"Data/Sounds/ambient/amb_forest_wood_creak_2.wav",
						"Data/Sounds/ambient/amb_forest_wood_creak_3.wav"};
void UpdateSounds(){
	delay -= time_step;
	if(delay < 0.0f){
		delay = RangedRandomFloat(3.0, 20.0f);
		MovementObject@ player = ReadCharacterID(player_id);
		vec3 position = player.position + vec3(RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius));
		PlaySound(sounds[rand() % sounds.size()], position);
	}
}

void UpdateReviving(){
	MovementObject@ player = ReadCharacterID(player_id);
	if(!EditorModeActive() && player.GetIntVar("knocked_out") == _dead && GetInputPressed(0, "mouse0")){
		Reset();
	}
}
