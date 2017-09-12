#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

//Parameters for user to change
int world_size = 5;
float block_size = 10.0f;
string building_block = "Data/Objects/block_path_straight_horizontal.xml";

//Variables not to be manually changed
string level_name;
int player_id = -1;
float height = 0.0f;
vec2 width_length = vec2(0.0f,0.0f);
int main_block_id = -1;
vec3 main_color = vec3(0);
float timer = 0.0f;
bool reset_player = true;
float floor_height;
vec2 grid_position;

MusicLoad ml("Data/Music/black_forest.xml");

World world;
int skip_update = 0;

array<BlockType@> block_types = {
                                    BlockType("Data/Objects/block_trees_1.xml", 5.1f),
                                    BlockType("Data/Objects/block_trees_2.xml", 5.1f),
                                    BlockType("Data/Objects/block_trees_3.xml", 5.1f),
                                    BlockType("Data/Objects/block_trees_4.xml", 5.1f),
                                    BlockType("Data/Objects/block_trees_5.xml", 5.1f)};
                                    /*BlockType("Data/Objects/block_trees_prefab.xml", 10.0f)};*/
                                    /*BlockType("Data/Objects/block_path_straight_vertical.xml", 5.1f),
                                    BlockType("Data/Objects/block_path_straight_horizontal.xml", 5.1f),
                                    BlockType("Data/Objects/block_house.xml", 5.1f),
                                    BlockType("Data/Objects/block_camp.xml", 5.1f),
                                    BlockType("Data/Objects/block_bushes.xml", 5.1f),
                                    BlockType("Data/Objects/block_tree.xml", 5.1f),
                                    BlockType("Data/Objects/block_tree_2.xml", 5.1f),
                                    BlockType("Data/Objects/block_trees.xml", 1.1f),
                                    BlockType("Data/Objects/block_trees_dense.xml", 1.0f),
                                    BlockType("Data/Objects/block_ruins.xml", 5.1f),
                                    BlockType("Data/Objects/block_guard_sword.xml", 0.0f),
                                    BlockType("Data/Objects/prefab.xml", 0.0f)};*/

class BlockType{
    string path;
    float probability;
    Object@ original;
    BlockType(string _path, float _probability){
        path = _path;
        probability = _probability;
    }
    void Init(){
        /*@original = ReadObjectFromID(CreateObject(path));
        original.SetEnabled(false);
        ScriptParams@ params = original.GetScriptParams();
        if(params.HasParam("Transpose")){
            params.Remove("Transpose");
            array<int> all_obj = GetObjectIDs();
            for(uint i = 0; i < all_obj.size(); i++){
                Object@ child = ReadObjectFromID(all_obj[i]);
                ScriptParams@ child_params = child.GetScriptParams();
                if(child_params.HasParam("BlockBase")){
                    child_params.Remove("BlockBase");
                }
                if(child_params.HasParam("BlockChild")){
                    child_params.Remove("BlockChild");
                }
            }
        }*/
    }
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

