#include "ui_effects.as"
#include "threatcheck.as"

string level_name;
int navpoint_type_id = 33;
int hotspot_type_id = 26;

int obj_id;
array<int> spawned_object_ids;
array<string> color_names;
array<vec3> colors;
array<string> stolen_item_names;
array<string> stolen_item_paths;
array<string> char_paths;

bool scene_build = false;
int thief_id = -1;

int chosen_savehouse = -1;

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

    stolen_item_names.insertLast("Flint Hammer");
    stolen_item_paths.insertLast(level.GetPath("FlintKnife"));

    stolen_item_names.insertLast("GabenKnife");
    stolen_item_paths.insertLast(level.GetPath("GabenKnife"));

    stolen_item_names.insertLast("Rat Sack");
    stolen_item_paths.insertLast(level.GetPath("RatSack"));

    char_paths.insertLast(level.GetPath("char_civ"));
    char_paths.insertLast(level.GetPath("char_raider"));
    char_paths.insertLast(level.GetPath("char_guard"));

    SetupScene();
}

void Reset(){
    Print("Reseting----------------------- \n");

    SetupScene();
    
}

void SetupScene(){
    scene_build = false;

    DeleteObjectsInList(spawned_object_ids);

    array<int> @nav_points = GetObjectIDsType(navpoint_type_id);
    array<array<int>> groups;
    int array_size = nav_points.size();

    while(array_size != 0){
        array<int> newGroup;
        GetGroup(nav_points[0], nav_points, nav_points, newGroup, newGroup);
        groups.insertLast(newGroup);
        //nav_points.removeAt(0);
        array_size = nav_points.size();
    }

    int number_of_groups = groups.size();
    Print( "Found " + number_of_groups + " waypoint groups.\n");
    int chosen_thief = GetRandomInt(number_of_groups);
    for(int a = 0;a<number_of_groups;a++){
        //
        int number_of_group_members = groups[a].size();
        string actor_path = char_paths[GetRandomInt(char_paths.size())];
        Object@ waypoint = ReadObjectFromID(groups[a][0]);
        vec3 waypoint_pos = waypoint.GetTranslation();
        vec3 spawn_point = vec3(waypoint_pos.x, waypoint_pos.y+2.0f, waypoint_pos.z);
        vec3 stolen_object_spawn_point = vec3(waypoint_pos.x, waypoint_pos.y+10.0f, waypoint_pos.z);
        Object@ char_obj = SpawnObjectAtSpawnPoint(spawn_point,actor_path);
        ScriptParams@ char_params = char_obj.GetScriptParams();
        waypoint.ConnectTo(char_obj);
        if(a == chosen_thief){
            thief_id = char_obj.GetID();
            int mirrored_int = GetRandomInt(2);
            AttachmentType attachtype;
            bool mirrored;
            if(mirrored_int == 0){
                mirrored = false;
            }else{
                mirrored = true;
            }
            int attachtype_int = GetRandomInt(2);
            Print("atttachtype: " + attachtype_int + "\n");
            switch(attachtype_int){
                case 0: attachtype = _at_grip; break;
                case 1: attachtype = _at_sheathe; break;
                //case 2: attachtype = _at_attachment; break;
            }
            int chosen_item_num = GetRandomInt(stolen_item_names.size());

            string item_path = stolen_item_paths[chosen_item_num];
            Object@ stolen_item = SpawnObjectAtSpawnPoint(stolen_object_spawn_point, item_path);
            char_obj.AttachItem(stolen_item, attachtype, mirrored);
            
            int chosen_color = GetRandomInt(colors.size());
            Print("Chosen " + stolen_item_names[chosen_item_num] + " with color: " + color_names[chosen_color] + " to the " + attachtype + "\n");
            stolen_item.SetTint(FloatTintFromByte(colors[chosen_color]));

            if(char_params.HasParam("Teams")) {
                char_params.SetString("Teams", "guard");
            } else{
                char_params.AddString("Teams", "guard");
            }
        }else{
            if(char_params.HasParam("Teams")) {
                char_params.SetString("Teams", "guard, turner");
            } else{
                char_params.AddString("Teams", "guard, turner");
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
                savehouses.insertLast(hotspots[i]);
                Print("FOUND A SAVEHOUSE!\n");
            }
        }
    }
    int random_savehouse = GetRandomInt(savehouses.size());
    chosen_savehouse = savehouses[random_savehouse];
    scene_build = true;
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
    }
}

void DrawGUI() {

}


void Update() {
    SetPlaceholderPreviews();
    if(scene_build == true || chosen_savehouse != -1){
        MovementObject@ thief = ReadCharacterID(thief_id);
        Object@ savehouse = ReadObjectFromID(chosen_savehouse);
        vec3 house_pos = savehouse.GetTranslation();
        int isAttacking = thief.QueryIntFunction("int IsAggressive()");
        if(isAttacking == 1){
            string command =    "nav_target = vec3("+house_pos.x+", "+house_pos.y+", "+house_pos.z+");" +
                                "goal = _navigate;";
            Print(command + "\n");
            thief.Execute(command);
        }
        
        //int num_known_chars = thief.GetIntVar("situation.known_chars.size();");
        Print("Is aggressive : " + isAttacking + "\n");
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