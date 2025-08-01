void Init() {
	
 
   
}



void SetParameters() {

params.AddInt("foodGo", 0);
params.AddInt("foodPrice", 0);
params.SetInt("foodPrice", (rand()%3)+1);
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
		params.SetInt("foodGo", 1);
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/foodPrice"+params.GetInt("foodPrice")+".png");
		level.SendMessage("displaytext \""+"Food Merchant"+"\"");
    }

}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
	params.SetInt("foodGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		//find the player
		if(params.GetInt("foodGo") == 1){
			int player_id  = -1;
    		int num = GetNumCharacters();
    		for(int i=0; i<num; ++i){
        		MovementObject@ char = ReadCharacter(i);
        		if(char.controlled){
            		player_id = char.GetID();
					break;
        		}
    		}
			//ReadCharacterID(player_ids[0])
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ paramzz = obj.GetScriptParams();
			MovementObject@ mo = ReadCharacterID(player_id);
			if(paramzz.GetInt("Gold") >= params.GetInt("foodPrice")){
				if(paramzz.GetString("trinketType") == "the Guild" && (rand()% 100 < paramzz.GetInt("trinketPower")*5) ){
					level.SendMessage("displaytext \""+"The merchant recognize your trinket and feeds you for free!!!");
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
				}else{
					paramzz.SetInt("Gold", paramzz.GetInt("Gold")-params.GetInt("foodPrice"));
					PlaySound("Data/Sounds/singleCoin.wav", mo.position);
				}
		  		paramzz.SetInt("Food", 100);
				PlaySound("Data/Sounds/eating.wav", mo.position);
			}else{
				level.SendMessage("displaytext \""+"You don't have enough gold ("+ paramzz.GetInt("Gold")+") to buy this food ("+params.GetInt("foodPrice")+")"+"\"");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
			obj.UpdateScriptParams();
		}
	}
}

