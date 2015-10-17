#include "ui_effects.as"
#include "threatcheck.as"

string level_name;
int navpoint_type_id = 33;
int hotspot_type_id = 26;
int placeholder_type_id = 35;

array<int> char_ids;
array<int> weap_ids;

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
bool mission_done = false;

const int kMaxMetaStates = 10;
array<string> meta_states;
const int kMaxMetaEvents = 100;
array<MetaEvent> meta_events;
int meta_event_start;
int meta_event_end;
uint64 meta_event_wait;
float wait_player_move_dist;
bool wait_for_click;
float text_visible;
int main_text_id;
int ingame_text_id;
int timer_text_id;

enum MetaEventType {
    kDisplay,
    kWait,
    kMessage
}

class MetaEvent {
    MetaEventType type;
    string data;
}

void Init(string p_level_name) {
    level_name = p_level_name;
    meta_states.resize(kMaxMetaStates);
    meta_events.resize(kMaxMetaEvents);
    int meta_event_start = 0;
    int meta_event_end = 0;
    meta_event_wait = global_time;
    wait_player_move_dist = 0.0f;
    wait_for_click = false;

    main_text_id = TextInit(600,600);
    timer_text_id = TextInit(512,512);
    ingame_text_id = TextInit(512,512);
    show_text = false;
    text_visible = 0.0f;
    SetupScene();
}

void Reset(){
    Print("Reseting----------------------- \n");
    SetupScene();
}

void SetupScene(){
    //Before the scene is build the custom update code needs to be paused so non existing objects won't be called.

    global_time = 0.0f;
    timer_time = 120000.0f;
    timer_started = false;

    meta_states.resize(kMaxMetaStates);
    meta_events.resize(kMaxMetaEvents);
    meta_event_wait = global_time;
    wait_player_move_dist = 0.0f;
    wait_for_click = false;

    show_text = false;
    text_visible = 0.0f;

    SetIntroText();
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
    }else if(token == "add_enemy"){
        token_iter.FindNextToken(msg);
        string char_id = token_iter.GetToken(msg);
        char_ids.push_back(atoi(char_id));
    }else if(token == "add_weapon"){
        token_iter.FindNextToken(msg);
        string weap_id = token_iter.GetToken(msg);
        weap_ids.push_back(atoi(weap_id));
    }else if(token == "remove_enemies"){
        Print("Number of enemies: " + char_ids.size() + "\n");
        for(int i = 0;i<GetNumCharacters();i++){
            MovementObject@ temp_char = ReadCharacter(i);
            temp_char.Execute("situation.clear();");
        }
        for(uint32 i = 0; i<char_ids.size(); i++){
            Print("Deleting enemies.\n");
            DeleteObjectID(char_ids[i]);
        }
        char_ids.resize(0);
    }else if(token == "remove_weapons"){
        for(uint32 i = 0; i<weap_ids.size(); i++){
            DeleteObjectID(weap_ids[i]);
        }
        weap_ids.resize(0);
    }else if(token == "reset_characters"){

    }else if(token == "set"){
        token_iter.FindNextToken(msg);
        string param1 = token_iter.GetToken(msg);
        token_iter.FindNextToken(msg);
        string param2 = token_iter.GetToken(msg);
        if(param1 == "show_text"){
            if(param2 == "false"){
                show_text = false;
            } else if(param2 == "true"){
                show_text = true;
            }
        }
    }else if(token == "wait_for_player_move"){
        token_iter.FindNextToken(msg);
        string param1 = token_iter.GetToken(msg);
        wait_player_move_dist = atof(param1); 
        initial_player_pos_set = false;
    } else if(token == "wait_for_click"){
        wait_for_click = true;
    }

}


void Update() {
    time += time_step;
    global_time += uint64(time_step * 1000);
    if(timer_started){
        timer_time -= uint64(time_step * 1000);
    }
    if(timer_time /1000 == 0){
        timer_started = false;
    }
    SetPlaceholderPreviews();

    if(show_text){
        text_visible += float(time_step);
        text_visible = min(1.0f, text_visible);
    } else {
        text_visible -= float(time_step);
        text_visible = max(0.0f, text_visible);
    }
    Print(show_text + "\n");
    UpdateMetaEventWait();
    while(meta_event_start != meta_event_end && !MetaEventWaiting()){
        ProcessMetaEvent(meta_events[meta_event_start]);
        meta_event_start = (meta_event_start+1)%kMaxMetaEvents;
    }
    UpdateMusic();

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

void DrawGUI() {

    float ui_scale = 0.5f;
    float visible = 1.0f;
    float display_time = time;

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromPath(level.GetPath("diffuse_tex"));
        float stretch = GetScreenHeight() / image.GetHeight();
        image.position.x = GetScreenWidth() * 0.4f - 200;
        image.position.y = ((1.0-visible) * GetScreenHeight() * -1.2);
        image.position.z = 3;
        image.tex_scale.y = 20;
        image.tex_scale.x = 20;
        image.color = vec4(0.6f,0.8f,0.6f,text_visible*0.8f);
        image.scale = vec3(600 / image.GetWidth(), stretch, 1.0);}

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromText(level.GetTextElement(main_text_id)); 
        image.position.x = int(GetScreenWidth() * 0.4f - 200 + 10);
        image.position.y = GetScreenHeight()-500;
        image.position.z = 4;
        image.color = vec4(1,1,1,text_visible);}

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromText(level.GetTextElement(timer_text_id)); 
        image.position.x = GetScreenWidth()/2-100;
        image.position.y = GetScreenHeight()-350;
        image.position.z = 4;
        image.color = vec4(1,1,1,1);}

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromText(level.GetTextElement(ingame_text_id)); 
        image.position.x = GetScreenWidth()/2-256;
        image.position.y = GetScreenHeight()-500;
        image.position.z = 3;
        image.color = vec4(1,1,1,1);}

}

