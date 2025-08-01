#include "undergrowth_includes.as"

void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("gateGo", 0);
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
		params.SetInt("gateGo", 1);
		if(paramzz.GetInt("relicDistance") > 0 ){
			if(params.GetInt("gateGo") == 1){
				if(params.GetInt("tracked") == 0){
					params.SetInt("tracked", 1);
					PlaySound("Data/Sounds/gateTravel.wav", mo.position);
					paramzz.setInt("relicDistance", paramzz.GetInt("relicDistance")-1);
					if(paramzz.GetInt("relicDistance") == 0){
						level.SendMessage("displaytext \""+"You arrived to the lands where the relic has been hidden. Be vigilant, if you are taken out in combat the item will not reveal itself to you.");
					}else{
						level.SendMessage("displaytext \""+"You are getting closer to the relic!! Get Through "+paramzz.GetInt("relicDistance")+" more gates without falling in combat. Only heroes can be drawn to such power.");
					}
				}
			}
		}
    }
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("gateGo", 0);
	}
}

void Update(){
	
}

void CheckKeyPresses(){
	

}

