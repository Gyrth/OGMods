#include "ui_effects.as"
#include "threatcheck.as"

string level_name;
int navpoint_type_id = 33;

int obj_id;
array<int> spawned_object_ids;
array<string> color_names;
array<vec3> colors;
array<string> stolen_item_names;
array<string> stolen_item_paths;

void Init(string p_level_name) {
    level_name = p_level_name;
    

    color_names.insertLast("Red");
    colors.insertLast(vec3(255,0,0));

    color_names.insertLast("Green");
    colors.insertLast(vec3(0,255,0));

    color_names.insertLast("Blue");
    colors.insertLast(vec3(0,0,255));

    stolen_item_names.insertLast("Dog Knife");
    stolen_item_paths.insertLast("Data/Items/DogWeapons/DogKnife.xml");

    stolen_item_names.insertLast("Rat Sack");
    stolen_item_paths.insertLast("Data/Items/collectable/ratjunksack.xml");

    stolen_item_names.insertLast("Large Bag");
    stolen_item_paths.insertLast("Data/Items/gear/rabbit_gear/large_bag.xml");

    stolen_item_names.insertLast("Dog Awl");
    stolen_item_paths.insertLast("Data/Items/gear/dogtools/dogtoolawl.xml");

    stolen_item_names.insertLast("Dog Hammer");
    stolen_item_paths.insertLast("Data/Items/gear/dogtools/dogtoolhammer.xml");

    SetupScene();
}

void Reset(){
    Print("Reseting----------------------- \n");

    SetupScene();
    
}

void SetupScene(){

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
        int number_of_group_members = groups[a].size();
        string actor_path = level.GetPath("char_guard");
        Object@ waypoint = ReadObjectFromID(groups[a][0]);
        vec3 waypoint_pos = waypoint.GetTranslation();
        vec3 spawn_point = vec3(waypoint_pos.x, waypoint_pos.y+2.0f, waypoint_pos.z);
        Object@ char_obj = SpawnObjectAtSpawnPoint(spawn_point,actor_path);
        waypoint.ConnectTo(char_obj);
        if(a == chosen_thief){
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
                //case 2: attachtype = _at_attachment;
            }
            int num_stolen_items = stolen_item_names.size();
            int chosen_item_num = GetRandomInt(num_stolen_items);

            string item_path = stolen_item_paths[chosen_item_num];
            Object@ stolen_item = SpawnObjectAtSpawnPoint(waypoint_pos, item_path);
            char_obj.AttachItem(stolen_item, attachtype, mirrored);
            
            int number_of_colors = colors.size();
            int chosen_color = GetRandomInt(number_of_colors);
            Print("Chosen " + stolen_item_names[chosen_item_num] + " with color: " + colors[chosen_color] + "\n");
            Print("Color " + color_names[chosen_color] + "\n");
            stolen_item.SetTint(FloatTintFromByte(colors[chosen_color]));
        }
    }

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