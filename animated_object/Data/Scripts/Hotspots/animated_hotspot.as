array<int> node_ids;
int prev_node_id = -1;
int objectID = -1;
vec3 small_offset = vec3(0.01f,0.01f,0.01f);
vec3 connect_lines_color = vec3(0.0f,0.0f,1.0f);
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
array<int> children;
float pi = 3.14159265f;
string identifier;
bool retrieve_children = false;
bool rewrite_identifier = false;
bool wait = false;
int other_hotspot_id = -1;

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
    if(ui_time == 0.0f){
        //The level is loaded with an existing animation hotspot in it.
        retrieve_children = true;
    }else{
        //The hotspot is created while the game is running.
        array<int> all_objects = GetObjectIDs();
        int nr_with_ident = 0;
        other_hotspot_id = -1;
        if(params.HasParam("Identifier")){
            for(uint32 i = 0; i < all_objects.size(); i++){
                ScriptParams@ temp_params = ReadObjectFromID(all_objects[i]).GetScriptParams();
                if(temp_params.HasParam("Identifier")){
                    if(temp_params.GetString("Identifier") == params.GetString("Identifier")){
                        if(all_objects[i] != hotspot.GetID()){
                            other_hotspot_id = all_objects[i];
                        }
                        nr_with_ident++;
                    }
                }
            }
        }
        Print("Found nr_with_ident " + nr_with_ident + "\n");
        if(nr_with_ident == 0){
            Print("An empty animation hotspot is loaded\n");
            params.AddString("Identifier", GetUniqueIdentifier());
            SetParameters();
            CreateMainAnimationObject();
        }else if(nr_with_ident == 1){
            //The animation group is loaded via a group and this identifier is unique.
            /*RetrieveExistingAnimation();*/
            if(!GetInputDown(0, "z") && !GetInputDown(0, "lalt")){
                Print("Creating new main animation object " + objectPath + "\n");
                identifier = params.GetString("Identifier");
                SetParameters();
                CreateMainAnimationObject();
            }
            retrieve_children = true;
        }else if(nr_with_ident == 2){
            /*DisplayError("er", "Two with same id " + objectPath);*/
            //The anim is loaded as a group, and the identifier is already taken.
            identifier = params.GetString("Identifier");
            if(!GetInputDown(0, "z") && !GetInputDown(0, "lalt")){
                Print("Creating new main animation object " + objectPath + "\n");
                SetParameters();
                CreateMainAnimationObject();
            }
            AddRewritingLevelParam();
            wait = true;
        }else if(nr_with_ident > 2){
            DisplayError("Uuuuuuhhmmm", "There are more than 2 animation hotspots with the same identifier, how did you manage to do that?");
            /*CreateMainAnimationObject();*/
            /*rewrite_identifier = true;*/
        }
    }
    Print("retrive children " + retrieve_children + "\n");
}

void AddRewritingLevelParam(){
    ScriptParams@ level_params = level.GetScriptParams();
    if(level_params.HasParam("RewritingIdentifier")){
        level_params.SetString("RewritingIdentifier", level_params.GetString("RewritingIdentifier") + " " + identifier);
    }else{
        level_params.AddString("RewritingIdentifier", identifier);
    }
}

void RemoveRewriteLevelParam(){
    ScriptParams@ level_params = level.GetScriptParams();
    if(!level_params.HasParam("RewritingIdentifier")){
        return;
    }
    array<string> ids = level_params.GetString("RewritingIdentifier").split(" ");
    for(uint i = 0; i < ids.size(); i++){
        if(ids[i] == identifier){
            ids.removeAt(i);
            i--;
        }
    }
    if(ids.size() > 0){
        //Still some identifiers left to rewrite.
        string new_param = join(ids, " ");
        level_params.SetString("RewritingIdentifier", new_param);
    }else{
        //No animation identifiers left to rewrite.
        level_params.Remove("RewritingIdentifier");
    }
}

void PostInit(){
    if(post_init_done){
        return;
    }
    //When the level first loads, there might already be animations setup
    //So those are retrieved first.
    if(retrieve_children){
        Print("Loading existing level animation " + ui_time + "\n");
        RetrieveExistingAnimation();
        retrieve_children = false;
    }else if(rewrite_identifier){
        RemoveRewriteLevelParam();
        RewriteAnimationGroup();
        rewrite_identifier = false;
    }
    UpdatePlayMode();
    post_init_done = true;
    Print("Postinit done\n");
}

