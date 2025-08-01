#include "undergrowth_includes.as"
void Init() {
	
 
   
}



void SetParameters() {

params.AddInt("healGo", 0);
params.AddInt("healPrice", 0);
//
params.SetInt("healPrice", (rand()%3)+1);
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
		params.SetInt("healGo", 1);
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/healerPrice"+params.GetInt("healPrice")+".png");
		level.SendMessage("displaytext \""+"Healer"+"\"");
    }

}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
	params.SetInt("healGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	int noHeal = 0;

	if(GetInputPressed(0, "x")){
		//find the player
		if(params.GetInt("healGo") == 1){
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
			MovementObject@ mo = ReadCharacterID(player_id);
			//if actually needa a healer
			if(mo.GetFloatVar("blood_damage") > 0.0 || mo.GetFloatVar("blood_health") < 1.0f || 
			mo.GetFloatVar("block_health") < 1.0f || mo.GetFloatVar("temp_health") < 1.0f || 
			mo.GetFloatVar("permanent_health")< 1.0f || paramzz.GetInt("Poison") > 0 || paramzz.GetInt("Sick") > 0) {
				if(paramzz.GetInt("Gold") >= params.GetInt("healPrice")){
					if(paramzz.GetString("trinketType") == "the Guild" && (rand()% 100 < paramzz.GetInt("trinketPower")*5) ){
						level.SendMessage("displaytext \""+"The merchant recognize your trinket and heals you for free!!!");
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						paramzz.SetInt("Gold", paramzz.GetInt("Gold")-params.GetInt("healPrice"));
						PlaySound("Data/Sounds/singleCoin.wav", mo.position);
						PlaySound("Data/Sounds/singleCoin.wav", mo.position);
					}
					mo.Execute("Recover();");
					paramzz.SetInt("Poison", 0);
					paramzz.SetInt("Sick", 0);
					PlaySound("Data/Sounds/healing.wav", mo.position);
					createHealSparks();
				}else{
					level.SendMessage("displaytext \""+"You don't have enough gold ("+ paramzz.GetInt("Gold")+") to pay the healer ("+params.GetInt("healPrice")+")"+"\"");
					PlaySound("Data/Sounds/nope.wav", mo.position);
				}
			}else{
				level.SendMessage("displaytext \""+"You don't require the services of a healer right now.");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
			obj.UpdateScriptParams();
		}
	}
}

