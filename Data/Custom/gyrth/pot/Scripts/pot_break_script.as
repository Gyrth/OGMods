	Object@ pot_hotspot = ReadObjectFromID(hotspot.GetID());
	int pot_id = CreateObject("Data/Custom/gyrth/pot/Objects/pot_whole.xml");
	Object@ pot_obj = ReadObjectFromID(pot_id);
	vec3 hotspot_pos = pot_hotspot.GetTranslation();
	float up_offset = 0.5f;
	vec3 spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+up_offset, hotspot_pos.z);
	int obj_id;
	array<int> spawned_object_ids;
	int char_id;
	bool broken = false;
	
void Init() {
	pot_obj.SetTranslation(spawn_point);
	ScriptParams@ pot_params = pot_obj.GetScriptParams();
    pot_params.AddIntCheckbox("No Save", true);
	pot_hotspot.SetScale(vec3(0.5f,0.5f,0.5f));
}
void SetParameters() {

}
void HandleEventItem(string event, ItemObject @obj){
    if(event == "enter"){
        OnEnterItem(obj);
    } 
    if(event == "exit"){
        OnExitItem(obj);
    } 
}
void Reset(){
	Print("reset");
	int numShards = spawned_object_ids.size();
	for(int i = 0;i<numShards;i++){
		DeleteObjectID(spawned_object_ids[i]);
	}
	spawned_object_ids.resize(0);
	pot_id = CreateObject("Data/Custom/gyrth/pot/Objects/pot_whole.xml");
	
	hotspot_pos = pot_hotspot.GetTranslation();
	spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+up_offset, hotspot_pos.z);
	Object@ new_pot_obj = ReadObjectFromID(pot_id);
	new_pot_obj.SetTranslation(spawn_point);

	ScriptParams@ pot_params = new_pot_obj.GetScriptParams();
    pot_params.AddIntCheckbox("No Save", true);
	pot_hotspot.SetScale(vec3(0.5f,0.5f,0.5f));
	broken = false;
}

void OnEnterItem(ItemObject @obj) {
	if(broken == false){
		DeleteObjectID(pot_id);
		PlaySound("Data/Custom/gyrth/pot/Sounds/pot_break.wav", spawn_point);
		Object@ pot_shard1_obj = SpawnObjectAtSpawnPoint(spawn_point, "Data/Custom/gyrth/pot/Items/pot_shard1.xml");
		Object@ pot_shard2_obj = SpawnObjectAtSpawnPoint(spawn_point, "Data/Custom/gyrth/pot/Items/pot_shard2.xml");
		Object@ pot_shard3_obj = SpawnObjectAtSpawnPoint(spawn_point, "Data/Custom/gyrth/pot/Items/pot_shard3.xml");
		Object@ pot_shard4_obj = SpawnObjectAtSpawnPoint(spawn_point, "Data/Custom/gyrth/pot/Items/pot_shard4.xml");
		Object@ pot_shard5_obj = SpawnObjectAtSpawnPoint(spawn_point, "Data/Custom/gyrth/pot/Items/pot_shard5.xml");
		
		ScriptParams@ pot_shard1_params = pot_shard1_obj.GetScriptParams();
		ScriptParams@ pot_shard2_params = pot_shard2_obj.GetScriptParams();
		ScriptParams@ pot_shard3_params = pot_shard3_obj.GetScriptParams();
		ScriptParams@ pot_shard4_params = pot_shard4_obj.GetScriptParams();
		ScriptParams@ pot_shard5_params = pot_shard5_obj.GetScriptParams();
		
		pot_shard1_params.AddIntCheckbox("No Save", true);
		pot_shard2_params.AddIntCheckbox("No Save", true);
		pot_shard3_params.AddIntCheckbox("No Save", true);
		pot_shard4_params.AddIntCheckbox("No Save", true);
		pot_shard5_params.AddIntCheckbox("No Save", true);
		
		//DeleteObjectID(hotspot.GetID());
		//ItemObject@ item_obj = ReadItem(obj_id+1);
		//item_obj.SetLinearVelocity(direction);
		broken = true;
	}
}

void OnExitItem(ItemObject @obj) {
	Print("Exited Hotspot"+"\n");
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