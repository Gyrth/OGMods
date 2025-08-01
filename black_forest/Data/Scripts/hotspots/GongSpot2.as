#include "undergrowth_spawns.as"

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
			 level.SendMessage("displayhud /Data/UI/Icons/gongSpot.png");
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
				level.SendMessage("displaytext \""+"You rang the enemy's gong!!");
				PlaySound("Data/Sounds/Gong.wav", player_mo.position);
				SendInEnemyChar();
			}else{
				PlaySound("Data/Sounds/meh.wav", player_mo.position);
				level.SendMessage("displaytext \""+"You already used that gong.");
			}
		}
	}
}
