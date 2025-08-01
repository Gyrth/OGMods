void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("quest2Go", 0);
	params.AddInt("tracked", 0);
	//level.SendMessage("displaytext \""+"debug: dead body spawned"+"\"");
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
		ScriptParams@ paramzz = obj.GetScriptParams();
		//
		params.SetInt("quest2Go", 1);
		if(paramzz.GetInt("questType") == 2 && paramzz.GetInt("questStatus") == 0){
		  	paramzz.SetInt("questStatus", 1);
			PlaySound("Data/Sounds/quest2riff.wav", mo.position);
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("questReset");
			level.SendMessage("displayhud /Data/UI/Icons/quest2completed.png");
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("quest2Go", 0);
	}
}

void Update(){
	
}

void CheckKeyPresses(){
	

}

