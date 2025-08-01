void Init() {
}



void SetParameters() {
	params.AddInt("looted", 0);
	params.AddInt("Open", 0);
	params.AddInt("Scroll", 1);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
		 params.SetInt("Open", 1);
    } else if(event == "exit"){
        OnExit(mo);
		 params.SetInt("Open", 0);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		  if(params.GetInt("looted") == 0){
			 level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/scrollCrate.png");
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
				if(paramxx.GetInt("Search")+paramxx.GetInt("Faith")+paramxx.GetInt("Tracking")+paramxx.GetInt("Steal") < 200){
					if(paramxx.GetString("trinketType") == "Wisdom" && (rand()% 100 < paramxx.GetInt("trinketPower")*5) ){
						paramxx.SetInt("xp", (params.GetInt("xp")+2));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						paramxx.SetInt("xp", (paramxx.GetInt("xp")+1));
					}
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displaytext \""+"You found "+params.GetInt("Scroll")+" ancient scroll!!");
					PlaySound("Data/Sounds/yay.wav", mo.position);
				}else{
					level.SendMessage("displaytext \""+"Your knowledge is too vast, scrolls are to no use to you.");
					PlaySound("Data/Sounds/meh.wav", mo.position);
				}
				obj.UpdateScriptParams();
				params.SetInt("looted", 1);
			}
		}
	}
}