        /*int id = CreateObject(building_block);
        AddObjectID(id);
        Object@ obj = ReadObjectFromID(id);
        obj.SetTranslation(position);*/
    }
    array<SpawnObject@> GetObjectsToSpawn(){
        return objects_to_spawn;
    }
    void Delete(){
        if(obj_ids.size() < 0){
            Print("No objects!\n");
        }
        for(uint i = 0; i < obj_ids.size(); i++){
            /*QueueDeleteObjectID(obj_ids[i]);*/
            DeleteObjectID(obj_ids[i]);
        }
        obj_ids.resize(0);
        deleted = true;
    }
    void AddObjectID(int id){
        obj_ids.insertLast(id);
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
    World(){}
    void Reset(){}
    void MoveXUp(){
        for(uint i = 0; i < blocks.size(); i++){
            blocks[i][0].Delete();
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
            blocks[i][blocks[i].size() - 1].Delete();
            blocks[i].removeAt(blocks[i].size() - 1);
        }
        for(uint i = 0; i < blocks.size(); i++){
            Block@ new_block = CreateBlock(blocks[i][0], vec3(-block_size * 2.0f, 0.0f, 0.0f));
            blocks[i].insertAt(0, new_block);
        }
    }
    void MoveZUp(){
        for(uint i = 0; i < blocks[0].size(); i++){
            blocks[0][i].Delete();
        }
        blocks.removeAt(0);
        array<Block@> new_row;
        for(int i = 0; i < world_size; i++){
            Block@ new_block = CreateBlock(blocks[blocks.size() - 1][i], vec3(0.0f, 0.0f, block_size * 2.0f));
            new_row.insertLast(new_block);
        }
        blocks.insertLast(new_row);
    }
    void MoveZDown(){
        //Remove the bottom row.
        for(uint i = 0; i < blocks[blocks.size() - 1].size(); i++){
            blocks[blocks.size() - 1][i].Delete();
        }
        blocks.removeLast();
        array<Block@> new_row;
        for(int i = 0; i < world_size; i++){
            Block@ new_block = CreateBlock(blocks[0][i], vec3(0.0f, 0.0f, -block_size * 2.0f));
            new_row.insertLast(new_block);
        }
        blocks.insertAt(0, new_row);
    }
    Block@ CreateBlock(Block@ adjacent_block, vec3 offset){
        /*DebugDrawLine(adjacent_block.position + offset, adjacent_block.position + offset + vec3(0.0f,20.0f,0.0f), vec3(0.0f), _persistent);*/
        Block new_block(adjacent_block.position + offset);
        objects_to_spawn.insertAt(0, new_block.GetObjectsToSpawn());
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
                /*DebugDrawText(new_block_pos + vec3(0,10.0f,0), i + ":" + j, 1.0f, true, _persistent);*/
                Block new_block(new_block_pos);
                objects_to_spawn.insertAt(0, new_block.GetObjectsToSpawn());
                new_row.insertLast(@new_block);
            }
            blocks.insertLast(new_row);
        }
        /*while(objects_to_spawn.size() > 0){
            UpdateSpawning();
        }*/
    }
    void UpdateSpawning(){
        if(objects_to_spawn.size() > 0){
            if(!objects_to_spawn[0].owner.deleted){

                /*int id = DuplicateObject(objects_to_spawn[0].block_type.original);
                Object@ new_block = ReadObjectFromID(id);
                new_block.SetSelectable(false);
                /*new_block.SetScale(vec3(10.0f));*/
                /*new_block.SetTranslation(objects_to_spawn[0].position + vec3(0.0f, new_block.GetBoundingBox().y / 2.0f, 0.0f));*/

                /*int id = DuplicateObject(objects_to_spawn[0].block_type.original);*/
                //Other scripts can create objects as well. So we first need to mark those as old or else they will get added to the world system.
                MarkOldObjects();
                int id = CreateObject(objects_to_spawn[0].block_type.path);

                objects_to_spawn[0].owner.AddObjectID(id);
                Object@ obj = ReadObjectFromID(id);
                vec3 bounds = obj.GetBoundingBox();
                if(IsGroupDerived(id)){
                    ScriptParams@ params = obj.GetScriptParams();
                    TransposeNewBlock(objects_to_spawn[0]);
                    /*obj.SetTranslation(objects_to_spawn[0].position + vec3(0.0f, obj.GetScale().y / 2.0f, 0.0f));*/
                }else{
                    obj.SetTranslation(objects_to_spawn[0].position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f));
                }
            }
            objects_to_spawn.removeAt(0);
        }
    }
    void TransposeNewBlock(SpawnObject@ spawn_object){
        //Find the main base.
        array<int> all_obj = GetObjectIDs();
        vec3 offset = vec3(0.0f);
        vec3 position = spawn_object.owner.position;
        vec3 base_pos = vec3(0.0f);
        bool block_base_found = false;

        for(uint i = 0; i < all_obj.size(); i++){
            Object@ obj = ReadObjectFromID(all_obj[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(params.HasParam("BlockBase")){
                //Add the blockbase to the added objects so that it can be removed later.
                spawn_object.owner.AddObjectID(all_obj[i]);
                offset = offset - obj.GetTranslation();
                obj.SetTranslation(position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f));
                base_pos = position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f);
                params.Remove("BlockBase");
                params.AddInt("Old", 1);
                block_base_found = true;
                break;
            }
        }
        if(!block_base_found){
            DisplayError("Ohno", "No blockbase found in " + spawn_object.block_type.path);
        }
        /*DebugDrawLine(position, position + vec3(0.0f,20.0f,0.0f), vec3(0.0f), _persistent);*/

        //Now set all children with the offset.
        int num = 0;

        array<EntityType> transpose_types = {_env_object, _movement_object, _item_object, _hotspot_object, _decal_object, _dynamic_light_object, _path_point_object};

        for(uint i = 0; i < all_obj.size(); i++){
            Object@ obj = ReadObjectFromID(all_obj[i]);
            if(transpose_types.find(obj.GetType()) != -1){
                ScriptParams@ params = obj.GetScriptParams();
                if(!params.HasParam("Old") && all_obj[i] != player_id){
                    spawn_object.owner.AddObjectID(all_obj[i]);
                    params.AddInt("Old", 1);
                    obj.SetTranslation(obj.GetTranslation() + base_pos + offset);
                    num++;
                }
            }
        }
        Print("Found " + num + " children\n");
    }

    void MarkOldObjects(){
        array<int> all_obj = GetObjectIDs();
        for(uint i = 0; i < all_obj.size(); i++){
            Object@ obj = ReadObjectFromID(all_obj[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(!params.HasParam("Old")){
                params.AddInt("Old", 1);
            }
        }
    }
    float timer = 0.0f;
    bool rain = false;
    void UpdateWeather(){
        /*if(timer > 50.0f){
            timer = 0.0f;
            ScriptParams@ params = level.GetScriptParams();
            if(rain){
                params.SetString("GPU Particle Field", "#RAIN");
            }else{
                params.Remove("GPU Particle Field");
            }
            rain = !rain;
        }
        timer += time_step;*/
    }
}

void Init(string p_level_name) {
    level_name = p_level_name;
    for(uint i = 0; i < block_types.size(); i++){
        block_types[i].Init();
    }
    PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
}

void ReadScriptParameters(){
  ScriptParams@ level_params = level.GetScriptParams();
}

bool HasFocus(){
    return false;
}

void Reset(){
  /*player_id = -1;
  reset_player = true;*/
}

void ResetWorld(){
    array<int> all_obj = GetObjectIDs();
    for(uint i = 0; i < all_obj.size(); i++){
        Print("Prebuild id " + all_obj[i] + "\n");
    }
    world.Reset();
    ReadScriptParameters();
    world.CreateFloor();
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

}

void Update() {
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
        /*Print("Position " + grid_position.x + " " + grid_position.y + "\n");*/
        ResetWorld();
    }else{
      UpdateMovement();
      world.UpdateSpawning();
      world.UpdateWeather();
    }
    UpdateMusic();
    UpdateSounds();
}

