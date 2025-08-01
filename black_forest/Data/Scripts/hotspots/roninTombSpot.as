#include "undergrowth_includes.as"
void Init() {
	
 
   
}



void SetParameters() {
params.AddInt("Eaten", 0);	
params.AddInt("tombGo", 0);

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
		params.SetInt("tombGo", 1);
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/roninTomb.png");
    }

}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
	params.SetInt("tombGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		//find the player
		if(params.GetInt("tombGo") == 1){
			Object @obj = ReadObjectFromID(GetPlayerID());
			ScriptParams@ paramzz = obj.GetScriptParams();
			MovementObject@ mo = ReadCharacterID(GetPlayerID());
			if(params.GetInt("Eaten") == 0){	
				params.SetInt("Eaten", 1);
				//ReadCharacterID(player_ids[0])
				PlaySound("Data/Sounds/cueSound.wav", mo.position);
				paramzz.SetInt("relicDistance", (rand()%3)+3);
				obj.UpdateScriptParams();
				level.SendMessage("displaytext \""+"You have learned the location a relic "+paramzz.GetInt("relicDistance")+" leagues away. Travel across dark gates without dying to get there.");
			}else{
				PlaySound("Data/Sounds/meh.wav", mo.position);
				level.SendMessage("displaytext \""+"You already have read all the lore on this monument.");
			}
		}
	}
}

