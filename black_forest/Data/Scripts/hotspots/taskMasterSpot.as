void Init() {
	
 
   
}


bool diplomatAround(){
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        Object @obj = ReadObjectFromID(char.GetID());
		ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
        	if(char.GetIntVar("knocked_out") == _awake){
        		if(params.GetString("Name") == "diplomat"){
        			return true;
        		}
        	}
        }

    }
    return false;
}

int getDiplomatID(){
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        Object @obj = ReadObjectFromID(char.GetID());
		ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
        	if(params.GetString("Name") == "diplomat"){
        		return obj.GetID();
        	}
        }
    }
    return -1;
}

void trashRiggedObjects(){
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ paramss = obj.GetScriptParams();
        if(paramss.HasParam("Diplomat")){
        	// is this the diplomats items
            int diplo_int = paramss.GetInt("Diplomat");
            // are they ready to be trashed
            if(diplo_int == 1){
                DeleteObjectID(object_ids[i]);
            }
        }
    }
}

void SetParameters() {
params.AddInt("Quested", 0);	
params.AddInt("questGo", 0);
params.AddInt("questID", 0);
params.SetInt("questID", ((rand()%15)+1));
//params.SetInt("questID", 12);
params.AddString("Name", "taskMasterSpot");	
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
    	int player_id  = mo.GetID();
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		 params.SetInt("questGo", 77);
		//if the player rolls in with a quest
		if(paramzz.GetInt("questType") == 0){
		  	if(params.GetInt("Quested") == 0 ){
			  	level.SendMessage("clearhud");
			 	level.SendMessage("uicue");
			   	level.SendMessage("displayhud /Data/UI/Icons/taskmaster.png");
				//level.SendMessage("quest");
		  	}else{
				level.SendMessage("clearhud");
			 	level.SendMessage("uicue");
			   	level.SendMessage("displayhud /Data/UI/Icons/taskgtfo.png");
			}
		}else{
			if(paramzz.GetInt("questStatus") == 1){
				level.SendMessage("clearhud");
			 	level.SendMessage("uicue");
			   	level.SendMessage("displayhud /Data/UI/Icons/taskComplete.png");
			}else if(paramzz.GetInt("questStatus") == -1){
				level.SendMessage("clearhud");
			 	level.SendMessage("uicue");
			   	level.SendMessage("displayhud /Data/UI/Icons/taskFailed.png");
			}else{
				//level.SendMessage("displaytext \""+"player quest staus is "+paramzz.GetInt("questStatus")+"\"");
				level.SendMessage("clearhud");
			 	level.SendMessage("uicue");
			   	level.SendMessage("displayhud /Data/UI/Icons/tasked.png");
			}
		}
		level.SendMessage("displaytext \""+"Task Master"+"\"");
		obj.UpdateScriptParams();
    }

}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
	params.SetInt("questGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		
		//
		
	//
		if(params.GetInt("questGo") == 77 && params.GetString("Name") == "taskMasterSpot"){
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
			if(paramzz.GetInt("questType") == 0){
		  		if(params.GetInt("Quested") == 0 ){
					// gives quest
					level.SendMessage("quest");
					params.SetInt("Quested", 1);
		  		}else{
					//level.SendMessage("displaytext \""+"player has no quest so give quest "+""+"\"");
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("clearhud");
			 		level.SendMessage("uicue");
			   		level.SendMessage("displayhud /Data/UI/Icons/taskgtfo.png");
				}
			}else{
				if(params.GetInt("Quested") == 0 ){
				 	if(paramzz.GetInt("questStatus") == 1){
						level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
						level.SendMessage("questWin");
						level.SendMessage("questLoot");
						PlaySound("Data/Sounds/questWinSound.wav", mo.position);
						paramzz.SetInt("questType", 0);
						paramzz.SetInt("questStatus", 0);
						paramzz.SetFloat("Forts", paramzz.GetFloat("Forts")+0.1f);
						paramzz.SetFloat("trinketChances", paramzz.GetFloat("trinketChances")+0.1f);
						//params.GetFloat("trinketChances")
						//level.SendMessage("displaytext \""+"debug: Chances to find a trinket is now "+paramzz.GetFloat("Forts")+"%");
						obj.UpdateScriptParams();
						level.SendMessage("displayhud /Data/UI/Icons/questWin.png");
					}else if(paramzz.GetInt("questStatus") == -1){
						level.SendMessage("displaytext \""+"Quest failed. You brought shame to the Runners and your clan."+""+"\"");
						paramzz.SetInt("questType", 0);
						paramzz.SetInt("questStatus", 0);
						PlaySound("Data/Sounds/nay.wav", mo.position);
						obj.UpdateScriptParams();
						level.SendMessage("displayhud /Data/UI/Icons/questFail.png");
					}else if(paramzz.GetInt("questType") == 12){
						//quest status is at 1 and the quest type is 12 (escort)
						if(diplomatAround()){
							level.SendMessage("clearhud");
			 				level.SendMessage("uicue");
							level.SendMessage("questWin");
							level.SendMessage("questLoot");
							PlaySound("Data/Sounds/questWinSound.wav", mo.position);
							paramzz.SetInt("questType", 0);
							paramzz.SetInt("questStatus", 0);
							paramzz.SetFloat("Forts", paramzz.GetFloat("Forts")+0.1f);
							paramzz.SetFloat("trinketChances", paramzz.GetFloat("trinketChances")+0.1f);
                    		level.SendMessage("displayhud /Data/UI/Icons/quest12completed.png");
                    		if(getDiplomatID() != -1){
                    			//set the position of the diplomat way up because i do nmot know how to delete rigged objects yet
                    			Object@ diploObj = ReadObjectFromID(getDiplomatID());
                    			vec3 enemy_pos;
    							enemy_pos = vec3(mo.position.x, mo.position.y+20.0, mo.position.z);
								diploObj.SetTranslation(enemy_pos);
								trashRiggedObjects();
                    			QueueDeleteObjectID(getDiplomatID());
                    		}
                    		obj.UpdateScriptParams();
						}
					}
				}else{
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("clearhud");
			 		level.SendMessage("uicue");
			   		level.SendMessage("displayhud /Data/UI/Icons/taskgtfo.png");
				}
			}
			obj.UpdateScriptParams();
		}
	}
}

