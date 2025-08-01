void ReadPersistentInfo() {
        int weapID;
        SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
        Object @obj = ReadObjectFromID(player_id);
        ScriptParams@ params = obj.GetScriptParams();
        MovementObject@ mo = ReadCharacterID(player_id);
        //
        string fortChances_str = saved_level.GetValue("fortChances");
        string knockedout_str = saved_level.GetValue("knockedOut");
        string newGuy = saved_level.GetValue("newGuy");
        string jailed = saved_level.GetValue("jailed");
        string dungeoned = saved_level.GetValue("dungeoned");
        //level.SendMessage("displaytext \""+"debug: player RESPAWNED, knockedout value in the save is "+ knockedout_str);
		  //patch
		if(fortChances_str == ""){
			daytimer = 1;
			fortChances = 1.0;
			rogueUI("cue1");
			//PlaySound("Data/Sounds/cueSound.wav", mo.position);
			//object_ids.length();
			fortChances = atof(fortChances_str);
			params.SetString("playerName", adjectives[(rand() % adjectives.length())] + " " + names[(rand() % names.length())]);
			params.SetInt("Food", 100);
			params.SetInt("Water", 100);
			params.SetInt("Fatigue", 0);
			params.SetInt("Faith", 25);
			params.SetInt("PowerUp", 0);
			params.SetFloat("Forts", 0.1f);
			params.SetInt("Sick", 0);
			params.SetInt("lvl", 1);
			params.SetInt("xp", 0);
			params.SetInt("Bless", 0);
			params.SetInt("Poison", 0);
			params.SetInt("Hunted", 0);
			params.SetInt("Gold", 0);
			params.SetInt("Scroll", 0);
			params.SetInt("questStatus", 0);
			params.SetInt("questType", 0);
			params.SetInt("questKills", 0);
            params.SetInt("noWinter", 60);
			//caravanStrike
			params.SetInt("caravanStrike", 0);
			params.SetInt("distance", 0);
			params.SetInt("huntFactor", 0);
			params.SetInt("huntLevel", 0);
            params.SetInt("roninKill", 0);
            params.SetInt("roninGrave", 0);
            params.SetInt("relicDistance", -1);
            params.SetInt("huntLevel", 0);
			params.SetInt("Winter", 0);
			params.SetInt("Freezing", 0);
			params.SetInt("Search", 25);
			params.SetInt("Read", 25);
			params.SetInt("Steal", 25);
			params.SetInt("Tracking", 25);
			params.SetInt("FireNear", 0);
			params.SetInt("powerUp", 0);
			params.SetInt("throwFlag", 0);
			params.SetInt("throwKills", 0);
			params.SetInt("ShurikenUpgrade", 0);
			params.SetInt("ShurikenBelt", 0);
			params.SetInt("handKills", 0);
			params.SetInt("KungfuUpgrade", 0);
			params.SetInt("KungfuBelt", 0);
			params.SetInt("weaponKills", 0);
			params.SetInt("KenjutsuUpgrade", 0);
			params.SetInt("KenjutsuBelt", 0);
			params.SetInt("Assassination", 0);
			params.SetInt("NinjitsuUpgrade", 0);
			params.SetInt("NinjitsuBelt", 0);
            params.SetInt("graveDistance", 0);
			params.SetInt("lockPick", 0);
			params.SetInt("hour", 0);
			params.SetInt("day", 0);
			params.SetInt("survived", 0);
            params.SetInt("map", 0);
            params.SetFloat("wanted", 0.0f);            
            params.SetInt("Buddy", 0);
            params.SetInt("special1", 0);
            params.SetInt("special2", 0);
            params.SetInt("special3", 0);
            params.SetInt("special4", 0);
            params.SetInt("special5", 0);
            params.SetInt("special6", 0);
            params.SetInt("special7", 0);
            params.SetInt("special8", 0);
            params.SetInt("special9", 0);
            params.SetInt("special10", 0);
			params.SetString("trinketType", "");
			params.SetInt("trinketPower", 0);
			params.SetFloat("trinketChances", 0.0f);
			params.SetInt("knockedOut", 0);
			params.SetString("weapon1", "");
			params.SetString("weapon2", "");
			params.SetString("weapon3", "");
			params.SetString("weapon4", "");
            obj.UpdateScriptParams();  

	   }else{

		    params.SetString("playerName", saved_level.GetValue("playerNameCrash"));
		    params.SetInt("FireNear", atoi(saved_level.GetValue("FireNearCrash")));
		    params.SetInt("Tracking", atoi(saved_level.GetValue("TrackingCrash")));
		    params.SetInt("Steal", atoi(saved_level.GetValue("StealCrash")));
		    params.SetInt("Search", atoi(saved_level.GetValue("SearchCrash")));
		    params.SetInt("Read", atoi(saved_level.GetValue("ReadCrash")));
		    params.SetInt("Steal", atoi(saved_level.GetValue("StealCrash")));
		    params.SetInt("Freezing", atoi(saved_level.GetValue("FreezingCrash")));
		    params.SetInt("Winter", atoi(saved_level.GetValue("WinterCrash")));
		    params.SetInt("questType", atoi(saved_level.GetValue("questTypeCrash")));
		    params.SetInt("questStatus", atoi(saved_level.GetValue("questStatusCrash")));
		    params.SetInt("questKills", atoi(saved_level.GetValue("questKillsCrash")));
            params.SetInt("noWinter", atoi(saved_level.GetValue("noWinterCrash")));
		    params.SetInt("caravanStrike", atoi(saved_level.GetValue("caravanStrikeCrash")));
		    params.SetInt("distance", atoi(saved_level.GetValue("distanceCrash")));
		    params.SetInt("huntFactor", atoi(saved_level.GetValue("huntFactorCrash")));
	       	params.SetInt("huntLevel", atoi(saved_level.GetValue("huntLevelCrash")));
            //params.SetInt("ko", atoi(saved_level.GetValue("koCrash")));
		    //caravanStrike
		    //adjust quest block spawn rates
            if(params.GetInt("questType") == 2 && params.GetInt("questStatus") == 0){
                BlockTypeUpdate("Data/Objects/block_quest_2.xml", 15.0);
                //BlockTypeUpdate(string pathz, float valuez){
                //level.SendMessage("displaytext \""+"debug: tracking quest detected setting the dead runner block up"+"\"");
            }
            if(params.GetInt("questType") == 8 && params.GetInt("questStatus") == 0){
                BlockTypeUpdate("Data/Objects/block_quest_8.xml", 3.0);
            }
            if(params.GetInt("questType") == 9 && params.GetInt("questStatus") == 0){
                BlockTypeUpdate("Data/Objects/block_quest_9.xml", 3.0);
            }
            if(params.GetInt("questType") == 10 && params.GetInt("questStatus") == 0){
                BlockTypeUpdate("Data/Objects/block_quest_10.xml", 3.0);
            }
            if(params.GetInt("questType") == 11 && params.GetInt("questStatus") == 0){
                BlockTypeUpdate("Data/Objects/block_quest_11.xml", 3.0);
            }
            if(params.GetInt("questType") == 12 && params.GetInt("questStatus") == 0){
                spawnDiplomat();
            }
            BlockTypeUpdate("Data/Objects/block_trees_27.xml", 0.5+params.GetFloat("Forts"));
            BlockTypeUpdate("Data/Objects/block_trinket.xml", 0.0001+params.GetFloat("trinketChances"));
            params.SetInt("Scroll", atoi(saved_level.GetValue("ScrollCrash")));
            params.SetInt("Gold", atoi(saved_level.GetValue("GoldCrash")));
            params.SetInt("Poison", atoi(saved_level.GetValue("PoisonCrash")));
            params.SetInt("Hunted", atoi(saved_level.GetValue("HuntedCrash")));
            params.SetInt("Bless", atoi(saved_level.GetValue("BlessCrash")));
            params.SetInt("xp", atoi(saved_level.GetValue("xpCrash")));
            //
            if(params.GetInt("xp") > 10){
            	params.SetInt("xp", 10);	
            }
            //
            params.SetInt("lvl", atoi(saved_level.GetValue("lvlCrash")));
            params.SetInt("Sick", atoi(saved_level.GetValue("SickCrash")));
            params.SetFloat("Forts", atof(saved_level.GetValue("FortsCrash")));
            params.SetInt("Faith", atoi(saved_level.GetValue("FaithCrash")));
            params.SetInt("Fatigue", atoi(saved_level.GetValue("FatigueCrash")));
            params.SetInt("Water", atoi(saved_level.GetValue("WaterCrash")));
            params.SetInt("Food", atoi(saved_level.GetValue("FoodCrash")));
            params.SetInt("powerUp", atoi(saved_level.GetValue("powerUpCrash")));
            params.SetInt("roninKill", atoi(saved_level.GetValue("roninKillCrash")));
            params.SetInt("roninGrave", atoi(saved_level.GetValue("roninGraveCrash")));
            params.SetInt("relicDistance", atoi(saved_level.GetValue("relicDistanceCrash")));
            //Kungfu
            params.SetInt("handKills", atoi(saved_level.GetValue("handKillsCrash")));
            params.SetInt("KungfuBelt", atoi(saved_level.GetValue("KungfuBeltCrash")));
            params.SetInt("KungfuUpgrade", atoi(saved_level.GetValue("KungfuUpgradeCrash")));
            params.SetInt("KungfuMastery", atoi(saved_level.GetValue("KungfuMasteryCrash")));
            //Kenjutsu
            params.SetInt("weaponKills", atoi(saved_level.GetValue("weaponKillsCrash")));
            params.SetInt("KenjutsuBelt", atoi(saved_level.GetValue("KenjutsuBeltCrash")));
            params.SetInt("KenjutsuUpgrade", atoi(saved_level.GetValue("KenjutsuUpgradeCrash")));
            params.SetInt("KenjutsuMastery", atoi(saved_level.GetValue("KenjutsuMasteryCrash")));
            //Shuriken-jutsu
            params.SetInt("throwKills", atoi(saved_level.GetValue("throwKillsCrash")));
            params.SetInt("ShurikenBelt", atoi(saved_level.GetValue("ShurikenBeltCrash")));
            params.SetInt("ShurikenUpgrade", atoi(saved_level.GetValue("ShurikenUpgradeCrash")));
            params.SetInt("ShurikenMastery", atoi(saved_level.GetValue("ShurikenMasteryCrash")));
            //Ninjitsu
            params.SetInt("Assassination", atoi(saved_level.GetValue("AssassinationCrash")));
            params.SetInt("NinjitsuBelt", atoi(saved_level.GetValue("NinjitsuBeltCrash")));
            params.SetInt("NinjitsuUpgrade", atoi(saved_level.GetValue("NinjitsuUpgradeCrash")));
            params.SetInt("NinjitsuMastery", atoi(saved_level.GetValue("NinjitsuMasteryCrash")));
            //
            params.SetInt("throwFlag", atoi(saved_level.GetValue("throwFlagCrash")));
            params.SetInt("lockPick", atoi(saved_level.GetValue("lockPickCrash")));
            params.SetInt("hour", atoi(saved_level.GetValue("hourCrash")));
            params.SetInt("day", atoi(saved_level.GetValue("dayCrash")));
            params.SetInt("survived", atoi(saved_level.GetValue("survivedCrash")));
            params.SetInt("map", atoi(saved_level.GetValue("mapCrash")));
            params.SetFloat("wanted", atof(saved_level.GetValue("wantedCrash")));
            params.SetFloat("graveDistance", atof(saved_level.GetValue("graveDistance")));
            params.SetInt("Buddy", atoi(saved_level.GetValue("BuddyCrash")));
            params.SetInt("special1", atoi(saved_level.GetValue("special1Crash")));
            params.SetInt("special2", atoi(saved_level.GetValue("special2Crash")));
            params.SetInt("special3", atoi(saved_level.GetValue("special3Crash")));
            params.SetInt("special4", atoi(saved_level.GetValue("special4Crash")));
            params.SetInt("special5", atoi(saved_level.GetValue("special5Crash")));
            params.SetInt("special6", atoi(saved_level.GetValue("special6Crash")));
            params.SetInt("special7", atoi(saved_level.GetValue("special7Crash")));
            params.SetInt("special8", atoi(saved_level.GetValue("special8Crash")));
            params.SetInt("special9", atoi(saved_level.GetValue("special9Crash")));
            params.SetInt("special10", atoi(saved_level.GetValue("special10Crash")));
            // special blocks spawn rate
            if(params.GetInt("special1") == 1){
                BlockTypeUpdate("Data/Objects/special_1.xml", 0.5);
            }
            if(params.GetInt("special2") == 1){
                BlockTypeUpdate("Data/Objects/special_2.xml", 0.5);
            }
            if(params.GetInt("special3") == 1){
                BlockTypeUpdate("Data/Objects/special_3.xml", 0.5);
            }
            if(params.GetInt("special4") == 1){
                BlockTypeUpdate("Data/Objects/special_4.xml", 0.5);
            }
            if(params.GetInt("special5") == 1){
                BlockTypeUpdate("Data/Objects/special_5.xml", 0.5);
            }
            if(params.GetInt("Buddy") > 0){
                spawnBuddy();
            }
            params.SetString("trinketType", saved_level.GetValue("trinketTypeCrash"));
            params.SetInt("trinketPower", atoi(saved_level.GetValue("trinketPowerCrash")));
            params.SetFloat("trinketChances", atof(saved_level.GetValue("trinketChancesCrash")));
            spawnByLabel(saved_level.GetValue("weapon1Crash"));
            spawnByLabel(saved_level.GetValue("weapon2Crash"));
            spawnByLabel(saved_level.GetValue("weapon3Crash"));
            spawnByLabel(saved_level.GetValue("weapon4Crash"));
            if(saved_level.GetValue("knockedOut") == "knocked"){
                if (jailed == "yes"){
                    level.SendMessage("displaytext \""+"You have managed to sneak out of your cell. Escape the city by the sewers!!");
                }else{
                    level.SendMessage("displaytext \""+"A few moments later..."+"\"");
                }
                daytimer = 3;
                postKnocked = 1;
                rogueUI("cue2");
            }else{
                if (jailed == "yes"){
                    level.SendMessage("displaytext \""+"You have managed to sneak out of your cell. Escape the city by the sewers!!");
                }else{
                    level.SendMessage("displaytext \""+"Loading "+params.GetString("playerName")+"'s adventures!!");
                    //PreloadBlocks();
                }
                daytimer = 1;
                postKnocked = 0;
                rogueUI("cue3");
            }
            //PATCH!!
            if(!params.HasParam("map")){
                params.AddInt("map", 0);
            }
            //special maps unlocks patch
            if(!params.HasParam("special1")){
                params.AddInt("special1", 0);
                params.AddInt("special2", 0);
                params.AddInt("special3", 0);
                params.AddInt("special4", 0);
                params.AddInt("special5", 0);
                params.AddInt("special6", 0);
                params.AddInt("special7", 0);
                params.AddInt("special8", 0);
                params.AddInt("special9", 0);
                params.AddInt("special10", 0);
                params.AddInt("Buddy", 0);
            }
            if(params.HasParam("wanted")){
                //level.SendMessage("displaytext \""+"debug:  param found during initialisation, gtg dawg.");
            }else{
                //level.SendMessage("displaytext \""+"debug: no wanted param found setting up the float during initialisation.");
                params.AddFloat("wanted", 0.0f);    
            }
            obj.UpdateScriptParams();
            save_file.WriteInPlace();
        }
     
}
//
void WritePersistentInfo() {
	int weapID;
	SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
	Object @obj = ReadObjectFromID(player_id);
	MovementObject@ mo = ReadCharacterID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	saved_level.SetValue("playerName",""+params.GetString("playerName"));
	saved_level.SetValue("FireNear",""+params.GetInt("FireNear"));
	saved_level.SetValue("Tracking",""+params.GetInt("Tracking"));
	saved_level.SetValue("Steal",""+params.GetInt("Steal"));
	saved_level.SetValue("Read",""+params.GetInt("Read"));
	saved_level.SetValue("Search",""+params.GetInt("Search"));
	saved_level.SetValue("Freezing",""+params.GetInt("Freezing"));
	saved_level.SetValue("Winter",""+params.GetInt("Winter"));
	saved_level.SetValue("questType",""+params.GetInt("questType"));
	saved_level.SetValue("questStatus",""+params.GetInt("questStatus"));
	saved_level.SetValue("questKills",""+params.GetInt("questKills"));
    saved_level.SetValue("noWinter",""+params.GetInt("noWinter"));
	saved_level.SetValue("caravanStrike",""+params.GetInt("caravanStrike"));
	saved_level.SetValue("distance",""+params.GetInt("distance"));
	saved_level.SetValue("huntFactor",""+params.GetInt("huntFactor"));
	saved_level.SetValue("huntLevel",""+params.GetInt("huntLevel"));
	saved_level.SetValue("huntLevel",""+params.GetInt("knockedOut"));
    saved_level.SetValue("roninKill",""+params.GetInt("roninKill"));
    saved_level.SetValue("roninGrave",""+params.GetInt("roninGrave"));
    saved_level.SetValue("graveDistance",""+params.GetInt("graveDistance"));
    saved_level.SetValue("relicDistance",""+params.GetInt("relicDistance"));
	//saved_level.SetValue("ko",""+params.GetInt("ko"));
	//caravanStrike
	saved_level.SetValue("Scroll",""+params.GetInt("Scroll"));
	saved_level.SetValue("Gold",""+params.GetInt("Gold"));	
	saved_level.SetValue("Poison",""+params.GetInt("Poison"));
	saved_level.SetValue("Hunted",""+params.GetInt("Hunted"));
	saved_level.SetValue("Bless",""+params.GetInt("Bless"));
	saved_level.SetValue("xp",""+params.GetInt("xp"));	
	saved_level.SetValue("lvl",""+params.GetInt("lvl"));	
	saved_level.SetValue("Sick",""+params.GetInt("Sick"));	
	saved_level.SetValue("Forts",""+params.GetFloat("Forts"));
	saved_level.SetValue("Faith",""+params.GetInt("Faith"));
	saved_level.SetValue("Fatigue",""+params.GetInt("Fatigue"));
	saved_level.SetValue("Water",""+params.GetInt("Water"));
	saved_level.SetValue("Food",""+params.GetInt("Food"));
	saved_level.SetValue("powerUp",""+params.GetInt("powerUp"));
	saved_level.SetValue("throwFlag",""+params.GetInt("throwFlag"));
	//Shuriken-jutsu
	saved_level.SetValue("throwKills",""+params.GetInt("throwKills"));
	saved_level.SetValue("ShurikenBelt",""+params.GetInt("ShurikenBelt"));
	saved_level.SetValue("ShurikenUpgrade",""+params.GetInt("ShurikenUpgrade"));
	saved_level.SetValue("ShurikenMastery",""+params.GetInt("ShurikenMastery"));
	//Kung-fu
	saved_level.SetValue("handKills",""+params.GetInt("handKills"));
	saved_level.SetValue("KungfuBelt",""+params.GetInt("KungfuBelt"));
	saved_level.SetValue("KungfuUpgrade",""+params.GetInt("KungfuUpgrade"));
	saved_level.SetValue("KungfuMastery",""+params.GetInt("KungfuMastery"));
	//Kenjutsu
	saved_level.SetValue("weaponKills",""+params.GetInt("weaponKills"));
	saved_level.SetValue("KenjutsuBelt",""+params.GetInt("KenjutsuBelt"));
	saved_level.SetValue("KenjutsuUpgrade",""+params.GetInt("KenjutsuUpgrade"));
	saved_level.SetValue("KenjutsuMastery",""+params.GetInt("KenjutsuMastery"));
	//ninjitsu
	saved_level.SetValue("Assassination",""+params.GetInt("Assassination"));
	saved_level.SetValue("NinjitsuBelt",""+params.GetInt("NinjitsuBelt"));
	saved_level.SetValue("NinjitsuUpgrade",""+params.GetInt("NinjitsuUpgrade"));
	saved_level.SetValue("NinjitsuMastery",""+params.GetInt("NinjitsuMastery"));
	//
	saved_level.SetValue("lockPick",""+params.GetInt("lockPick"));
	saved_level.SetValue("hour",""+params.GetInt("hour"));
	saved_level.SetValue("day",""+params.GetInt("day"));
	saved_level.SetValue("survived",""+params.GetInt("survived"));
    saved_level.SetValue("map",""+params.GetInt("map"));
    saved_level.SetValue("wanted",""+params.GetFloat("wanted"));
    saved_level.SetValue("Buddy",""+params.GetInt("Buddy"));
    //
    saved_level.SetValue("special1",""+params.GetInt("special1"));
    saved_level.SetValue("special2",""+params.GetInt("special2"));
    saved_level.SetValue("special3",""+params.GetInt("special3"));
    saved_level.SetValue("special4",""+params.GetInt("special4"));
    saved_level.SetValue("special5",""+params.GetInt("special5"));
    saved_level.SetValue("special6",""+params.GetInt("special6"));
    saved_level.SetValue("special7",""+params.GetInt("special7"));
    saved_level.SetValue("special8",""+params.GetInt("special8"));
    saved_level.SetValue("special9",""+params.GetInt("special9"));
    saved_level.SetValue("special10",""+params.GetInt("special10"));
    //
	saved_level.SetValue("trinketType",""+params.GetString("trinketType"));
	saved_level.SetValue("trinketPower",""+params.GetInt("trinketPower"));
	saved_level.SetValue("trinketChances",""+params.GetFloat("trinketChances"));
	if(params.GetInt("knockedOut") == 1){
		//level.SendMessage("displaytext \""+"Saving that the player has been knocked out"+"\"");
		saved_level.SetValue("knockedOut", "knocked");
	}else{
		//level.SendMessage("displaytext \""+"Saving that the player has NOT been knocked out"+"\"");
		saved_level.SetValue("knockedOut", "");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",0);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon1",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon1","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",1);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon2",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon2","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",2);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon3",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon3","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",3);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon4",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon4","");
	}
    saved_level.SetValue("fortChances",""+fortChances);
    save_file.WriteInPlace();
	//level.SendMessage("displaytext \""+"Save file after write has knocked out at "+saved_level.GetValue("knockedOut"));
}

