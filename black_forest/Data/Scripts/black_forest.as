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
ivec2 grid_position(0, 0);
bool rebuild_world = false;
EntityType _group = EntityType(29);
bool post_init_done = false;
IMGUI@ imGUI;
IMContainer@ text_container;
FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0;
array<int> character_reset_list;
bool released_player = false;
vec3 starting_pos;

MusicLoad ml("Data/Music/black_forest.xml");

World world;

enum block_creation_states{
	duplicate_block,
	translate_block,
	skip_state,
	make_connections
}

array<BlockType@> block_types = {
									BlockType("Data/Objects/block_house_1.xml", 1.0f, 1),
									BlockType("Data/Objects/block_house_2.xml", 1.0f, 1),
									BlockType("Data/Objects/block_house_3.xml", 1.0f, 1),
									BlockType("Data/Objects/block_trees_falen.xml", 1.0f, 1),

									BlockType("Data/Objects/block_wolf_den_1.xml", 0.05f, 1),
									BlockType("Data/Objects/block_wolf_den_2.xml", 0.05f, 1),
									BlockType("Data/Objects/block_wolf_den_3.xml", 0.05f, 1),
									BlockType("Data/Objects/block_wolf_den_4.xml", 0.05f, 1),

									BlockType("Data/Objects/block_lake_1.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_2.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_3.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_4.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_5.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_6.xml", 0.5f, 1),
									BlockType("Data/Objects/block_lake_7.xml", 0.5f, 1),

									BlockType("Data/Objects/block_guard_patrol.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_1.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_2.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_3.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_4.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_5.xml", 0.75f, 1),
									BlockType("Data/Objects/block_camp_6.xml", 0.75f, 1),

									BlockType("Data/Objects/block_ruins_1.xml", 3.0f, 1),
									BlockType("Data/Objects/block_ruins_2.xml", 3.0f, 1),
									BlockType("Data/Objects/block_ruins_3.xml", 3.0f, 1),
									BlockType("Data/Objects/block_ruins_4.xml", 3.0f, 1),
									BlockType("Data/Objects/block_ruins_5.xml", 3.0f, 1),
									BlockType("Data/Objects/block_ruins_6.xml", 3.0f, 1),

									BlockType("Data/Objects/block_trees_1.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_2.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_3.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_4.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_5.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_6.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_7.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_8.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_9.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_10.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_11.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_12.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_13.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_14.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_15.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_16.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_17.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_18.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_19.xml", 15.0f, 1),
									BlockType("Data/Objects/block_trees_20.xml", 15.0f, 1),

									BlockType("Data/Objects/block_gatehouse.xml", 50.0f, 2),
									BlockType("Data/Objects/block_stucco_house.xml", 50.0f, 4)
								};

class BlockType{
	string path;
	float probability;
	Object@ original;
	array<int> children_ids;
	vec3 target_translation = vec3(0.0f, -10000.0f, 0.0f);
	int block_size_mult;

	BlockType(string _path, float _probability, int _block_size_mult){
		path = _path;
		probability = _probability;
		block_size_mult = _block_size_mult;
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
			/* obj.SetEnabled(false); */
			if(obj.GetType() == _group){
				GetBlockChildrenIds(obj);
			}
		}
	}
}

float preload_progress = 0.0f;
int preload_counter = 0;
bool skip_one_preload = false;

