Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
int stakeID;
int nooseObjID;
int firstRopePoint;
int ropeObject;
int victimID = -1;
int nooseItemID;
bool activated = false;

void Init() {
    firstRopePoint = CreateObject("Data/Objects/placeholder/empty_placeholder.xml");
    ropeObject = CreateObject("Data/Objects/rope.xml");
    nooseObjID = CreateObject("Data/Objects/noose.xml");
    stakeID = CreateObject("Data/Objects/stake.xml");
    thisHotspot.SetScale(0.5f);

    vec3 hotspotPos = thisHotspot.GetTranslation();
    Object@ firstRopePointObj = ReadObjectFromID(firstRopePoint);
    firstRopePointObj.SetTranslation(vec3(hotspotPos.x, hotspotPos.y + 1.0f, hotspotPos.z));
}

void Reset(){
    victimID = -1;
    DeleteObjectID(nooseItemID);
    nooseObjID = CreateObject("Data/Objects/noose.xml");
    activated = false;
}

void SetParameters() {
    params.AddFloatSlider("Pull Speed",1,"min:0,max:10,step:0.1,text_mult:100");
    params.AddIntCheckbox("Left Leg", true);
    params.AddIntCheckbox("Right Leg", true);
    params.AddIntCheckbox("Left Arm", true);
    params.AddIntCheckbox("Right Arm", true);
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
        string ragdollType = "_RGDL_INJURED";
        mo.Execute("HandleRagdollImpactImpulse(vec3(0), this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 1.0f);");
        mo.rigged_object().SetRagdollStrength(1.0f);
        victimID = mo.GetID();
        nooseItemID = CreateObject("Data/Items/noose_closed.xml");
        Object@ nooseObject = ReadObjectFromID(nooseItemID);
        Object@ charObj = ReadObjectFromID(victimID);
        charObj.AttachItem(nooseObject, _at_attachment, false);
        nooseObject.SetScale(vec3(0.5f, 0.5f,0.5f));
        DeleteObjectID(nooseObjID);
        activated = true;
    }
}

void Update(){
    if(ObjectExists(firstRopePoint) && ObjectExists(ropeObject)){
        //When the trap is triggered the ID is no longer -1.
        if(victimID != -1){
            MovementObject@ currentChar = ReadCharacterID(victimID);
            Object@ firstRopePointObj = ReadObjectFromID(firstRopePoint);
            Object@ charObj = ReadObjectFromID(currentChar.GetID());
            ItemObject@ nooseItem = ReadItemID(nooseItemID);
            //vec3 legPos = currentChar.rigged_object().GetIKTargetTransform("right_leg").GetTranslationPart();
            vec3 legPos = nooseItem.GetPhysicsPosition();
                
                vec3 ropeEndPos = firstRopePointObj.GetTranslation();

                if(params.GetInt("Left Leg") == 1){
                    currentChar.rigged_object().MoveRagdollPart("left_leg",ropeEndPos,0.0f);
                }
                if(params.GetInt("Right Leg") == 1){
                    currentChar.rigged_object().MoveRagdollPart("right_leg",ropeEndPos,0.0f);
                }
                if(params.GetInt("Left Arm") == 1){
                    currentChar.rigged_object().MoveRagdollPart("leftarm",ropeEndPos,0.0f);
                }
                if(params.GetInt("Right Arm") == 1){
                    currentChar.rigged_object().MoveRagdollPart("rightarm",ropeEndPos,0.0f);
                }
                
                currentChar.rigged_object().SetRagdollDamping(0.5f);
                Object@ ropeObj = ReadObjectFromID(ropeObject);

                vec3 newPos = ((legPos + firstRopePointObj.GetTranslation())/2);
                ropeObj.SetTranslation(newPos);
                ropeObj.SetScale(vec3(1.0f, (distance(legPos, firstRopePointObj.GetTranslation()))/2, 1.0f));

                
                quaternion newRotation;
                vec3 normal = normalize(legPos - firstRopePointObj.GetTranslation());
                GetRotationBetweenVectors(vec3(0.0f, 1.0f, 0.0f), normal, newRotation);

                ropeObj.SetRotation(newRotation);

        }else{
            Object@ firstRopePointObj = ReadObjectFromID(firstRopePoint);
            Object@ ropeObj = ReadObjectFromID(ropeObject);
            Object@ nooseObj = ReadObjectFromID(nooseObjID);
            Object@ stakeObj = ReadObjectFromID(stakeID);

            nooseObj.SetTranslation(thisHotspot.GetTranslation());
            nooseObj.SetRotation(thisHotspot.GetRotation());
            nooseObj.SetScale(vec3(1.0f));
            stakeObj.SetTranslation(thisHotspot.GetTranslation());
            stakeObj.SetRotation(thisHotspot.GetRotation());

            vec3 newPos = ((firstRopePointObj.GetTranslation() + thisHotspot.GetTranslation())/2);
            ropeObj.SetTranslation(newPos);
            ropeObj.SetScale(vec3(1.0f, (distance(firstRopePointObj.GetTranslation(), thisHotspot.GetTranslation()))/2, 1.0f));

            
            quaternion newRotation;
            vec3 normal = normalize(firstRopePointObj.GetTranslation() - thisHotspot.GetTranslation());
                    GetRotationBetweenVectors(vec3(0.0f, 1.0f, 0.0f), normal, newRotation);

            ropeObj.SetRotation(newRotation);
        }
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