//for crash saves
void crashSave() {
	int weapID;
	SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
	Object @obj = ReadObjectFromID(player_id);
	MovementObject@ mo = ReadCharacterID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	saved_level.SetValue("playerNameCrash",""+params.GetString("playerName"));
	saved_level.SetValue("FireNearCrash",""+params.GetInt("FireNear"));
	saved_level.SetValue("TrackingCrash",""+params.GetInt("Tracking"));
	saved_level.SetValue("StealCrash",""+params.GetInt("Steal"));
	saved_level.SetValue("ReadCrash",""+params.GetInt("Read"));
	saved_level.SetValue("SearchCrash",""+params.GetInt("Search"));
	saved_level.SetValue("FreezingCrash",""+params.GetInt("Freezing"));
	saved_level.SetValue("WinterCrash",""+params.GetInt("Winter"));
	saved_level.SetValue("questTypeCrash",""+params.GetInt("questType"));
	saved_level.SetValue("questStatusCrash",""+params.GetInt("questStatus"));
	saved_level.SetValue("questKillsCrash",""+params.GetInt("questKills"));
    saved_level.SetValue("noWinterCrash",""+params.GetInt("noWinter"));
	saved_level.SetValue("caravanStrikeCrash",""+params.GetInt("caravanStrike"));
	saved_level.SetValue("distanceCrash",""+params.GetInt("distance"));
	saved_level.SetValue("huntFactorCrash",""+params.GetInt("huntFactor"));
	saved_level.SetValue("huntLevelCrash",""+params.GetInt("huntLevel"));
    saved_level.SetValue("roninKillCrash",""+params.GetInt("roninKill"));
    saved_level.SetValue("roninGraveCrash",""+params.GetInt("roninGrave"));
    saved_level.SetValue("relicDistanceCrash",""+params.GetInt("relicDistance"));
	//saved_level.SetValue("koCrash",""+params.GetInt("ko"));
	//caravanStrike
	saved_level.SetValue("ScrollCrash",""+params.GetInt("Scroll"));
	saved_level.SetValue("GoldCrash",""+params.GetInt("Gold"));	
	saved_level.SetValue("PoisonCrash",""+params.GetInt("Poison"));
	saved_level.SetValue("HuntedCrash",""+params.GetInt("Hunted"));
	saved_level.SetValue("BlessCrash",""+params.GetInt("Bless"));
	saved_level.SetValue("xpCrash",""+params.GetInt("xp"));	
	saved_level.SetValue("lvlCrash",""+params.GetInt("lvl"));	
	saved_level.SetValue("SickCrash",""+params.GetInt("Sick"));	
	saved_level.SetValue("FortsCrash",""+params.GetFloat("Forts"));
	saved_level.SetValue("FaithCrash",""+params.GetInt("Faith"));
	saved_level.SetValue("FatigueCrash",""+params.GetInt("Fatigue"));
	saved_level.SetValue("WaterCrash",""+params.GetInt("Water"));
	saved_level.SetValue("FoodCrash",""+params.GetInt("Food"));
	saved_level.SetValue("powerUpCrash",""+params.GetInt("powerUp"));
	saved_level.SetValue("throwFlagCrash",""+params.GetInt("throwFlag"));
	//Shuriken-jutsu
	saved_level.SetValue("throwKillsCrash",""+params.GetInt("throwKills"));
	saved_level.SetValue("ShurikenBeltCrash",""+params.GetInt("ShurikenBelt"));
	saved_level.SetValue("ShurikenUpgradeCrash",""+params.GetInt("ShurikenUpgrade"));
	saved_level.SetValue("ShurikenMasteryCrash",""+params.GetInt("ShurikenMastery"));
	//Kung-fu
	saved_level.SetValue("handKillsCrash",""+params.GetInt("handKills"));
	saved_level.SetValue("KungfuBeltCrash",""+params.GetInt("KungfuBelt"));
	saved_level.SetValue("KungfuUpgradeCrash",""+params.GetInt("KungfuUpgrade"));
	saved_level.SetValue("KungfuMasteryCrash",""+params.GetInt("KungfuMastery"));
	//Kenjutsu
	saved_level.SetValue("weaponKillsCrash",""+params.GetInt("weaponKills"));
	saved_level.SetValue("KenjutsuBeltCrash",""+params.GetInt("KenjutsuBelt"));
	saved_level.SetValue("KenjutsuUpgradeCrash",""+params.GetInt("KenjutsuUpgrade"));
	saved_level.SetValue("KenjutsuMasteryCrash",""+params.GetInt("KenjutsuMastery"));
	//ninjitsu
	saved_level.SetValue("AssassinationCrash",""+params.GetInt("Assassination"));
	saved_level.SetValue("NinjitsuBeltCrash",""+params.GetInt("NinjitsuBelt"));
	saved_level.SetValue("NinjitsuUpgradeCrash",""+params.GetInt("NinjitsuUpgrade"));
	saved_level.SetValue("NinjitsuMasteryCrash",""+params.GetInt("NinjitsuMastery"));
	//
	saved_level.SetValue("lockPickCrash",""+params.GetInt("lockPick"));
	saved_level.SetValue("hourCrash",""+params.GetInt("hour"));
	saved_level.SetValue("dayCrash",""+params.GetInt("day"));
	saved_level.SetValue("survivedCrash",""+params.GetInt("survived"));
    saved_level.SetValue("mapCrash",""+params.GetInt("map"));
    saved_level.SetValue("wantedCrash",""+params.GetFloat("wanted"));
    saved_level.SetValue("BuddyCrash",""+params.GetInt("Buddy"));
    //
    saved_level.SetValue("special1Crash",""+params.GetInt("special1"));
    saved_level.SetValue("special2Crash",""+params.GetInt("special2"));
    saved_level.SetValue("special3Crash",""+params.GetInt("special3"));
    saved_level.SetValue("special4Crash",""+params.GetInt("special4"));
    saved_level.SetValue("special5Crash",""+params.GetInt("special5"));
    saved_level.SetValue("special6Crash",""+params.GetInt("special6"));
    saved_level.SetValue("special7Crash",""+params.GetInt("special7"));
    saved_level.SetValue("special8Crash",""+params.GetInt("special8"));
    saved_level.SetValue("special9Crash",""+params.GetInt("special9"));
    saved_level.SetValue("special10Crash",""+params.GetInt("special10"));
    //
	saved_level.SetValue("trinketTypeCrash",""+params.GetString("trinketType"));
	saved_level.SetValue("trinketPowerCrash",""+params.GetInt("trinketPower"));
	saved_level.SetValue("trinketChancesCrash",""+params.GetFloat("trinketChances"));
	if(params.GetInt("knockedOut") == 1){
		//level.SendMessage("displaytext \""+"CRASHSAVING that the player has been knocked out"+"\"");
		saved_level.SetValue("knockedOut", "knocked");
	}else{
		//level.SendMessage("displaytext \""+"CRASHSAVING that the player has NOT been knocked out"+"\"");
		saved_level.SetValue("knockedOut", "");
	}
    saved_level.SetValue("fortChancesCrash",""+fortChances);
	weapID = mo.GetArrayIntVar("weapon_slots",0);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon1Crash",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon1Crash","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",1);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon2Crash",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon2Crash","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",2);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon3Crash",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon3Crash","");
	}
	weapID = mo.GetArrayIntVar("weapon_slots",3);
	if(weapID != -1){
		ItemObject@ weap = ReadItemID(weapID);
		saved_level.SetValue("weapon4Crash",""+weap.GetLabel());			
	}else{
		saved_level.SetValue("weapon4Crash","");
	}
    save_file.WriteInPlace();
	//level.SendMessage("displaytext \""+"Crash Saving...quest status is "+params.GetInt("questStatus"));
}