void Init() {
	
 
   
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
		if(paramzz.GetInt("questType") == 10){
			if(paramzz.GetInt("questStatus") == 0){
				level.SendMessage("displaytext \""+"Kill the general switfly. Do not get bested or your mission will fail."+"\"");
				paramzz.SetInt("questKills", 99);
			}else if(paramzz.GetInt("questStatus") == -1){
				level.SendMessage("displaytext \""+"The general has fled and is replaced by an assitant. The target is gone. You have failed."+"\"");
				paramzz.SetInt("questKills", 0);
			}
			
		}
		//
		obj.UpdateScriptParams();
    }
}

void OnExit(MovementObject @mo) {
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
	if(mo.controlled){
		paramzz.SetInt("questKills", 0);
	}
}

void Update(){
	
}

void CheckKeyPresses(){

}

