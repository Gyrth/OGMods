void Init() {
}



void SetParameters() {	
params.AddInt("Open", 0);	
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
				int player_id  = -1;
    		int num = GetNumCharacters();
    		for(int i=0; i<num; ++i){
        		MovementObject@ char = ReadCharacter(i);
        		if(char.controlled){
            		player_id = char.GetID();
					break;
        		}
    		}
    if(mo.controlled){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		paramzz.SetInt("caravanStrike", 0);
		obj.UpdateScriptParams();
    }
}

void OnExit(MovementObject @mo) {
	
}

void Update(){
	
}

void CheckKeyPresses(){
	
}