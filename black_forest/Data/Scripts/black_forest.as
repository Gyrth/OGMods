#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

//Parameters for user to change
int world_size = 4;
float block_size = 10.0f;
string building_block = "Data/Objects/block_path_straight_horizontal.xml";
bool rain = false;
//Variables not to be manually changed
int rain_sound_id = -1;
string level_name;
int player_id = -1;
bool reset_player = true;
float floor_height;
vec2 grid_position;
bool rebuild_world = false;

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

void ForgetCharacter(int id){
    array<int> mos = GetObjectIDsType(_movement_object);
    for(uint i = 0; i < mos.size(); i++){
        MovementObject@ char = ReadCharacterID(mos[i]);
        char.Execute("situation.MovementObjectDeleted(" + id + ");");
    }
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
    array<int> Delete(){
        array<int> garbage;
        for(uint i = 0; i < obj_ids.size(); i++){
            Object@ obj = ReadObjectFromID(obj_ids[i]);
            if(obj.GetType() == _movement_object){
                MovementObject@ char = ReadCharacterID(obj_ids[i]);
                MovementObject@ player = ReadCharacterID(player_id);
                if(distance(char.position, player.position) < (world_size * block_size / 2.0f)){
                    garbage.insertLast(obj_ids[i]);
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
                    /*DebugDrawWireSphere(item.GetPhysicsPosition(), 0.5f, color, _persistent);
                    DebugDrawWireSphere(player.position, 0.5f, color, _persistent);*/
                    garbage.insertLast(obj_ids[i]);
                    continue;
                }
            }
            DeleteObjectID(obj_ids[i]);
        }
        obj_ids.resize(0);
        deleted = true;
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
    array<int> garbage;
    World(){}
    void Reset(){
        for(uint i = 0; i < blocks.size(); i++){
            for(uint j = 0; j < blocks[i].size(); j++){
                blocks[i][j].Delete();
            }
        }
        for(uint i = 0; i < garbage.size(); i++){
            DeleteObjectID(garbage[i]);
        }
        blocks.resize(0);
        garbage.resize(0);
    }
    void MoveXUp(){
        for(uint i = 0; i < blocks.size(); i++){
            garbage.insertAt(0, blocks[i][0].Delete());
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
            garbage.insertAt(0, blocks[i][blocks[i].size() - 1].Delete());
            blocks[i].removeAt(blocks[i].size() - 1);
        }
        for(uint i = 0; i < blocks.size(); i++){
            Block@ new_block = CreateBlock(blocks[i][0], vec3(-block_size * 2.0f, 0.0f, 0.0f));
            blocks[i].insertAt(0, new_block);
        }
    }
    void MoveZUp(){
        for(uint i = 0; i < blocks[0].size(); i++){
            garbage.insertAt(0, blocks[0][i].Delete());
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
            garbage.insertAt(0, blocks[blocks.size() - 1][i].Delete());
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
        array<EntityType> transpose_types = {_env_object, _movement_object, _item_object, _hotspot_object, _decal_object, _dynamic_light_object, _path_point_object};
        for(uint i = 0; i < all_obj.size(); i++){
            Object@ obj = ReadObjectFromID(all_obj[i]);
            if(transpose_types.find(obj.GetType()) != -1){
                ScriptParams@ params = obj.GetScriptParams();
                if(!params.HasParam("Old") && all_obj[i] != player_id){
                    spawn_object.owner.AddObjectID(all_obj[i]);
                    params.AddInt("Old", 1);
                    obj.SetTranslation(obj.GetTranslation() + base_pos + offset);
                }
            }
        }
        spawn_object.owner.ConnectAll();
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
    float garbage_timer = 1.0f;
    void RemoveGarbage(){
        garbage_timer -= time_step;
        if(garbage_timer < 0.0f){
            garbage_timer = 1.0f;
            for(uint i = 0; i < garbage.size(); i++){
                Object@ obj = ReadObjectFromID(garbage[i]);
                if(obj.GetType() == _movement_object){
                    MovementObject@ char = ReadCharacterID(garbage[i]);
                    MovementObject@ player = ReadCharacterID(player_id);
                    if(distance(char.position, player.position) > (world_size * block_size)){
                        //MovementObject need to be queued or else the ItemObject they hold is going to reset position in the same update.
                        QueueDeleteObjectID(garbage[i]);
                        ForgetCharacter(garbage[i]);
                        garbage.removeAt(i);
                        i--;
                    }
                }else if(obj.GetType() == _item_object){
                    MovementObject@ player = ReadCharacterID(player_id);
                    ItemObject@ item = ReadItemID(garbage[i]);
                    if(distance(item.GetPhysicsPosition(), player.position) > (world_size * block_size)){
                        /*DebugDrawLine(item.GetPhysicsPosition(), player.position, vec3(1.0f), _persistent);*/
                        DeleteObjectID(garbage[i]);
                        garbage.removeAt(i);
                        i--;
                    }
                }
            }
        }
    }
    float timer = RangedRandomFloat(5.0f, 6.0f);
    void UpdateWeather(){
        /*if(timer < 0.0f){
            timer = RangedRandomFloat(5.0f, 6.0f);
            ScriptParams@ params = level.GetScriptParams();
            if(rain){
                params.SetString("GPU Particle Field", "#RAIN");
                params.SetString("Custom Shader", "#RAINY #ADD_MOON");
                if(rand() % 2 == 0){
                    PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
                }
                rain_sound_id = PlaySoundLoop("Data/Sounds/weather/rain.wav", 1.0f);
            }else{
                if(rain_sound_id != -1){
                    StopSound(rain_sound_id);
                    rain_sound_id = -1;
                }
                params.SetString("GPU Particle Field", "#BUGS");
                params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
            }
            rain = !rain;
        }
        timer -= time_step;*/
    }
}

void Init(string p_level_name) {
    level_name = p_level_name;
    for(uint i = 0; i < block_types.size(); i++){
        block_types[i].Init();
    }
    PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
    ReadScriptParameters();
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
    if(rebuild_world){
        BuildWorld();
        rebuild_world = false;
    }
}

void BuildWorld(){
    world.Reset();
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
        BuildWorld();
    }else{
      UpdateMovement();
      world.UpdateSpawning();
      world.UpdateWeather();
      world.RemoveGarbage();
    }
    UpdateMusic();
    UpdateSounds();
    UpdateReviving();
}

void UpdateMovement(){
    MovementObject@ player = ReadCharacterID(player_id);
    vec2 new_grid_position = vec2(floor(player.position.x / (2.0f * block_size)), floor(player.position.z / (2.0f * block_size)));

    /*DebugText("awe", "Player pos " + player.position.x + " And " + player.position.z, _delete_on_update);
    DebugText("awe2", "New grid pos " + new_grid_position.x + " And " + new_grid_position.y, _delete_on_update);*/

    /*vec2 new_grid_position = vec2(floor(player.position.x), floor(player.position.z));*/
    vec2 moved = vec2(0.0f);
    if(grid_position != new_grid_position){
        /*Print("Grid pos changed\n");*/
      if(new_grid_position.y > grid_position.y){
          /*Print("Moved up\n");*/
          world.MoveZUp();
          moved += vec2(0.0f, 1.0f);
      }
      if(new_grid_position.y < grid_position.y){
          /*Print("Moved down\n");*/
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

void UpdateReviving(){
    MovementObject@ player = ReadCharacterID(player_id);
    if(!EditorModeActive() && player.GetIntVar("knocked_out") == _dead && GetInputPressed(0, "mouse0")){
        Reset();
    }
}
