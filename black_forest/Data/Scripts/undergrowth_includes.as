
int GetPlayerID() {
    int id = -1;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.is_player){
            id = char.GetID();
			break;
        }
    }
    return id;
}

void createBuffSparks(){
    MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
    for(int xx = 0; xx < 50; xx++){
        vec3 initial_position = vec3(player_mo.position.x , player_mo.position.y, player_mo.position.z);
        uint32 id = MakeParticle("Data/Particles/Undergrowth/magicspark.xml", initial_position, vec3(RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f)));
    }
}

void createHealSparks(){
    MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
    for(int xx = 0; xx < 50; xx++){
        vec3 initial_position = vec3(player_mo.position.x , player_mo.position.y, player_mo.position.z);
        uint32 id = MakeParticle("Data/Particles/Undergrowth/healspark.xml", initial_position, vec3(RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f)));
    }
}

void createTrinketSparks(){
    MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
    for(int xx = 0; xx < 50; xx++){
        vec3 initial_position = vec3(player_mo.position.x , player_mo.position.y, player_mo.position.z);
        uint32 id = MakeParticle("Data/Particles/Undergrowth/trinketspark.xml", initial_position, vec3(RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f)));
    }
}
//
int GetBuddyID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        Object @obj = ReadObjectFromID(char.GetID());
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
                if(params.GetString("Name") == "runnerBuddy"){
                    return char.GetID();
                }
            
        }

    }
    return -1;
}

int GetDiplomatID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        Object @obj = ReadObjectFromID(char.GetID());
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
                if(params.GetString("Name") == "diplomat"){
                    return char.GetID();
                } 
        }
    }
    return -1;
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

bool buddyAround(){
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        Object @obj = ReadObjectFromID(char.GetID());
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            if(char.GetIntVar("knocked_out") == _awake){
                if(params.GetString("Name") == "runnerBuddy"){
                    return true;
                }
            }
        }

    }
    return false;
}

//useful for ui display
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
        return "Diamon";
    }else if(foo == 9){
        return "Unique";
    }else if(foo == 10){
        return "Epic";
    }else{
        return "poop";
    }
}
string titleReader(){
        Object @obj = ReadObjectFromID(GetPlayerID());
        ScriptParams@ params = obj.GetScriptParams();

        if(params.GetInt("Steal") > params.GetInt("Search") && params.GetInt("Steal") > params.GetInt("Faith") &&  params.GetInt("Steal") > params.GetInt("Tracking")){
            return "Rogue";
        }else if(params.GetInt("Search") > params.GetInt("Steal") && params.GetInt("Search") > params.GetInt("Faith") &&  params.GetInt("Search") > params.GetInt("Tracking")){
            return "Scout";
        }else if(params.GetInt("Tracking") > params.GetInt("Steal") && params.GetInt("Tracking") > params.GetInt("Search") &&  params.GetInt("Tracking") > params.GetInt("Faith")){
            return "Guardian";
        }else if(params.GetInt("Faith") > params.GetInt("Steal") && params.GetInt("Faith") > params.GetInt("Search") &&  params.GetInt("Faith") > params.GetInt("Tracking")){
            return "Monk";
        }else{
            return "Vagabond";
        }
    
}

string beltReader(){
        Object @obj = ReadObjectFromID(GetPlayerID());
        ScriptParams@ params = obj.GetScriptParams();
        if(params.GetInt("ShurikenBelt") > params.GetInt("KenjutsuBelt") && params.GetInt("ShurikenBelt") > params.GetInt("KungfuBelt") &&  params.GetInt("ShurikenBelt") > params.GetInt("NinjitsuBelt")){
            return " Shinobi";
        }else if(params.GetInt("KenjutsuBelt") > params.GetInt("ShurikenBelt") && params.GetInt("KenjutsuBelt") > params.GetInt("KungfuBelt") &&  params.GetInt("KenjutsuBelt") > params.GetInt("NinjitsuBelt")){
            return " Samurai";
        }else if(params.GetInt("NinjitsuBelt") > params.GetInt("ShurikenBelt") && params.GetInt("NinjitsuBelt") > params.GetInt("KungfuBelt") &&  params.GetInt("NinjitsuBelt") > params.GetInt("KenjutsuBelt")){
            return " Ninja";
        }else if(params.GetInt("KungfuBelt") > params.GetInt("ShurikenBelt") && params.GetInt("KungfuBelt") > params.GetInt("NinjitsuBelt") &&  params.GetInt("KungfuBelt") > params.GetInt("KenjutsuBelt")){
            return " Sensei";
        }else{
            return " Runner";
        }  
}



