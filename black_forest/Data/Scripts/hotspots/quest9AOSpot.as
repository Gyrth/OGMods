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
		if(paramzz.GetInt("questType") == 9){
			if(paramzz.GetInt("questStatus") == 0){
				level.SendMessage("displaytext \""+"Get to the top and steal the plans."+"\"");
			}else{
				level.SendMessage("questReset");
				level.SendMessage("displaytext \""+"The plans were taken away the last time you were detected. The mission failed."+"\"");
			}
			paramzz.SetInt("questKills", 99);
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

