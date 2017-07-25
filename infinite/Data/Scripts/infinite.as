#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

//Parameters for user to change
int world_size;
string building_block;
float block_scale;
float local_block_scale;
float min_color;
float max_color;
float max_extra;
bool change_colours;

//Variables not to be changed
string level_name;
array<array<array<int>>> world;
int player_id = -1;
float height = 0.0f;
vec2 width_length = vec2(0.0f,0.0f);
int main_block_id = -1;
vec3 main_color = vec3(0);
float timer = 0.0f;

MusicLoad ml("Data/Music/challengelevel.xml");

void Init(string p_level_name) {
  level_name = p_level_name;
}

void ReadScriptParameters(){
  ScriptParams@ level_params = level.GetScriptParams();
  world_size = level_params.GetInt("World size");
  building_block = level_params.GetString("Building block");
  block_scale = level_params.GetFloat("Block scale");
  local_block_scale = level_params.GetFloat("Local block scale");
  min_color = level_params.GetFloat("Minimum color");
  max_color = level_params.GetFloat("Maximum color");
  max_extra = level_params.GetFloat("Maximum extra");
  change_colours = (level_params.GetInt("Change colours") == 1);
}

bool HasFocus(){
    return false;
}

void Reset(){
  for(int i = 0; i < int(world.size()); i++){
    for(int j = 0; j < int(world[i].size()); j++){
      for(int z = 0; z < int(world[i][j].size()); z++){
        DeleteObjectID(world[i][j][z]);
      }
    }
  }
  world.resize(0);
  ReadScriptParameters();
  if(main_block_id != -1){
    DeleteObjectID(main_block_id);
  }
  main_block_id = CreateObject(building_block, true);
  Object@ block = ReadObjectFromID(main_block_id);
  block.SetScale(vec3(0));
  main_color = RandomColor();
  Object@ player_obj = ReadObjectFromID(player_id);
  height = floor(player_obj.GetTranslation().y);
  width_length = vec2(floor(player_obj.GetTranslation().x / (2.0f * block_scale)), floor(player_obj.GetTranslation().z / (2.0f * block_scale)));
  CreateFloor();
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

vec3 RandomColor(){
    vec3 color = vec3(RangedRandomFloat(min_color, max_color), RangedRandomFloat(min_color, max_color), RangedRandomFloat(min_color, max_color));
    return color;
}

vec3 RandomAdjacentColor(vec3 color){
    float new_x = RangedRandomFloat(-max_extra, max_extra) + color.x;
    float new_y = RangedRandomFloat(-max_extra, max_extra) + color.y;
    float new_z = RangedRandomFloat(-max_extra, max_extra) + color.z;
    vec3 new_color = vec3(max(min_color, (min(max_color, new_x))), max(min_color, (min(max_color, new_y))), max(min_color, (min(max_color, new_z))));
    return new_color;
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
        Reset();
    }else{
        MovementObject@ player = ReadCharacterID(player_id);
        vec2 new_width_length = vec2(floor(player.position.x / (2.0f * block_scale)), floor(player.position.z / (2.0f * block_scale)));
        vec2 moved = vec2(0.0f);
        if(width_length != new_width_length){
            if(width_length.y > new_width_length.y){
                DeleteRow(world[world.size() - 1]);
                world.removeLast();
                array<array<int>> new_row;
                for(uint i = 0; i < world[0].size(); i++){
                    new_row.insertLast(array<int> = {CreateBlock(world[0][i][0], vec3(0.0f, 0.0f, -1.0f))});
                    AddRandomHeightBlocks(new_row[i]);
                }
                world.insertAt(0, new_row);
                moved += vec2(0.0f, -1.0f);
            }
            if(width_length.y < new_width_length.y){
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
            main_color = RandomAdjacentColor(main_color);
        }
        UpdateColours();
    }
}

int CreateBlock(int adjacent_block_id, vec3 offset){
    vec3 scaled_offset = offset * (2.0f * block_scale);
    int id = DuplicateObject(ReadObjectFromID(main_block_id));
    Object@ block = ReadObjectFromID(main_block_id);
    block.SetTint(RandomAdjacentColor(main_color));
    //int id = CreateObject(building_block, true);
    Object@ adjacent_block = ReadObjectFromID(adjacent_block_id);
    Object@ new_block = ReadObjectFromID(id);
    new_block.SetSelectable(false);
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

void UpdateColours(){
    if(change_colours){
        timer += time_step;
        if(timer > 0.1f){
          for(uint i = 0; i < world.size(); i++){
              for(uint j = 0; j < world[i].size(); j++){
                  for(uint k = 0; k < world[i][j].size(); k++){
                      Object@ block = ReadObjectFromID(world[i][j][k]);
                      //vec3 cur_tint = block.GetTint();
                      //block.SetTint(RandomAdjacentColor(cur_tint));
                      block.SetTint(RandomAdjacentColor(main_color));
                  }
              }
          }
          main_color = RandomAdjacentColor(main_color);
          timer = 0.0f;
        }
    }
}

void DeleteRow(array<array<int>> row){
    for(uint i = 0; i < row.size(); i++){
        for(uint j = 0; j < row[i].size(); j++){
            DeleteObjectID(row[i][j]);
        }
    }
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
    }
}

void CreateFloor(){
    MovementObject@ player = ReadCharacterID(player_id);
    vec3 player_pos = player.position;
    float floor_height = height - (block_scale * 2.0 * world_size);

    vec3 starting_pos = vec3(width_length.x - ((world_size) * block_scale) + (block_scale), 0, width_length.y - ((world_size) * block_scale) + (block_scale));
    for(uint i = 0; i < uint(world_size); i++){
        array<array<int>> new_row;
        for(uint j = 0; j < uint(world_size); j++){
            int id = DuplicateObject(ReadObjectFromID(main_block_id));
            Object@ block = ReadObjectFromID(id);
            block.SetTint(main_color);
            block.SetSelectable(false);
            block.SetScale(local_block_scale * block_scale);

            vec3 new_pos = vec3(starting_pos.x + ((block_scale * 2.0f) * float(j)), floor_height, starting_pos.z + ((block_scale * 2.0f) * float(i)));
            block.SetTranslation(new_pos);
            array<int> new_column = {id};
            AddRandomHeightBlocks(new_column);
            new_row.insertLast(new_column);
        }
        world.insertLast(new_row);
        main_color = RandomAdjacentColor(main_color);
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
