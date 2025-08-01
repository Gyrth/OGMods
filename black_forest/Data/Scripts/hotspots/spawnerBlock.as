#include "threatcheck.as"

string rndEnemy(){
	int dice = rand()%10;
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
	}
	return "Data/Characters/Undergrowth/cat_clan/Scout.xml";
}






void spawner(string mob){
	//find an id to create
    int enemyID = CreateObject(mob);
    //create actual object
    Object@ charObj = ReadObjectFromID(enemyID);
    //find a suitable spawn location
    Object@ spawn_obj = ReadObjectFromID(findSpawnPoint());
    // move the guy the spawn location
    vec3 enemy_pos;
	charObj.SetTranslation(spawn_obj.GetTranslation());
	//charObj.QueueScriptMessage("escort_me "+player_id); 
}


int findPlayerId(){
    int player_id  = -1;
        int num = GetNumCharacters();
        for(int i=0; i<num; ++i){
            MovementObject@ char = ReadCharacter(i);
            if(char.controlled){
                player_id = char.GetID();
                return player_id;
            }
        }
    //found nothing will return -1
   // DisplayError("oh noes", "the player has no id foo!! (which is slightly concerning actually)");
    return player_id;
}

int findSpawnPoint(){
    /*
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ paramss = obj.GetScriptParams();
            if(paramss.HasParam("spawntag")){
                return object_ids[i];
            }
        }

        return -1;
    */
    string spawnName = "spawnPoint_"+rand()%4;
    //now that we have the name of the spawn point we do a loop
   // level.SendMessage("displaytext \""+" will spawn at "+spawnName);
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        if(obj.GetName() == spawnName){
            return object_ids[i];
        }
    }
    //
    return -1;

}
void SetParameters() {
    params.AddInt("Eaten", 0);  
    params.AddInt("Open", 0);   
}

void Init() {
    if(params.GetInt("Eaten") == 0){
        //spawner(rndEnemy());
        // Create the new object
        int spawnedObjectId = CreateObject(rndEnemy(), true );
        Object @new_obj = ReadObjectFromID( spawnedObjectId );
        // Find the spawn point 
        Object@ spawn = ReadObjectFromID(findSpawnPoint());
        //
        //
        new_obj.SetTranslation(spawn.GetTranslation());
        vec4 rot_vec4 = spawn.GetRotationVec4();
        quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
        new_obj.SetRotation(q);
        params.SetInt("Eaten", 1); 
    }
}




void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
		 params.SetInt("Open", 1);
        OnEnter(mo);
    } else if(event == "exit"){
		 params.SetInt("Open", 0);
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	
}

void OnExit(MovementObject @mo) {

}

void Update(){


}


