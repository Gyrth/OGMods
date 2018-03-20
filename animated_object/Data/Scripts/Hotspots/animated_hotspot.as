array<int> animation_keys;
int prev_node_id = -1;
int main_object = -1;
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
int wiremesh_preview = 1;
bool draw_preview_objects = false;
string default_preview_mesh = "Data/Objects/arrow.xml";

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

string GetTypeString() {
    return "AnimationHotspot";
}

float CalculateWholeDistance(){
    float whole = 0.0f;
    for(uint i = 1; i < animation_keys.size(); i++){
        whole += distance(ReadObjectFromID(animation_keys[i - 1]).GetTranslation(), ReadObjectFromID(animation_keys[i]).GetTranslation());
    }
    //Add the distance between the fist and last node as well.
    whole += distance(ReadObjectFromID(animation_keys[0]).GetTranslation(), ReadObjectFromID(animation_keys[(animation_keys.size() - 1)]).GetTranslation());
    return whole;
}

PlayMode current_mode;
int nr_with_ident = 0;
void Init() {
    SetParameters();
    if(params.HasParam("Identifier")){
        identifier = params.GetString("Identifier");
    }
    model_path = params.GetString("Model Path");
    current_mode = PlayMode(params.GetInt("Play mode"));
    objectPath = params.GetString("Object Path");
    wiremesh_preview = params.GetInt("Wiremesh preview");
    draw_preview_objects = (params.GetInt("Draw preview objects") == 1);

    if(ui_time == 0.0f){
        //The level is loaded with an existing animation hotspot in it.
        retrieve_children = true;
    }else{
        //The hotspot is created while the game is running.
        array<int> all_objects = GetObjectIDs();
        int other_hotspot_id = -1;
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
        if(GetInputDown(0, "z")){
            //Undo
            retrieve_children = true;
        }else if(GetInputDown(0, "lalt")){
            //Duplicating.
            if(nr_with_ident == 1){
                retrieve_children = true;
            }else if(nr_with_ident == 2){
                Object@ other_hotspot = ReadObjectFromID(other_hotspot_id);
                other_hotspot.ReceiveScriptMessage("RewriteAnimationGroup");
                retrieve_children = true;
                AddRewritingLevelParam();
            }else{
                DisplayError("Ohno", "Shouldn't get here.");
            }
        }else{
            //Either new hotspot or spawngroup.
            if(nr_with_ident == 0){
                params.AddString("Identifier", GetUniqueIdentifier());
                identifier = params.GetString("Identifier");
            }else if(nr_with_ident == 1){
                //The animation group is loaded via a group and this identifier is unique.
                retrieve_children = true;
            }else if(nr_with_ident == 2){
                //The anim is loaded as a group, and the identifier is already taken.
                Object@ other_hotspot = ReadObjectFromID(other_hotspot_id);
                other_hotspot.ReceiveScriptMessage("RewriteAnimationGroup");
                retrieve_children = true;
                AddRewritingLevelParam();
            }else if(nr_with_ident > 2){
                DisplayError("Ohno", "There are " + nr_with_ident + " animation hotspots with the same identifier, how did you manage to do that?");
            }
        }
    }
}

void AddRewritingLevelParam(){
    ScriptParams@ level_params = level.GetScriptParams();
    if(level_params.HasParam("RewritingIdentifier")){
        level_params.SetString("RewritingIdentifier", level_params.GetString("RewritingIdentifier") + " " + identifier);
    }else{
        level_params.AddString("RewritingIdentifier", identifier);
    }
}

void RemoveRewritingLevelParam(){
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
    level.ReceiveLevelEvents(hotspot.GetID());
    //When the level first loads, there might already be animations setup
    //So those are retrieved first.
    if(retrieve_children){
        RetrieveExistingAnimation();
        retrieve_children = false;
        RemoveRewritingLevelParam();
    }
    UpdatePlayMode();
    if(draw_preview_objects){
        if(wiremesh_preview == 0){
            AddPlaceholders();
        }
    }
    post_init_done = true;
}

void RewriteAnimationGroup(){
    //We got all the children so a new identifier can be generated.
    params.SetString("Identifier", GetUniqueIdentifier());
    identifier = params.GetString("Identifier");
    for(uint i = 0; i < animation_keys.size(); i++){
        ScriptParams@ object_params = ReadObjectFromID(animation_keys[i]).GetScriptParams();
        object_params.SetString("BelongsTo", identifier);
    }
    if(ObjectExists(main_object)){
        ScriptParams@ main_obj_params = ReadObjectFromID(main_object).GetScriptParams();
        main_obj_params.SetString("BelongsTo", identifier);
    }
}

