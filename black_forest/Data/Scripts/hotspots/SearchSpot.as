void Init() {
}



void SetParameters() {
params.AddInt("Searched", 0);
params.AddInt("Open", 0);	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
		if(mo.controlled){
        	OnEnter(mo);
		 	params.SetInt("Open", 123);
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
		if(params.GetInt("Searched") == 0){
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("displayhud /Data/UI/Icons/lootage.png");
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
		if( params.GetInt("Open") == 123){
			if(params.GetInt("Searched") == 0){
				//level.SendMessage("displaytext \""+"You have acquired some food."+"\"");
				// PlaySound("Data/Sounds/cloth_fabric_choke_fall_2.wav", );
				level.SendMessage("rumble");
				params.SetInt("Searched", 1);
			}else{
				level.SendMessage("displaytext \""+"You have searched this container already."+"\"");
			}
		}
	}
}
