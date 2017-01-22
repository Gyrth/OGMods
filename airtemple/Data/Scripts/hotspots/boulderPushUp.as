void Init() {
}

void SetParameters() {
}
void HandleEventItem(string event, ItemObject @obj){
    //Print("ITEMOBJECT EVENT: "+event+"\n");
    if(event == "enter"){
        OnEnterItem(obj);
    }
    if(event == "exit"){
        OnExitItem(obj);
    }
}

void OnEnterItem(ItemObject @obj) {
	if(obj.GetType() == _collectable){
		vec3 vel(0.0f,15.5f,0.0f);
		obj.SetLinearVelocity(vel);
	}
}

void OnExitItem(ItemObject @obj) {
}
