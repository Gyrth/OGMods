#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

bool reset_allowed = true;
float time = 0.0f;
string level_name;
int world_size = 10;
array<array<array<int>>> world;
int player_id = -1;
float height = 0.0f;
vec2 width_length = vec2(0.0f,0.0f);
string building_block = "Data/Objects/primitives/edged_cube.xml";
vec3 block_scale = vec3(3.0);
int focus_block_id = -1;
int main_block_id = -1;

MusicLoad ml("Data/Music/challengelevel.xml");

void Init(string p_level_name) {
    level_name = p_level_name;
    world.resize(world_size);
    for(uint i = 0; i < world.size(); i++){
        world[i].resize(world_size);
        for(uint j = 0; j < world.size(); j++){
            world[i][j].resize(world_size);
        }
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
        main_block_id = CreateObject(building_block, true);
        Object@ block = ReadObjectFromID(main_block_id);
        block.SetScale(0.0f);
        CreateFloor();
        PrintBlockWorld();

        Object@ adjacent_block = ReadObjectFromID(world[0][0][0]);
        Print("Id at 0 0 0: " + world[0][0][0] + "\n");
    }

    time += time_step;
    MovementObject@ player = ReadCharacterID(player_id);
    vec2 new_width_length = vec2(floor(player.position.x / (2.0f * block_scale.x)), floor(player.position.z / (2.0f * block_scale.x)));

    //Print("New:" + new_width_length.x + "x" + new_width_length.y + " " + " Cur:" + width_length.x + "x" + width_length.y + "\n");

    //Print(new_width_length.x + " is between " + (width_length.x - (2.0f * block_scale.x)) + " and " + (width_length.x + (2.0f * block_scale.x)) + "\n");

    //if(new_width_length.x < (width_length.x - (block_scale.x)) || new_width_length.x > (width_length.x + (block_scale.x)) ||
    //  new_width_length.y < (width_length.y - (block_scale.x)) || new_width_length.y > (width_length.y + (block_scale.x))){
    if(width_length != new_width_length){
        //Print(" " + width_length.x + " " + width_length.y + " i snot " + new_width_length.x + " " + new_width_length.y + "\n");
        if(width_length.y > new_width_length.y){
            //DebugText("key", "Moved up", _fade);
            for(uint i = 0; i < world[world.size() - 1].size(); i++){
                DeleteObjectID(world[world.size() - 1][i][0]);
            }
            world.removeLast();

            array<array<int>> new_row(world_size, array<int>(3));
            for(uint i = 0; i < world[0].size(); i++){
                int id = DuplicateObject(ReadObjectFromID(main_block_id));
                //int id = CreateObject(building_block, true);
                new_row[i][0] = id;
                Object@ block = ReadObjectFromID(id);
                //block.SetScale(block_scale);
                block.SetScale(0.99f * block_scale);
                vec3 offset = vec3(0.0f, 0.0f, -1.0f) * (2.0f * block_scale.x);
                Object@ adjacent_block = ReadObjectFromID(world[0][i][0]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
                //DebugDrawLine(player.position, adjacent_block.GetTranslation(), vec3(0), _fade);
            }
            world.insertAt(0, new_row);
        }
        if(width_length.y < new_width_length.y){
            //DebugText("key", "Moved down" , _fade);
            for(uint i = 0; i < world[0].size(); i++){
                DeleteObjectID(world[0][i][0]);
            }
            world.removeAt(0);

            array<array<int>> new_row(world_size, array<int>(3));
            for(uint i = 0; i < world[world.size() - 1].size(); i++){
                int id = DuplicateObject(ReadObjectFromID(main_block_id));
                //int id = CreateObject(building_block, true);
                new_row[i][0] = id;
                Object@ block = ReadObjectFromID(id);
                //block.SetScale(block_scale);
                block.SetScale(0.99f * block_scale);
                vec3 offset = vec3(0.0f, 0.0f, 1.0f) * (2.0f * block_scale.x);
                Object@ adjacent_block = ReadObjectFromID(world[world.size() - 1][i][0]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
            }
            world.insertLast(new_row);
        }
        if(width_length.x < new_width_length.x){
            //DebugText("key", "Moved right", _fade);
            for(uint i = 0; i < world.size(); i++){
                DeleteObjectID(world[i][0][0]);
                world[i].removeAt(0);
            }

            for(uint i = 0; i < world.size(); i++){
                int id = DuplicateObject(ReadObjectFromID(main_block_id));
                //int id = CreateObject(building_block, true);
                Object@ block = ReadObjectFromID(id);
                //block.SetScale(block_scale);
                block.SetScale(0.99f * block_scale);
                vec3 offset = vec3(1.0f, 0.0f, 0.0f) * (2.0f * block_scale.x);
                Object@ adjacent_block = ReadObjectFromID(world[i][world[i].size() - 1][0]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
                array<int> new_row = {id};
                world[i].insertLast(new_row);
            }
        }
        if(width_length.x > new_width_length.x){
            //DebugText("key", "Moved left\n" , _fade);
            for(uint i = 0; i < world.size(); i++){
                DeleteObjectID(world[i][world[i].size() - 1][0]);
                world[i].removeAt(world[i].size() - 1);
            }

            for(uint i = 0; i < world.size(); i++){
                int id = DuplicateObject(ReadObjectFromID(main_block_id));
                //int id = CreateObject(building_block, true);
                Object@ block = ReadObjectFromID(id);
                //block.SetScale(block_scale);
                block.SetScale(0.99f * block_scale);
                vec3 offset = vec3(-1.0f, 0.0f, 0.0f) * (2.0f * block_scale.x);
                Object@ adjacent_block = ReadObjectFromID(world[i][0][0]);
                block.SetTranslation(offset + adjacent_block.GetTranslation());
                array<int> new_row = {id};
                world[i].insertAt(0, new_row);
            }
        }
        width_length = new_width_length;
      }
}

void PrintBlockWorld(){
    for(uint i = 0; i < world.size(); i++){
        Print("[");
        for(uint j = 0; j < world[i].size(); j++){
            Print(" [" + world[i][j][0] + "] ");
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
            int id = DuplicateObject(ReadObjectFromID(main_block_id));
            //int id = CreateObject(building_block, true);
            Print("adding " + i + " " + j + " 0\n");
            world[i][j][0] = id;
            Object@ block = ReadObjectFromID(id);
            //block.SetScale(block_scale);
            block.SetScale(0.99f * block_scale);
            block.SetTranslation(vec3( width_length.x - (world_size / 2) * (block_scale.x * 2), 0, width_length.y - (world_size / 2) * (block_scale.x * 2)) + (vec3(float(j) * (block_scale.x * 2), floor_height, float(i) * (block_scale.x * 2))));
            //block.SetTranslation(vec3( width_length.x - (world_size / 2), 0, width_length.y - (world_size / 2)) + (vec3(float(j), floor_height, float(i))));
            //DebugDrawText(block.GetTranslation() + vec3(0.0f, 1.6f, 0.0f), "" + id, 5.0f, true, _persistent);
            //DebugDrawLine(player_pos, block.GetTranslation(), vec3(0), _persistent);
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
