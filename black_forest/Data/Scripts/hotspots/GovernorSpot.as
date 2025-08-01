void Init() {
}



void SetParameters() {
	params.AddInt("QuestType", rand()%5);
	params.AddInt("Quested", 0);
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
		  if(params.GetInt("quested") == 0){
			 level.SendMessage("clearhud");
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
		if(params.GetInt("Open")==1){
			if(params.GetInt("Quested")==0){
				// PlaySound("Data/Sounds/cloth_fabric_choke_fall_2.wav", );
				level.SendMessage("taskMaster");
			}else{
			}
		}
	}
}
