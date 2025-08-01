void Init() {
 
}



void SetParameters() {
	params.AddInt("Researched", 0);	
	params.AddInt("ResearchGo", 0);	
	params.AddInt("researchID", 0);
	params.SetInt("researchAmount", 0);
	params.SetInt("researchID", rand()%5);
	int foo = 0;
	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	int player_id  = mo.GetID();
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ paramzz = obj.GetScriptParams();
	
    if(mo.controlled){
		 params.SetInt("ResearchGo", 1);
			//if the player rolls in with a quest
			if(paramzz.GetInt("map") > 0){
					level.SendMessage("displayhud /Data/UI/Icons/research_map.png");
					PlaySound("Data/Sounds/study.wav", mo.position);
					level.SendMessage("displaytext \""+"Map Table: You currently have "+paramzz.GetInt("map") +"% to find a secret locations but uses all your map knowledge."+"\"");
			}else{
				level.SendMessage("displaytext \""+"Your current map knowledge is at 0%. Find more maps across the world in order to reveal secret locations.");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
    }
	obj.UpdateScriptParams();
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("ResearchGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		int player_id  = -1;
		int dice = rand()%100;
    	int num = GetNumCharacters();
    	for(int i=0; i<num; ++i){
        	MovementObject@ char = ReadCharacter(i);
        	if(char.controlled){
            	player_id = char.GetID();
				break;
        	}
    	}
		//
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		MovementObject@ mo = ReadCharacterID(player_id);
		//
		if(params.GetInt("ResearchGo") == 1 ){
			if(paramzz.GetInt("map") > 0){
				if(dice <= paramzz.GetInt("map")){
					int gtg = 0;
					int strikes = 0;
					while(gtg == 0 && strikes < 10 ){
						if(params.GetInt("researchID") == 0 && paramzz.GetInt("special1") == 0){
							gtg = 1;
							paramzz.SetInt("special1", 1);
							level.SendMessage("displaytext \""+"You have discovered the Bersimon library!!");
						}else if(params.GetInt("researchID") == 1 && paramzz.GetInt("special2") == 0){
							gtg = 1;
							paramzz.SetInt("special2", 1);
							level.SendMessage("displaytext \""+"You have discovered the Gong of the Arisen!!");
						}else if(params.GetInt("researchID") == 2 && paramzz.GetInt("special3") == 0){
							gtg = 1;
							paramzz.SetInt("special3", 1);
							level.SendMessage("displaytext \""+"You have discovered the Summer Stone!!");
						}else if(params.GetInt("researchID") == 3 && paramzz.GetInt("special4") == 0){
							gtg = 1;
							paramzz.SetInt("special4", 1);
							level.SendMessage("displaytext \""+"You have discovered the Sword Tree!!");
						}else if(params.GetInt("researchID") == 4 && paramzz.GetInt("special5") == 0){
							gtg = 1;
							paramzz.SetInt("special5", 1);
							level.SendMessage("displaytext \""+"You have discover the Lake of the Lance!!");
						}
						strikes ++;
					}
					//if we havent found a spot yet we will go thru them all and find an empty one
					if(gtg == 0){
						if(paramzz.GetInt("special1") == 0){
							gtg = 1;
							paramzz.SetInt("special1", 1);
							level.SendMessage("displaytext \""+"You have discovered the Bersimon library!!");
						}else if(paramzz.GetInt("special2") == 0){
							gtg = 1;
							paramzz.SetInt("special2", 1);
							level.SendMessage("displaytext \""+"You have discovered the Gong of the Arisen!!");
						}else if(paramzz.GetInt("special3") == 0){
							gtg = 1;
							paramzz.SetInt("special3", 1);
							level.SendMessage("displaytext \""+"You have discovered the Summer Stone!!");
						}else if(paramzz.GetInt("special4") == 0){
							gtg = 1;
							paramzz.SetInt("special4", 1);
							level.SendMessage("displaytext \""+"You have discovered the Sword Tree!!");
						}else if(paramzz.GetInt("special5") == 0){
							gtg = 1;
							paramzz.SetInt("special5", 1);
							level.SendMessage("displaytext \""+"You have discover the Lake of the Lance!!");
						}
					}
					//after all this if we have not found a spot we give up in shame
					if(gtg == 0){
						level.SendMessage("displaytext \""+"You currently have discovered all the locations!!");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}else{
						PlaySound("Data/Sounds/mapResearchYay.wav", mo.position);
						paramzz.SetInt("map", 0);
					}
				}else{
					level.SendMessage("displaytext \""+"You did not found any new locations based on the map information you had. (dice roll of "+dice+")");
					PlaySound("Data/Sounds/meh.wav", mo.position);
					paramzz.SetInt("map", 0);
				}
			}else{
				level.SendMessage("displaytext \""+"Your map knowledge is currently at 0%, collect more maps and try your luck again.");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
			
		}
		obj.UpdateScriptParams();
	}
	
}


