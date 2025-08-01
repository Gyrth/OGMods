#include "undergrowth_includes.as"
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
			 level.SendMessage("displayhud /Data/UI/Icons/magicWaterProp.png");
			
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
		if( params.GetInt("Open") == 1){
			if(params.GetInt("Prayed") == 0){
				Object @obj = ReadObjectFromID(GetPlayerID());
				ScriptParams@ paramxx = obj.GetScriptParams();
				MovementObject@ mo = ReadCharacterID(GetPlayerID());
				PlaySound("Data/Sounds/healing.wav", mo.position);
				mo.ReceiveMessage("healer_touch");
				paramxx.SetInt("Poison", 0);
				paramxx.SetInt("Sick", 0);
				paramxx.SetInt("water", 100);
				createHealSparks();
				params.SetInt("Prayed", 1);
				obj.UpdateScriptParams();
			}
		}	
	}
}
