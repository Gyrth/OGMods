#include "undergrowth_includes.as"

vec3 findSpawnPoint(){

    array<int> @object_ids = GetObjectIDs();
    array<int> placesID;
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ block_params = obj.GetScriptParams();
        if(block_params.HasParam("Name")){
            if(block_params.GetString("Name") == "SpawnPlace"){
                placesID.insertLast(object_ids[i]);
            }
        }
    }

    if(placesID.length() > 0){
        int random_id = placesID[rand()% placesID.length()];
		return ReadObjectFromID(random_id).GetTranslation();
    }else{
		return ReadCharacterID(GetPlayerID()).position + vec3(0.0, 15.0, 0.0);
	}

}

string rndEnemy(){
	//int dice = rand()%11;
	int dice = 10;
	if(dice == 0){
		return "Data/Characters/Undergrowth/RatMaleRogue.xml";
	}else if(dice == 1){
		return "Data/Characters/Undergrowth/rat_clan/attacker.xml";
	}else if(dice == 2){
		return "Data/Characters/Undergrowth/rat_clan/bodyGuard.xml";
	}else if(dice == 3){
		return "Data/Characters/Undergrowth/rat_clan/scout.xml";
	}else if(dice == 4){
		return "Data/Characters/Undergrowth/dog_clan/generic.xml";
	}else if(dice == 5){
		return "Data/Characters/Undergrowth/dog_clan/heavy.xml";
	}else if(dice == 6){
		return "Data/Characters/Undergrowth/dog_clan/scout.xml";
	}else if(dice == 7){
		return "Data/Characters/Undergrowth/cat_clan/generic.xml";
	}else if(dice == 8){
		return "Data/Characters/Undergrowth/cat_clan/heavy.xml";
	}else if(dice == 9){
		return "Data/Characters/Undergrowth/cat_clan/Scout.xml";
	}else if(dice == 10){
		return "Data/Characters/Undergrowth/cat_clan/cutPurse.xml";
	}
	return "Data/Characters/Undergrowth/cat_clan/Scout.xml";
}

void spawnDiplomat(){
	MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
    string enemyPath = "Data/Characters/Undergrowth/rabbitDiplomat.xml";
    int enemyID = CreateObject(enemyPath);
    Object@ charObj = ReadObjectFromID(enemyID);
    vec3 enemy_pos;
    enemy_pos = vec3(player_mo.position.x-3.0, player_mo.position.y, player_mo.position.z-3.0);
	charObj.SetTranslation(enemy_pos);
	charObj.QueueScriptMessage("escort_me "+GetPlayerID()); 
}

void spawnBuddy(){
    MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
    string enemyPath = "Data/Characters/Undergrowth/runnerBuddy.xml";
    int enemyID = CreateObject(enemyPath);
    Object@ charObj = ReadObjectFromID(enemyID);
    vec3 enemy_pos;
    enemy_pos = vec3(player_mo.position.x-3.0, player_mo.position.y, player_mo.position.z-3.0);
    charObj.SetTranslation(enemy_pos);
    charObj.QueueScriptMessage("escort_me "+GetPlayerID()); 
}

void SendInEnemyChar(){
    string enemyPath = rndEnemy();
    //find an id to create
    int enemyID = CreateObject(enemyPath);
    //create actual object
    Object@ charObj = ReadObjectFromID(enemyID);
    //find a suitable spawn location
	vec3 spawn_pos = findSpawnPoint();
    // move the guy the spawn location
    vec3 enemy_pos;
	charObj.SetTranslation(spawn_pos);
	charObj.ReceiveScriptMessage("escort_me "+GetPlayerID()); 
}

void SendInHunters(){
	//find an id to create
    int enemyID = CreateObject("Data/Characters/Undergrowth/dog_clan/hunter.xml");
    //create actual object
    Object@ charObj = ReadObjectFromID(enemyID);
    //find a suitable spawn location
    vec3 spawn_pos = findSpawnPoint();
    // move the guy the spawn location
    vec3 enemy_pos;
	charObj.SetTranslation(spawn_pos);
	charObj.ReceiveScriptMessage("escort_me "+GetPlayerID()); 
}