void RetrieveExistingAnimation(){
    array<int> all_objects = GetObjectIDs();
    array<int> found_placeholders;
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
                    main_object = all_objects[i];
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
    animation_keys.resize(found_placeholders.size());
    int size = 0;
    //Now put the placeholders back in order.
    for(uint i = 0; i < found_placeholders.size(); i++){
        ScriptParams@ placeholder_params = ReadObjectFromID(found_placeholders[i]).GetScriptParams();
        if(placeholder_params.HasParam("Index")){
            animation_keys[placeholder_params.GetInt("Index")] = found_placeholders[i];
            if(placeholder_params.GetInt("Index") + 1 > size){
                size = placeholder_params.GetInt("Index") + 1;
            }
        }
    }
    animation_keys.resize(size);
}

void SetParameters() {
    params.AddInt("Play mode", 0);
    params.AddInt("Number of Keys", 2);
    params.AddFloatSlider("Seconds",1.0f,"min:0.1,max:10.0,step:1.0,text_mult:1");
    params.AddFloatSlider("Forward",0.0f,"min:0.0,max:360.0,step:1.0,text_mult:1");
    params.AddFloatSlider("Interpolation",1.0f,"min:0.0,max:1.0,step:0.1,text_mult:1");
    params.AddString("Object Path", "Data/Objects/arrow.xml");
    params.AddIntCheckbox("Const speed", true);
    params.AddIntCheckbox("Wiremesh preview", false);
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
    if(!ObjectExists(main_object)){
        CreateMainAnimationObject();
        if(wiremesh_preview == 0){
            AddPlaceholders();
        }
    }
    ResetAnimation();
}

void ResetAnimation(){
    if(animation_keys.size() < 2 || main_object == -1){
        return;
    }
    index = 0;
    prev_node_id = -1;
    next_pathpoint = true;
    node_timer = 0.0f;
    done = false;
    Object@ object = ReadObjectFromID(main_object);
    object.SetTranslation(ReadObjectFromID(animation_keys[index]).GetTranslation());
    object.SetRotation(ReadObjectFromID(animation_keys[index]).GetRotation());
    UpdatePlayMode();
}

bool CheckObjectsExist(){
    if(!ObjectExists(main_object)){
        ResetLevel();
        return false;
    }

    if(index > (int(animation_keys.size()) - 1) || !ObjectExists(animation_keys[index])){
        return false;
    }
    if(!ObjectExists(animation_keys[index])){
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
        if(token == "RewriteAnimationGroup"){
            if(!ObjectExists(main_object)){
                RetrieveExistingAnimation();
            }
            RewriteAnimationGroup();
        }else if(token == "level_event"){
            ScriptParams@ level_params = level.GetScriptParams();
            if(level_params.HasParam("RewritingIdentifier") || !EditorModeActive()){
                return;
            }
            token_iter.FindNextToken(msg);
            string command = token_iter.GetToken(msg);
            if(command == "added_object"){
                token_iter.FindNextToken(msg);
                int id = atoi(token_iter.GetToken(msg));
                CheckNewAnimationKey(id);
            }
        }
    }
}

void Update(){
    PostInit();
    UpdateAnimationKeys();
    if(CheckParamChanges()){
        return;
    }
    if(!CheckObjectsExist()){
        return;
    }
    if(playing && done == false || playing && looping && !on_enter){
      Object@ object = ReadObjectFromID(main_object);
      vec3 nextPathpointPos = ReadObjectFromID(animation_keys[index]).GetTranslation();
      vec3 currentPos = object.GetTranslation();
      if(next_pathpoint){
          next_pathpoint = false;
          int prev_index = index;
          prev_node_id = animation_keys[index];
          if(reverse){
            index--;
          }else{
            index++;
          }
          int numPathpoints = animation_keys.size();
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
        }else if(objectPath != params.GetString("Object Path")){
            if(FileExists(params.GetString("Object Path"))){
                objectPath = params.GetString("Object Path");
                for(uint i = 0; i < children.size(); i++){
                    DeleteObjectID(children[i]);
                }
                DeleteObjectID(main_object);
                children.resize(0);
                ResetLevel();
                return true;
            }
        }else if(current_mode != PlayMode(params.GetInt("Play mode"))){
            UpdatePlayMode();
            ResetAnimation();
            return true;
        }
        if(draw_preview_objects != (params.GetInt("Draw preview objects") == 1)){
            draw_preview_objects = (params.GetInt("Draw preview objects") == 1);
            if(draw_preview_objects && wiremesh_preview == 0){
                AddPlaceholders();
            }else{
                RemovePlaceholders();
            }
            return true;
        }

        if(wiremesh_preview != params.GetInt("Wiremesh preview")){
            wiremesh_preview = params.GetInt("Wiremesh preview");
            if(draw_preview_objects && wiremesh_preview == 0){
                AddPlaceholders();
            }else{
                RemovePlaceholders();
            }
            return true;
        }
    }
    return false;
}