int TextInit(int width, int height){
    int id = level.CreateTextElement();
    TextCanvasTexture @text = level.GetTextElement(id);
    text.Create(width, height);
    return id;
}

void AddMetaEvent(MetaEventType type, string data) {
    int next_meta_event_end = (meta_event_end+1)%kMaxMetaEvents;
    if(next_meta_event_end == meta_event_start){
        DisplayError("Error", "Too many meta events to add new one");
        return;
    }
    meta_events[meta_event_end].type = type;
    meta_events[meta_event_end].data = data;
    meta_event_end = next_meta_event_end;
}

void ClearMetaEvents() {
    meta_event_start = 0;
    meta_event_end = 0;
}

void ClearMeta() {
    ClearMetaEvents();
    UpdateIngameText("");
    show_text = false;
    meta_event_wait = 0;
    wait_player_move_dist = 0.0f;
    wait_for_click = false;
}



void UpdateMetaEventWait() {
    if(wait_player_move_dist > 0.0f){
        if(player_id != -1){
            MovementObject@ player_char = ReadCharacter(player_id);
            if(!initial_player_pos_set){
                initial_player_pos = player_char.position;
                initial_player_pos_set = true;
            }
            if(xz_distance_squared(initial_player_pos, player_char.position) > wait_player_move_dist){
                wait_player_move_dist = 0.0f;
                timer_started = true;
            }
        }
    }
    if(wait_for_click){
        if(GetInputDown(0, "attack")){
            wait_for_click = false;
            timer_started = true;
        }
    }
}

bool MetaEventWaiting(){
    bool waiting = false;
    if(global_time < meta_event_wait){
        waiting = true;
    }
    if(wait_player_move_dist > 0.0f){
        waiting = true;
    }
    if(wait_for_click){
        waiting = true;
    }
    return waiting;
}

// Returns true if a wait event was encountered
void ProcessMetaEvent(MetaEvent me){
    switch(me.type){
    case kWait:
        meta_event_wait = uint64(global_time + 1000 * atof(me.data));
        Print("Waittime : " + uint64(global_time + 1000 * atof(me.data)) + "\n");
        //Print("wait: " + Waittime )
        break;
    case kDisplay:
        UpdateIngameText(me.data);
        break;
    case kMessage:
        ReceiveMessage(me.data);
        break;
    }
}

void SetIntroText() {
    AddMetaEvent(kMessage, "set show_text true");

    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    int line_break_dist = 42;
    text.AddText("Protect The Caravan", big_style);
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Good luck!",small_style);

    text.UploadTextCanvasToTexture();

    AddMetaEvent(kMessage, "wait_for_player_move 5.0");
    AddMetaEvent(kMessage, "set show_text false");
}

void UpdateIngameText(string str) {
    TextCanvasTexture @text = level.GetTextElement(ingame_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle style;
    style.font_face_id = GetFontFaceID(font_str, 48);

    vec2 pen_pos = vec2(0,256);
    int line_break_dist = 42;
    text.SetPenPosition(pen_pos);
    text.SetPenColor(255,255,255,255);
    text.SetPenRotation(0.0f);
    
    text.AddText(str, style);

    text.UploadTextCanvasToTexture();
}

void SetEndText(string win_or_lose, string text_message) {
    
    mission_done = true;
    timer_started = false;
    AddMetaEvent(kWait, "2.0");
    AddMetaEvent(kMessage, "set show_text true");
    AddMetaEvent(kWait, "2.0");
    AddMetaEvent(kMessage, "reset_characters");
    AddMetaEvent(kWait, "0.1");
    AddMetaEvent(kMessage, "reset");
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    int line_break_dist = 42;
    text.AddText("Kill the Thief", big_style);
    pen_pos.y += line_break_dist;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText(text_message, small_style);
    pen_pos.y += line_break_dist;
    
    text.SetPenPosition(pen_pos);
    if(win_or_lose == "win"){
        PlaySoundGroup(level.GetPath("win_sound"));
        text.AddText("Well done.", small_style);
    }
    else if(win_or_lose == "lose"){
        PlaySoundGroup(level.GetPath("lose_sound"));
        text.AddText("You lose.", small_style);
    }

    text.UploadTextCanvasToTexture();

}