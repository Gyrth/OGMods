#include "undergrowth_includes.as"

void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("quest15Go", 0);
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
		params.SetInt("quest15Go", 1);
		if(paramzz.GetInt("questType") == 15 && paramzz.GetInt("questStatus") == 0){
			if(params.GetInt("quest15Go") == 1){
			if(params.GetInt("tracked") == 0){
				if(skillCheck("Tracking", 0)){
		  			paramzz.SetInt("questStatus", 1);
					PlaySound("Data/Sounds/quest2riff.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("questReset");
					level.SendMessage("displayhud /Data/UI/Icons/quest15completed.png");
					level.SendMessage("displaytext \""+"You have found the ring!! (Bushcraft skill success)");
				}else{
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displaytext \""+"The ring is not here. find another pond to search. (Bushcraft skill failed)");
				}
				params.SetInt("tracked", 1);
			}else{
				level.SendMessage("displaytext \""+"You have searched that pond already.");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
		}
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("quest15Go", 0);
	}
}

void Update(){
	
}

void CheckKeyPresses(){
	

}