void missionTell(){
        Object @obj = ReadObjectFromID(GetPlayerID());
        ScriptParams@ params = obj.GetScriptParams();
        MovementObject@ mo = ReadCharacterID(GetPlayerID());
        PlaySound("Data/Sounds/mish.wav", mo.position);
        if(params.GetInt("questStatus") == 1){
            level.SendMessage("displaytext \""+"Your mission is successful go to a rabbit fort to collect your reward."+"\"");
        }else if(params.GetInt("questStatus") == -1){
            level.SendMessage("displaytext \""+"You have failed your mission and brought dishonor to your dojo."+"\"");
        }else{
            if(params.GetInt("questType") == 1){
                level.SendMessage("displaytext \""+"Current mission: Deliver a special message to the next rabbit fort you encounter."+"\"");
            }else if(params.GetInt("questType") == 2){
                level.SendMessage("displaytext \""+"Current mission: Find the dead Runner somewhere in the forest."+"\"");
            }else if(params.GetInt("questType") == 3){
                level.SendMessage("displaytext \""+"Current mission: Get to the next rabbit fort without being detected."+"\"");
            }else if(params.GetInt("questType") == 4){
                level.SendMessage("displaytext \""+"Current mission: kill "+(5-params.GetInt("questKills"))+" more rats.");
            }else if(params.GetInt("questType") == 5){
                level.SendMessage("displaytext \""+"Current mission: kill "+(5-params.GetInt("questKills"))+" more cats.");
            }else if(params.GetInt("questType") == 6){
                level.SendMessage("displaytext \""+"Current mission: kill "+(5-params.GetInt("questKills"))+" more dogs.");
            }else if(params.GetInt("questType") == 7){
                level.SendMessage("displaytext \""+"Current mission: Kill a wolf.");
            }else if(params.GetInt("questType") == 8){
                level.SendMessage("displaytext \""+"Current mission: Find the enemy well and poison it. You must avoid being knocked out during this mission.");
            }else if(params.GetInt("questType") == 9){
                level.SendMessage("displaytext \""+"Current mission: Infiltrate the enemy base without being detected and steal the plans.");
            }else if(params.GetInt("questType") == 10){
                level.SendMessage("displaytext \""+"Current mission: Kill the enemy General. You must avoid being knocked out by her or her guards.");
            }else if(params.GetInt("questType") == 11){
                level.SendMessage("displaytext \""+"Current mission: Find a trench and push back the invasion. Your trench buddy must not die.");
            }else if(params.GetInt("questType") == 12){
                level.SendMessage("displaytext \""+"Current mission: Escort the diplomat to the next fort. The diplomat must not die.");
            }else if(params.GetInt("questType") == 13){
                level.SendMessage("displaytext \""+"Current mission: Loot "+(10-params.GetInt("questKills"))+" more containers. If you are knocked out, you have to start over.");
            }else if(params.GetInt("questType") == 14){
                level.SendMessage("displaytext \""+"Current mission: Go and place a firebomb on any containers. Do not get detected. ");
            }else if(params.GetInt("questType") == 15){
                level.SendMessage("displaytext \""+"Current mission: Search the bottom of ponds for the missing clan seal. Nasty.");
            }else{
                level.SendMessage("displaytext \""+"Current mission: None. Go to a rabbit fort to get a mission.");
            }
        }
}

int GetCharPrimaryWeapon(MovementObject@ mo){
    return mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
}

string GetCharWeaponTag(int weapID){
    if(weapID != -1){
        string weapLabel;
        ItemObject@ weap = ReadItemID(weapID);
        return weapLabel = weap.GetLabel();
    } 
    return "";
}

bool skillCheck(string skill, int adjust){
    int trink = 0;
    Object @obj = ReadObjectFromID(GetPlayerID());
    ScriptParams@ params = obj.GetScriptParams();

    if(params.GetString("trinketType") == "Knowledge"){
        trink = params.GetInt("trinketPower");
    }
    //
    if(rand() % 100 < params.GetInt(skill)+adjust+trink){
         return true;
    }
    return false;
}

