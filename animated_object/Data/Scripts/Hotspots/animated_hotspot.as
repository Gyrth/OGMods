array<int> placeholderIDs;
int previousPathpointID = -1;
int objectID = -1;
vec3 unnoticableOffset = vec3(0.01f,0.01f,0.01f);

int index = 0;

Object@ mainHotspot = ReadObjectFromID(hotspot.GetID());
bool postInitDone = false;
bool done = false;
bool reverse = false;
bool playing = false;
bool looping = false;
bool on_enter = false;
bool on_exit = false;
bool reverse_at_end = false;
bool mult_trigger = false;
string modelPath;
string objectPath;

enum PlayMode{
  KLoopForward = 0,
  KLoopBackward = 1,
  KOnEnterLoopForwardAndBackward = 2,
  KOnEnterSingleForward = 3,
  KOnEnterForwardAndBackward = 4,
  KOnEnterForwardOnExitBackward = 5,
  KOnEnterLoopForward = 6,
  KOnEnterLoopBackward = 7,
}

PlayMode current_mode = KOnEnterSingleForward;

void Init() {
}

void SetParameters() {
  params.AddInt("Play mode", current_mode);
  params.AddInt("Number of Keys", 2);
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
  if(mo.controlled && on_enter && !playing){
    //Once the user steps into the hotspot the animation will start.
    playing = true;
  }
}

void OnExit(MovementObject @mo) {
  if(mo.controlled && on_exit){
    if(playing && !reverse || !playing && reverse){
      playing = true;
      reverse = true;
    }
  }
}

void Reset(){
    if(placeholderIDs.size() < 1 || objectID == -1){
      return;
    }
    index = 0;
    UpdatePlayMode(true);
    done = false;
    Object@ object = ReadObjectFromID(objectID);
    if(!ObjectExists(placeholderIDs[index])){
        return;
    }
    object.SetTranslation(ReadObjectFromID(placeholderIDs[index]).GetTranslation() + unnoticableOffset);
    object.SetRotation(ReadObjectFromID(placeholderIDs[index]).GetRotation());
    //Once the level is reset the new paths will be used.
    modelPath = params.GetString("Model Path");
    if(objectPath != params.GetString("Object Path")){
        DeleteObjectID(objectID);
        objectPath = params.GetString("Object Path");
        objectID = CreateObject(objectPath);
    }
}

