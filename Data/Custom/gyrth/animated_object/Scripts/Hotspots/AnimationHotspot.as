array<int> placeholderIDs;
int previousPathpointID = -1;
int objectID = -1;
vec3 unnoticableOffset = vec3(0.01f,0.01f,0.01f);

int currentPathPointIndex = 0;

Object@ mainHotspot = ReadObjectFromID(hotspot.GetID());
bool postInitDone = false;
bool animationDone = false;
string modelPath;
string objectPath;

void Init() {
}

void SetParameters() {
    params.AddInt("Number of Keys", 2);
    params.AddIntCheckbox("Loop", false);
    params.AddIntCheckbox("Running", false);
    params.AddFloatSlider("Speed",0.01f,"min:0.001,max:0.1,step:0.001,text_mult:1000");
    params.AddString("Object Path", "Data/Objects/Buildings/Door1.xml");
    //Unfortunately I can not get the model path from the xml file via scripting.
    //So the model needs to be declared seperatly.
    params.AddString("Model Path", "Data/Models/Buildings/Door1.obj");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
        //Once the user steps into the hotspot the animation will start.
        params.SetInt("Running", 1);
    }
}

void Reset(){
    currentPathPointIndex = 0;
    params.SetInt("Running", 0);
    animationDone = false;
    Object@ object = ReadObjectFromID(objectID);
    object.SetTranslation(ReadObjectFromID(placeholderIDs[currentPathPointIndex]).GetTranslation() + unnoticableOffset);
    object.SetRotation(ReadObjectFromID(placeholderIDs[currentPathPointIndex]).GetRotation());
    //Once the level is reset the new paths will be used.
    modelPath = params.GetString("Model Path");
    if(objectPath != params.GetString("Object Path")){
        DeleteObjectID(objectID);
        objectPath = params.GetString("Object Path");
        objectID = CreateObject(objectPath);
    }
}