void AddPlaceholders(){
    for(uint i = 0; i < animation_keys.size(); i++){
        Object@ key = ReadObjectFromID(animation_keys[i]);
        AddPlaceholder(key);
    }
}

void AddPlaceholder(Object@ key){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(key);
    if(IsGroupDerived(main_object)){
        placeholder_object.SetPreview(default_preview_mesh);
    }else{
        placeholder_object.SetPreview(objectPath);
    }
    placeholder_object.SetEditorDisplayName("Animation Key");
}

void RemovePlaceholders(){
    for(uint i = 0; i < animation_keys.size(); i++){
        Object@ key = ReadObjectFromID(animation_keys[i]);
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(key);
        placeholder_object.SetPreview("");
        placeholder_object.SetEditorDisplayName("Animation Key");
    }
}

Object@ current_pathpoint;
Object@ previous_pathpoint;

void UpdateTransform(){
    if(playing && prev_node_id != -1){
        node_timer += time_step;
        @current_pathpoint = ReadObjectFromID(animation_keys[index]);
        @previous_pathpoint = ReadObjectFromID(prev_node_id);
        Object@ object = ReadObjectFromID(main_object);

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
                next_pathpoint = true;
                node_timer = 0.0f;
            }
        }else{
            //The animation will devide the time between the animation keys.
            float node_time = max(0.0001, params.GetFloat("Seconds")) / animation_keys.size();
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
    }else if(EditorModeActive() || !playing && prev_node_id == -1){
        if(animation_keys.size() > 0){
            Object@ firstPathpoint = ReadObjectFromID(animation_keys[0]);
            Object@ mainObject = ReadObjectFromID(main_object);
            mainObject.SetTranslation(firstPathpoint.GetTranslation());
            mainObject.SetRotation(firstPathpoint.GetRotation());
        }
    }else if(prev_node_id != -1 && !playing){
        //If the animation is playing but no where to go, just stay at the first key.
        if(animation_keys.size() > 0){
            Object@ firstPathpoint = ReadObjectFromID(prev_node_id);
            Object@ mainObject = ReadObjectFromID(main_object);
            mainObject.SetTranslation(firstPathpoint.GetTranslation());
            mainObject.SetRotation(firstPathpoint.GetRotation());
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

        float rotation_y = atan2(-path_direction.x, -path_direction.z) + (params.GetFloat("Forward") / 180.0f * pi);
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
        float extra_y_rot = (params.GetFloat("Forward") / 180.0f * pi);
        new_rotation = new_rotation.opMul(quaternion(vec4(0,1,0,extra_y_rot)));
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

void CheckNewAnimationKey(int id){
    ScriptParams@ level_params = level.GetScriptParams();
    if(level_params.HasParam("RewritingIdentifier") || !EditorModeActive()){
        return;
    }
    //Check for new animation keys that have been duplicated.
    Object@ obj = ReadObjectFromID(id);
    ScriptParams@ obj_params = obj.GetScriptParams();
    if(obj_params.HasParam("BelongsTo")){
        if(obj_params.GetString("BelongsTo") == identifier && animation_keys.find(id) == -1){
            animation_keys.insertAt(obj_params.GetInt("Index") + 1, id);
            params.SetInt("Number of Keys", params.GetInt("Number of Keys") + 1);

            if(draw_preview_objects && wiremesh_preview == 0){
                AddPlaceholder(obj);
            }else{
                PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
                placeholder_object.SetEditorDisplayName("Animation Key");
            }

            WritePlaceholderIndexes();
            ResetAnimation();
        }
    }
}

void UpdateAnimationKeys(){
    ScriptParams@ level_params = level.GetScriptParams();
    if(level_params.HasParam("RewritingIdentifier") || !EditorModeActive()){
        return;
    }
    bool reset = false;
    //Check for deleted animation keys.
    for(uint i = 0; i < animation_keys.size(); i++){
        if(!ObjectExists(animation_keys[i])){
            animation_keys.removeAt(i);
            params.SetInt("Number of Keys", animation_keys.size());
            i--;
            reset = true;
        }
    }
    //A minimum of 2 keys is needed.
    if(params.GetInt("Number of Keys") < 2){
        params.SetInt("Number of Keys", 2);
    }
    //Create more placeholders if there aren't enough in the scene.
    while(animation_keys.size() != uint(params.GetInt("Number of Keys"))){
        if(animation_keys.size() < uint(params.GetInt("Number of Keys"))){
            CreatePathpoint();
        }else if(animation_keys.size() > uint(params.GetInt("Number of Keys"))){
            DeleteObjectID(animation_keys[animation_keys.size() - 1]);
            animation_keys.removeLast();
        }
        reset = true;
    }
    if(reset){
        WritePlaceholderIndexes();
        ResetAnimation();
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
    for(uint i = 0; i < uint(animation_keys.length()); ++i){
        if(ObjectExists(animation_keys[i])){
            Object @obj = ReadObjectFromID(animation_keys[i]);
            if(obj.IsSelected()){
                DebugDrawText(obj.GetTranslation(), "#" + (i + 1), 50.0f, true, _delete_on_draw);
            }
            if(draw_preview_objects && wiremesh_preview == 1){
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
    int objID = CreateObject("Data/Objects/animation_key.xml", false);
    animation_keys.push_back(objID);
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
    placeholderParams.SetString("BelongsTo", identifier);
    newObj.SetTranslation(main_hotspot.GetTranslation() + ((animation_keys.size() - 1) * vec3(0.0f,1.0f,0.0f)));

    if(draw_preview_objects && wiremesh_preview == 0){
        AddPlaceholder(newObj);
    }else{
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(newObj);
        placeholder_object.SetEditorDisplayName("Animation Key");
    }
}

void CreateMainAnimationObject(){
    MarkAllObjects();
    main_object = CreateObject(objectPath, false);
    Object@ main_obj = ReadObjectFromID(main_object);
    main_obj.SetSelectable(false);
    ScriptParams@ object_params = main_obj.GetScriptParams();
    object_params.AddInt("" + hotspot.GetID(), 1);
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
    array<int> all_objects = GetObjectIDs();
    for(uint i = 0; i < all_objects.size(); i++){
        Object@ obj = ReadObjectFromID(all_objects[i]);
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(!obj_params.HasParam("" + hotspot.GetID())){
            if(!obj_params.HasParam("Name")){
                obj_params.AddString("Name", "animation_child");
            }
            if(!obj_params.HasParam("BelongsTo")){
                obj_params.SetString("BelongsTo", identifier);
            }
            children.insertLast(all_objects[i]);
        }else{
            obj_params.Remove("" + hotspot.GetID());
        }
    }
}

void WritePlaceholderIndexes(){
    for(uint i = 0; i < animation_keys.size(); i++){
        if(!ObjectExists(animation_keys[i])){
            continue;
        }
        Object@ placeholder = ReadObjectFromID(animation_keys[i]);
        ScriptParams@ placeholder_params = placeholder.GetScriptParams();
        placeholder_params.SetInt("Index", i);
    }
}

void Dispose(){
    level.StopReceivingLevelEvents(hotspot.GetID());
    if(!GetInputDown(0, "z")){
        if(GetInputDown(0, "delete")){
            for(uint i = 0; i < animation_keys.size(); i++){
                if(ObjectExists(animation_keys[i])){
                    QueueDeleteObjectID(animation_keys[i]);
                }
            }
            for(uint i = 0; i < children.size(); i++){
                if(ObjectExists(children[i])){
                    //A work-around deleting manually.
                        DeleteObjectID(children[i]);
                    }
                }
            if(ObjectExists(main_object)){
                DeleteObjectID(main_object);
            }
        }
    }
}
