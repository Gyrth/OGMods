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
		 	params.SetInt("Open", 1234);
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
			level.SendMessage("displayhud /Data/UI/Icons/weaponRack.png");
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
		if( params.GetInt("Open") == 1234){
			if(params.GetInt("Searched") == 0){
				level.SendMessage("rackle");
				params.SetInt("Searched", 1);
			}else{
				level.SendMessage("displaytext \""+"You have searched this rack already."+"\"");
			}
		}
	}
}
