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
}



void SetParameters() {
params.AddInt("Prayed", 0);
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
		  if(params.GetInt("Prayed") == 0){
			 level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/gongage.png");
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

		if(params.GetInt("Open") == 1){
			int player_id = GetPlayerID();
			MovementObject@ player_mo = ReadCharacterID(player_id);
			if(params.GetInt("Prayed") == 0){
				Object @obj = ReadObjectFromID(player_id);
				ScriptParams@ paramzz = obj.GetScriptParams();
				if(paramzz.GetInt("Buddy") <= 0){
					level.SendMessage("displaytext \""+"A fellow Runner that was nearby answered your call for help!!");
					PlaySound("Data/Sounds/Gong.wav", player_mo.position);
					paramzz.SetInt("Buddy", 1);
					string enemyPath = "Data/Characters/Undergrowth/runnerBuddy.xml";
    				int enemyID = CreateObject(enemyPath);
    				vec3 enemy_pos;
    				enemy_pos = vec3(player_mo.position.x-3.0, player_mo.position.y, player_mo.position.z-3.0);
    				Object@ charObj = ReadObjectFromID(enemyID);
					charObj.SetTranslation(enemy_pos);
					charObj.QueueScriptMessage("escort_me "+player_id); 
					obj.UpdateScriptParams();
					params.SetInt("Prayed", 1);
				}else{
					PlaySound("Data/Sounds/meh.wav", player_mo.position);
					level.SendMessage("displaytext \""+"You already have an ally.");
				}
			}else{
				PlaySound("Data/Sounds/meh.wav", player_mo.position);
				level.SendMessage("displaytext \""+"You already used that gong.");
			}
		}
	}
}
