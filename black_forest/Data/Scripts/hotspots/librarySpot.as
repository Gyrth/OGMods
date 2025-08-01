void Init() {
 
}



void SetParameters() {
	params.AddInt("Researched", 0);	
	params.AddInt("ResearchGo", 0);	
	params.AddInt("researchID", 0);
	params.SetInt("researchAmount", 0);
	params.SetInt("researchID", rand()%4);
	int foo = 0;
	while(foo < 25){
		params.SetInt("researchAmount", params.GetInt("researchAmount")+1);
		foo = rand()%100;
	}
	
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
			if(paramzz.GetInt("xp") > 0){
					if(params.GetInt("researchID") == 0){
						level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/research_scavenge.png");
					}else if(params.GetInt("researchID") == 1){
						level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/research_steal.png");
					}else if(params.GetInt("researchID") == 2){
						level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/research_tracking.png");
					}else if(params.GetInt("researchID") == 3){
						level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/research_praying.png");
					}
					PlaySound("Data/Sounds/study.wav", mo.position);
					level.SendMessage("displaytext \""+"Bersimon's Library: You can study as much as you have scrolls for a +"+params.GetInt("researchAmount")+"% to your skill."+"\"");
			}else{
				level.SendMessage("displaytext \""+"Find ancient scrolls of the lost rabbit clans in order to perfect your skills.");
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
			if(params.GetInt("Researched")==0){
			if(paramzz.GetInt("xp") > 0){
				params.SetInt("Researched", 1);
					if(params.GetInt("researchID") == 0){
						paramzz.SetInt("Search", paramzz.GetInt("Search")+params.GetInt("researchAmount"));
						paramzz.SetInt("xp",  paramzz.GetInt("xp")-1);
						obj.UpdateScriptParams();
						level.SendMessage("displaytext \""+" Your Scavenge skill is now at "+paramzz.GetInt("Search"));
					}else if(params.GetInt("researchID") == 1){
						paramzz.SetInt("Steal", paramzz.GetInt("Steal")+params.GetInt("researchAmount"));
						paramzz.SetInt("xp",  paramzz.GetInt("xp")-1);
						obj.UpdateScriptParams();
						level.SendMessage("displaytext \""+" Your Robbery skill is now at "+paramzz.GetInt("Steal"));
					}else if(params.GetInt("researchID") == 2){
						paramzz.SetInt("Tracking", paramzz.GetInt("Tracking")+params.GetInt("researchAmount"));
						paramzz.SetInt("xp", paramzz.GetInt("xp")-1);
						obj.UpdateScriptParams();
						level.SendMessage("displaytext \""+" Your Bushcraft skill is now at "+paramzz.GetInt("Tracking"));
					}else if(params.GetInt("researchID") == 3){
						paramzz.SetInt("Faith", paramzz.GetInt("Faith")+params.GetInt("researchAmount"));
						paramzz.SetInt("xp",  paramzz.GetInt("xp")-1);
						obj.UpdateScriptParams();
						level.SendMessage("displaytext \""+" Your Meditation skill is now at "+paramzz.GetInt("Faith"));
					}
					PlaySound("Data/Sounds/researchWin.wav", mo.position);
			}
			}else{
				level.SendMessage("displaytext \""+"There is no more knowledge to be gained from that library.");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
			
		}
	}
}