void UpdateMovement(){
    MovementObject@ player = ReadCharacterID(player_id);
    vec2 new_grid_position = vec2(floor(player.position.x / (2.0f * block_size)), floor(player.position.z / (2.0f * block_size)));

    DebugText("awe", "Player pos " + player.position.x + " And " + player.position.z, _delete_on_update);
    DebugText("awe2", "New grid pos " + new_grid_position.x + " And " + new_grid_position.y, _delete_on_update);

    /*vec2 new_grid_position = vec2(floor(player.position.x), floor(player.position.z));*/
    vec2 moved = vec2(0.0f);
    if(grid_position != new_grid_position){
        /*Print("Grid pos changed\n");*/
      if(new_grid_position.y > grid_position.y){
          Print("Moved up\n");
          world.MoveZUp();
          moved += vec2(0.0f, 1.0f);
      }
      if(new_grid_position.y < grid_position.y){
          Print("Moved down\n");
          world.MoveZDown();
          moved += vec2(0.0f, -1.0f);
      }
      if(new_grid_position.x > grid_position.x){
          /*Print("Moved left\n");*/
          world.MoveXUp();
          moved += vec2(1.0f, 0.0f);
      }
      if(new_grid_position.x < grid_position.x){
          /*Print("Moved right\n");*/
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
