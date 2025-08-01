#include "undergrowth_spawns.as"

void Init() {
	
 
   
}

void SetParameters() {
	params.AddInt("quest11Go", 0);
	params.AddInt("attacked", 0);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		int player_id  = -1;
    	int num = GetNumCharacters();
    	for(int i=0; i<num; ++i){
        	MovementObject@ char = ReadCharacter(i);
        	if(char.controlled){
            	player_id = char.GetID();
				break;
        	}
    	}
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		//
		params.SetInt("quest11Go", 1);
		if(paramzz.GetInt("questType") == 11 && paramzz.GetInt("questStatus") == 0 && params.GetInt("attacked") == 0){
			params.SetInt("attacked", 1);
			SendInAttackers();
			SendInAttackers();
			SendInAttackers();
			SendInAttackers();
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("quest11Go", 0);
	}
}

void Update(){

}

void CheckKeyPresses(){
	
	
}

