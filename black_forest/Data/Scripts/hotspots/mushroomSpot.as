#include "undergrowth_includes.as"

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
    if(mo.controlled){
		if(params.GetInt("Eaten") == 0 ){
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("displayhud /Data/UI/Icons/mushroom.png");
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
		int skillBonus = 0;
		if(paramzz.GetString("trinketType") == "Knowledge"){
			skillBonus = paramzz.GetInt("trinketPower");
		}
			if(params.GetInt("Eaten") == 0){
				params.SetInt("Eaten", 1);
				PlaySound("Data/Sounds/eating.wav", mo.position);
				if(rand()% 100 < paramzz.GetInt("Tracking")+20+skillBonus){
					//level.SendMessage("nom");
					if(paramzz.GetString("trinketType") == "Plenty" && (rand()% 100 < paramzz.GetInt("trinketPower")*5) ){
						paramzz.SetInt("Food", (paramzz.GetInt("Food")+25));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						paramzz.SetInt("Food", (paramzz.GetInt("Food")+20));
					}
				}else{
					if(paramzz.GetString("trinketType") == "Venom" && (rand()% 100 < paramzz.GetInt("trinketPower")*5) ){
						level.SendMessage("displaytext \""+"Your trinket protected you against the poison!!");
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "purity"){
                            PlaySound("Data/Sounds/purityProc.wav", mo.position);
                            level.SendMessage("clearhud");
                            level.SendMessage("uicue");
                            level.SendMessage("displayhud /Data/UI/Icons/purityProc.png");
                            createTrinketSparks();
                        }else{
							level.SendMessage("clearhud");
							level.SendMessage("uicue");
							level.SendMessage("displaytext \""+" Bushcraft skill failed. You should have not eaten the stinky mushrooms.");
							if(paramzz.GetInt("Poison")<= 0){
								paramzz.SetInt("Poison", 5);
							}else{
								paramzz.SetInt("Poison", (paramzz.GetInt("Poison")+5));
							}
							PlaySound("Data/Sounds/poison.wav", mo.position);
							level.SendMessage("displayhud /Data/UI/Icons/poisoned.png");
							mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
        					uint32 idz = MakeParticle("Data/Particles/Undergrowth/poison_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
        				}
					}
					params.SetInt("Eaten", 1);
					if(paramzz.GetString("trinketType") == "Plenty" && (rand()% 100 < paramzz.GetInt("trinketPower")*5) ){
						paramzz.SetInt("Food", (paramzz.GetInt("Food")+15));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					}else{
						paramzz.SetInt("Food", (paramzz.GetInt("Food")+10));
					}
				}
				obj.UpdateScriptParams();
			}
		}
	}
}
