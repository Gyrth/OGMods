#include "undergrowth_includes.as"

string getRandomWeapon(){
    int rnd = rand()%21;
    switch(rnd){
    	case 0: return "Data/Items/DogWeapons/DogKnife.xml";
        case 1: return "Data/Items/DogWeapons/DogBroadSword.xml"; 
       	case 2: return "Data/Items/DogWeapons/DogSword.xml"; 
        case 3: return "Data/Items/DogWeapons/DogSpear.xml"; 
		case 4: return "Data/Items/DogHammer.xml"; 
		case 5: return "Data/Items/gear/dogtools/dogtoolawl.xml";
		case 6: return "Data/Items/gear/dogtools/dogtoolhammer.xml";
		case 7: return "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml";
		case 8: return "Data/Items/staffbasic.xml";
		case 9: return "Data/Items/Rapier.xml";
		case 10: return "Data/Items/MainGauche.xml";
		case 11: return "Data/Items/Undergrowth/Polearm_Scimitar_Weapon.xml";
		case 12: return "Data/Items/Undergrowth/Polearm_FlatEdge_Weapon.xml";
		case 13: return "Data/Items/Undergrowth/Polearm_Spiked_Weapon.xml";
		case 14: return "Data/jims_weapon_pack/rat_weapons/jims_rat_club.xml";
		case 15: return "Data/jims_weapon_pack/rat_weapons/jims_rat_sword.xml";
		case 16: return "Data/jims_weapon_pack/kendostick_2h/jims_kendostick_2h_red.xml";
		case 17: return "Data/jims_weapon_pack/katana_viola/jims_rabies_sword.xml";
		case 18: return "Data/jims_weapon_pack/katana_viola/jims_katana_viola.xml";
		case 19: return "Data/Items/Undergrowth/Sword_1_Weapon.xml";
		case 20: return "Data/Items/Undergrowth/Sword_2_Weapon.xml";
	}
	return "Data/Items/DogWeapons/DogKnife.xml";
}

void Init() {
}



void SetParameters() {
	params.AddInt("Eaten", 0);	
	params.AddInt("Open", 0);	
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
	if(!EditorModeActive()){
    	if(!mo.controlled){
    		Object @obj = ReadObjectFromID(mo.GetID());
    		Object @player_obj = ReadObjectFromID(GetPlayerID());
    		ScriptParams@ player_params = player_obj.GetScriptParams();
			ScriptParams@ paramzz = obj.GetScriptParams();
    		if(!paramzz.HasParam("weaponized")){
    			if(paramzz.GetString("Teams") == "meatEater"){
    				if(rand()%100 < player_params.GetInt("huntFactor")){
    					paramzz.AddInt("weaponized", 1);	
						int weaponID = CreateObject(getRandomWeapon());
						mo.Execute("AttachWeapon(" + weaponID + ")");
					}
				}
			}
			obj.UpdateScriptParams();
    	}
	}
    
}

void OnExit(MovementObject @mo) {

}

void Update(){

}

