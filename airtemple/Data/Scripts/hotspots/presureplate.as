float time = 0.0f;
void Init() {
}
string go;
void SetParameters() {
	params.AddString("ItemID", "331");
	params.AddString("HotspotNumber", "0");
	//go = params.GetString("ItemID");
	//params.AddString("Message to send on exit","");
    //msg2 = params.GetString("Message to send on exit");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
	else if(event == "exit"){
        OnExit(mo);
    }
}
void OnEnter(MovementObject @mo) {
	if(mo.controlled){
		mo.Execute("presureplatecounter++");
		level.SendMessage("moveobj"+params.GetString("ItemID")+"dn"+params.GetString("HotspotNumber"));
	}
}
void OnExit(MovementObject @mo) {
	//level.SendMessage("moveobj"+params.GetString("ItemID")+"up"+params.GetString("HotspotNumber"));
}
