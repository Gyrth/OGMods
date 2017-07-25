array<int> node_ids;
int prev_node_id = -1;
int objectID = -1;
vec3 small_offset = vec3(0.01f,0.01f,0.01f);
int index = 0;
Object@ main_hotspot = ReadObjectFromID(hotspot.GetID());
bool post_init_done = false;
bool done = false;
bool reverse = false;
bool playing = false;
bool looping = false;
bool on_enter = false;
bool on_exit = false;
bool reverse_at_end = false;
bool mult_trigger = false;
string model_path;
string objectPath;
float node_timer = 0.0f;
bool next_pathpoint = true;

enum PlayMode{
  kLoopForward = 0,
  kLoopBackward = 1,
  kOnEnterLoopForwardAndBackward = 2,
  kOnEnterSingleForward = 3,
  kOnEnterForwardAndBackward = 4,
  kOnEnterForwardOnExitBackward = 5,
  kOnEnterLoopForward = 6,
  kOnEnterLoopBackward = 7,
}

float CalculateWholeDistance(){
  float whole = 0.0f;
  for(uint i = 1; i < node_ids.size(); i++){
    whole += distance(ReadObjectFromID(node_ids[i - 1]).GetTranslation(), ReadObjectFromID(node_ids[i]).GetTranslation());
  }
  //Add the distance between the fist and last node as well.
  whole += distance(ReadObjectFromID(node_ids[0]).GetTranslation(), ReadObjectFromID(node_ids[(node_ids.size() - 1)]).GetTranslation());
  return whole;
}

PlayMode current_mode;

void Init() {
}

