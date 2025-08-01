#include "undergrowth_includes.as"
#include "undergrowth_spawns.as"

string getRandomPower(){
    int rnd = rand()%7;
    switch(rnd){
    	case 0: return "Shadow Run";
        case 1: return "Blood Thirst"; 
       	case 2: return "Holy Avenger"; 
        case 3: return "Banshee"; 
		case 4: return "Assassin"; 
        case 5: return "North"; 
        case 6: return "Purity"; 
	}
	return "Poop";
}

void Init() {
    int spawnedObjectId = createMagicItem();
    Object @new_obj = ReadObjectFromID( spawnedObjectId );
    Object@ spawn = ReadObjectFromID(hotspot.GetID());
    new_obj.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    new_obj.SetRotation(q);
}



void SetParameters() {

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    
}

void OnExit(MovementObject @mo) {

}

void Update(){

}