void Update(){
  PostInit();
  if(!ObjectExists(objectID)){
    CreateMainAnimationObject();
    return;
  }
  UpdatePlayMode();
  UpdatePlaceholders();
  if(playing && done == false || playing && looping && !on_enter){
      Object@ object = ReadObjectFromID(objectID);
      //If the current pathpoint got deleted just reset.
      if((placeholderIDs.size() - 1) < uint(index) || !ObjectExists(placeholderIDs[index])){
          Reset();
          return;
      }
      vec3 nextPathpointPos = ReadObjectFromID(placeholderIDs[index]).GetTranslation();
      vec3 currentPos = object.GetTranslation();
      if(distance(nextPathpointPos + unnoticableOffset, currentPos) < params.GetFloat("Speed")){
          previousPathpointID = placeholderIDs[index];
          if(reverse){
            index--;
          }else{
            index++;
          }
          int numPathpoints = placeholderIDs.size();
          if(index >= numPathpoints){
            if(!looping){
              if(reverse_at_end){
                index--;
                if(on_exit){
                  reverse = true;
                  playing = false;
                  done = false;
                  return;
                }else{
                  reverse = !reverse;
                  return;
                }
              }else{
                playing = false;
                if(mult_trigger){
                  index = 0;
                  done = false;
                  UpdatePlayMode(true);
                  return;
                }else{
                  done = true;
                }
              }
            }else{
              done = false;
              if(reverse_at_end){
                reverse = !reverse;
                index--;
                return;
              }
            }
            index = 0;
          }else if(index < 0){
            if(!looping){
              playing = false;
              if(mult_trigger){
                index = 0;
                done = false;
                UpdatePlayMode(true);
                return;
              }
            }else{
              done = false;
              if(reverse_at_end){
                reverse = !reverse;
                index++;
                return;
              }
            }
            index = (numPathpoints-1);
          }
          Object@ nextPathpoint = ReadObjectFromID(placeholderIDs[index]);
          ScriptParams@ paramsNextPathpoint = nextPathpoint.GetScriptParams();
          if(paramsNextPathpoint.HasParam("Playsound")){
            if(paramsNextPathpoint.GetString("Playsound") != ""){
              PlaySound(paramsNextPathpoint.GetString("Playsound"), nextPathpoint.GetTranslation());
            }
          }
      }
      if(playing){
        if(previousPathpointID != -1){
          //Position
          vec3 tempvec = ((nextPathpointPos + unnoticableOffset) - currentPos);
          vec3 direction = normalize(tempvec);
          vec3 newPos = currentPos + (direction*params.GetFloat("Speed"));
          object.SetTranslation(newPos);
          //Rotation
          if(!ObjectExists(previousPathpointID) || !ObjectExists(placeholderIDs[index])){
            Reset();
            return;
          }
          Object@ currentPathpoint = ReadObjectFromID(placeholderIDs[index]);
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
  }
  if(!playing && done == false && EditorModeActive()){
    if(placeholderIDs.size() > 0){
      Object@ firstPathpoint = ReadObjectFromID(placeholderIDs[0]);
      Object@ mainObject = ReadObjectFromID(objectID);
      mainObject.SetTranslation(firstPathpoint.GetTranslation() + unnoticableOffset);
      mainObject.SetRotation(firstPathpoint.GetRotation());
      index = 0;
    }
  }
}

void UpdatePlaceholders(){
  //Create more placeholders if there aren't enough in the scene.
  if(placeholderIDs.size() < uint32(params.GetFloat("Number of Keys"))){
    CreatePathpoint();
    WritePlaceholderIndexes();
  }else if(placeholderIDs.size() > uint32(params.GetFloat("Number of Keys"))){
    DeleteObjectID(placeholderIDs[placeholderIDs.size() - 1]);
    placeholderIDs.removeLast();
    WritePlaceholderIndexes();
  }
  SetPlaceholderPreviews();
}

void UpdatePlayMode(bool ignore_editormode = false){
  if(current_mode != PlayMode(params.GetInt("Play mode")) && !ignore_editormode){
    Reset();
  }
  if(EditorModeActive() || ignore_editormode){
    current_mode = PlayMode(params.GetInt("Play mode"));
    switch(current_mode){
      case KLoopForward :
        playing = true;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = false;
        reverse = false;
        reverse_at_end = false;
        break;
      case KLoopBackward :
        playing = true;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = false;
        reverse = true;
        reverse_at_end = false;
        break;
      case KOnEnterLoopForwardAndBackward :
        playing = false;
        looping = true;
        mult_trigger = true;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case KOnEnterSingleForward :
        playing = false;
        looping = false;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = false;
        break;
      case KOnEnterForwardAndBackward :
        playing = false;
        looping = false;
        mult_trigger = true;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case KOnEnterForwardOnExitBackward :
        playing = false;
        looping = false;
        mult_trigger = true;
        on_exit = true;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case KOnEnterLoopForward :
        playing = false;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = false;
        break;
      case KOnEnterLoopBackward :
        playing = false;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = true;
        reverse_at_end = false;
        break;
      default :
        params.SetInt("Play mode", PlayMode(0));
        current_mode = PlayMode(0);
        break;
    }
  }
}

void PostInit(){
  if(postInitDone){
    return;
  }
  //The paths need to be stored in a variable because it will cause an invalid path error when the user is editing the path.
  modelPath = params.GetString("Model Path");
  objectPath = params.GetString("Object Path");
  //When the level first loads, there might already be animations setup
  //So those are retrieved first. With the ID of this hotspot as identifier.
  array<int> allObjects = GetObjectIDs();
  array<int> found_placeholders;
  for(uint32 i = 0; i<allObjects.size(); i++){
      ScriptParams@ tempParam = ReadObjectFromID(allObjects[i]).GetScriptParams();
      if(tempParam.HasParam("BelongsTo")){
          if(tempParam.GetInt("BelongsTo") == hotspot.GetID()){
              if(tempParam.GetString("Name") == "animation_key"){
                  //These are the pathpoints that the object will follow.
                  found_placeholders.insertLast(allObjects[i]);
              }
          }
      }
  }
  placeholderIDs.resize(found_placeholders.size());
  //Now put the placeholders back in order.
  for(uint i = 0; i < found_placeholders.size(); i++){
    ScriptParams@ placeholder_params = ReadObjectFromID(found_placeholders[i]).GetScriptParams();
    if(placeholder_params.HasParam("Index")){
      placeholderIDs[placeholder_params.GetInt("Index")] = found_placeholders[i];
    }
  }
  Print("Num placeholders " + placeholderIDs.size() + "\n");
  postInitDone = true;
}

void SetPlaceholderPreviews() {
    if(!EditorModeActive()){
      return;
    }
    vec3 previousPos;
    for(uint i = 0; i < uint(placeholderIDs.length()); ++i){
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
  int objID = CreateObject("Data/Objects/placeholder.xml", false);
  placeholderIDs.push_back(objID);
  Object @newObj = ReadObjectFromID(objID);
  newObj.SetSelectable(true);
  newObj.SetTranslatable(true);
  newObj.SetRotatable(true);
  newObj.SetScalable(false);

  ScriptParams@ placeholderParams = newObj.GetScriptParams();
  //When a new pathpoint is created the hotspot ID is added to it's parameters.
  //This will be used when the level is closed and loaded again.
  placeholderParams.AddInt("BelongsTo", hotspot.GetID());
  placeholderParams.AddString("Playsound", "");
  newObj.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
}

void CreateMainAnimationObject(){
  objectID = CreateObject(objectPath);
  Print("Create main object " + objectID + "\n");
  Object@ mainObject = ReadObjectFromID(objectID);
  mainObject.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
}

void WritePlaceholderIndexes(){
  for(uint i = 0; i < placeholderIDs.size(); i++){
    if(!ObjectExists(placeholderIDs[i])){
        return;
    }
    Object@ placeholder = ReadObjectFromID(placeholderIDs[i]);
    ScriptParams@ placeholder_params = placeholder.GetScriptParams();
    placeholder_params.SetInt("Index", i);
  }
}

void Dispose(){
  for(uint i = 0; i < placeholderIDs.size(); i++){
    DeleteObjectID(placeholderIDs[i]);
  }
  DeleteObjectID(objectID);
}
