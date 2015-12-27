Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
int triggerStoneID;
int ropeObjID;
int victimID = -1;
int harpoonID;
int spawnHotspotID = -1;
bool activated = false;

void Init() {
    spawnHotspotID = CreateObject("Data/Objects/placeholder/empty_placeholder.xml");
    triggerStoneID = CreateObject("Data/Objects/Crete/CreteBlockStandard.xml");
    Object@ triggerStoneObj = ReadObjectFromID(triggerStoneID);
    triggerStoneObj.SetScale(0.1f);
    thisHotspot.SetScale(0.2f);

    vec3 hotspotPos = thisHotspot.GetTranslation();
    Object@ spawnHotspotObj = ReadObjectFromID(spawnHotspotID);
    spawnHotspotObj.SetTranslation(vec3(hotspotPos.x, hotspotPos.y + 1.0f, hotspotPos.z));
}

void Reset(){
    victimID = -1;
    DeleteObjectID(harpoonID);
    DeleteObjectID(ropeObjID);
    activated = false;
}

void SetParameters() {
    params.AddFloatSlider("Pull Speed",1,"min:0,max:10,step:0.1,text_mult:100");
    params.AddIntCheckbox("Left Leg", true);
    params.AddIntCheckbox("Right Leg", true);
    params.AddIntCheckbox("Left Arm", false);
    params.AddIntCheckbox("Right Arm", false);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(activated == false){

        harpoonID = CreateObject("Data/Items/StandardArrow.xml");
        ropeObjID = CreateObject("Data/Objects/rope.xml");
        Object@ harpoonObj = ReadObjectFromID(harpoonID);
        Object@ spawnHotspotObj = ReadObjectFromID(spawnHotspotID);
        Object@ triggerStoneObj = ReadObjectFromID(triggerStoneID);

        harpoonObj.SetTranslation(spawnHotspotObj.GetTranslation());
        vec3 hotspotPos = thisHotspot.GetTranslation();
        triggerStoneObj.SetTranslation(vec3(hotspotPos.x, hotspotPos.y - 0.1f, hotspotPos.z));
        quaternion rot;
        vec3 dir = harpoonObj.GetRotation() * vec3(0,-1,0);

        vec3 torso_pos = mo.rigged_object().GetAvgIKChainPos("head");

        GetRotationBetweenVectors(dir, spawnHotspotObj.GetTranslation() - torso_pos, rot);
        
        
        harpoonObj.SetRotation(rot);
        vec3 direction = normalize(torso_pos - spawnHotspotObj.GetTranslation());
        ItemObject@ harpoonItem = ReadItemID(harpoonID);
        harpoonItem.SetLinearVelocity(direction * 50.0f);


        activated = true;
    }
}

void Update(){
    if(ObjectExists(harpoonID) && activated && ObjectExists(ropeObjID)){
        ItemObject@ harpoonItem = ReadItemID(harpoonID);
        Object@ spawnHotspotObj = ReadObjectFromID(spawnHotspotID);
        if(harpoonItem.StuckInWhom() != -1){
            MovementObject@ victim = ReadCharacterID(harpoonItem.StuckInWhom());
            victim.rigged_object().MoveRagdollPart("torso",spawnHotspotObj.GetTranslation(),10.0f);
            victim.rigged_object().MoveRagdollPart("head",spawnHotspotObj.GetTranslation(),10.0f);
            //victim.rigged_object().ApplyForceToRagdoll(100.0f, spawnHotspotObj.GetTranslation());
            victim.rigged_object().SetRagdollDamping(0.5f);
        }
        Object@ ropeObj = ReadObjectFromID(ropeObjID);
        vec3 harpoonPos = harpoonItem.GetPhysicsPosition();

        vec3 newPos = ((harpoonPos + spawnHotspotObj.GetTranslation())/2);
        ropeObj.SetTranslation(newPos);
        ropeObj.SetScale(vec3(1.0f, (distance(harpoonPos, spawnHotspotObj.GetTranslation()))/2, 1.0f));

        
        quaternion newRotation;
        vec3 normal = normalize(harpoonPos - spawnHotspotObj.GetTranslation());
        GetRotationBetweenVectors(vec3(0.0f, 1.0f, 0.0f), normal, newRotation);

        ropeObj.SetRotation(newRotation);
    }else{
            Object@ spawnHotspotObj = ReadObjectFromID(spawnHotspotID);
            Object@ triggerStoneObj = ReadObjectFromID(triggerStoneID);

            triggerStoneObj.SetTranslation(thisHotspot.GetTranslation());
            triggerStoneObj.SetRotation(thisHotspot.GetRotation());
        }

}

void OnExit(MovementObject @mo) {

}

int RetrieveSavedObject(int objectType){
    int returnID = -1;
    array<int> @objectIDs = GetObjectIDsType(objectType);
    int numObjects = objectIDs.size();
    for(int i = 0; i< numObjects;i++){

        Object @obj = ReadObjectFromID(objectIDs[i]);
        ScriptParams@ objectParams = obj.GetScriptParams();
        if(objectParams.HasParam("BelongsTo")){
            if(objectParams.GetInt("BelongsTo") == hotspot.GetID()){
                returnID = objectIDs[i];
            }
        }
    }
    return returnID;
}