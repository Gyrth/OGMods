Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
int firstClawID = -1;
int secondClawID = -1;
int victimID = -1;
bool activated = false;

void Init() {
    firstClawID = CreateObject("Data/Objects/bear_claw.xml");
    secondClawID = CreateObject("Data/Objects/bear_claw.xml");
}

void Reset(){
    victimID = -1;
    activated = false;
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
    DebugText("a", "Text", _fade);
    if(activated == false){
        string ragdollType = "_RGDL_INJURED";
        mo.Execute("HandleRagdollImpactImpulse(vec3(0), this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 1.0f);");
        mo.rigged_object().SetRagdollStrength(1.0f);
        victimID = mo.GetID();
        activated = true;
    }
}

void Update(){
    if(ObjectExists(firstClawID) && ObjectExists(secondClawID)){
        //When the trap is triggered the ID is no longer -1.
        if(victimID != -1){
            MovementObject@ currentChar = ReadCharacterID(victimID);
            Object@ charObj = ReadObjectFromID(currentChar.GetID());
            Object@ firstClawObj = ReadObjectFromID(firstClawID);
            Object@ secondClawObj = ReadObjectFromID(secondClawID);

        }else{

            Object@ firstClawObj = ReadObjectFromID(firstClawID);
            Object@ secondClawObj = ReadObjectFromID(secondClawID);

            

            firstClawObj.SetTranslation(thisHotspot.GetTranslation());
            secondClawObj.SetTranslation(thisHotspot.GetTranslation());
            quaternion hotspotRotation = thisHotspot.GetRotation();
            quaternion newRot = invert(hotspotRotation);


            firstClawObj.SetRotation(newRot);
            secondClawObj.SetRotation(thisHotspot.GetRotation());
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