// start of the belt system------------------------------------------------------------------------------------------------------------
void assBelt(){
	//--this is just to find the player--
	int player_id  = GetPlayerID();
	//-- player objects pre loaded --
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	MovementObject@ moo = ReadCharacterID(player_id);
	// check for ninjitsu belts 
	if(params.GetInt("Assassination") > 0 && params.GetInt("NinjitsuBelt") < 1){
		params.SetInt("NinjitsuBelt", 1);
		//params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin1.png");
	//}else if(params.GetInt("Assassination") > 6 && params.GetInt("NinjitsuBelt") < 2){
	}else if(params.GetInt("Assassination") > 6 && params.GetInt("NinjitsuBelt") < 2){
		params.SetInt("NinjitsuBelt", 2);
		//params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	//}else if(params.GetInt("Assassination") > 14 && params.GetInt("NinjitsuBelt") < 3){
	}else if(params.GetInt("Assassination") > 16 && params.GetInt("NinjitsuBelt") < 3){
		params.SetInt("NinjitsuBelt", 3);
		//params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	//}else if(params.GetInt("Assassination") > 32 && params.GetInt("NinjitsuBelt") < 4){
	}else if(params.GetInt("Assassination") > 32 && params.GetInt("NinjitsuBelt") < 4){
		params.SetInt("NinjitsuBelt", 4);
		//params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	//}else if(params.GetInt("Assassination") > 64 && params.GetInt("NinjitsuBelt") < 5){
	}else if(params.GetInt("Assassination") > 64 && params.GetInt("NinjitsuBelt") < 5){
		params.SetInt("NinjitsuBelt", 5);
		params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	//}else if(params.GetInt("Assassination") > 128 && params.GetInt("NinjitsuBelt") < 6){
	}else if(params.GetInt("Assassination") > 128 && params.GetInt("NinjitsuBelt") < 6){
		params.SetInt("NinjitsuBelt", 6);
		//params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	//}else if(params.GetInt("Assassination") > 250 && params.GetInt("NinjitsuBelt") < 7){
	}else if(params.GetInt("Assassination") > 256 && params.GetInt("NinjitsuBelt") < 7){
		params.SetInt("NinjitsuBelt", 7);
		params.SetInt("NinjitsuUpgrade", params.GetInt("NinjitsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/nin2.png");
	}
	obj.UpdateScriptParams();
}

void kungBelt(){
	//--this is just to find the player--
	int player_id  = GetPlayerID();
	//-- player objects pre loaded --
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	MovementObject@ moo = ReadCharacterID(player_id);
	// check for kung belts 
	if(params.GetInt("handKills") > 0 && params.GetInt("KungfuBelt") < 1){
		params.SetInt("KungfuBelt", 1);
		//params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung1.png");
	}else if(params.GetInt("handKills") > 6 && params.GetInt("KungfuBelt") < 2){
		params.SetInt("KungfuBelt", 2);
		//params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung2.png");
	}else if(params.GetInt("handKills") > 16 && params.GetInt("KungfuBelt") < 3){
		params.SetInt("KungfuBelt", 3);
		//params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung3.png");
	}else if(params.GetInt("handKills") > 32 && params.GetInt("KungfuBelt") < 4){
		params.SetInt("KungfuBelt", 4);
		//params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung4.png");
	}else if(params.GetInt("handKills") > 64 && params.GetInt("KungfuBelt") < 5){
		params.SetInt("KungfuBelt", 5);
		params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung5.png");
	}else if(params.GetInt("handKills") > 128 && params.GetInt("KungfuBelt") < 6){
		params.SetInt("KungfuBelt", 6);
		params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung6.png");
	}else if(params.GetInt("handKills") > 256 && params.GetInt("KungfuBelt") < 7){
		params.SetInt("KungfuBelt", 7);
		params.SetInt("KungfuUpgrade", params.GetInt("KungfuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kung7.png");
	}
}

void kenjuBelt(){
	//--this is just to find the player--
	int player_id  = GetPlayerID();
	//-- player objects pre loaded --
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	MovementObject@ moo = ReadCharacterID(player_id);
	// check for kung belts 
	
	if(params.GetInt("weaponKills") > 0 && params.GetInt("KenjutsuBelt") < 1){
		params.SetInt("KenjutsuBelt", 1);
		//params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju1.png");
	}else if(params.GetInt("weaponKills") > 16 && params.GetInt("KenjutsuBelt") < 2){
		params.SetInt("KenjutsuBelt", 2);
		//params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju2.png");
	}else if(params.GetInt("weaponKills") > 32 && params.GetInt("KenjutsuBelt") < 3){
		params.SetInt("KenjutsuBelt", 3);
		//params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju3.png");
	}else if(params.GetInt("weaponKills") > 64 && params.GetInt("KenjutsuBelt") < 4){
		params.SetInt("KenjutsuBelt", 4);
		//params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju4.png");
	}else if(params.GetInt("weaponKills") > 128 && params.GetInt("KenjutsuBelt") < 5){
		params.SetInt("KenjutsuBelt", 5);
		params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju5.png");
	}else if(params.GetInt("weaponKills") > 256 && params.GetInt("KenjutsuBelt") < 6){
		params.SetInt("KenjutsuBelt", 6);
		params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju6.png");
	}else if(params.GetInt("weaponKills") > 512 && params.GetInt("KenjutsuBelt") < 7){
		params.SetInt("KenjutsuBelt", 7);
		params.SetInt("KenjutsuUpgrade", params.GetInt("KenjutsuUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/kenju7.png");
	}
}

void shuriBelt(){
	//--this is just to find the player--
	int player_id  = GetPlayerID();
	//-- player objects pre loaded --
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	MovementObject@ moo = ReadCharacterID(player_id);
	// check for kung belts 
	
	if(params.GetInt("throwKills") > 0 && params.GetInt("ShurikenBelt") < 1){
		params.SetInt("ShurikenBelt", 1);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri1.png");
	}else if(params.GetInt("throwKills") > 6 && params.GetInt("ShurikenBelt") < 2){
		params.SetInt("ShurikenBelt", 2);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri2.png");
	}else if(params.GetInt("throwKills") > 16 && params.GetInt("ShurikenBelt") < 3){
		params.SetInt("ShurikenBelt", 3);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri3.png");
	}else if(params.GetInt("throwKills") > 32 && params.GetInt("ShurikenBelt") < 4){
		params.SetInt("ShurikenBelt", 4);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri4.png");
	}else if(params.GetInt("throwKills") > 64 && params.GetInt("ShurikenBelt") < 5){
		params.SetInt("ShurikenBelt", 5);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri5.png");
	}else if(params.GetInt("throwKills") > 128 && params.GetInt("ShurikenBelt") < 6){
		params.SetInt("ShurikenBelt", 6);
		
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri6.png");
	}else if(params.GetInt("throwKills") > 256 && params.GetInt("ShurikenBelt") < 7){
		params.SetInt("ShurikenBelt", 7);
		params.SetInt("ShurikenUpgrade", params.GetInt("ShurikenUpgrade")+1);
		//play sound
		PlaySound("Data/Sounds/beltUp.wav", moo.position);
		//
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/shuri7.png");
	}
}