void RewriteAnimationGroup(){
    //We got all the children so a new identifier can be generated.
    params.SetString("Identifier", GetUniqueIdentifier());
    identifier = params.GetString("Identifier");
    Print("This anim has " + node_ids.size() + " anim keys\n");
    for(uint i = 0; i < node_ids.size(); i++){
        ScriptParams@ object_params = ReadObjectFromID(node_ids[i]).GetScriptParams();
        object_params.SetString("BelongsTo", identifier);
    }
    Print("This anim has " + node_ids.size() + " children\n");
    for(uint i = 0; i < children.size(); i++){
        ScriptParams@ object_params = ReadObjectFromID(children[i]).GetScriptParams();
        object_params.SetString("BelongsTo", identifier);
    }
    if(ObjectExists(objectID)){
        ScriptParams@ main_obj_params = ReadObjectFromID(objectID).GetScriptParams();
        main_obj_params.SetString("BelongsTo", identifier);
    }
    Print("Done rewriting\n");
}

void RetrieveExistingAnimation(){
    array<int> all_objects = GetObjectIDs();
    array<int> found_placeholders;
    Print("retrieve " + params.GetString("Object Path") + "\n");
    for(uint32 i = 0; i < all_objects.size(); i++){
        if(!ObjectExists(all_objects[i])){
            continue;
        }
        Object@ obj = ReadObjectFromID(all_objects[i]);
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(obj_params.HasParam("BelongsTo")){
            if(obj_params.GetString("BelongsTo") == identifier){
                if(obj_params.GetString("Name") == "animation_key"){
                    //These are the pathpoints that the object will follow.
                    if(found_placeholders.find(all_objects[i]) == -1){
                        //Check if the animation key is already added.
                        found_placeholders.insertLast(all_objects[i]);
                    }
                }else if(obj_params.GetString("Name") == "animation_child"){
                    children.insertLast(all_objects[i]);
                    obj.SetSelectable(false);
                    obj.SetTranslatable(false);
                    obj.SetRotatable(false);
                    obj.SetScalable(false);
                    obj.SetCopyable(false);
                    obj.SetDeletable(false);
                }else if(obj_params.GetString("Name") == "animation_main"){
                    Print("Found main object \n");
                    objectID = all_objects[i];
                    obj.SetSelectable(false);
                    obj.SetTranslatable(false);
                    obj.SetRotatable(false);
                    obj.SetScalable(false);
                    obj.SetCopyable(false);
                    obj.SetDeletable(false);
                }
            }
        }
    }
    node_ids.resize(found_placeholders.size());
    int size = 0;
    Print("Found animation keys " + found_placeholders.size() + "\n");
    //Now put the placeholders back in order.
    for(uint i = 0; i < found_placeholders.size(); i++){
        ScriptParams@ placeholder_params = ReadObjectFromID(found_placeholders[i]).GetScriptParams();
        if(placeholder_params.HasParam("Index")){
            node_ids[placeholder_params.GetInt("Index")] = found_placeholders[i];
            if(placeholder_params.GetInt("Index") + 1 > size){
                size = placeholder_params.GetInt("Index") + 1;
            }
            Print("adding id " + found_placeholders[i] + " to index " + placeholder_params.GetInt("Index") + "\n");
        }
    }
    node_ids.resize(size);
    Print("Done retrieving\n");
    for(uint i = 0; i < node_ids.size(); i++){
        Print(" " + node_ids[i]);
    }
    Print("\n");
}

