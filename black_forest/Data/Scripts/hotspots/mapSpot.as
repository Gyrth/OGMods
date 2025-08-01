#include "undergrowth_includes.as"
void Init() {
}



void SetParameters() {
params.AddInt("read", 0);
params.AddInt("mapOpen", 0);	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
    	 if(mo.controlled){
        	params.SetInt("mapOpen", 1);
        	OnEnter(mo);
		 	
		}
    } else if(event == "exit"){
    	 if(mo.controlled){
    	 	params.SetInt("mapOpen", 0);
        	OnExit(mo);
		}
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		  if(params.GetInt("read") == 0){
			 level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/mapage.png");	
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
		if( params.GetInt("mapOpen") == 1){
			if(params.GetInt("read") == 0){
				Object @obj = ReadObjectFromID(GetPlayerID());
				ScriptParams@ paramzz = obj.GetScriptParams();
				MovementObject@ mo = ReadCharacterID(GetPlayerID());
			 	paramzz.SetInt("map", (paramzz.GetInt("map")+((rand() % 5)+1)));
                PlaySound("Data/Sounds/mapPicked.wav", mo.position);
                level.SendMessage("clearhud");
                level.SendMessage("uicue");
                level.SendMessage("displayhud /Data/UI/Icons/mapHUD.png");
                params.SetInt("read", 1);
			}
		}
	}
}
