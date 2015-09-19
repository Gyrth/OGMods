void Init() {
}

void SetParameters() {
    params.AddString("Display Image", "image path here");
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
	    level.SendMessage("clearhud");
        level.SendMessage("displayhud \""+params.GetString("Display Image")+"\"");
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
    }
}