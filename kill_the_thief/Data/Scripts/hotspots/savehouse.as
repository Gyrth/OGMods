void Init() {
}
void SetParameters() {
	params.AddString("Name", "savehouse");
	params.AddInt("ThiefID", -1);
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
	Print("Character entered with id: " + mo.GetID() + "\n");
	if(mo.GetID() == params.GetInt("ThiefID")){

		level.SendMessage("thiefsave");
	}
}
void OnExit(MovementObject @mo) {

}