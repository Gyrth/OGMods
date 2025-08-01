#include "undergrowth_includes.as"

void Init() {
	
 
   
}



void SetParameters() {
	params.AddInt("peddlerGo", 0);
	params.AddInt("peddlerThere", 0);
	params.AddInt("itemPrice", 0);
	params.AddInt("itemType", 0);
	params.SetInt("itemType", (rand()%6));
	if(params.GetInt("itemType") == 0){
		// rabbit knife
		params.SetInt("itemPrice", 1);	
	}else if(params.GetInt("itemType") == 1){
		// full meal
		params.SetInt("itemPrice", 2);
	}else if(params.GetInt("itemType") == 2){
		// coffee (no freeze)
		params.SetInt("itemPrice", 1);
	}else if(params.GetInt("itemType") == 3){
		// 2 picklocks
		params.SetInt("itemPrice", 1);
	}else if(params.GetInt("itemType") == 4){
		// scroll
		params.SetInt("itemPrice", 3);
	}else if(params.GetInt("itemType") == 5){
		// healing balm
		params.SetInt("itemPrice", 2);
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

    if(mo.controlled){
		params.SetInt("peddlerGo", 1);
		level.SendMessage("clearhud");
		level.SendMessage("uicue");
		level.SendMessage("displayhud /Data/UI/Icons/peddlerItem"+params.GetInt("itemType")+".png");
		level.SendMessage("displaytext \""+"Peddler"+"\"");
    }else {
		//check if he is a peddler
		int peddler_id  = mo.GetID();
		Object @obj = ReadObjectFromID(peddler_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		if(paramzz.HasParam("Name")){
        	string name_str = paramzz.GetString("Name");
            if("Peddler" == name_str){
            	paramzz.SetInt("peddlerThere", 1);
            }
        }
	}

}

void OnExit(MovementObject @mo) {
	if(mo.controlled){
		params.SetInt("peddlerGo", 0);
    }else {
		//check if he is a peddler
		int peddler_id  = mo.GetID();
		Object @obj = ReadObjectFromID(peddler_id);
		ScriptParams@ paramzz = obj.GetScriptParams();
		if(paramzz.HasParam("Name")){
        	string name_str = paramzz.GetString("Name");
            if("Peddler" == name_str){
            	paramzz.SetInt("peddlerThere", 0);
            }
        }
	}
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	if(GetInputPressed(0, "x")){
		//find the player
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
		ScriptParams@ paramxx = obj.GetScriptParams();
		MovementObject@ mo = ReadCharacterID(player_id);
		if(params.GetInt("peddlerGo") == 1){
			if(params.GetInt("peddlerGo") == 1){
			
			//ReadCharacterID(player_ids[0])
			
			if(paramxx.GetInt("Gold") >= params.GetInt("itemPrice")){
				if(paramxx.GetString("trinketType") == "the Guild" && (rand()% 100 < paramxx.GetInt("trinketPower")*5) ){
					level.SendMessage("displaytext \""+"The merchant recognize your trinket and gives you the item for free!!!");
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
				}else{
					paramxx.SetInt("Gold", paramxx.GetInt("Gold")-params.GetInt("itemPrice"));
					PlaySound("Data/Sounds/singleCoin.wav", mo.position);
				}
				if(params.GetInt("itemType")== 0){
					    string itemPath;
						int rnd = rand()%19;
    					switch(rnd){
    						case 0: itemPath = "Data/Items/DogWeapons/DogKnife.xml"; break;
        					case 1: itemPath = "Data/Items/DogWeapons/DogBroadSword.xml"; break;
       						case 2: itemPath = "Data/Items/DogWeapons/DogSword.xml"; break;
        					case 3: itemPath = "Data/Items/DogWeapons/DogSpear.xml"; break;
							case 4: itemPath = "Data/Items/DogHammer.xml"; break;
							case 5: itemPath  = "Data/Items/gear/dogtools/dogtoolawl.xml"; break;
							case 6: itemPath  = "Data/Items/gear/dogtools/dogtoolhammer.xml"; break;
							case 7: itemPath  = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml"; break;
							case 8: itemPath  = "Data/Items/staffbasic.xml"; break;
							case 9: itemPath  = "Data/Items/Rapier.xml"; break;
							case 10: itemPath  = "Data/Items/MainGauche.xml"; break;
							case 11: itemPath  = "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml"; break;
							case 12: itemPath  = "Data/Items/Undergrowth/Polearm_FlatEdge_Weapon.xml"; break;
							case 13: itemPath  = "Data/Items/Undergrowth/Polearm_Spiked_Weapon.xml"; break;
							case 14: itemPath  = "Data/jims_weapon_pack/rat_weapons/jims_rat_club.xml"; break;
							case 15: itemPath  = "Data/jims_weapon_pack/rat_weapons/jims_rat_sword.xml"; break;
							case 16: itemPath = "Data/jims_weapon_pack/kendostick_2h/jims_kendostick_2h_red.xml"; break;
							case 17: itemPath = "Data/jims_weapon_pack/katana_viola/jims_rabies_sword.xml"; break;
							case 18: itemPath = "Data/jims_weapon_pack/katana_viola/jims_katana_viola.xml"; break;
						}
    					int weaponID = CreateObject(itemPath);
						mo.Execute("AttachWeapon(" + weaponID + ")");
						//primary_weapon_id = weapon_slots[primary_weapon_slot];
						//level.SendMessage("displayhud /Data/UI/Icons/lockPick"+paramxx.GetInt("lockPick")+".png");
    					//Object@ charObj = ReadObjectFromID(weaponID);
    					//charObj.SetTranslation(obj.GetTranslation());
						//level.SendMessage("displaytext \""+"weapon id is "+obj.weapon_slots[0]+"\"");
				}else if(params.GetInt("itemType")== 1){
					PlaySound("Data/Sounds/eating.wav", mo.position);
					paramxx.SetInt("Food", 100);
				}else if(params.GetInt("itemType")== 2){
					PlaySound("Data/Sounds/drinking.wav", mo.position);
					paramxx.SetInt("Freezing", 0);
					if(paramxx.GetString("trinketType") == "Plenty" && (rand()% 100 < paramxx.GetInt("trinketPower")*5) ){
						paramxx.SetInt("Food", (paramxx.GetInt("Water")+35));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						paramxx.SetInt("Water", paramxx.GetInt("Water")+25);
					}
				}else if(params.GetInt("itemType")== 3){
					PlaySound("Data/Sounds/lockPickPicked.wav", mo.position);
					paramxx.SetInt("lockPick", paramxx.GetInt("lockPick")+2);
					if(paramxx.GetInt("lockPick") > 10){
						paramxx.SetInt("lockPick", 10);
					}
					level.SendMessage("clearhud");
			 		level.SendMessage("uicue");
			 		level.SendMessage("displayhud /Data/UI/Icons/lockPick"+paramxx.GetInt("lockPick")+".png");
				}else if(params.GetInt("itemType")== 4){
					PlaySound("Data/Sounds/scroll.wav", mo.position);
					paramxx.SetInt("xp", paramxx.GetInt("xp")+1);
					if(paramxx.GetInt("xp") > 10){
						paramxx.SetInt("xp", 10);
					}
					if(paramxx.GetInt("xp") < 1){
						paramxx.SetInt("xp", 1);
					}
					level.SendMessage("clearhud");
			 		level.SendMessage("uicue");
			 		level.SendMessage("displayhud /Data/UI/Icons/scroll"+paramxx.GetInt("xp")+".png");
				}else if(params.GetInt("itemType")== 5){
					PlaySound("Data/Sounds/healing.wav", mo.position);
					mo.ReceiveMessage("healer_touch");
					paramxx.SetInt("Poison", 0);
					paramxx.SetInt("Sick", 0);
					createHealSparks();
				}
			}else{
				level.SendMessage("displaytext \""+"You don't have enough gold ("+ paramxx.GetInt("Gold")+") to buy this item ("+params.GetInt("itemPrice")+")"+"\"");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
			obj.UpdateScriptParams();
			}else{
				level.SendMessage("displaytext \""+"There's no peddler here to trade with you."+"\"");
				PlaySound("Data/Sounds/nope.wav", mo.position);
			}
		}
	}
}

