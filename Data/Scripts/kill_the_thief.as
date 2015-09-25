#include "ui_effects.as"
#include "threatcheck.as"

string level_name;
int navpoint_type_id = 33;
int hotspot_type_id = 26;
int placeholder_type_id = 35;

int obj_id;
array<int> spawned_object_ids;
array<string> color_names;
array<vec3> colors;
array<string> stolen_item_names;
array<string> stolen_item_paths;
array<string> char_names;
array<string> char_paths;

bool scene_build = false;
int thief_id = -1;

int chosen_savehouse = -1;
string chosen_thief_name;
string chosen_stolen_item_name;
string chosen_stolen_item_color_name;

const int kMaxMetaStates = 10;
array<string> meta_states;
const int kMaxMetaEvents = 100;
array<MetaEvent> meta_events;
int meta_event_start;
int meta_event_end;
uint64 meta_event_wait;
float wait_player_move_dist;
bool wait_for_click;
int main_text_id;
int ingame_text_id;
int timer_text_id;
float text_visible;
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

enum MetaEventType {
    kDisplay,
    kWait,
    kMessage,
    KTimer
}

class MetaEvent {
    MetaEventType type;
    string data;
}
void Init(string p_level_name) {
    level_name = p_level_name;
    

    color_names.insertLast("Red");
    colors.insertLast(vec3(255,0,0));

    color_names.insertLast("Green");
    colors.insertLast(vec3(0,255,0));

    color_names.insertLast("Blue");
    colors.insertLast(vec3(0,0,255));

    color_names.insertLast("White");
    colors.insertLast(vec3(255,255,255));

    color_names.insertLast("Black");
    colors.insertLast(vec3(0,0,0));

    stolen_item_names.insertLast("Dog Knife");
    stolen_item_paths.insertLast(level.GetPath("DogKnife"));

    stolen_item_names.insertLast("Dog Awl");
    stolen_item_paths.insertLast(level.GetPath("DogAwl"));

    stolen_item_names.insertLast("Dog Hammer");
    stolen_item_paths.insertLast(level.GetPath("DogHammer"));

    stolen_item_names.insertLast("Flint Knife");
    stolen_item_paths.insertLast(level.GetPath("FlintKnife"));

    stolen_item_names.insertLast("Gaben Knife");
    stolen_item_paths.insertLast(level.GetPath("GabenKnife"));

    stolen_item_names.insertLast("Rat Sack");
    stolen_item_paths.insertLast(level.GetPath("RatSack"));

    char_paths.insertLast(level.GetPath("char_civ"));
    char_names.insertLast("Civilian Rabbit");

    char_paths.insertLast(level.GetPath("char_raider"));
    char_names.insertLast("Raider Rabbit");

    char_paths.insertLast(level.GetPath("char_guard"));
    char_names.insertLast("Rabbit Guard");

    char_paths.insertLast(level.GetPath("hooded_rat"));
    char_names.insertLast("Hooded Rat");
    
    char_paths.insertLast(level.GetPath("striped_cat"));
    char_names.insertLast("Striped Cat");

    char_paths.insertLast(level.GetPath("female_dog"));
    char_names.insertLast("Female Dog");

    char_paths.insertLast(level.GetPath("male_dog"));
    char_names.insertLast("Male Dog");

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
    scene_build = false;

    global_time = 0.0f;
    timer_time = 120000.0f;
    timer_started = false;
    DeleteObjectsInList(spawned_object_ids);

    array<int> @nav_points = GetObjectIDsType(navpoint_type_id);
    array<array<int>> groups;
    int array_size = nav_points.size();

    while(array_size != 0){
        array<int> newGroup;
        GetGroup(nav_points[0], nav_points, nav_points, newGroup, newGroup);
        groups.insertLast(newGroup);
        array_size = nav_points.size();
    }
    //One character is spawed at every waypoint group.
    int number_of_groups = groups.size();
    Print( "Found " + number_of_groups + " waypoint groups.\n");
    //The thief is randomly selected.
    int chosen_thief = GetRandomInt(number_of_groups);
    //The item the thief stole also randomly selected.
    int chosen_item_num = GetRandomInt(stolen_item_names.size());
    int random_thief_index = GetRandomInt(char_paths.size());
    string actor_path = char_paths[random_thief_index];
    chosen_thief_name = char_names[random_thief_index];
    for(int a = 0;a<number_of_groups;a++){
        //Get a random waypoint in the group of waypoints so that the characters aren't spawned at the same position each time.
        Object@ waypoint = ReadObjectFromID(groups[a][GetRandomInt(groups[a].size())]);
        vec3 waypoint_pos = waypoint.GetTranslation();
        vec3 spawn_point = vec3(waypoint_pos.x, waypoint_pos.y+2.0f, waypoint_pos.z);
        //Spawn the item and character above the character to prevent collisions. This can cause crashes.
        vec3 object_spawn_point = vec3(waypoint_pos.x, waypoint_pos.y+10.0f, waypoint_pos.z);
        

        //Some random attachment variables to make the position of the item less predictable.
        int mirrored_int = GetRandomInt(2);
        AttachmentType attachtype;
        bool mirrored;
        if(mirrored_int == 0){
            mirrored = false;
        }else{
            mirrored = true;
        }
        int attachtype_int = GetRandomInt(2);
        Print("attachtype: " + attachtype_int + "\n");
        switch(attachtype_int){
            case 0: attachtype = _at_grip; break;
            case 1: attachtype = _at_sheathe; break;
        }

        if(a == chosen_thief){
            Object@ char_obj = SpawnObjectAtSpawnPoint(spawn_point,actor_path);
            Print("Random character index: " + chosen_thief + " and ID: " + char_obj.GetID() + "\n");
            thief_id = char_obj.GetID();

            string item_path = stolen_item_paths[chosen_item_num];
            chosen_stolen_item_name = stolen_item_names[chosen_item_num];
            Object@ stolen_item = SpawnObjectAtSpawnPoint(object_spawn_point, item_path);
            char_obj.AttachItem(stolen_item, attachtype, mirrored);
            
            int chosen_color = GetRandomInt(colors.size());
            chosen_stolen_item_color_name = color_names[chosen_color];
            Print("Chosen " + stolen_item_names[chosen_item_num] + " with color: " + color_names[chosen_color] + " to the " + attachtype + "\n");
            stolen_item.SetTint(FloatTintFromByte(colors[chosen_color]));

            waypoint.ConnectTo(char_obj);
            ScriptParams@ char_params = char_obj.GetScriptParams();

            if(char_params.HasParam("Teams")) {
                char_params.SetString("Teams", "guard");
            } else{
                char_params.AddString("Teams", "guard");
            }

        }else{
            string non_thief_actor_path = char_paths[GetRandomInt(char_paths.size())];
            while(non_thief_actor_path == actor_path){
                non_thief_actor_path = char_paths[GetRandomInt(char_paths.size())];
                Print("while\n");
            }
             
            Object@ char_obj = SpawnObjectAtSpawnPoint(spawn_point,non_thief_actor_path);
            //If the character is not a thief it might get a decoy object attached somewhere.
            int random_item = GetRandomInt(stolen_item_paths.size());
            if(random_item != chosen_item_num){
                string item_path = stolen_item_paths[random_item];
                Object@ random_object = SpawnObjectAtSpawnPoint(object_spawn_point, item_path);
                char_obj.AttachItem(random_object, attachtype, mirrored);
            }
            //Setting the hostile boolean to false will cause the AI to not attack the player, 
            //but let the player attack the NPC.
            MovementObject@ non_thief =ReadCharacterID(char_obj.GetID());
            non_thief.Execute("hostile = false;");
            Print("Setting holstile to false\n");

            //Connect the waypoint to the new character so that the character will start patrolling.
            //This connect function could also be reversed (char to waypoint)
            waypoint.ConnectTo(char_obj);
            ScriptParams@ char_params = char_obj.GetScriptParams();

            //Set the team parameter to something else than Turner's so that characters can fight him.
            //Create the parameter if it doesn't exist.
            if(char_params.HasParam("Teams")) {
                char_params.SetString("Teams", "guard");
            } else{
                char_params.AddString("Teams", "guard");
            }
        }



    }

    //Setup the savehouse hotspots.
    array<int> savehouses;
    array<int> @hotspots = GetObjectIDsType(hotspot_type_id);
    int num_hotspots = hotspots.length();
    Print("---------Found "+ num_hotspots + "\n");
    for(int i=0; i<num_hotspots; ++i){
        Object @obj = ReadObjectFromID(hotspots[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("savehouse" == name_str){
                //When a savehouse is found the settings are reset.
                //The ID needs to be -1 first so there isn't a chance another savehouse is triggered.
                params.SetInt("ThiefID", -1);
                //Then the savehouse is added to the list so we can get a random one after this.
                savehouses.insertLast(hotspots[i]);
            }
        }
    }
    Print("Found " + savehouses.size() + " savehouses\n");
    //A random index is generated within the size of the array.
    int random_savehouse = GetRandomInt(savehouses.size());
    //Now the index is used to get the ID of the savehouse.
    chosen_savehouse = savehouses[random_savehouse];
    //Set the ID of the thief as a parameter so that the thief can now trigger the hotspot.
    Object @obj = ReadObjectFromID(chosen_savehouse);
    ScriptParams@ params = obj.GetScriptParams();
    params.SetInt("ThiefID", thief_id);
    //Release the scene_build boolean so that the update loop can now use the characters and other objects.
    scene_build = true;
    ClearMeta();
    SetIntroText();
}


void GetGroup(int startingPoint, array<int> &in navPointsIn, array<int> &out navPointsOut, array<int> &in newGroupIn, array<int> &out newGroupOut){

    navPointsOut = navPointsIn;
    newGroupOut = newGroupIn;

    int newgroupinsize = newGroupIn.size();
    int newgroupoutsize = newGroupOut.size();


    PathPointObject@ current_pathpoint = cast<PathPointObject>(ReadObjectFromID(startingPoint));
    int num_connections = current_pathpoint.NumConnectionIDs();
    //Print("This node has this many connections : "+ num_connections + "\n"); 
    int newoutsize = newGroupOut.size();
    newGroupOut.insertLast(startingPoint);
    int numberOfWaypoints = navPointsOut.size();

    for(int k = 0;k<numberOfWaypoints;k++){
       
        if(navPointsOut[k] == startingPoint){
            
            int outsize = navPointsOut.size();
            navPointsOut.removeAt(k);
            break;
        }
    }

    for(int i = 0; i<num_connections;i++){
        if(navPointsOut.find(current_pathpoint.GetConnectionID(i)) == 0){

            int neighbourID = current_pathpoint.GetConnectionID(i);

            newoutsize = newGroupOut.size();
            GetGroup(neighbourID, navPointsOut, navPointsOut, newGroupOut, newGroupOut);
            newoutsize = newGroupOut.size();
        }
    }

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
    if(token == "reset"){
        Reset();
    } else if(token == "dispose_level"){
        gui.RemoveAll();
    } else if(token == "thiefsave"){
        Print("Thief is in the savehouse!\n");
        CloseDoors();
    } else if(token == "wait_for_player_move"){
        token_iter.FindNextToken(msg);
        string param1 = token_iter.GetToken(msg);
        wait_player_move_dist = atof(param1); 
        initial_player_pos_set = false;
    } else if(token == "wait_for_click"){
        wait_for_click = true;
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
    }
}

void DrawGUI() {
    // Do not draw the GUI in editor mode (it makes it hard to edit)
    /*if(GetPlayerCharacterID() == -1){
        return;
    }*/

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

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromPath(level.GetPath("diffuse_tex"));
        float stretch = GetScreenHeight() / image.GetHeight();
        image.position.x = GetScreenWidth() /2 - 200;
        image.position.y = GetScreenHeight() -150;
        image.position.z = 3;
        image.tex_scale.y = 20;
        image.tex_scale.x = 20;
        image.color = vec4(1.0f,1.0f,1.0f,0.5f);
        image.scale = vec3(400 / image.GetWidth(), 5000.0, 1.0);}

}


