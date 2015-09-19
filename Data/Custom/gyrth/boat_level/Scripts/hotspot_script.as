	Object@ this_hotspot = ReadObjectFromID(hotspot.GetID());
	int obj_id = CreateObject("Data/Custom/gyrth/boat_level/Objects/rat_actor.xml");
	int boat_id = CreateObject("Data/Custom/gyrth/boat_level/Objects/boat.xml");
	Object@ rat_obj = ReadObjectFromID(obj_id);
	Object@ boat_obj = ReadObjectFromID(boat_id);
	MovementObject@ char = ReadCharacterID(obj_id);
void Init() {
	rat_obj.SetTranslation(this_hotspot.GetTranslation());
	boat_obj.SetTranslation(this_hotspot.GetTranslation());
	array<int> @nav_points = GetObjectIDsType(33);
	int numberOfWaypoints = nav_points.size();
	if(numberOfWaypoints != 0){
		Object @firstNavPoint = ReadObjectFromID(nav_points[0]);
		Print("Connecting " + obj_id + " to " + nav_points[0] + "\n");
		firstNavPoint.ConnectTo(rat_obj);
	}
	//char.rigged_object().SetCharScale(0.1);
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

void Update() {
    mat4 transform = char.rigged_object().GetAvgIKChainTransform("torso");
	mat4 torso_vec = transform.GetRotationPart();
	//Print("ObjID: "+ "" + " BoatID:" + boat_id +"\n");
	this_hotspot.SetTranslation(rat_obj.GetTranslation());
	boat_obj.SetTranslation(vec3(char.position.x, char.position.y + 4.0f, char.position.z));
	//boat_obj.SetRotation(transform);
}