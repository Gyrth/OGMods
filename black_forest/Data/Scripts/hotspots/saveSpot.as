int GetPlayerID() {
    int id = -1;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            id = char.GetID();
            break;
        }
    }
    return id;
}

void Init() {
    //save spots used to save charcater progression when entering forts. 
    // now the progression is saved every 4 secs so no need for that. 
}



void SetParameters() {
    params.AddInt("Open", 0);
    params.AddString("Namezz", "saveSpot");	
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

}

void OnExit(MovementObject @mo) {
  
}

void Update(){
	
}

void CheckKeyPresses(){
	
}