void Update() {
    time += time_step;
    global_time += time_step * 1000;
    if(timer_started){
        timer_time -= time_step * 1000;
        Print(timer_time /1000 + "\n");
    }
    if(timer_time /1000 == 0){
        timer_started = false;
    }

    SetPlaceholderPreviews();
    if(scene_build == true && ObjectExists(chosen_savehouse) && ObjectExists(thief_id)){
        MovementObject@ thief = ReadCharacterID(thief_id);

        MovementObject@ player = ReadCharacter(0);
        DebugDrawLine(thief.position, player.position, vec3(255,255,255), _delete_on_update);

        Object@ savehouse = ReadObjectFromID(chosen_savehouse);
        vec3 house_pos = savehouse.GetTranslation();
        int isAttacking = thief.QueryIntFunction("int IsAggressive()");
        if(isAttacking == 1){
            string command =    "nav_target = vec3("+house_pos.x+", "+house_pos.y+", "+house_pos.z+");" +
                                "goal = _navigate;";
            Print(command + "\n");
            thief.Execute(command);
        }
    }
    if(timer_time/1000 != previous_timer_time && timer_time/1000 >= 0){
        int seconds = (timer_time/1000)%60;
        if(seconds < 10){
            AddMetaEvent(KTimer, "" + (timer_time/1000)/60 + ":0" + seconds);
        }else{
            AddMetaEvent(KTimer, "" + (timer_time/1000)/60 + ":" + seconds);
        }
        
        previous_timer_time = timer_time/1000;
    }


    if(show_text){
        text_visible += time_step;
        text_visible = min(1.0f, text_visible);
    } else {
        text_visible -= time_step;
        text_visible = max(0.0f, text_visible);
    }

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

// Attach a specific preview path to a given placeholder object
void SetSpawnPointPreview(Object@ spawn, string &in path){

    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);

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
            if("savehouse_preview" == name_str){
                SetSpawnPointPreview(obj,level.GetPath("savehouse_preview"));
            }
        }
    }

}