void SendInAttackers(){
	//find an id to create
    int enemyID = CreateObject("Data/Characters/Undergrowth/rat_clan/attacker.xml");
    //create actual object
    Object@ charObj = ReadObjectFromID(enemyID);
    //find a suitable spawn location
    vec3 spawn_pos = findSpawnPoint();
    // move the guy the spawn location
    vec3 enemy_pos;
	charObj.SetTranslation(spawn_pos);
	charObj.ReceiveScriptMessage("escort_me "+GetPlayerID()); 
}

void SendInAssassin(int player_id){
    string enemyPath = "Data//Characters/rat_clan/ninja.xml";
    //find an id to create
    int enemyID = CreateObject(enemyPath);
    //create actual object
    Object@ charObj = ReadObjectFromID(enemyID);
    //find a suitable spawn location
    vec3 spawn_pos = findSpawnPoint();
    // move the guy the spawn location
    vec3 enemy_pos;
	charObj.SetTranslation(spawn_pos);
	charObj.ReceiveScriptMessage("escort_me "+GetPlayerID()); 
}

void spawnByLabel(string myLabel){
	string itemPath;
	if(myLabel == "sword"){
		itemPath = "Data/Items/DogWeapons/DogSword.xml";
	}else if(myLabel == "knife"){
		itemPath = "Data/Items/DogWeapons/DogKnife.xml"; 
	}else if(myLabel == "rapier"){
		itemPath = "Data/Items/Rapier.xml";
	}else if(myLabel == "spearz"){
		itemPath = "Data/Items/DogWeapons/DogSpear.xml";
	}else if(myLabel == "ninjato"){
		itemPath = "Data/jims_weapon_pack/katana_viola/jims_katana_viola.xml";
	}else if(myLabel == "odashi"){
		itemPath = "Data/Items/Undergrowth/Sword_2_Weapon.xml";
	}else if(myLabel == "katana"){
        itemPath = "Data/Items/Undergrowth/Sword_1_Weapon.xml";
    }else if(myLabel == "staffz"){
		itemPath  = "Data/Items/staffbasic.xml";
	}else if(myLabel == "big_swordz"){
		itemPath = "Data/Items/DogWeapons/DogBroadSword.xml";
	}else if(myLabel == "naginata"){
		itemPath = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml";
	}else if(myLabel == "yari"){
		itemPath = "Data/Items/Undergrowth/Polearm_FlatEdge_Weapon.xml";
	}else if(myLabel == "jumonji_yari"){
		itemPath = "Data/Items/Undergrowth/Polearm_Spiked_Weapon.xml";
	}else if(myLabel == "warhammer"){
		itemPath = "Data/Items/DogHammer.xml";
	}else if(myLabel == "hammer"){
		itemPath = "Data/Items/gear/dogtools/dogtoolhammer.xml";
	}else if(myLabel == "shank"){
		itemPath = "Data/Items/gear/dogtools/dogtoolawl.xml";
	}else if(myLabel == "rat_club"){
		itemPath = "Data/jims_weapon_pack/rat_weapons/jims_rat_club.xml";
	}else if(myLabel == "rat_sword"){
		itemPath = "Data/jims_weapon_pack/rat_weapons/jims_rat_sword.xml";
	}else if(myLabel == "rabies"){
		itemPath = "Data/jims_weapon_pack/rabies_weapons/jims_rabies_sword.xml";
	}else if(myLabel == "kendo2h"){
		itemPath = "Data/jims_weapon_pack/kendostick_2h/jims_kendostick_2h_red.xml";
	}else if(myLabel == "assassin"){
		itemPath = "Data/Items/Undergrowth/special_assassin.xml";
	}else if(myLabel == "bloodThirst"){
		itemPath = "Data/Items/Undergrowth/special_bloodThirst.xml";
	}else if(myLabel == "north"){
		itemPath = "Data/Items/Undergrowth/special_north.xml";
	}else if(myLabel == "banshee"){
		itemPath = "Data/Items/Undergrowth/special_banshee.xml";
	}else if(myLabel == "holyAvenger"){
		itemPath = "Data/Items/Undergrowth/special_holyAvenger.xml";
	}else if(myLabel == "purity"){
		itemPath = "Data/Items/Undergrowth/special_purity.xml";
	}else if(myLabel == "shadowRun"){
		itemPath = "Data/Items/Undergrowth/special_shadowRun.xml";
	}else{
		return;
	}
    int gearID = CreateObject(itemPath);
    Object@ charObj = ReadObjectFromID(gearID);
	MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
	vec3 initial_position = vec3(player_mo.position.x+3 , player_mo.position.y, player_mo.position.z+3);
    charObj.SetTranslation(initial_position);
}

