#include "undergrowth_includes.as"



void Init() {
}



void SetParameters() {
	params.AddInt("asleep", 0);	
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
	//if(!EditorModeActive()){
    	if(!mo.controlled){

    		Object @obj = ReadObjectFromID(mo.GetID());
			ScriptParams@ paramzz = obj.GetScriptParams();
    		if(!paramzz.HasParam("sleeping")){
    			if(paramzz.GetString("Teams") == "meatEater"){
    				//level.SendMessage("displaytext \""+"is a meat eater");
    				paramzz.AddInt("sleeping", 1);
    				mo.Execute("patrol_wait_until = time + 9999.0;"+
                        "patrol_idle_override = \"Data/Animations/r_sleep.anm\";"+
                        "asleep = true;");

				}
			}
			obj.UpdateScriptParams();
    	}
	//}
    
}

void OnExit(MovementObject @mo) {

}

void Update(){

}