void Update(){
	if(postInitDone == true){
        //Create more placeholders if there aren't enough in the scene.
        if(placeholderIDs.size() < uint32(params.GetFloat("Number of Keys"))){
            CreatePathpoint();
        }else if(placeholderIDs.size() > uint32(params.GetFloat("Number of Keys"))){
            DeleteObjectID(placeholderIDs[placeholderIDs.size() - 1]);
            placeholderIDs.removeLast();
        }
        if(params.GetInt("Running") == 1 && animationDone == false || params.GetInt("Running") == 1 && params.GetInt("Loop") == 1){

            Object@ object = ReadObjectFromID(objectID);
            vec3 nextPathpointPos = ReadObjectFromID(placeholderIDs[currentPathPointIndex]).GetTranslation();
            vec3 currentPos = object.GetTranslation();

            if(distance(nextPathpointPos + unnoticableOffset, currentPos) < params.GetFloat("Speed")){
                previousPathpointID = placeholderIDs[currentPathPointIndex];
                currentPathPointIndex++;

                int numPathpoints = placeholderIDs.size();
                if(currentPathPointIndex >= numPathpoints){

                    if(params.GetInt("Loop") == 0){

                        params.SetInt("Running", 0);
                        animationDone = true;
                    }else{
                        animationDone = false;
                    }
                    currentPathPointIndex = 0;
                }
                Object@ nextPathpoint = ReadObjectFromID(placeholderIDs[currentPathPointIndex]);
                ScriptParams@ paramsNextPathpoint = nextPathpoint.GetScriptParams();
                if(paramsNextPathpoint.HasParam("Playsound")){
                    if(paramsNextPathpoint.GetString("Playsound") != ""){
                        PlaySound(paramsNextPathpoint.GetString("Playsound"), nextPathpoint.GetTranslation());
                    }
                }
            }
            if(params.GetInt("Running") == 1){
                if(previousPathpointID != -1){
                    //Position
                    vec3 tempvec = ((nextPathpointPos + unnoticableOffset) - currentPos);
                    vec3 direction = normalize(tempvec);
                    vec3 newPos = currentPos + (direction*params.GetFloat("Speed"));
                    object.SetTranslation(newPos);

                    //Rotation
                    Object@ currentPathpoint = ReadObjectFromID(placeholderIDs[currentPathPointIndex]);
                    Object@ previousPathpoint = ReadObjectFromID(previousPathpointID);
                    float curPathpointPos = distance(currentPathpoint.GetTranslation(), object.GetTranslation());
                    float prevPathpointPos = distance(previousPathpoint.GetTranslation(), object.GetTranslation());
                    float totalDistance = curPathpointPos + prevPathpointPos;
                    float prevCounts = (1.0f * prevPathpointPos)/totalDistance;
                    float curCounts = (1.0f * curPathpointPos)/totalDistance;
                    quaternion newRotation;
                    newRotation.x = (currentPathpoint.GetRotation().x * prevCounts) + (previousPathpoint.GetRotation().x * curCounts);
                    newRotation.y = (currentPathpoint.GetRotation().y * prevCounts) + (previousPathpoint.GetRotation().y * curCounts);
                    newRotation.z = (currentPathpoint.GetRotation().z * prevCounts) + (previousPathpoint.GetRotation().z * curCounts);
                    newRotation.w = (currentPathpoint.GetRotation().w * prevCounts) + (previousPathpoint.GetRotation().w * curCounts);
                    object.SetRotation(newRotation);
                }
                
            }
        }else if(params.GetInt("Running") == 0 && animationDone == false){
            //animationDone = false;
            if(placeholderIDs.size() > 0){
                Object@ firstPathpoint = ReadObjectFromID(placeholderIDs[0]);
                Object@ mainObject = ReadObjectFromID(objectID);
                mainObject.SetTranslation(firstPathpoint.GetTranslation() + unnoticableOffset);
                mainObject.SetRotation(firstPathpoint.GetRotation());
                currentPathPointIndex = 0;
            }

        }
        if(GetPlayerCharacterID() == -1){
            SetPlaceholderPreviews();
        }
	}else{
        PostInit();
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

void PostInit(){

    //The paths need to be stored in a variable because it will cause an invalid path error when the user is editing the path.
    modelPath = params.GetString("Model Path");
    objectPath = params.GetString("Object Path");
    
    //When the level first loads, there might already be animations setup
    //So those are retrieved first. With the ID of this hotspot as identifier.
    array<int> allObjects = GetObjectIDs();
    for(uint32 i = 0; i<allObjects.size(); i++){
        ScriptParams@ tempParam = ReadObjectFromID(allObjects[i]).GetScriptParams();
        if(tempParam.HasParam("BelongsTo")){
            if(tempParam.GetInt("BelongsTo") == hotspot.GetID()){
                if(tempParam.GetString("Name") == "animation_key"){
                    //These are the pathpoints that the object will follow.
                    placeholderIDs.insertLast(allObjects[i]);
                }
            }
        }
    }
    //

    objectID = CreateObject(objectPath);
    Object@ mainObject = ReadObjectFromID(objectID);
    ScriptParams@ mainObjectParam = mainObject.GetScriptParams();
    mainObjectParam.AddIntCheckbox("No Save", true);
    mainObjectParam.AddString("Name", "animation_object");
    mainObjectParam.AddInt("BelongsTo", hotspot.GetID());
    mainObject.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
    


    postInitDone = true;
}

void SetPlaceholderPreviews() {
    int numPlaceHolders = placeholderIDs.length();
    vec3 previousPos;
    for(int i=0; i<numPlaceHolders; ++i){
        if(ObjectExists(placeholderIDs[i])){
            Object @obj = ReadObjectFromID(placeholderIDs[i]);
            SetObjectPreview(obj,objectPath);
            if(i>0){
                //Every pathpoint needs to be connected with a line to show the animation path.
                DebugDrawLine(obj.GetTranslation(), previousPos, vec3(0.5f), _delete_on_update);
            }else{
                //If it's the first pathpoint a line needs to be draw to the main hotspot.
                DebugDrawLine(mainHotspot.GetTranslation(), obj.GetTranslation(), vec3(0.5f), _delete_on_update);
            }
            previousPos = obj.GetTranslation();
        }else{
            placeholderIDs.removeAt(i);
        }
    }
}

void SetObjectPreview(Object@ spawn, string &in path){
    mat4 objectInformation;
    objectInformation.SetTranslationPart(spawn.GetTranslation() + unnoticableOffset);
    mat4 rotation = Mat4FromQuaternion(spawn.GetRotation());
    objectInformation.SetRotationPart(rotation);
    //The mesh is previewed on the pathpoint to show where the animation object will be.
    DebugDrawWireMesh(modelPath, objectInformation, vec4(0.5f), _delete_on_update);
}

void CreatePathpoint(){
    int objID = CreateObject("Data/Custom/gyrth/animated_object/Objects/Placeholder.xml");
    Print(objID + "Creating new pathpoint\n");
    placeholderIDs.push_back(objID);
    Object @newObj = ReadObjectFromID(objID);

    ScriptParams@ placeholderParams = newObj.GetScriptParams();
    //When a new pathpoint is created the hotspot ID is added to it's parameters.
    //This will be used when the level is closed and loaded again.
    placeholderParams.AddInt("BelongsTo", hotspot.GetID());
    placeholderParams.AddString("Playsound", "");
    newObj.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
}