void Init() {
}



void SetParameters() {
params.AddInt("Open", 0);
	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
		if(mo.controlled){
			params.SetInt("Open", 1);
        	OnEnter(mo);
		}
    } else if(event == "exit"){
		if(mo.controlled){
			params.SetInt("Open", 0);
        	OnExit(mo);
		}
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/drinkage.png");
    }
}

void OnExit(MovementObject @mo) {
  
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "x")){
		if(params.GetInt("Open")==1){
			// PlaySound("Data/Sounds/cloth_fabric_choke_fall_2.wav", );
			level.SendMessage("slurp");
		}
	}
}