void SetParameters() {
  params.AddInt("Play mode", 3);
  params.AddInt("Number of Keys", 2);
  params.AddFloatSlider("Seconds",1.0f,"min:0.1,max:10.0,step:1.0,text_mult:1");
  params.AddString("Object Path", "Data/Objects/Buildings/Door1.xml");
  params.AddIntCheckbox("Const time", true);
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
  if(mo.controlled && on_enter && !playing && !done){
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
    if(node_ids.size() < 2 || objectID == -1){
      return;
    }
    index = 0;
    prev_node_id = -1;
    next_pathpoint = true;
    node_timer = 0.0f;
    done = false;
    if(!ObjectExists(node_ids[index])){
      return;
    }
    //Once the level is reset the new paths will be used.
    model_path = params.GetString("Model Path");
    if(objectPath != params.GetString("Object Path")){
        DeleteObjectID(objectID);
        objectPath = params.GetString("Object Path");
        objectID = CreateObject(objectPath);
    }
    Object@ object = ReadObjectFromID(objectID);
    object.SetTranslation(ReadObjectFromID(node_ids[index]).GetTranslation());
    object.SetRotation(ReadObjectFromID(node_ids[index]).GetRotation());
}

bool CheckObjectsExist(){
  if(!ObjectExists(objectID)){
    CreateMainAnimationObject();
    Reset();
    return false;
  }

  if(index > (int(node_ids.size()) - 1) || !ObjectExists(node_ids[index])){
    Reset();
    return false;
  }
  if(!ObjectExists(node_ids[index])){
    Reset();
    return false;
  }
  if(prev_node_id != -1){
    if(!ObjectExists(prev_node_id)){
      prev_node_id = -1;
    }
  }
  return true;
}

void Update(){
  PostInit();
  UpdatePlayMode();
  UpdatePlaceholders();
  if(!CheckObjectsExist()){
    return;
  }
  if(playing && done == false || playing && looping && !on_enter){
      Object@ object = ReadObjectFromID(objectID);
      vec3 nextPathpointPos = ReadObjectFromID(node_ids[index]).GetTranslation();
      vec3 currentPos = object.GetTranslation();
      if(next_pathpoint){
          next_pathpoint = false;
          int prev_index = index;
          prev_node_id = node_ids[index];
          if(reverse){
            index--;
          }else{
            index++;
          }
          int numPathpoints = node_ids.size();
          if(index >= numPathpoints){
            if(!looping){
              if(reverse_at_end){
                index = index - 2;
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
                index = index - 2;
                return;
              }
            }
            index = 0;
          }else if(index < 0){
            if(!looping){
              playing = false;
              if(mult_trigger){
                index = 1;
                done = false;
                UpdatePlayMode(true);
                return;
              }
            }else{
              done = false;
              if(reverse_at_end){
                reverse = !reverse;
                index = index + 2;
                return;
              }
            }
            index = (numPathpoints-1);
          }
          PlayAvailableSound();
      }
  }
  UpdateTransform();
}

void UpdateTransform(){
  if(playing && prev_node_id != -1){
    node_timer += time_step;
    Object@ currentPathpoint = ReadObjectFromID(node_ids[index]);
    Object@ previousPathpoint = ReadObjectFromID(prev_node_id);
    Object@ object = ReadObjectFromID(objectID);

    if(params.GetInt("Const time") == 1){
      bool skip = false;
      //The animation will have a constant speed.
      float whole_distance = CalculateWholeDistance();
      if(whole_distance != 0.0f){
        float node_distance = distance(currentPathpoint.GetTranslation(), previousPathpoint.GetTranslation());
        if(node_distance != 0.0f){
          float node_time = params.GetFloat("Seconds") * (node_distance / whole_distance);
          //Position
          float alpha = node_timer / node_time;
          vec3 new_position = mix(previousPathpoint.GetTranslation(), currentPathpoint.GetTranslation(), alpha);
          object.SetTranslation(new_position);
          //Rotation
          quaternion relative = mix(previousPathpoint.GetRotation(), currentPathpoint.GetRotation(), alpha);
          object.SetRotation(relative);
          if(alpha >= 1.0f){
            next_pathpoint = true;
            node_timer = 0.0f;
          }
        }else{
          skip = true;
        }
      }else{
        skip = true;
      }
      if(skip){
        object.SetTranslation(currentPathpoint.GetTranslation());
        object.SetRotation(currentPathpoint.GetRotation());
        next_pathpoint = true;
        node_timer = 0.0f;
      }
    }else{
      //The animation will devide the time between the animation keys.
      float node_time = params.GetFloat("Seconds") / node_ids.size();
      //Position
      float alpha = node_timer / node_time;
      vec3 new_position = mix(previousPathpoint.GetTranslation(), currentPathpoint.GetTranslation(), alpha);
      object.SetTranslation(new_position);
      //Rotation
      quaternion relative = mix(previousPathpoint.GetRotation(), currentPathpoint.GetRotation(), alpha);
      object.SetRotation(relative);
      if(alpha >= 1.0f){
        next_pathpoint = true;
        node_timer = 0.0f;
      }
    }
  }else if(done == false && EditorModeActive()){
    //If the animation is playing but no where to go, just stay at the first key.
    if(node_ids.size() > 0){
      Object@ firstPathpoint = ReadObjectFromID(node_ids[0]);
      Object@ mainObject = ReadObjectFromID(objectID);
      mainObject.SetTranslation(firstPathpoint.GetTranslation());
      mainObject.SetRotation(firstPathpoint.GetRotation());
      index = 0;
    }
  }
}

void PlayAvailableSound(){
  if(prev_node_id != -1){
    Object@ pathpoint = ReadObjectFromID(prev_node_id);
    ScriptParams@ param = pathpoint.GetScriptParams();
    if(param.HasParam("Playsound")){
      if(param.GetString("Playsound") != ""){
        PlaySound(param.GetString("Playsound"), pathpoint.GetTranslation());
      }
    }
  }
}

void UpdatePlaceholders(){
  //Create more placeholders if there aren't enough in the scene.
  if(node_ids.size() != uint(params.GetFloat("Number of Keys"))){
    if(node_ids.size() < uint(params.GetFloat("Number of Keys"))){
      CreatePathpoint();
      WritePlaceholderIndexes();
    }else if(node_ids.size() > uint32(params.GetFloat("Number of Keys"))){
      DeleteObjectID(node_ids[node_ids.size() - 1]);
      node_ids.removeLast();
      WritePlaceholderIndexes();
    }
    Reset();
  }
  SetPlaceholderPreviews();
}

void UpdatePlayMode(bool ignore_editormode = false){
  if(EditorModeActive() || ignore_editormode){
    if(current_mode != PlayMode(params.GetInt("Play mode")) && EditorModeActive()){
      Reset();
    }
    current_mode = PlayMode(params.GetInt("Play mode"));
    switch(current_mode){
      case kLoopForward :
        playing = true;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = false;
        reverse = false;
        reverse_at_end = false;
        break;
      case kLoopBackward :
        playing = true;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = false;
        reverse = true;
        reverse_at_end = false;
        break;
      case kOnEnterLoopForwardAndBackward :
        playing = false;
        looping = true;
        mult_trigger = true;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case kOnEnterSingleForward :
        playing = false;
        looping = false;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = false;
        break;
      case kOnEnterForwardAndBackward :
        playing = false;
        looping = false;
        mult_trigger = true;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case kOnEnterForwardOnExitBackward :
        playing = false;
        looping = false;
        mult_trigger = true;
        on_exit = true;
        on_enter = true;
        reverse = false;
        reverse_at_end = true;
        break;
      case kOnEnterLoopForward :
        playing = false;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = false;
        reverse_at_end = false;
        break;
      case kOnEnterLoopBackward :
        playing = false;
        looping = true;
        mult_trigger = false;
        on_exit = false;
        on_enter = true;
        reverse = true;
        reverse_at_end = false;
        break;
      default :
        params.SetInt("Play mode", kOnEnterSingleForward);
        current_mode = kOnEnterSingleForward;
        break;
    }
  }
}

void PostInit(){
  if(post_init_done){
    return;
  }
  current_mode = PlayMode(params.GetInt("Play mode"));
  //The paths need to be stored in a variable because it will cause an invalid path error when the user is editing the path.
  model_path = params.GetString("Model Path");
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
  node_ids.resize(found_placeholders.size());
  //Now put the placeholders back in order.
  for(uint i = 0; i < found_placeholders.size(); i++){
    ScriptParams@ placeholder_params = ReadObjectFromID(found_placeholders[i]).GetScriptParams();
    if(placeholder_params.HasParam("Index")){
      node_ids[placeholder_params.GetInt("Index")] = found_placeholders[i];
    }
  }
  UpdatePlayMode(true);
  post_init_done = true;
}

void SetPlaceholderPreviews() {
    if(!EditorModeActive()){
      return;
    }
    vec3 previousPos;
    for(uint i = 0; i < uint(node_ids.length()); ++i){
      if(ObjectExists(node_ids[i])){
        Object @obj = ReadObjectFromID(node_ids[i]);
        SetObjectPreview(obj,objectPath);
        if(i>0){
          //Every pathpoint needs to be connected with a line to show the animation path.
          DebugDrawLine(obj.GetTranslation(), previousPos, vec3(0.5f), _delete_on_update);
        }else{
          //If it's the first pathpoint a line needs to be draw to the main hotspot.
          DebugDrawLine(main_hotspot.GetTranslation(), obj.GetTranslation(), vec3(0.5f), _delete_on_update);
        }
        previousPos = obj.GetTranslation();
      }else{
        node_ids.removeAt(i);
      }
    }
}

void SetObjectPreview(Object@ spawn, string &in path){
  mat4 objectInformation;
  objectInformation.SetTranslationPart(spawn.GetTranslation());
  mat4 rotation = Mat4FromQuaternion(spawn.GetRotation());
  objectInformation.SetRotationPart(rotation);
  //The mesh is previewed on the pathpoint to show where the animation object will be.
  DebugDrawWireMesh(model_path, objectInformation, vec4(0.5f), _delete_on_update);
}

void CreatePathpoint(){
  int objID = CreateObject("Data/Objects/placeholder.xml", false);
  node_ids.push_back(objID);
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
  newObj.SetTranslation(main_hotspot.GetTranslation() + small_offset);
}

void CreateMainAnimationObject(){
  objectID = CreateObject(objectPath);
}

void WritePlaceholderIndexes(){
  for(uint i = 0; i < node_ids.size(); i++){
    if(!ObjectExists(node_ids[i])){
      return;
    }
    Object@ placeholder = ReadObjectFromID(node_ids[i]);
    ScriptParams@ placeholder_params = placeholder.GetScriptParams();
    placeholder_params.SetInt("Index", i);
  }
}

void Dispose(){
  for(uint i = 0; i < node_ids.size(); i++){
    DeleteObjectID(node_ids[i]);
  }
  DeleteObjectID(objectID);
}
