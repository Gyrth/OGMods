

void Init() {
	
    
}



void SetParameters() {

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {

    if(mo.controlled){
    	Object @obj = ReadObjectFromID(hotspot.GetID());

		//level.SendMessage("displaytext \""+"just got to place "+obj.GetName());

    }else {
		
	}

}

void OnExit(MovementObject @mo) {
	
}

void Update(){
}


