void Init() {
}

string trinketPowerTell (int foo){
	if(foo == 0){
		return "Lead";
	}else if(foo == 1){
		return "Bronze";
	}else if(foo == 2){
		return "Iron";
	}else if(foo == 3){
		return "Steel";
	}else if(foo == 4){
		return "Silver";
	}else if(foo == 5){
		return "Gold";
	}else if(foo == 6){
		return "Platinum";
	}else if(foo == 7){
		return "Emerald";
	}else if(foo == 8){
		return "Diamond";
	}else if(foo == 9){
		return "Unique";
	}else if(foo == 10){
		return "Epic";
	}else{
		return "poop";
	}
}

void SetParameters() {
	 params.AddInt("Open", 0);
	params.AddInt("Eaten", 0);	
	params.AddInt("Taken", 0);
	params.AddString("trinketType", "");
	params.AddInt("trinketPower", 0);	
	//params.AddInt("trinketIcon", 0);	
	int dice = rand()% 10;
	if(dice == 0){
		// protects from cold
		 params.SetString("trinketType", "Glacier");
	}else if(dice == 0){
		//adds to skills
		params.SetString("trinketType", "Knowledge");
	}else if(dice == 1){
		//protects from poison
		params.SetString("trinketType", "Venom");
	}else if(dice == 2){
		//protects from disease
		params.SetString("trinketType", "Purity");
	}else if(dice == 3){
		//protects from hunger (hunger comes in at x% slower)
		params.SetString("trinketType", "Fasting");
	}else if(dice == 4){
		//escape hunting faster
		params.SetString("trinketType", "Evasion");
	}else if(dice == 5){
		//protects from Wendigo
		params.SetString("trinketType", "Wendigo");
	}else if(dice == 6){
		//get x% chances to have mores scrolls when looting
		params.SetString("trinketType", "Wisdom");
	}else if(dice == 7){
		//x% of gettgin gold when looting
		params.SetString("trinketType", "Fortune");
	}else if(dice == 8){
		//get x% amount more food and water when looting
		params.SetString("trinketType", "Plenty");
	}else if(dice == 10){
		//get x% to have free stuff when dealing with merchants
		params.SetString("trinketType", "the Guild");
	}else if(dice == 9){
		//bless drops x% slower
		params.SetString("trinketType", "the Monk");
	}else{
		params.SetString("trinketType", "Garbonzo");
	}
	//determine the power of the trinket
	params.SetInt("trinketPower", 1);
	
	//determine player id
	int player_id  = -1;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
    	MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
        	player_id = char.GetID();
			break;
        }
    }
	if(player_id != -1){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		for(int i = 1; i <  (paramzz.GetFloat("Forts")*10); i++){
			if(rand()% 4 == 0){
				params.SetInt("trinketPower", params.GetInt("trinketPower")+1);
			}
		}
	}
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
		 params.SetInt("Open", 1);
        OnEnter(mo);
    } else if(event == "exit"){
		 params.SetInt("Open", 0);
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		if(params.GetInt("Taken") == 0 ){
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			//level.SendMessage("displayhud /Data/UI/Icons/mushroom.png");
			level.SendMessage("displaytext \""+"This shrine has a "+trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+". Press x to equip. "+"\"");
		}
    }
}

void OnExit(MovementObject @mo) {
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "x")){
		if(params.GetInt("Open") == 1){
		if(params.GetInt("Taken") == 0){
			int player_id  = -1;
    		int num = GetNumCharacters();
    		for(int i=0; i<num; ++i){
        		MovementObject@ char = ReadCharacter(i);
        		if(char.controlled){
            		player_id = char.GetID();
					break;
        		}
    		}
			MovementObject@ mo = ReadCharacterID(player_id);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ paramzz = obj.GetScriptParams();
			PlaySound("Data/Sounds/trinketEquip.wav", mo.position);
			level.SendMessage("displaytext \""+" You have acquired a new trinket."+(paramzz.GetFloat("Forts")*10));
			paramzz.SetString("trinketType", params.GetString("trinketType"));
			paramzz.SetInt("trinketPower", params.GetInt("trinketPower"));
			params.SetInt("Taken", 1);
			obj.UpdateScriptParams();	
		}
		}
	}
	
}
