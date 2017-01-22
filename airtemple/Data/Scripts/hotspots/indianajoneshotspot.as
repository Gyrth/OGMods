bool scriptHasRun = false;
void Init() {

}

void SetParameters() {
	params.AddString("ItemToDetect", "0");
	params.AddString("ItemToMove", "331");
}
void HandleEventItem(string event, ItemObject @obj){
    if(event == "enter"){
        OnEnterItem(obj);
    }
    if(event == "exit"){
        OnExitItem(obj);
    }
}

void OnEnterItem(ItemObject @obj) {
}

void OnExitItem(ItemObject @obj) {
	//Print("Leaving: "+obj+"\n");
	if(scriptHasRun == false && (obj.GetID() == 181)) {
		scriptHasRun = true;
		level.SendMessage("indimov"+params.GetString("ItemToMove")+"dn"+params.GetString("ItemToDetect"));
	}
}
