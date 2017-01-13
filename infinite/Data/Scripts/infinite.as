#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

bool reset_allowed = true;
float time = 0.0f;
string level_name;
int world_size = 30;
array<array<int>> world;
int player_id = -1;
float height = 0.0f;
vec2 width_length = vec2(0.0f,0.0f);
string building_block = "Data/Objects/primitives/edged_cube.xml";
vec3 block_scale = vec3(0.5);
int focus_block_id = -1;

MusicLoad ml("Data/Music/challengelevel.xml");

void Init(string p_level_name) {
    level_name = p_level_name;
    world.resize(world_size);
    for(uint i = 0; i < world.size(); i++){
        world[i].resize(world_size);
    }
}

bool HasFocus(){
    return false;
}

void Reset(){
    time = 0.0f;
    reset_allowed = true;
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
    } else if(token == "dispose_level"){
        gui.RemoveAll();
    } else if(token == "achievement_event"){
        token_iter.FindNextToken(msg);
    } else if(token == "achievement_event_float"){
        token_iter.FindNextToken(msg);
        string str = token_iter.GetToken(msg);
        token_iter.FindNextToken(msg);
        float val = atof(token_iter.GetToken(msg));
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
        MovementObject@ char = ReadCharacterID(player_id);
        height = floor(char.position.y);
        width_length = vec2(floor(char.position.x), floor(char.position.z));
        CreateFloor();
    }

    time += time_step;
    MovementObject@ player = ReadCharacterID(player_id);
    vec2 new_width_length = vec2(floor(player.position.x), floor(player.position.z));

    if(width_length != new_width_length){
        if(width_length.y > new_width_length.y){
            //DebugText("key", "Moved up", _fade);
            for(uint i = 0; i < world[world.size() - 1].size(); i++){
                DeleteObjectID(world[world.size() - 1][i]);
            }
            world.removeLast();

            array<int> new_row;
            for(uint i = 0; i < world[0].size(); i++){
                int id = CreateObject(building_block, true);
                new_row.insertLast(id);
                Object@ block = ReadObjectFromID(id);
                block.SetScale(block_scale);
                vec3 offset = vec3(0.0f, 0.0f, -1.0f);
                Object@ adjacent_block = ReadObjectFromID(world[0][i]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
            }
            world.insertAt(0, new_row);
        }
        if(width_length.y < new_width_length.y){
            //DebugText("key", "Moved down" , _fade);
            for(uint i = 0; i < world[0].size(); i++){
                DeleteObjectID(world[0][i]);
            }
            world.removeAt(0);

            array<int> new_row;
            for(uint i = 0; i < world[world.size() - 1].size(); i++){
                int id = CreateObject(building_block, true);
                new_row.insertLast(id);
                Object@ block = ReadObjectFromID(id);
                block.SetScale(block_scale);
                vec3 offset = vec3(0.0f, 0.0f, 1.0f);
                Object@ adjacent_block = ReadObjectFromID(world[world.size() - 1][i]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
            }
            world.insertLast(new_row);
        }
        if(width_length.x < new_width_length.x){
            //DebugText("key", "Moved right", _fade);
            for(uint i = 0; i < world.size(); i++){
                DeleteObjectID(world[i][0]);
                world[i].removeAt(0);
            }

            for(uint i = 0; i < world.size(); i++){
                int id = CreateObject(building_block, true);
                Object@ block = ReadObjectFromID(id);
                block.SetScale(block_scale);
                vec3 offset = vec3(1.0f, 0.0f, 0.0f);
                Object@ adjacent_block = ReadObjectFromID(world[i][world[i].size() - 1]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
                world[i].insertLast(id);
            }
        }
        if(width_length.x > new_width_length.x){
            //DebugText("key", "Moved left\n" , _fade);
            for(uint i = 0; i < world.size(); i++){
                DeleteObjectID(world[i][world[i].size() - 1]);
                world[i].removeAt(world[i].size() - 1);
            }

            for(uint i = 0; i < world.size(); i++){
                int id = CreateObject(building_block, true);
                Object@ block = ReadObjectFromID(id);
                block.SetScale(block_scale);
                vec3 offset = vec3(-1.0f, 0.0f, 0.0f);
                Object@ adjacent_block = ReadObjectFromID(world[i][0]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
                world[i].insertAt(0, id);
            }
        }
        width_length = new_width_length;
      }
}

void PrintBlockWorld(){
    for(uint i = 0; i < world.size(); i++){
        Print("[");
        for(uint j = 0; j < world[i].size(); j++){
            Print(" [" + world[i][j] + "] ");
        }
        Print("]\n");
    }
    Print("\n");
}

void CreateFloor(){
    MovementObject@ player = ReadCharacterID(player_id);
    vec3 player_pos = player.position;
    float floor_height = height - 10;
    for(uint i = 0; i < uint(world_size); i++){
        for(uint j = 0; j < uint(world_size); j++){
            int id = CreateObject(building_block, true);
            world[i][j] = id;
            Object@ block = ReadObjectFromID(id);
            block.SetScale(vec3(0.5f));
            block.SetTranslation(player_pos - vec3(world_size / 2, 0, world_size / 2) + vec3(float(j), floor_height, float(i)));
            //DebugDrawText(block.GetTranslation() + vec3(0.0f, 0.6f, 0.0f), "" + id, 5.0f, true, _persistent);
        }
    }
    //PrintBlockWorld();
}

void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}
