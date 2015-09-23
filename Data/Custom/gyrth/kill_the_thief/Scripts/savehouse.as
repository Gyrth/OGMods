void Init() {
}
void SetParameters() {

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

}
void OnExit(MovementObject @mo) {

}