void PreloadBlocks(){
	if(!post_init_done || preload_done){return;}

	if(skip_one_preload){
		skip_one_preload = false;
	}else if(preload_counter < int(block_types.size())){
		preload_progress = (preload_counter + 1) * 100.0f / block_types.size();
		block_types[preload_counter].Preload();
		preload_counter += 1;
		ShowPreloadProgress();
		skip_one_preload = true;
	}else{
		preload_done = true;
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

BlockType@ GetRandomBlockType(int available_space){
	float sum = 0.0f;
	array<BlockType@> filtered_block_types;

	for(uint i = 0; i < block_types.size(); i++){
		if(block_types[i].block_size_mult <= available_space){
			filtered_block_types.insertLast(block_types[i]);
		}
	}

	for(uint i = 0; i < filtered_block_types.size(); i++){
		sum += filtered_block_types[i].probability;
	}

	float random = RangedRandomFloat(0.0f, sum);
	for(uint i = 0; i < filtered_block_types.size(); i++){
		if(random < filtered_block_types[i].probability){
			return filtered_block_types[i];
		}
		random -= filtered_block_types[i].probability;
	}

	DisplayError("Ohno", "Random block did not return anything.");
	return filtered_block_types[0];
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
	BlockType@ type;
	array<ivec2> on_grid_positions;
	array<ivec2> off_grid_positions;

	Block(vec3 _position, int available_space){
		position = _position;
		@type = @GetRandomBlockType(available_space);
		SpawnObject new_spawn(type, position, this);
		objects_to_spawn.insertLast(@new_spawn);
		position.x += (type.block_size_mult * block_size) - (block_size);
		position.y -= (type.block_size_mult * block_size);
		position.z += (type.block_size_mult * block_size) - (block_size);
	}

	array<SpawnObject@> GetObjectsToSpawn(){
		return objects_to_spawn;
	}

	void Delete(ivec2 delete_position){
		for(uint i = 0; i < on_grid_positions.size(); i++){
			if(on_grid_positions[i].x == delete_position.x && on_grid_positions[i].y == delete_position.y){
				on_grid_positions.removeAt(i);
			}
		}

		if(on_grid_positions.size() == 0){
			AddToGarbage();
		}
	}

	void AddToGarbage(){
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

		world.garbages.insertLast(garbage);
		obj_ids.resize(0);
	}

	void AddObjectID(int id){
		obj_ids.insertLast(id);
	}

	void MakeConnections(){
		int char_id = -1;
		int item_id = -1;
		array<int> pathpoints;

		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _path_point_object){
				pathpoints.insertLast(obj_ids[i]);
			}else if(obj.GetType() == _item_object){
				item_id = obj_ids[i];
			}else if(obj.GetType() == _placeholder_object){
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Path")){
					PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
					placeholder_object.SetPreview("Data/Objects/IGF_Characters/pale_turner.xml");
					placeholder_object.SetSpecialType(kSpawn);

					string path = obj_params.GetString("Path");
					char_id = CreateObject(path);
					obj_ids.insertLast(char_id);
					Object@ char_obj = ReadObjectFromID(char_id);
					char_obj.SetTranslation(obj.GetTranslation());
				}
			}
		}

		if(char_id != -1){
			Object@ char = ReadObjectFromID(char_id);
			for(uint i = 0; i < pathpoints.size(); i++){
				//Connect the character to the first pathpoint.
				Object@ pathpoint = ReadObjectFromID(pathpoints[i]);
				if(i == 0){
					pathpoint.ConnectTo(char);
				}

				//Connect all the pathspoints together.
				if(i != (pathpoints.size() - 1)){
					Object@ next_pathpoint = ReadObjectFromID(pathpoints[i + 1]);
					pathpoint.ConnectTo(next_pathpoint);
				}
			}

			//Attach any item/weapon to the grip of the target character.
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

	SpawnObject(BlockType @_block_type, vec3 _position, Block@ _owner){
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
				if(blocks[i][j] !is null){
					//Delete all the existing blocks and their garbage.
					blocks[i][j].Delete(ivec2(i, j));
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
			/* garbages.insertAt(0, blocks[i][0].Delete()); */
		}

		for(uint i = 0; i < blocks.size(); i++){
			Block@ new_block = CreateBlock(vec3(block_size * 2.0f, 0.0f, 0.0f), i, blocks[i].size() - 1, 1, 1);
			blocks[i].insertLast(new_block);
		}
	}

	void MoveXDown(){
		//Remove all the blocks on the left side so we can move to the right.
		for(uint i = 0; i < blocks.size(); i++){
			/* garbages.insertAt(0, blocks[i][blocks[i].size() - 1].Delete()); */
		}

		for(uint i = 0; i < blocks.size(); i++){
			Block@ new_block = CreateBlock(vec3(-block_size * 2.0f, 0.0f, 0.0f), i, 0, -1, 1);
			blocks[i].insertAt(0, new_block);
		}
	}

	void MoveZUp(){
		for(uint i = 0; i < blocks[0].size(); i++){
			/* garbages.insertAt(0, blocks[0][i].Delete()); */
		}

		array<Block@> new_row;
		blocks.insertLast(new_row);
		for(uint i = 0; i < blocks[blocks.size() - 1].size(); i++){
			Block@ new_block = CreateBlock(vec3(0.0f, 0.0f, block_size * 2.0f), blocks.size() - 1, i, 1, -1);
			blocks[blocks.size() - 1].insertLast(new_block);
		}
	}

	void MoveZDown(){
		//Remove the bottom row.
		for(uint i = 0; i < blocks[blocks.size() - 1].size(); i++){
			/* garbages.insertAt(0, blocks[blocks.size() - 1][i].Delete()); */
		}

		array<Block@> new_row;
		blocks.insertAt(0, new_row);
		for(uint i = 0; i < blocks[0].size(); i++){
			Block@ new_block = CreateBlock(vec3(0.0f, 0.0f, -block_size * 2.0f), 0, i, 1, 1);
			blocks[0].insertLast(new_block);
		}
	}

	Block@ CreateBlock(vec3 position, int start_x, int start_y, int direction_x, int direction_y){
		int available_space = GetAvailableSpace(start_x, start_y, direction_x, direction_y);
		Block new_block(position, available_space);
		objects_to_spawn.insertAt((objects_to_spawn.size()), new_block.GetObjectsToSpawn());
		return @new_block;
	}

	int GetAvailableSpace(int start_x, int start_y, int direction_x, int direction_y){
		int available_space_y = 1;
		int available_space_x = 1;

		while(true){
			//Check how many blocks of space we have available in the row.
			if(int(blocks[start_x].size()) > start_y + (available_space_y * direction_x) && start_y + (available_space_y * direction_x) > 0){
				if(blocks[start_x][start_y + (available_space_y * direction_x)] is null){
					available_space_y += 1;
				}else{
					break;
				}
			}else{
				if(available_space_y > 2 * world_size){
					break;
				}else{
					available_space_y += 1;
				}
			}
		}

		while(true){
			//Check how many rows we have available in the whole blocks array.
			if(int(blocks.size()) > start_x + (available_space_x * direction_y) && start_x + (available_space_x * direction_y) > 0){
				if(blocks[start_x + (available_space_x * direction_y)][start_x] is null){
					available_space_x += 1;
				}else{
					break;
				}
			}else{
				if(available_space_x > 2 * world_size){
					break;
				}else{
					available_space_x += 1;
				}
			}
		}

		if(available_space_x < available_space_y){
			return available_space_x;
		}else{
			return available_space_y;
		}
	}

	void InsertBlock(int x, int y){
		if(int(blocks.size()) <= x){
			array<Block@> new_row(world_size);
			blocks.insertLast(new_row);
		}

		if(int(blocks.size()) > x && int(blocks[x].size()) > y && blocks[x][y] !is null){
			return;
		}

		int available_space = GetAvailableSpace(x, y, 1, 1);

		/* Log(warning, "available space " + available_space); */

		ivec2 adjusted_grid_location  = ivec2(grid_position.x - (world_size / 2) + x, grid_position.y - (world_size / 2) + y);
		Log(warning, "Grid position " + adjusted_grid_location.x + " " + adjusted_grid_location.y);
		vec3 adjusted_grid_position = vec3(adjusted_grid_location.x, 0.0f, adjusted_grid_location.y) * (block_size * 2.0f);
		Log(warning, "adjusted_grid_position " + adjusted_grid_position.x + " " + adjusted_grid_position.z);

		vec3 spawn_pos = starting_pos + adjusted_grid_position;
		Block new_block(spawn_pos, available_space);
		/* DebugDrawText(spawn_pos + vec3(0.0f, block_size, 0.0f), "x:" + x + "y:" + y + "\n" + available_space, 1.0f, true, _persistent); */
		objects_to_spawn.insertAt((objects_to_spawn.size()), new_block.GetObjectsToSpawn());

		//Set the same block at all the positions it occupies.
		for(uint k = 0; k < uint(pow(new_block.type.block_size_mult, 2.0f)); k++){
			int x_offset = int(floor(k / new_block.type.block_size_mult));
			int y_offset = int(floor(k % new_block.type.block_size_mult));

			//Add a new row if needed.
			if(int(blocks.size()) <= (x + x_offset)){
				array<Block@> new_row(world_size);
				blocks.insertLast(new_row);
			}
			//Expand row if needed.
			if(int(blocks[x + x_offset].size()) <= (y + y_offset)){
				blocks[x + x_offset].resize(blocks[x + x_offset].size() + 1);
			}

			if((x + x_offset) < world_size && (y + y_offset) < world_size){
				new_block.on_grid_positions.insertLast(ivec2(x + x_offset, y + y_offset));
			}else{
				new_block.off_grid_positions.insertLast(ivec2(x + x_offset, y + y_offset));
			}

			@blocks[x + x_offset][y + y_offset] = new_block;
		}
	}

	void CreateFloor(){
		Object@ player_obj = ReadObjectFromID(player_id);
		vec3 player_pos = vec3(floor(player_obj.GetTranslation().x),floor(player_obj.GetTranslation().y),floor(player_obj.GetTranslation().z));
		floor_height = player_pos.y - (block_size) - 1.0f;

		starting_pos = player_pos;
		starting_pos.y = floor_height;

		for(uint i = 0; i < uint(world_size); i++){
			for(uint j = 0; j < uint(world_size); j++){
				InsertBlock(i, j);
			}
		}
	}

	block_creation_states block_creation_state = duplicate_block;
	int skip_counter = 0;

	void UpdateSpawning(){
		if(!preload_done){return;}

		if(objects_to_spawn.size() > 0){

			ShowBuildProgress();

			if(!released_player){
				MovementObject@ player = ReadCharacterID(player_id);
				Object@ spawn = ReadObjectFromID(player_id);
				player.velocity = vec3(0.0f);
				player.position = spawn.GetTranslation();
			}

			SpawnObject@ spawn_obj = objects_to_spawn[0];
			if(!spawn_obj.owner.deleted){
				//In the first update we create the object.
				if(block_creation_state == duplicate_block){
					int id = DuplicateObject(spawn_obj.block_type.original);
					Object@ obj = ReadObjectFromID(id);
					obj.SetEnabled(true);
					obj.SetSelectable(true);
					obj.SetDeletable(true);
					obj.SetTranslatable(true);
					spawn_obj.owner.AddObjectID(id);
					AddNewBlockObjects(spawn_obj.owner, obj);

					RotateBlock(id);
					block_creation_state = skip_state;
				}if(block_creation_state == skip_state){
					//Because prefabs take a while to load, we need to pause a couple of updates before translating.
					skip_counter += 1;
					if(skip_counter == 2){
						skip_counter = 0;
						block_creation_state = translate_block;
					}
				}if(block_creation_state == translate_block){
					//In the second update we translate the object to the correct spot.
					int id = spawn_obj.owner.obj_ids[0];
					Object@ obj = ReadObjectFromID(id);
					if(IsGroupDerived(id)){
						TransposeNewBlock(spawn_obj.owner, spawn_obj.block_type.path);
					}else{
						obj.SetTranslation(spawn_obj.position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f));
					}
					block_creation_state = make_connections;
				}if(block_creation_state == make_connections){
					spawn_obj.owner.MakeConnections();
					objects_to_spawn.removeAt(0);
					block_creation_state = duplicate_block;
				}
			}else{
				objects_to_spawn.removeAt(0);
				block_creation_state = duplicate_block;
			}
		}else if(!released_player){
			MovementObject@ player = ReadCharacterID(player_id);
			player.static_char = false;
			released_player = true;
			text_container.clear();
			/* blackout_amount = 1.0f; */
			UpdateGlobalReflection();
		}
	}

	void AddNewBlockObjects(Block@ owner, Object@ obj){
		array<int> ids = obj.GetChildren();

		for(uint i = 0; i < ids.size(); i++){
			owner.AddObjectID(ids[i]);
			Object@ child_obj = ReadObjectFromID(ids[i]);
			if(child_obj.GetType() == _group){
				AddNewBlockObjects(owner, child_obj);
			}else if(child_obj.GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(ids[i]);
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
				if(!released_player){
					obj.SetTint(vec3(0.0f, 0.0f, 10.0f));
				}

				break;
			}
		}

		if(!block_base_found){
			DisplayError("Ohno", "No blockbase found in " + path);
		}

		//Now set all children with the offset.
		array<EntityType> transpose_types = {_env_object, _movement_object, _item_object, _hotspot_object, _decal_object, _dynamic_light_object, _path_point_object, _placeholder_object};
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _prefab){
				DisplayError("Error", "Block contains a prefab! " + path);
			}
			if(obj_ids[i] != player_id && transpose_types.find(obj.GetType()) != -1){
				vec3 start_pos = obj.GetTranslation();
				quaternion start_rot = obj.GetRotation();
				obj.SetTranslation(start_pos + base_pos + offset);
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
	/* text_container.addFloatingElement(background, "background", vec2(0.0f, 0.0f)); */
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
	load_progress.setText("       " + floor(preload_progress) + "%\nPreloading assets.");
}

void ShowBuildProgress(){
	IMText @load_progress = cast<IMText>(text_container.getContents());
	if(load_progress !is null){
		load_progress.setText(world.objects_to_spawn.size() + " blocks left.\nCreating world.");
	}
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
		world_size = level_params.GetInt("World Size");
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
	resetting = true;
	MovementObject@ player = ReadCharacterID(player_id);
	player.static_char = true;
}

bool created_world = false;

void BuildWorld(){
	if((post_init_done && preload_done && final_translation_done && !created_world)){
		world.Reset();
		world.CreateFloor();
		created_world = true;
		rebuild_world = false;
	}
}

void UpdateGlobalReflection(){
	array<int> gl_ids = GetObjectIDsType(_reflection_capture_object);
	for(uint i = 0; i < gl_ids.size(); i++){
		Object@ gl_obj = ReadObjectFromID(gl_ids[i]);
		gl_obj.SetTranslation(gl_obj.GetTranslation() + vec3(RangedRandomFloat(-1.0f, 1.0f)));
		/* DebugDrawText(gl_obj.GetTranslation(), "GlobalReflection", 1.0f, true, _persistent); */
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
	HUDImage @blackout_image = hud.AddImage();
	blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
	blackout_image.position.y = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.x = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.z = -2.0f;
	blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight()) * 2.0f;
	blackout_image.color = vec4(0.0f, 0.0f, 0.0f, blackout_amount);
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
bool resetting = false;

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
	UpdateFading();
	imGUI.update();

	if(resetting){
		created_world = false;
		released_player = false;
		player_id = -1;
		resetting = false;
		/* blackout_amount = 1.0f; */
	}
}

void UpdateFading(){
	if(world.objects_to_spawn.size() == 0 && blackout_amount > 0.0f){
		blackout_amount -= time_step * 0.5f;;
	}
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
		grid_position = ivec2(int(floor(player.position.x / (block_size))), int(floor(player.position.z / (block_size))));
		player.static_char = true;
	}
}