int spawnByLabel2(string myLabel){
	string itemPath;
	if(myLabel == "sword"){
		itemPath = "Data/Items/DogWeapons/DogSword.xml";
	}else if(myLabel == "knife"){
		itemPath = "Data/Items/DogWeapons/DogKnife.xml"; 
	}else if(myLabel == "rapier"){
		itemPath = "Data/Items/Rapier.xml";
	}else if(myLabel == "spearz"){
		itemPath = "Data/Items/DogWeapons/DogSpear.xml";
	}else if(myLabel == "katana"){
		itemPath = "Data/Items/Undergrowth/Sword_2_Weapon.xml";
	}else if(myLabel == "odashi"){
		itemPath = "Data/Items/Undergrowth/Sword_1_Weapon.xml";
	}else if(myLabel == "staffz"){
		itemPath  = "Data/Items/staffbasic.xml";
	}else if(myLabel == "big_swordz"){
		itemPath = "Data/Items/DogWeapons/DogBroadSword.xml";
	}else if(myLabel == "naginata"){
		itemPath = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml";
	}else if(myLabel == "yari"){
		itemPath = "Data/Items/Undergrowth/Polearm_FlatEdge_Weapon.xml";
	}else if(myLabel == "jumonji_yari"){
		itemPath = "Data/Items/Undergrowth/Polearm_Spiked_Weapon.xml";
	}else if(myLabel == "warhammer"){
		itemPath = "Data/Items/DogHammer.xml";
	}else if(myLabel == "hammer"){
		itemPath = "Data/Items/gear/dogtools/dogtoolhammer.xml";
	}else if(myLabel == "shank"){
		itemPath = "Data/Items/gear/dogtools/dogtoolawl.xml";
	}else if(myLabel == "rat_club"){
		itemPath = "Data/jims_weapon_pack/rat_weapons/jims_rat_club.xml";
	}else if(myLabel == "rat_sword"){
		itemPath = "Data/jims_weapon_pack/rat_weapons/jims_rat_sword.xml";
	}else if(myLabel == "rabies"){
		itemPath = "Data/jims_weapon_pack/rabies_weapons/jims_rabies_sword.xml";
	}else if(myLabel == "kendo2h"){
		itemPath = "Data/jims_weapon_pack/kendostick_2h/jims_kendostick_2h_red.xml";
	}else if(myLabel == "assassin"){
		itemPath = "Data/Items/Undergrowth/special_assassin.xml";
	}else if(myLabel == "bloodThirst"){
		itemPath = "Data/Items/Undergrowth/special_bloodThirst.xml";
	}else if(myLabel == "north"){
		itemPath = "Data/Items/Undergrowth/special_north.xml";
	}else if(myLabel == "banshee"){
		itemPath = "Data/Items/Undergrowth/special_banshee.xml";
	}else if(myLabel == "holyAvenger"){
		itemPath = "Data/Items/Undergrowth/special_holyAvenger.xml";
	}else if(myLabel == "purity"){
		itemPath = "Data/Items/Undergrowth/special_purity.xml";
	}else if(myLabel == "shadowRun"){
		itemPath = "Data/Items/Undergrowth/special_shadowRun.xml";
	}
    int gearID = CreateObject(itemPath);
    Object@ charObj = ReadObjectFromID(gearID);
	MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
	vec3 initial_position = vec3(player_mo.position.x+1 , player_mo.position.y, player_mo.position.z);
    charObj.SetTranslation(initial_position);
	return gearID;
}

