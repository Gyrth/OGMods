void Init() {
}



void SetParameters() {
	params.AddInt("Stealed", 0);
	params.AddInt("Open", 0);	
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
		  if(params.GetInt("Stealed") == 0){
			  level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/stealage.png");
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
			if(params.GetInt("Stealed") == 0){
				//level.SendMessage("displaytext \""+"You have acquired some food."+"\"");
				// PlaySound("Data/Sounds/cloth_fabric_choke_fall_2.wav", );
				level.SendMessage("shuffle");
				params.SetInt("Stealed", 1);
			}else{
				level.SendMessage("displaytext \""+"You already plundered that container."+"\"");
			}
		}
	}
}
