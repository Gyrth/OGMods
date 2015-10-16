Object@ movingPlatformHotspot = ReadObjectFromID(hotspot.GetID());
int objID;
int pathpointID;
array<int> pathPointIDs;
int currentPathPointIndex = 0;
float time = 0.0f;
int navpointTypeID = 33;
int objectTypeID = 20;
bool postInitDone = false;
bool gettingPathpoints = false;
string currentPlatformPath;

void Init() {

}

void Reset(){
    //While the new settings and objects are fetched the update loop should skip the loop to avoid null references. 
    gettingPathpoints = true;
    //If the platform path has changed, the old object is removed and the new one is spawned.
    if(params.GetString("PlatformPath") != currentPlatformPath){
        DeleteObjectID(objID);
        AfterInit();
        currentPlatformPath = params.GetString("PlatformPath");
    }

    Object@ platformObj = ReadObjectFromID(objID);
    //Put the platform object on the position of the hotspot, it's starting point.
    platformObj.SetTranslation(movingPlatformHotspot.GetTranslation());
    //Resizing the array to 0 will remove every item in it.
    pathPointIDs.resize(0);
    //Resursively get every pathpoint connected to the first that this script created.
    GetNeighbours(pathpointID, pathPointIDs, pathPointIDs);

    int numPathpoints = pathPointIDs.size();
    //Start at the first pathpoint.
    currentPathPointIndex = 0;
    Print("Number of pathpoint ids: " + numPathpoints + "\n");
    gettingPathpoints = false;
}

void SetParameters() {
    params.AddIntCheckbox("ShowDebug", false);
    params.AddFloat("PlatformSpeed", 0.01f);
    params.AddString("PlatformPath", "Data/Objects/Crete/hex_crete_half.xml");
    params.AddFloat("GravitySphereSize", 5.00f);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {

}
void Update(){
    time += time_step;
    if(postInitDone == true){
        if(gettingPathpoints == false){
            
            Object@ pathpointObj = ReadObjectFromID(pathpointID);
            Object@ platformObj = ReadObjectFromID(objID);
            vec3 nextPathpointPos = ReadObjectFromID(pathPointIDs[currentPathPointIndex]).GetTranslation();
            vec3 currentPos = platformObj.GetTranslation();

            if(distance(nextPathpointPos, currentPos) < 0.1f){
                currentPathPointIndex++;
                int numPathpoints = pathPointIDs.size();
                if(currentPathPointIndex >= numPathpoints){
                    currentPathPointIndex = 0;
                }
            }
            vec3 direction = normalize(nextPathpointPos - currentPos);
            vec3 newPos = currentPos + (direction*params.GetFloat("PlatformSpeed"));
            platformObj.SetTranslation(newPos);
            array<int> nearbyCharacters;
            //Every character in the sphere will move with the platform. This will make velocity relative to the platform.
            GetCharactersInSphere(currentPos, params.GetFloat("GravitySphereSize"), nearbyCharacters);
            if(params.GetInt("ShowDebug") == 1){
                DebugDrawWireSphere(currentPos, params.GetFloat("GravitySphereSize"), vec3(255,255,255), _delete_on_update);
            }
            int numChars = nearbyCharacters.size();
            for(int i=0; i<numChars; ++i){
                MovementObject@ tempChar = ReadCharacterID(nearbyCharacters[i]);
                tempChar.position += direction*params.GetFloat("PlatformSpeed");
            }
            if(GetPlayerCharacterID() == -1){
                DebugDrawLine(movingPlatformHotspot.GetTranslation(), pathpointObj.GetTranslation(), vec3(0.0f,1.0f,1.0f), _delete_on_update);
            }
        }
    }else{
        AfterInit();
    }
}

void OnExit(MovementObject @mo) {

}

int GetPlayerCharacterID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return i;
        }
    }
    return -1;
}

void GetNeighbours(int startingPoint, array<int> &out groupOut, array<int> &in groupIn){
    groupOut = groupIn;

    PathPointObject@ currentPathpoint = cast<PathPointObject>(ReadObjectFromID(startingPoint));
    int numConnections = currentPathpoint.NumConnectionIDs();

    groupOut.insertLast(startingPoint);

    for(int i = 0; i<numConnections;i++){

        if(groupOut.find(currentPathpoint.GetConnectionID(i)) == -1){

            GetNeighbours(currentPathpoint.GetConnectionID(i), groupOut, groupOut);
        }
    }

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

void AfterInit(){
    //The AfterInit function is nessesary because the Init function does not have access to the Objects in the scene yet.
    //There might already be objects in the scene so retrieve those first.
    pathpointID = RetrieveSavedObject(navpointTypeID);
    objID = RetrieveSavedObject(objectTypeID);

    if(pathpointID == -1){
        //If those do not exist then make a new pathpoint and platform object.
        Print("Spawning new pathpoint\n");
        pathpointID = CreateObject("Data/Objects/pathpoint/pathpoint.xml");
        Object@ pathpointObj = ReadObjectFromID(pathpointID);
        ScriptParams@ pathpointParams = pathpointObj.GetScriptParams();
        pathpointParams.SetInt("BelongsTo", hotspot.GetID());
        pathpointParams.SetInt("ID", pathpointID);
        pathpointObj.SetTranslation(movingPlatformHotspot.GetTranslation());
    }
    if(objID == -1){
        objID = CreateObject(params.GetString("PlatformPath"));
        Print("Creating new Platform\n");
        Object@ platformObj = ReadObjectFromID(objID);
        ScriptParams@ platformParams = platformObj.GetScriptParams();
        platformParams.SetInt("BelongsTo", hotspot.GetID());
        platformObj.SetTranslation(movingPlatformHotspot.GetTranslation());
    }
    currentPlatformPath = params.GetString("PlatformPath");
    GetNeighbours(pathpointID, pathPointIDs, pathPointIDs);
    int numPathpoints = pathPointIDs.size();

    postInitDone = true;
}