void createGear(){
    string itemPath;
	//int rnd = 17;
    int rnd = rand()%21;
	if(rnd == 18){
		PlaySound("Data/Sounds/versus/fight_win1_1.wav");
	}
    switch(rnd){
    	case 0: itemPath = "Data/Items/DogWeapons/DogKnife.xml"; break;
        case 1: itemPath = "Data/Items/DogWeapons/DogBroadSword.xml"; break;
       	case 2: itemPath = "Data/Items/DogWeapons/DogSword.xml"; break;
        case 3: itemPath = "Data/Items/DogWeapons/DogSpear.xml"; break;
		case 4: itemPath = "Data/Items/DogHammer.xml"; break;
		case 5: itemPath  = "Data/Items/gear/dogtools/dogtoolawl.xml"; break;
		case 6: itemPath  = "Data/Items/gear/dogtools/dogtoolhammer.xml"; break;
		case 7: itemPath  = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml"; break;
		case 8: itemPath  = "Data/Items/staffbasic.xml"; break;
		case 9: itemPath  = "Data/Items/Rapier.xml"; break;
		case 10: itemPath  = "Data/Items/MainGauche.xml"; break;
		case 11: itemPath  = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml"; break;
		case 12: itemPath  = "Data/Items/Undergrowth/Polearm_FlatEdge_Weapon.xml"; break;
		case 13: itemPath  = "Data/Items/Undergrowth/Polearm_Spiked_Weapon.xml"; break;
		case 14: itemPath  = "Data/jims_weapon_pack/rat_weapons/jims_rat_club.xml"; break;
		case 15: itemPath  = "Data/jims_weapon_pack/rat_weapons/jims_rat_sword.xml"; break;
		case 16: itemPath = "Data/jims_weapon_pack/kendostick_2h/jims_kendostick_2h_red.xml"; break;
		case 17: itemPath = "Data/jims_weapon_pack/katana_viola/jims_rabies_sword.xml"; break;
		case 18: itemPath = "Data/jims_weapon_pack/katana_viola/jims_katana_viola.xml"; break;
		case 19: itemPath  = "Data/Items/Undergrowth/Sword_1_Weapon.xml"; break;
		case 20: itemPath  = "Data/Items/Undergrowth/Sword_2_Weapon.xml"; break;
	}
    int gearID = CreateObject(itemPath);
    Object@ charObj = ReadObjectFromID(gearID);
	MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
	vec3 initial_position = vec3(player_mo.position.x+1 , player_mo.position.y+1, player_mo.position.z);
    charObj.SetTranslation(initial_position);
}

int createMagicItem(){
	string itemPath;
	//int rnd = 17;
    int rnd = rand()%7;
    switch(rnd){
    	case 0: itemPath = "Data/Items/Undergrowth/special_banshee.xml"; break;
        case 1: itemPath = "Data/Items/Undergrowth/special_shadowRun.xml"; break;
       	case 2: itemPath = "Data/Items/Undergrowth/special_assassin.xml"; break;
        case 3: itemPath = "Data/Items/Undergrowth/special_holyAvenger.xml"; break;
		case 4: itemPath = "Data/Items/Undergrowth/special_bloodThirst.xml"; break;
		case 5: itemPath = "Data/Items/Undergrowth/special_north.xml"; break;
		case 6: itemPath = "Data/Items/Undergrowth/special_purity.xml"; break;
	}
    int gearID = CreateObject(itemPath);
   	// Object@ charObj = ReadObjectFromID(gearID);
	// MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
	// vec3 initial_position = vec3(player_mo.position.x+1 , player_mo.position.y+1, player_mo.position.z);
   	// charObj.SetTranslation(initial_position);
    return gearID;	
}

