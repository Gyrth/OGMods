#include "undergrowth_includes.as"

void Init() {
    
}



void SetParameters() {

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
    	Object @obj = ReadObjectFromID(GetPlayerID());
		ScriptParams@ params = obj.GetScriptParams();
		params.SetFloat("wanted", 0.0f);
		SavedLevel @saved_level = save_file.GetSavedLevel("undergrowth_redux");
		saved_level.SetValue("jailed", "");
		save_file.WriteInPlace();
		//level.SendMessage("displaytext \""+"debug: jail is at  "+ saved_level.GetValue("jailed"));
		level.SendMessage("loadlevel \"" + "Data/Levels/undergrowth_redux.xml" + "\"");
		obj.UpdateScriptParams();
    }

}

void OnExit(MovementObject @mo) {
	
}

void Update(){
	CheckKeyPresses();
}

void CheckKeyPresses(){
	
	
}

