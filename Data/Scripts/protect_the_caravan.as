#include "ui_effects.as"
#include "threatcheck.as"

string level_name;
int navpoint_type_id = 33;
int hotspot_type_id = 26;
int placeholder_type_id = 35;


bool show_text;
uint64 global_time; // in ms
float target_time;
float time;
int player_id;
// Level state
vec3 initial_player_pos;
bool initial_player_pos_set;

bool timer_started = false;
uint64 timer_time;
uint64 previous_timer_time;

void Init(string p_level_name) {
    level_name = p_level_name;
    
}

void Reset(){
    Print("Reseting----------------------- \n");
    SetupScene();
    
}

void SetupScene(){
    
}

bool HasFocus(){
    return false;
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "dispose_level"){
        gui.RemoveAll();
    }else if(token == "reset"){
        Reset();
    }else if(token == "reset_characters"){

    }
}

void DrawGUI() {

}


void Update() {
    time += time_step;
    global_time += uint64(time_step * 1000);
    SetPlaceholderPreviews();
}


void UpdateMusic() {
    player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }

    PlaySong("ambient-tense");
}

// Find spawn points and set which object is displayed as a preview
void SetPlaceholderPreviews() {
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("character_spawn" == name_str){
                SetSpawnPointPreview(obj,level.GetPath("spawn_preview"));
            }
            if("enemy_spawn" == name_str){
                SetSpawnPointPreview(obj,level.GetPath("enemy_preview"));
            }
            if("weapon_spawn" == name_str){
                SetSpawnPointPreview(obj,level.GetPath("weap_preview"));
            }
        }
    }
}
// Attach a specific preview path to a given placeholder object
void SetSpawnPointPreview(Object@ spawn, string &in path){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);
}