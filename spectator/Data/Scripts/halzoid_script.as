void Init() {
}
 
string displayText;
string changeToChar;
string changeTeam;
string newTeamName;
string recoverHealth;
string recoverAll;
float changeRunSpeedAmt;
float changeDmgResistanceAmt;
float changeAttackSpeedAmt;
float changeAttackDmgAmt;
 
void SetParameters() {
       
	params.AddString("Display Text","false");
    displayText = params.GetString("Display Text");
 
	params.AddString("Change to Character(Path)","false");
    changeToChar = params.GetString("Change to Character(Path)");
   
	params.AddString("Change Team","false");
	changeTeam = params.GetString("Change Team");
	
	params.AddString("New Team Name","guard");
	newTeamName = params.GetString("New Team Name");
 
	params.AddString("Recover Health","false");
    recoverHealth = params.GetString("Recover Health");
 
	params.AddString("Recover All","false");

	
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
	 
		//Display Text
		if (displayText != "false")
		    level.Execute("ReceiveMessage2(\"displaytext\",\""+displayText+"\")");
		 
		//Change to character
		if (changeToChar != "false")
		    mo.Execute("SwitchCharacter(\""+changeToChar+"\");");
		 
		//Change team
		if (changeTeam != "false"){
			Object@ mo_obj = ReadObjectFromID(mo.GetID());
			ScriptParams@ mo_params = mo_obj.GetScriptParams();
			mo_params.SetString("Teams", newTeamName);
		}
		   
		//Recover Health
		if (recoverHealth == "true")
		    mo.Execute("RecoverHealth();");
		 
		//Recover All
		if (recoverAll == "true")
		    mo.Execute("Recover();");
		 
		//Change Player Run Speed
		if (changeRunSpeedAmt > 0.0f){
		    mo.Execute("run_speed = 8*"+changeRunSpeedAmt+";");
		    mo.Execute("true_max_speed = 12*"+changeRunSpeedAmt+";");
		}
		 
		//Change Damage Resistance
		if (changeDmgResistanceAmt != 0.0f){
		    float damageResistance = 1.0f / changeDmgResistanceAmt;
		    mo.Execute("p_damage_multiplier = "+damageResistance+";");
		}
		 
		//Change Attack Speed
		if (changeAttackSpeedAmt != 0.0f){
		    mo.Execute("p_attack_speed_mult = min(2.0f, max(0.1f, "+changeAttackDmgAmt+"));");
		}
		 
		//Change Attack Damage
		if (changeAttackDmgAmt != 0.0f){
		    mo.Execute("p_attack_damage_mult = max(0.0f, "+changeAttackDmgAmt+");");
		}
 
	}
	else{
	//NPCs
	 
	}
}
 
void OnExit(MovementObject @mo) {
    if(mo.controlled){
        level.Execute("ReceiveMessage(\"cleartext\")");
    }
}
