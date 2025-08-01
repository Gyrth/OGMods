void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("quest8Go", 0);
	params.AddInt("poisoned", 0);
	//level.SendMessage("displaytext \""+"debug: dead body spawned"+"\"");
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
		params.SetInt("quest8Go", 1);
		if(paramzz.GetInt("questType") == 8 && paramzz.GetInt("questStatus") == 0){
			level.SendMessage("displaytext \""+"Press x to poison this well."+"\"");
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("quest8Go", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		if(params.GetInt("quest8Go") == 1){
			if(params.GetInt("poisoned") == 0){
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
				MovementObject@ mo = ReadCharacterID(player_id);
				if(paramzz.GetInt("questType") == 8){
					if(paramzz.GetInt("questStatus") == 0){
						paramzz.SetInt("questStatus", 1);
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("questReset");
						level.SendMessage("displayhud /Data/UI/Icons/quest8completed.png");
						params.SetInt("poisoned", 1);
					}else if(paramzz.GetInt("questStatus") == -1){
						level.SendMessage("displaytext \""+"You have lost the poison vial. This quest is failed."+"\"");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}
				}else{
					//normal drinks
					level.SendMessage("slurp");
				}
			}else{
				level.SendMessage("displaytext \""+"You already poisoned that well. Get back to a Rabbit fortress for your reward."+"\"");
				//PlaySound("Data/Sounds/nope.wav", mo.position);
			}
		}
	}
}

