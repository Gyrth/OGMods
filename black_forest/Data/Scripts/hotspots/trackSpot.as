void Init() {
}



void SetParameters() {
params.AddInt("Tracked", 0);	
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
    if(mo.controlled){
		if(params.GetInt("Tracked") == 0 ){
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("displayhud /Data/UI/Icons/caravanTracks.png");
		}
    }
}

void OnExit(MovementObject @mo) {
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "x")){
		if(params.GetInt("Open") == 1){
			int player_id  = -1;
			int skillBonus = 0;
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
			if(params.GetInt("Tracked") == 0){
				ScriptParams@ level_params = level.GetScriptParams();
				if(level_params.GetInt("Rain") != 1){
					if(paramzz.GetInt("hour") < 20 || paramzz.GetInt("Winter")>0){
						if(paramzz.GetString("trinketType") == "Knowledge"){
							skillBonus = paramzz.GetInt("trinketPower");
						}
						if(rand()% 100 < paramzz.GetInt("Tracking")+skillBonus){
							level.SendMessage("clearhud");
							level.SendMessage("uicue");
							PlaySound("Data/Sounds/yay.wav", mo.position);
							PlaySound("Data/Sounds/caravan.wav", mo.position);
							level.SendMessage("trackingCaravan");
							paramzz.SetInt("caravanStrike", (paramzz.GetInt("caravanStrike")+3));
							if(paramzz.GetInt("caravanStrike") <= 0 ){
								level.SendMessage("displayhud /Data/UI/Icons/caravaning0.png");
							}else if(paramzz.GetInt("caravanStrike") <= 3){
								level.SendMessage("displaytext \""+" Bushcraft skill success. A caravan has passed here recently. Find more tracks to get closer!!");
								level.SendMessage("displayhud /Data/UI/Icons/caravaning1.png");
							}else if(paramzz.GetInt("caravanStrike") <= 6){
								level.SendMessage("displaytext \""+" Bushcraft skill success. You are getting closer to the caravan.");
								level.SendMessage("displayhud /Data/UI/Icons/caravaning2.png");
							}else if(paramzz.GetInt("caravanStrike") > 6){
								level.SendMessage("displaytext \""+" Bushcraft skill success. The caravan is here somewhere!! Find it before it moves away.");
								level.SendMessage("displayhud /Data/UI/Icons/caravaning3.png");
							}
						}else{
							level.SendMessage("clearhud");
							level.SendMessage("uicue");
							level.SendMessage("displaytext \""+" Bushcraft skill failed. You can't make anything out of these tracks.");
							PlaySound("Data/Sounds/meh.wav", mo.position);
							params.SetInt("Tracked", 1);
						}
					}else{
					
						level.SendMessage("displaytext \""+"It is impossible to track at night if there is no snow.");
						PlaySound("Data/Sounds/nope.wav", mo.position);
						
					}
				}else{
					//params.GetInt("hour") < 20 && 
					level.SendMessage("displaytext \""+"It is impossible to track when it rains.");
					
					PlaySound("Data/Sounds/nope.wav", mo.position);
				}
			}
			obj.UpdateScriptParams();
		}
	}
	
}
	

