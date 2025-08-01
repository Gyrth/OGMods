void Init() {
}



void SetParameters() {
params.AddInt("Open", 0);
params.AddInt("Tipper", 0);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
		
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		//DisplayError("wtf", "mo is controlled");
		if(params.GetInt("Open")== 0){
			//DisplayError("wtf", "open is 0");
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("tipDelay");
			params.SetInt("Tipper", (rand()%56));
			//level.SendMessage("displaytext \""+"tipper is "+params.GetInt("Tipper")+"\"");
			level.SendMessage("displayhud /Data/UI/Icons/tip"+params.GetInt("Tipper")+".png");
			PlaySound("Data/Sounds/tipSound.wav", mo.position);
			params.SetInt("Open", 1);
		}
		
    }
}

void OnExit(MovementObject @mo) {
  
}

void Update(){
	
}

void CheckKeyPresses(){
	
}