void SetParameters() {
    params.AddInt("Play mode", 0);
    params.AddInt("Number of Keys", 2);
    params.AddFloatSlider("Seconds",1.0f,"min:0.1,max:10.0,step:1.0,text_mult:1");
    params.AddFloatSlider("Interpolation",1.0f,"min:0.0,max:1.0,step:0.1,text_mult:1");
    params.AddString("Object Path", "Data/Objects/arrow.xml");
    params.AddIntCheckbox("Const speed", true);
    params.AddIntCheckbox("AI trigger", false);
    params.AddIntCheckbox("Interpolate translation", false);
    params.AddIntCheckbox("Interpolate rotation", false);
    params.AddIntCheckbox("Draw preview objects", true);
    params.AddIntCheckbox("Draw path lines", false);
    params.AddIntCheckbox("Draw connect lines", true);
    params.AddIntCheckbox("Scale Object Preview", false);
    //Unfortunately I can not get the model path from the xml file via scripting.
    //So the model needs to be declared seperatly.
    params.AddString("Model Path", "Data/Models/arrow.obj");

    identifier = params.GetString("Identifier");
    model_path = params.GetString("Model Path");
    current_mode = PlayMode(params.GetInt("Play mode"));
    objectPath = params.GetString("Object Path");
}

string GetNewIdentifier(){
    return rand() + "";
}

string GetUniqueIdentifier(){
    array<int> all_objects = GetObjectIDs();
    array<string> taken_identifiers = {""};
    for(uint i = 0; i < all_objects.size(); i++){
        Object@ obj = ReadObjectFromID(all_objects[i]);
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(obj_params.HasParam("Identifier")){
            taken_identifiers.insertLast(obj_params.GetString("Identifier"));
        }
    }
    string new_identifier = "";
    while(taken_identifiers.find(new_identifier) != -1){
        /*DisplayError("ohno", "ID not unique!");*/
        new_identifier = GetNewIdentifier();
    }
    return new_identifier;
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if((mo.controlled || params.GetInt("AI trigger") == 1) && on_enter && !playing && !done){
        //Once the user steps into the hotspot the animation will start.
        playing = true;
    }
}

void OnExit(MovementObject @mo) {
    if((mo.controlled || params.GetInt("AI trigger") == 1) && on_exit){
        if(playing && !reverse || !playing && reverse){
          playing = true;
          reverse = true;
        }
    }
}

void Reset(){
    Print("Resetting\n");
    if(node_ids.size() < 2){
        return;
    }

    if(objectPath != params.GetString("Object Path")){
        if(FileExists(params.GetString("Object Path"))){
            objectPath = params.GetString("Object Path");
            CreateMainAnimationObject();
            Object@ object = ReadObjectFromID(objectID);
            object.SetTranslation(ReadObjectFromID(node_ids[index]).GetTranslation());
            object.SetRotation(ReadObjectFromID(node_ids[index]).GetRotation());
        }
    }

    if(!ObjectExists(objectID)){
        CreateMainAnimationObject();
    }

    index = 0;
    prev_node_id = -1;
    next_pathpoint = true;
    node_timer = 0.0f;
    done = false;
    Object@ object = ReadObjectFromID(objectID);
    object.SetTranslation(ReadObjectFromID(node_ids[index]).GetTranslation());
    object.SetRotation(ReadObjectFromID(node_ids[index]).GetRotation());
    UpdatePlayMode();
}

bool CheckObjectsExist(){
    if(!ObjectExists(objectID)){
        ResetLevel();
        return false;
    }

    if(index > (int(node_ids.size()) - 1) || !ObjectExists(node_ids[index])){
        return false;
    }
    if(!ObjectExists(node_ids[index])){
        return false;
    }
    if(prev_node_id != -1){
        if(!ObjectExists(prev_node_id)){
            prev_node_id = -1;
        }
    }
    return true;
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();
    while(token_iter.FindNextToken(msg)){
        string token = token_iter.GetToken(msg);
        /*DisplayError("okay", "Received " + token);*/
        Print("received " + token + "\n");
        if(token == "GetNonTakenObjects"){
            token_iter.FindNextToken(msg);
            int id = atoi(token_iter.GetToken(msg));
            SendNonTakenObjects(id);
        }else if(token == "AddAnimationKey"){
            /*DisplayError("okay", "Adding AddAnimationKey ");*/
            token_iter.FindNextToken(msg);
            node_ids.insertLast(atoi(token_iter.GetToken(msg)));
        }else if(token == "AddAnimationChild"){
            token_iter.FindNextToken(msg);
            children.insertLast(atoi(token_iter.GetToken(msg)));
        }else if(token == "SetMainObject"){
            token_iter.FindNextToken(msg);
            objectID = atoi(token_iter.GetToken(msg));
        }else if(token == "Done"){
            wait = false;
            RemoveRewriteLevelParam();
            RewriteAnimationGroup();
            params.SetInt("Number of Keys", node_ids.size());
            Print("hello\n");
        }
    }
}

