void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("quest9Go", 0);
	params.AddInt("stolen", 0);
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
		params.SetInt("quest9Go", 1);
		if(paramzz.GetInt("questType") == 9 && paramzz.GetInt("questStatus") == 0){
			level.SendMessage("displaytext \""+"Press x to steal the plans."+"\"");
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("quest9Go", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "x")){
		int player_id  = -1;
    	int num = GetNumCharacters();
    	for(int i=0; i<num; ++i){
        	MovementObject@ char = ReadCharacter(i);
        	if(char.controlled){
            	player_id = char.GetID();
				break;
        	}
    	}
		MovementObject@ mo = ReadCharacterID(player_id);
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		if(params.GetInt("quest9Go") == 1){
			if(params.GetInt("stolen") == 0){
				if(paramzz.GetInt("questType") == 9){
					if(paramzz.GetInt("questStatus") == 0){
						paramzz.SetInt("questStatus", 1);
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("questReset");
						level.SendMessage("displayhud /Data/UI/Icons/quest9completed.png");
						params.SetInt("stolen", 1);
					}else if(paramzz.GetInt("questStatus") == -1){
						level.SendMessage("displaytext \""+"The plans are gone. You were detected during your approach."+"\"");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}
				}
			}else{
				level.SendMessage("displaytext \""+"You took the plans already. Return them to a Rabbit fort!!"+"\"");
				//PlaySound("Data/Sounds/nope.wav", mo.position);
			}
		}
	}
}