void UpdateMovement(){
	if(!post_init_done || !preload_done || !final_translation_done || !created_world || rebuild_world){
		return;
	}

	MovementObject@ player = ReadCharacterID(player_id);
	ivec2 new_grid_position = ivec2(int(floor(player.position.x / (2.0f * block_size))), int(floor(player.position.z / (2.0f * block_size))));
	ivec2 moved = ivec2(0);
	if(grid_position.x != new_grid_position.x && grid_position.y != new_grid_position.y){
		if(new_grid_position.y > grid_position.y){
			/* world.MoveZUp(); */
			moved += ivec2(0, 1);
		}
		if(new_grid_position.y < grid_position.y){
			/* world.MoveZDown(); */
			moved += ivec2(0, -1);
		}
		if(new_grid_position.x > grid_position.x){
			/* world.MoveXUp(); */
			moved += ivec2(1, 0);
		}
		if(new_grid_position.x < grid_position.x){
			/* world.MoveXDown(); */
			moved += ivec2(-1, 0);
		}
		grid_position = grid_position + moved;
		Log(warning, "grid_position : " + grid_position.x + "," + grid_position.y);
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
	if(!EditorModeActive() && player.GetIntVar("knocked_out") != _awake && GetInputPressed(0, "mouse0")){
		Reset();
	}
}
