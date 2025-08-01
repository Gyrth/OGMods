#include "undergrowth_includes.as"

void Init() {
}



void createSword(){
string itemPath;
	//int rnd = 17;
    int rnd = rand()%2;

    switch(rnd){
    	case 0: itemPath = "Data/Items/Undergrowth/Sword_1_Weapon.xml"; break;
        case 1: itemPath = "Data/Items/Undergrowth/Sword_2_Weapon.xml"; break;
	}
	//jims_weapon_pack
    int gearID = CreateObject(itemPath);
    Object@ charObj = ReadObjectFromID(gearID);
	MovementObject@ player_mo = ReadCharacterID(GetPlayerID());
	vec3 initial_position = vec3(player_mo.position.x+1 , player_mo.position.y+1, player_mo.position.z);
    charObj.SetTranslation(initial_position);
}

void SetParameters() {
	params.AddInt("Prayed", 0);
	params.AddInt("Open", 0);	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
		 params.SetInt("Open", 1);
    } else if(event == "exit"){
        OnExit(mo);
		 params.SetInt("Open", 0);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
		  if(params.GetInt("Prayed") == 0){
			 level.SendMessage("clearhud");
			 level.SendMessage("uicue");
			 level.SendMessage("displayhud /Data/UI/Icons/swordTree.png");
		  }
    }
}

void OnExit(MovementObject @mo) {
  
}

void Update(){
	
	CheckKeyPresses();
	
}

void CheckKeyPresses(){
	if(GetInputPressed(1, "x")){
		if(params.GetInt("Open") == 1){
			int player_id = GetPlayerID();
			MovementObject@ player_mo = ReadCharacterID(player_id);
			if(params.GetInt("Prayed") == 0){
				Object @obj = ReadObjectFromID(player_id);
				ScriptParams@ paramzz = obj.GetScriptParams();
					level.SendMessage("displaytext \""+"You pull a blade from the tree.");
					PlaySound("Data/Sounds/bigSpell.wav", player_mo.position);
					params.SetInt("Prayed", 1);
					string itemPath;
					createSword();
			}else{
				PlaySound("Data/Sounds/meh.wav", player_mo.position);
				level.SendMessage("displaytext \""+"You already desecrated the tree once. Don't push your luck.");
			}
		}
	}
}
