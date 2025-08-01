void Init() {
	
 
   
}



void SetParameters() {
params.AddInt("Trained", 0);	
params.AddInt("trainGo", 0);
params.AddInt("trainType", 0);
params.SetInt("trainType", (rand() % 4));
params.AddInt("Skill", (rand() % 4)+1);
params.AddString("Name", "runnerMasterSpot");

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
		 params.SetInt("trainGo", 1);
		 if(params.GetInt("Trained") == 0 ){
			//if the player rolls in with a quest
			if(params.GetInt("trainType") == 0){
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/KungfuMaster.png");
				if(paramzz.GetInt("KungfuBelt")< 4){
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("displaytext \""+"Come back when you have at least a blue belt in Kung Fu."+"\"");
				}
			}else if (params.GetInt("trainType") == 1){
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/KenjutsuMaster.png");
				if(paramzz.GetInt("KenjutsuBelt")< 4){
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("displaytext \""+"Come back when you have at least a blue belt in Kenjutsu."+"\"");
				}
			}else if (params.GetInt("trainType") == 2){
				level.SendMessage("clearhud");
				if(paramzz.GetInt("ShurikenBelt")< 4){
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("displaytext \""+"Come back when you have at least a blue belt in Shuriken Ju."+"\"");
				}
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/ShurikenMaster.png");
			}else if (params.GetInt("trainType") == 3){
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/NinjitsuMaster.png");
				if(paramzz.GetInt("ShurikenBelt")< 4){
					PlaySound("Data/Sounds/nope.wav", mo.position);
					level.SendMessage("displaytext \""+"Come back when you have at least a blue belt in Ninjitsu."+"\"");
				}
			}
			level.SendMessage("displaytext \""+"Task Master"+"\"");
		}else{
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("displayhud /Data/UI/Icons/noMaster.png");
			PlaySound("Data/Sounds/nope.wav", mo.position);
		}
    }
	obj.UpdateScriptParams();
}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
	params.SetInt("trainGo", 0);
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "x")){
		if(params.GetInt("trainGo") == 1 && params.GetString("Name") == "runnerMasterSpot"){
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
			if(params.GetInt("Trained") == 0 ){
				if(params.GetInt("trainType") == 0){
		  			//kung fu
					if(paramzz.GetInt("KungfuUpgrade") >= 1){
			  			level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/trainKung"+paramzz.GetInt("KungfuMastery")+".png");
						paramzz.SetInt("KungfuMastery", paramzz.GetInt("KungfuMastery")+1);
						paramzz.SetInt("KungfuUpgrade", paramzz.GetInt("KungfuUpgrade")-1); 
						PlaySound("Data/Sounds/researchWin.wav", mo.position);
						params.SetInt("Trained", 1);
					}else{
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/noBelts.png");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}
				}else if(params.GetInt("trainType") == 1){
					//kenjutsu
					if(paramzz.GetInt("KenjutsuUpgrade") >= 1){
			  			level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/trainKenju"+paramzz.GetInt("KenjutsuMastery")+".png");
						paramzz.SetInt("KenjutsuMastery", paramzz.GetInt("KenjutsuMastery")+1);
						paramzz.SetInt("KenjutsuUpgrade", paramzz.GetInt("KenjutsuUpgrade")-1); 
						PlaySound("Data/Sounds/researchWin.wav", mo.position);
						params.SetInt("Trained", 1);
					}else{
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/noBelts.png");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}			
				}else if(params.GetInt("trainType") == 2){
					//shuriken ju
					if(paramzz.GetInt("ShurikenUpgrade") >= 1){
			  			level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/trainShuri"+paramzz.GetInt("ShurikenMastery")+".png");
						paramzz.SetInt("ShurikenMastery", paramzz.GetInt("ShurikenMastery")+1);
						paramzz.SetInt("ShurikenUpgrade", paramzz.GetInt("ShurikenUpgrade")-1); 
						PlaySound("Data/Sounds/researchWin.wav", mo.position);
						params.SetInt("Trained", 1);
					}else{
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/noBelts.png");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}				
				}else if(params.GetInt("trainType") == 3){
					//Ninjutsu
					if(paramzz.GetInt("NinjitsuUpgrade") >= 1){
			  			level.SendMessage("clearhud");
			 			level.SendMessage("uicue");
			   			level.SendMessage("displayhud /Data/UI/Icons/trainNinja"+paramzz.GetInt("NinjitsuMastery")+".png");
						paramzz.SetInt("NinjitsuMastery", paramzz.GetInt("NinjitsuMastery")+1);
						paramzz.SetInt("NinjitsuUpgrade", paramzz.GetInt("NinjitsuUpgrade")-1); 
						PlaySound("Data/Sounds/researchWin.wav", mo.position);
						params.SetInt("Trained", 1);
					}else{
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/noBelts.png");
						PlaySound("Data/Sounds/nope.wav", mo.position);
					}
				}
			}
			obj.UpdateScriptParams();
		}
	}
}

