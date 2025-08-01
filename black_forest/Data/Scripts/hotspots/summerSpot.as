#include "undergrowth_includes.as"


const float frequency = 2.0f;
float delay = frequency;

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
			 level.SendMessage("displayhud /Data/UI/Icons/summerStone.png");
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
					paramzz.SetInt("Winter", 1);
					level.SendMessage("displaytext \""+"You have banished the cold weather!!!");
					PlaySound("Data/Sounds/bigSpell.wav", player_mo.position);
					level.SendMessage("item_hit "+player_id);
					params.SetInt("Prayed", 1);
					createBuffSparks();
			}else{
				PlaySound("Data/Sounds/meh.wav", player_mo.position);
				level.SendMessage("displaytext \""+"You already touched the stone.");
			}
		}
	}
}
