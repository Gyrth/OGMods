array<int> enemyspawn_ids;
Object@ main_hotspot = ReadObjectFromID(hotspot.GetID());
int placeholder_type_id = 35;
bool init_done = false;
bool triggered = false;
int target_id = -1;
void Init() {

}

void SetParameters() {
    params.AddInt("Number of Enemies", 1);

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    ScriptParams@ char_params = ReadObjectFromID(mo.GetID()).GetScriptParams();
    if(char_params.HasParam("Teams")){
        Print("Char entered with team: " + char_params.GetString("Teams") + "\n");
        if(char_params.GetString("Teams") == "caravan, turner" && triggered == false){
            Print("entered team turner" + triggered + "\n");
            target_id = mo.GetID();
            SpawnCharacters();
            triggered = true;
        }
    }
}
void Update(){
    if(init_done){
        if(params.GetInt("Number of Enemies") != 0){
            if(enemyspawn_ids.size() < uint32(params.GetFloat("Number of Enemies"))){
                int obj_id = CreateObject("Data/Custom/Gyrth/protect_the_caravan/Objects/placeholder_enemy_spawn.xml");
                enemyspawn_ids.push_back(obj_id);
                Object @new_obj = ReadObjectFromID(obj_id);
                new_obj.SetDeletable(false);
                ScriptParams@ spawnpoint_params = new_obj.GetScriptParams();
                if(spawnpoint_params.HasParam("BelongsTo")){
                    Print("Setting id to " + hotspot.GetID() + "\n");
                    spawnpoint_params.SetInt("BelongsTo", hotspot.GetID());
                }

                new_obj.SetTranslation(main_hotspot.GetTranslation());
            }else if(enemyspawn_ids.size() > uint32(params.GetFloat("Number of Enemies"))){
                DeleteObjectID(enemyspawn_ids[enemyspawn_ids.size() - 1]);
                enemyspawn_ids.removeAt(enemyspawn_ids.size() - 1);
            }

        }
        if(GetPlayerCharacterID() == -1){
            for(uint32 i = 0; i<enemyspawn_ids.size(); i++){
                if(ObjectExists(enemyspawn_ids[i])){
                    Object@ spawn_hotspot = ReadObjectFromID(enemyspawn_ids[i]);
                    DebugDrawLine(main_hotspot.GetTranslation(), spawn_hotspot.GetTranslation(), vec3(0.5f), _delete_on_update); 
                }
            }
        }
    }else{
        AfterInitFunction();
    }
}

void OnExit(MovementObject @mo) {

}

int GetPlayerCharacterID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return i;
        }
    }
    return -1;
}
void AfterInitFunction(){
    Print("Starting afterinitfunction.\n");

    array<int> @placeholders = GetObjectIDsType(35);
    int num_placeholders = placeholders.size();
    for(int i = 0; i< num_placeholders;i++){

        Object @obj = ReadObjectFromID(placeholders[i]);
        ScriptParams@ placeholder_params = obj.GetScriptParams();
        if(placeholder_params.HasParam("BelongsTo")){
            if(placeholder_params.GetInt("BelongsTo") == hotspot.GetID()){

                enemyspawn_ids.push_back(placeholders[i]);
            }
        }
    }
    init_done = true;
}
void SpawnCharacters(){

        string command =    "nav_target = vec3("+main_hotspot.GetTranslation().x+", "+main_hotspot.GetTranslation().y+", "+main_hotspot.GetTranslation().z+");" +
                            "goal = _navigate;";

    for(uint32 i = 0; i<enemyspawn_ids.size(); i++){
        if(ObjectExists(enemyspawn_ids[i])){
            Object@ spawnpoint = ReadObjectFromID(enemyspawn_ids[i]);
            ScriptParams@ placeholder_params = spawnpoint.GetScriptParams();

            string char_choise = placeholder_params.GetString("Character");
            string weap_choise = placeholder_params.GetString("Weapon");
            Print("Weapon dir " + weap_choise + " char dir " + char_choise + "\n");
            string char_dir = level.GetPath(char_choise);
            string weap_dir = level.GetPath(weap_choise);

            int char_id = CreateObject(char_dir);
            Object@ char_obj = ReadObjectFromID(char_id);
            MovementObject@ char = ReadCharacterID(char_id);
            ScriptParams@ enemy_params = char_obj.GetScriptParams();
            enemy_params.SetString("Teams", "Enemy");
            char_obj.SetTranslation(spawnpoint.GetTranslation());
            char.Execute(command);

            int weap_id = CreateObject(weap_dir);
            Object@ weap_obj = ReadObjectFromID(weap_id);

            char_obj.AttachItem(weap_obj, _at_grip, false);
        }
    }
}