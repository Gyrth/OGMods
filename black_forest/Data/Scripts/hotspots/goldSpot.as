void Init() {
}



void SetParameters() {
	params.AddInt("looted", 0);
	params.AddInt("Open", 0);
	//params.AddInt("cash", (rand()%4)+1);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
    	if(mo.controlled){
        OnEnter(mo);
		 params.SetInt("Open", 1);
		}
    } else if(event == "exit"){
    	if(mo.controlled){
        OnExit(mo);
		 params.SetInt("Open", 0);
		}
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		  if(params.GetInt("looted") == 0){
			 level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/lootCrate.png");
			
		  }
    }
}

void OnExit(MovementObject @mo) {
  
}

void Update(){
	
	CheckKeyPresses();
	
}

void CheckKeyPresses(){
	if(GetInputPressed(1, "x")){
		if( params.GetInt("Open") == 1){
			if(params.GetInt("looted") == 0){
				int amount = (rand() % 4)+1;
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
				ScriptParams@ paramxx = obj.GetScriptParams();
				MovementObject@ mo = ReadCharacterID(player_id);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displaytext \""+"You found "+amount+" gold pieces !!");
				PlaySound("Data/Sounds/yay.wav", mo.position);
				PlaySound("Data/Sounds/cashish.wav", mo.position);
				if(paramxx.GetString("trinketType") == "Fortune" && (rand()% 100 < paramxx.GetInt("trinketPower")*5) ){
					paramxx.SetInt("Gold", paramxx.GetInt("Gold")+amount+1);
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
				}else{
					paramxx.SetInt("Gold", paramxx.GetInt("Gold")+amount);
				}
				obj.UpdateScriptParams();
				params.SetInt("looted", 1);
			}
		}
	}
}
