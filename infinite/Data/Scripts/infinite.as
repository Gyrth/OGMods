#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

//Parameters for user to change
int world_size = 11;
string building_block = "Data/Objects/primitives/edged_cube.xml";
float block_scale = 3.0;
float local_block_scale = 0.99f;

//Variables not to be changed
string level_name;
array<array<array<int>>> world;
int player_id = -1;
float height = 0.0f;
vec2 width_length = vec2(0.0f,0.0f);
int main_block_id = -1;

MusicLoad ml("Data/Music/challengelevel.xml");

void Init(string p_level_name) {
    level_name = p_level_name;
}

bool HasFocus(){
    return false;
}

void Reset(){
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
        MovementObject@ player = ReadCharacterID(player_id);
        height = floor(player.position.y);
        //width_length = vec2(floor(player.position.x), floor(player.position.z));
        width_length = vec2(floor(player.position.x / (2.0f * block_scale)), floor(player.position.z / (2.0f * block_scale)));
        main_block_id = CreateObject(building_block, true);
        Object@ block = ReadObjectFromID(main_block_id);
        block.SetScale(0.0f);
        CreateFloor();
        width_length = vec2(floor(player.position.x / (2.0f * block_scale)), floor(player.position.z / (2.0f * block_scale)));
        PrintBlockWorld();
    }else{
        MovementObject@ player = ReadCharacterID(player_id);
        vec2 new_width_length = vec2(floor(player.position.x / (2.0f * block_scale)), floor(player.position.z / (2.0f * block_scale)));
        vec2 moved = vec2(0.0f);
        if(width_length != new_width_length){
            if(width_length.y > new_width_length.y){
                Print("Moved up\n");

                DeleteRow(world[world.size() - 1]);
                world.removeLast();

                array<array<int>> new_row;
                for(uint i = 0; i < world[0].size(); i++){
                    //new_row[i].insertLast(CreateBlock(world[0][i][0], vec3(0.0f, 0.0f, -1.0f)));
                    new_row.insertLast(array<int> = {CreateBlock(world[0][i][0], vec3(0.0f, 0.0f, -1.0f))});
                    AddRandomHeightBlocks(new_row[i]);
                }
                world.insertAt(0, new_row);
                moved += vec2(0.0f, -1.0f);
            }
            if(width_length.y < new_width_length.y){
                Print("Moved down\n");

                DeleteRow(world[0]);
                world.removeAt(0);

                array<array<int>> new_row;
                for(uint i = 0; i < world[world.size() - 1].size(); i++){
                    new_row.insertLast(array<int> = {CreateBlock(world[world.size() - 1][i][0], vec3(0.0f, 0.0f, 1.0f))});
                    AddRandomHeightBlocks(new_row[i]);
                }
                world.insertLast(new_row);
                moved += vec2(0.0f, 1.0f);
            }
            if(width_length.x < new_width_length.x){
                Print("Moved right\n");

                for(uint i = 0; i < world.size(); i++){
                    DeleteColumn(world[i][0]);
                    world[i].removeAt(0);
                }

                for(uint i = 0; i < world.size(); i++){
                    array<int> new_column;
                    new_column.insertLast(CreateBlock(world[i][world[i].size() - 1][0], vec3(1.0f, 0.0f, 0.0f)));
                    AddRandomHeightBlocks(new_column);
                    world[i].insertLast(new_column);
                }
                moved += vec2(1.0f, 0.0f);
            }
            if(width_length.x > new_width_length.x){
                Print("Moved left\n");

                for(uint i = 0; i < world.size(); i++){
                    DeleteColumn(world[i][world[i].size() - 1]);
                    world[i].removeAt(world[i].size() - 1);
                }

                for(uint i = 0; i < world.size(); i++){
                    array<int> new_column;
                    new_column.insertLast(CreateBlock(world[i][0][0], vec3(-1.0f, 0.0f, 0.0f)));
                    AddRandomHeightBlocks(new_column);
                    world[i].insertAt(0, new_column);
                }
                moved += vec2(-1.0f, 0.0f);
            }
            width_length = width_length + moved;
        }
    }
}

int CreateBlock(int adjacent_block_id, vec3 offset){
    vec3 scaled_offset = offset * (2.0f * block_scale);
    int id = DuplicateObject(ReadObjectFromID(main_block_id));
    Object@ block = ReadObjectFromID(main_block_id);
    //int id = CreateObject(building_block, true);
    Object@ adjacent_block = ReadObjectFromID(adjacent_block_id);
    Object@ new_block = ReadObjectFromID(id);
    new_block.SetScale(vec3(local_block_scale * block_scale));
    new_block.SetTranslation(adjacent_block.GetTranslation() + scaled_offset);
    return id;
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

void DeleteRow(array<array<int>> row){
    for(uint i = 0; i < row.size(); i++){
        for(uint j = 0; j < row[i].size(); j++){
            DeleteObjectID(row[i][j]);
        }
    }
    //PrintBlockWorld();
}

void DeleteColumn(array<int> column){
    for(uint i = 0; i < column.size(); i++){
        DeleteObjectID(column[i]);
    }
}

void AddRandomHeightBlocks(array<int> @blocks){
    int amount = rand()%(world_size - 1);
    for(int i = 0; i < amount; i++){
        int id = CreateBlock(blocks[blocks.size() - 1], vec3(0.0f, 1.0f, 0.0f));
        blocks.insertLast(id);
        //DebugDrawLine(floor_block.GetTranslation(), new_block.GetTranslation(), vec3(0), _persistent);
    }
}

void CreateFloor(){
    MovementObject@ player = ReadCharacterID(player_id);
    vec3 player_pos = player.position;
    float floor_height = height - (block_scale * 2.0 * world_size);

    //vec3 starting_pos = vec3(width_length.x - ((world_size / 2.0f) * block_scale) + (block_scale / 2.0f), 0, width_length.y - ((world_size / 2.0f) * block_scale) + (block_scale / 2.0f));
    vec3 starting_pos = vec3(width_length.x - ((world_size) * block_scale) + (block_scale), 0, width_length.y - ((world_size) * block_scale) + (block_scale));
    Print("Starting pos " + starting_pos.x + " " + starting_pos.z + "\n");
    for(uint i = 0; i < uint(world_size); i++){
        array<array<int>> new_row;
        for(uint j = 0; j < uint(world_size); j++){
            int id = DuplicateObject(ReadObjectFromID(main_block_id));
            Object@ block = ReadObjectFromID(id);
            block.SetScale(local_block_scale * block_scale);

            vec3 new_pos = vec3(starting_pos.x + ((block_scale * 2.0f) * float(j)), floor_height, starting_pos.z + ((block_scale * 2.0f) * float(i)));
            Print("Setting block " + id + " on pos " + new_pos.x + " " + new_pos.y + " " + new_pos.z + "\n");
            block.SetTranslation(new_pos);

            //DebugDrawText(block.GetTranslation() + vec3(0.0f, block_scale, 0.0f), "" + id, 5.0f, true, _persistent);
            //DebugDrawLine(player_pos, block.GetTranslation(), vec3(0), _persistent);

            array<int> new_column = {id};
            AddRandomHeightBlocks(new_column);
            new_row.insertLast(new_column);
        }
        world.insertLast(new_row);
        //PrintBlockWorld();
    }
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