Object@ SpawnObjectAtSpawnPoint(vec3 spawn_point, string &in path){
    obj_id = CreateObject(path);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn_point);
    ScriptParams@ params = new_obj.GetScriptParams();
    params.AddIntCheckbox("No Save", true);
    return new_obj;
}

void CloseDoors(){
    //Get all the placeholder objects.
    array<int> @placeholders = GetObjectIDsType(placeholder_type_id);
    int num_placeholders = placeholders.size();
    for(int i = 0; i< num_placeholders;i++){
        Object @obj = ReadObjectFromID(placeholders[i]);
        //Check if the placeholder is a savehousepreview object.
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("savehouse_preview" == name_str){
                SpawnObjectAtPlaceholder(obj, level.GetPath("savehouse_preview"));
            }
        }
    }
}

void DeleteObjectsInList(array<int> &inout ids){
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

int GetRandomInt(int maxNum) {
    int rnd = rand()%maxNum;
    return rnd;
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

Object@ SpawnObjectAtPlaceholder(Object@ spawn, string &in path){
    int obj_id = CreateObject(path);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    vec3 scale = spawn.GetScale();

    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    new_obj.SetRotation(q);
    new_obj.SetScale(scale);
    ScriptParams@ params = new_obj.GetScriptParams();
    params.AddIntCheckbox("No Save", true);
    return new_obj;
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
    ShowTimer("");
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
        meta_event_wait = global_time + 1000 * atof(me.data);
        break;
    case kDisplay:
        UpdateIngameText(me.data);
        break;
    case kMessage:
        ReceiveMessage(me.data);
        break;
    case KTimer:
        ShowTimer(me.data);
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
    text.AddText("Kill the Thief", big_style);
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("There is a thief in this city.", small_style);
    pen_pos.y += line_break_dist;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Description: " + chosen_thief_name, small_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Stolen: " + chosen_stolen_item_color_name + " " + chosen_stolen_item_name, small_style);
    
    pen_pos.y += line_break_dist;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("The thief WILL run when he sees you.",small_style);
     pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Don't let him reach a savehouse.",small_style);
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Good luck!",small_style);

    text.UploadTextCanvasToTexture();

    AddMetaEvent(kMessage, "wait_for_click");
    AddMetaEvent(kMessage, "set show_text false");
}
void ShowTimer(string str) {   


    TextCanvasTexture @text = level.GetTextElement(timer_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle style;
    style.font_face_id = GetFontFaceID(font_str, 128);

    vec2 pen_pos = vec2(0,256);
    int line_break_dist = 42;
    text.SetPenPosition(pen_pos);
    
    if(timer_time /1000 <= 10){
        text.SetPenColor(255,0,0,255);
    }else{
        text.SetPenColor(0,0,0,255);
    }
    text.SetPenRotation(0.0f);
    
    text.AddText(str, style);

    text.UploadTextCanvasToTexture();
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