void SendNonTakenObjects(int id){
    array<int> all_objects = GetObjectIDs();
    string message = "";

    for(uint32 i = 0; i < all_objects.size(); i++){
        ScriptParams@ obj_params = ReadObjectFromID(all_objects[i]).GetScriptParams();
        if(obj_params.HasParam("BelongsTo")){
            if(obj_params.GetString("BelongsTo") == identifier){
                Print("Found " + all_objects[i] + "\n");
                if(obj_params.GetString("Name") == "animation_key"){
                    if(node_ids.find(all_objects[i]) == -1){
                        message += "AddAnimationKey " + all_objects[i] + " ";
                    }
                }else if(obj_params.GetString("Name") == "animation_child"){
                    if(children.find(all_objects[i]) == -1){
                        message += "AddAnimationChild " + all_objects[i] + " ";
                    }
                }else if(obj_params.GetString("Name") == "animation_main"){
                    if(objectID != all_objects[i]){
                        message += "SetMainObject " + all_objects[i] + " ";
                    }
                }
            }
        }
    }
    message += "Done";
    Print("Whole message " + message + "\n");
    Object@ target = ReadObjectFromID(id);
    target.ReceiveScriptMessage(message);
}


bool send_retrieve = false;
void Update(){
    if(wait){
        if(other_hotspot_id != -1){
            Object@ other_hotspot = ReadObjectFromID(other_hotspot_id);
            other_hotspot.ReceiveScriptMessage("GetNonTakenObjects " + hotspot.GetID());
            other_hotspot_id = -1;
        }
        return;
    }
    PostInit();
    UpdateAnimationKeys();
    if(CheckParamChanges()){
        return;
    }
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
                  UpdatePlayMode();
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
                UpdatePlayMode();
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

bool CheckParamChanges(){
    if(EditorModeActive()){
        if(model_path != params.GetString("Model Path")){
            if(FileExists(params.GetString("Model Path"))){
                model_path = params.GetString("Model Path");
                return true;
            }
        }
        if(objectPath != params.GetString("Object Path")){
            if(FileExists(params.GetString("Object Path"))){
                DeleteObjectID(objectID);
                for(uint i = 0; i < children.size(); i++){
                    DeleteObjectID(children[i]);
                }
                children.resize(0);
                ResetLevel();
                return true;
            }
        }
        if(current_mode != PlayMode(params.GetInt("Play mode"))){
            Print("Changed play mode\n");
            UpdatePlayMode();
            return true;
        }
    }
    return false;
}

Object@ current_pathpoint;
Object@ previous_pathpoint;

void UpdateTransform(){
    if(playing && prev_node_id != -1){
        node_timer += time_step;
        @current_pathpoint = ReadObjectFromID(node_ids[index]);
        @previous_pathpoint = ReadObjectFromID(prev_node_id);
        Object@ object = ReadObjectFromID(objectID);

        if(params.GetInt("Const speed") == 1){
            //The animation will have a constant speed.
            bool skip_node = false;
            float whole_distance = CalculateWholeDistance();
            if(whole_distance != 0.0f){
                float node_distance = distance(current_pathpoint.GetTranslation(), previous_pathpoint.GetTranslation());
                if(node_distance != 0.0f){
                    //To make sure the time isn't 0, or else it will devide by zero.
                    float node_time = max(0.0001f, params.GetFloat("Seconds") * (node_distance / whole_distance));
                    float alpha = node_timer / node_time;
                    //Setting the position and rotation:
                    if(node_timer > node_time){
                        next_pathpoint = true;
                        node_timer = 0.0f;
                        return;
                    }
                    CalculateTransform(object, alpha, node_distance);
                }else{
                    skip_node = true;
                }
            }else{
                skip_node = true;
            }
            if(skip_node){
                /*object.SetTranslation(current_pathpoint.GetTranslation());*/
                /*object.SetRotation(current_pathpoint.GetRotation());*/
                next_pathpoint = true;
                node_timer = 0.0f;
            }
        }else{
            //The animation will devide the time between the animation keys.
            float node_time = max(0.0001, params.GetFloat("Seconds")) / node_ids.size();
            //Setting the position and rotation:
            float alpha = node_timer / node_time;
            float node_distance = distance(current_pathpoint.GetTranslation(), previous_pathpoint.GetTranslation());
            if(node_timer > node_time){
                next_pathpoint = true;
                node_timer = 0.0f;
                return;
            }
            CalculateTransform(object, alpha, node_distance);
        }
    }else if(done == false && EditorModeActive()){
        //If the animation is playing but no where to go, just stay at the first key.
        if(node_ids.size() > 0){
            Object@ firstPathpoint = ReadObjectFromID(node_ids[0]);
            Object@ mainObject = ReadObjectFromID(objectID);
            /*mainObject.SetTranslation(firstPathpoint.GetTranslation());*/
            /*mainObject.SetRotation(firstPathpoint.GetRotation());*/
            index = 0;
        }
    }
    UpdateChildren();
}

void CalculateTransform(Object@ object, float alpha, float node_distance){
    quaternion new_rotation;
    vec3 new_position;
    if(params.GetInt("Interpolate translation") == 1){
        //Current time, start value, change in value, duration
        float offset_alpha = sine_wave(alpha, 0.0f, 1.0f, 1.0f);
        /*float offset_alpha = exp_wave(alpha, 0.0f, 1.0f, 1.0f);*/
        vec3 previous_direction = normalize(previous_pathpoint.GetRotation() * vec3(0.0f, 0.0f, 1.0f) * (reverse ? 1 : -1)) * node_distance * alpha;
        vec3 current_direction = normalize(current_pathpoint.GetRotation() * vec3(0.0f, 0.0f, 1.0f) * (reverse ? -1 : 1)) * (node_distance * (1.0f - alpha));
        vec3 new_position_curved = mix(previous_pathpoint.GetTranslation() + previous_direction, current_pathpoint.GetTranslation() + current_direction, offset_alpha);
        vec3 new_position_straight = mix(previous_pathpoint.GetTranslation(), current_pathpoint.GetTranslation(), alpha);
        new_position = mix(new_position_straight, new_position_curved, params.GetFloat("Interpolation"));
    }else{
        new_position = mix(previous_pathpoint.GetTranslation(), current_pathpoint.GetTranslation(), alpha);
    }
    if(params.GetInt("Interpolate rotation") == 1){
        vec3 path_direction = normalize(new_position - object.GetTranslation());
        vec3 up_direction = normalize(mix(previous_pathpoint.GetRotation(), current_pathpoint.GetRotation(), alpha) * vec3(0.0f, 1.0f, 0.0f));

        float rotation_y = atan2(path_direction.z, -path_direction.x) - (90 / 180.0f * pi);
        float rotation_x = asin(-path_direction.y);

        vec3 previous_direction = normalize(previous_pathpoint.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
        vec3 current_direction = normalize(current_pathpoint.GetRotation() * vec3(1.0f, 0.0f, 0.0f));
        vec3 roll = mix(previous_direction, current_direction, alpha);
        float rotation_z = asin(roll.y);
        new_rotation = quaternion(vec4(0,1,0,rotation_y)) * quaternion(vec4(1,0,0,rotation_x)) * quaternion(vec4(0,0,1,rotation_z));

        if(params.GetInt("Draw path lines") == 1){
            DebugDrawLine(object.GetTranslation(), object.GetTranslation() + (path_direction * 4.0f), vec3(0.0, 0.0, 1.0f), _delete_on_update);
            DebugDrawLine(object.GetTranslation(), object.GetTranslation() + (up_direction * 4.0f), vec3(0.0, 1.0, 0.0f), _delete_on_update);
        }
    }else{
        new_rotation = mix(previous_pathpoint.GetRotation(), current_pathpoint.GetRotation(), alpha);
    }

    if(params.GetInt("Draw path lines") == 1){
        DebugDrawLine(object.GetTranslation(), new_position, vec3(1, 0, 0), _fade);
    }

    object.SetRotation(new_rotation);
    object.SetTranslation(new_position);
}

//Current time, start value, change in value, duration
float sine_wave(float t, float b, float c, float d) {
	return -c/2 * (cos(pi*t/d) - 1) + b;
}

float exp_wave(float t, float b, float c, float d) {
	t /= d/2;
	if (t < 1) return c/2 * pow( 2, 10 * (t - 1) ) + b;
	t--;
	return c/2 * ( -pow( 2, -10 * t) + 2 ) + b;
};

void UpdateChildren(){
    for(uint i = 0; i < children.size(); i++){
        if(!ObjectExists(children[i])){
            children.removeAt(i);
            i--;
            continue;
        }
        Object@ obj = ReadObjectFromID(children[i]);
        obj.SetTranslation(obj.GetTranslation());
    }
}

void PlayAvailableSound(){
    if(prev_node_id != -1){
        Object@ pathpoint = ReadObjectFromID(prev_node_id);
        ScriptParams@ pathpoint_params = pathpoint.GetScriptParams();
        if(pathpoint_params.HasParam("Playsound")){
            if(pathpoint_params.GetString("Playsound") != ""){
                if(FileExists(pathpoint_params.GetString("Playsound"))){
                    PlaySound(pathpoint_params.GetString("Playsound"), pathpoint.GetTranslation());
                }else{
                    DisplayError("Error", "Could not find file " + pathpoint_params.GetString("Playsound"));
                }
            }
        }
    }
}

void UpdateAnimationKeys(){
    ScriptParams@ level_params = level.GetScriptParams();
    if(level_params.HasParam("RewritingIdentifier")){
        return;
    }
    bool reset = false;
    //Check for new animation keys that have been duplicated.
    array<int> all_placeholders = GetObjectIDsType(_placeholder_object);
    for(uint i = 0; i < all_placeholders.size(); i++){
        Object@ obj = ReadObjectFromID(all_placeholders[i]);
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(obj_params.HasParam("BelongsTo")){
            if(obj_params.GetString("BelongsTo") == identifier && node_ids.find(all_placeholders[i]) == -1){
                node_ids.insertAt(obj_params.GetInt("Index") + 1, all_placeholders[i]);
                params.SetInt("Number of Keys", params.GetInt("Number of Keys") + 1);
                reset = true;
            }
        }
    }
    //Check for deleted animation keys.
    for(uint i = 0; i < node_ids.size(); i++){
        if(!ObjectExists(node_ids[i])){
            node_ids.removeAt(i);
            params.SetInt("Number of Keys", node_ids.size());
            i--;
            reset = true;
        }
    }
    //A minimum of 2 keys is needed.
    if(params.GetInt("Number of Keys") < 2){
        params.SetInt("Number of Keys", 2);
    }
    //Create more placeholders if there aren't enough in the scene.
    if(node_ids.size() != uint(params.GetInt("Number of Keys"))){
        if(node_ids.size() < uint(params.GetInt("Number of Keys"))){
            CreatePathpoint();
        }else if(node_ids.size() > uint(params.GetInt("Number of Keys"))){
            for(uint i = 0; i < node_ids.size(); i++){
                Print(" " + node_ids[i]);
            }
            Print("\n");
            Print("Trying to delete " + node_ids[node_ids.size() - 1] + " size " + node_ids.size() + " exists " + ObjectExists(node_ids[node_ids.size() - 1]) + "\n");
            DeleteObjectID(node_ids[node_ids.size() - 1]);
            node_ids.removeLast();
        }
        reset = true;
    }
    if(reset){
        WritePlaceholderIndexes();
        Reset();
    }
}

void UpdatePlayMode(){
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
        params.SetInt("Play mode", kLoopForward);
        current_mode = PlayMode(-1);
        break;
    }
}

void DrawEditor(){
    vec3 previousPos;
    if(MediaMode()){
        return;
    }
    for(uint i = 0; i < uint(node_ids.length()); ++i){
        if(ObjectExists(node_ids[i])){
            Object @obj = ReadObjectFromID(node_ids[i]);
            if(params.GetInt("Draw preview objects") == 1){
                SetObjectPreview(obj,objectPath);
            }
            if(params.GetInt("Draw connect lines") == 1){
                if(i>0){
                    //Every pathpoint needs to be connected with a line to show the animation path.
                    DebugDrawLine(obj.GetTranslation(), previousPos, connect_lines_color, _delete_on_update);
                }else{
                    //If it's the first pathpoint a line needs to be draw to the main hotspot.
                    DebugDrawLine(main_hotspot.GetTranslation(), obj.GetTranslation(), connect_lines_color, _delete_on_update);
                }
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
    if(params.GetInt("Scale Object Preview") == 1){
        mat4 scale_mat;
        float scale = (spawn.GetScale().x + spawn.GetScale().y + spawn.GetScale().z ) / 3.0f;
        scale_mat[0] = scale;
        scale_mat[5] = scale;
        scale_mat[10] = scale;
        scale_mat[15] = 1.0f;
        objectInformation = objectInformation * scale_mat;
    }
    DebugDrawWireMesh(model_path, objectInformation, vec4(0.0f, 0.35f, 0.0f, 0.75f), _delete_on_update);
}

void CreatePathpoint(){
  int objID = CreateObject("Data/Objects/placeholder.xml", false);
  node_ids.push_back(objID);
  Object @newObj = ReadObjectFromID(objID);
  newObj.SetSelectable(true);
  newObj.SetTranslatable(true);
  newObj.SetRotatable(true);
  newObj.SetScalable(true);
  newObj.SetCopyable(true);
  newObj.SetDeletable(true);

  ScriptParams@ placeholderParams = newObj.GetScriptParams();
  //When a new pathpoint is created the hotspot ID is added to it's parameters.
  //This will be used when the level is closed and loaded again.
  placeholderParams.AddString("BelongsTo", identifier);
  placeholderParams.AddString("Playsound", "");
  newObj.SetTranslation(main_hotspot.GetTranslation() + ((node_ids.size() - 1) * vec3(0.0f,1.0f,0.0f)));
}

void CreateMainAnimationObject(){
    Print("Create main object\n");
    /*DisplayError("as", "Create main object");*/
    MarkAllObjects();
    objectID = CreateObject(objectPath, false);
    Object@ main_object = ReadObjectFromID(objectID);
    main_object.SetSelectable(false);
    ScriptParams@ object_params = main_object.GetScriptParams();
    object_params.AddString("BelongsTo", identifier);
    object_params.AddString("Name", "animation_main");
    FindNewChildren();
}

void MarkAllObjects(){
    array<int> all_ids = GetObjectIDs();
    for(uint i = 0; i < all_ids.size(); i++){
        Object@ obj = ReadObjectFromID(all_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        params.AddInt("" + hotspot.GetID(), 1);
    }
}

void FindNewChildren(){
    array<int> all_ids = GetObjectIDs();
    for(uint i = 0; i < all_ids.size(); i++){
        Object@ obj = ReadObjectFromID(all_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(!params.HasParam("" + hotspot.GetID())){
            children.insertLast(all_ids[i]);
            params.AddString("BelongsTo", identifier);
            params.AddString("Name", "animation_child");
            /*obj.SetSelectable(false);*/
        }else{
            params.Remove("" + hotspot.GetID());
        }
    }
    Print("This hotspot has " + children.size() + " children\n");
}

void WritePlaceholderIndexes(){
    for(uint i = 0; i < node_ids.size(); i++){
        if(!ObjectExists(node_ids[i])){
            continue;
        }
        Object@ placeholder = ReadObjectFromID(node_ids[i]);
        ScriptParams@ placeholder_params = placeholder.GetScriptParams();
        placeholder_params.SetInt("Index", i);
    }
}

void Dispose(){
    if(!GetInputDown(0, "z")){
        for(uint i = 0; i < node_ids.size(); i++){
            if(ObjectExists(node_ids[i])){
                DeleteObjectID(node_ids[i]);
            }
        }
        for(uint i = 0; i < children.size(); i++){
            if(ObjectExists(children[i])){
                QueueDeleteObjectID(children[i]);
            }
        }
        if(ObjectExists(objectID)){
            DeleteObjectID(objectID);
        }
    }
}
