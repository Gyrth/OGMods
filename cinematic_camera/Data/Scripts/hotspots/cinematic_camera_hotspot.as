array<int> pathpoint_ids;
int previousPathpointID = -1;
int camera_id = -1;
vec3 unnoticableOffset = vec3(0.01f,0.01f,0.01f);
string pathpoint_path = "Data/Objects/placeholder/empty_placeholder.xml";

int currentPathPointIndex = 0;

Object@ mainHotspot = ReadObjectFromID(hotspot.GetID());
bool postInitDone = false;
bool animationDone = false;

void Init() {
	Print("init\n");
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
	
}

void Reset(){
	Print("rest\n");
    currentPathPointIndex = 0;
    animationDone = false;
    Object@ camera_obj = ReadObjectFromID(camera_id);
    camera_obj.SetTranslation(ReadObjectFromID(pathpoint_ids[currentPathPointIndex]).GetTranslation() + unnoticableOffset);
}

void CheckKeyPresses(){
	if(GetInputPressed(0, "l")){
		Reset();
	}
}

void Update(){
	if(postInitDone == true){
		CheckKeyPresses();
		DrawCameraPos();
		if(EditorModeActive()){
			AddOrRemovePathpoints();
			DrawPathpointLines();
		}
		if(animationDone == false){
            Object@ camera_obj = ReadObjectFromID(camera_id);
			
            vec3 nextPathpointPos = ReadObjectFromID(pathpoint_ids[currentPathPointIndex]).GetTranslation();
            vec3 currentPos = camera_obj.GetTranslation();
			
			//Print("test\n");
            if(distance(nextPathpointPos + unnoticableOffset, currentPos) < 0.05f){
                previousPathpointID = pathpoint_ids[currentPathPointIndex];
                currentPathPointIndex++;

                int numPathpoints = pathpoint_ids.size();
                if(currentPathPointIndex >= numPathpoints){
                    animationDone = true;
                    currentPathPointIndex = 0;
					return;
                }
            }
			//Print(animationDone + "\n");
            if(animationDone == false){
                    //Position
					//Print("test\n");
                    vec3 tempvec = ((nextPathpointPos + unnoticableOffset) - currentPos);
                    vec3 direction = normalize(tempvec);
                    vec3 newPos = currentPos + (direction * 0.03f);
                    camera_obj.SetTranslation(newPos);
            }
			//Rotation
			//int player_id = GetPlayerCharacterID();
			int player_id = 0;
			if(player_id != -1){
				MovementObject@ player = ReadCharacter(player_id);
				
				quaternion new_cam_rot;
				vec3 start = camera_obj.GetTranslation();
				vec3 end = player.position;
				vec3 dir = normalize(start - end);
				dir.y = 0.0f;
				//vec3 dir = camera_obj.GetRotation() * vec3(0,0,1);
				GetRotationBetweenVectors(vec3(0.0f, 0.0f, 1.0f), dir, new_cam_rot);
				//new_cam_rot.w = 0.0f;
				camera_obj.SetRotation(new_cam_rot);
			}
        }
	}else{
        PostInit();
    }

}

void DrawPathpointLines(){
	//Print(pathpoint_ids.size() + "\n");
	for(uint i = 0; i < pathpoint_ids.size() - 1; i++){
		Object@ current_pathpoint = ReadObjectFromID(pathpoint_ids[i]);
		Object@ next_pathpoint = ReadObjectFromID(pathpoint_ids[i+1]);
		DebugDrawLine(current_pathpoint.GetTranslation(), next_pathpoint.GetTranslation(), vec3(1), _delete_on_update);
	}
}

void DrawCameraPos(){
	Object@ camera_obj = ReadObjectFromID(camera_id);
	if(animationDone){
		DebugDrawWireSphere(camera_obj.GetTranslation(), 0.1f, vec3(1,0,0), _delete_on_update);
	}else{
		DebugDrawWireSphere(camera_obj.GetTranslation(), 0.1f, vec3(0,1,0), _delete_on_update);
	}
}

void AddOrRemovePathpoints(){
	if(pathpoint_ids.size() < 1){
		CreatePathpoint();
	}
	else{
		//Check if all the pathpoints still exist.
		for(uint i = 0; i < pathpoint_ids.size(); i++){
			if(!ObjectExists(pathpoint_ids[i])){
				pathpoint_ids.removeAt(i);
				i--;
			}
		}
		array<int> all_objects = GetObjectIDsType(_placeholder_object);
		//Print(all_objects.size() + "\n");
		for(uint32 i = 0; i < all_objects.size(); i++){
	        ScriptParams@ temp_param = ReadObjectFromID(all_objects[i]).GetScriptParams();
	        if(temp_param.HasParam("BelongsTo")){
	            if(temp_param.GetInt("BelongsTo") == hotspot.GetID() && pathpoint_ids.find(all_objects[i]) == -1){
                    pathpoint_ids.insertLast(all_objects[i]);
	            }
	        }
	    }
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
	camera_id = CreateObject("Data/Objects/placeholder/camera_placeholder.xml", true);
    //When the level first loads, there might already be animations setup
    //So those are retrieved first. With the ID of this hotspot as identifier.
    array<int> allObjects = GetObjectIDs();
    for(uint32 i = 0; i<allObjects.size(); i++){
        ScriptParams@ tempParam = ReadObjectFromID(allObjects[i]).GetScriptParams();
        if(tempParam.HasParam("BelongsTo")){
            if(tempParam.GetInt("BelongsTo") == hotspot.GetID()){
                pathpoint_ids.insertLast(allObjects[i]);
            }
        }
    }
    Object@ camera_obj = ReadObjectFromID(camera_id);
    camera_obj.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
    postInitDone = true;
}

void CreatePathpoint(){
    int objID = CreateObject(pathpoint_path);
    Print(objID + "Creating new pathpoint\n");
    pathpoint_ids.push_back(objID);
    Object @newObj = ReadObjectFromID(objID);
	newObj.SetSelectable(true);
	newObj.SetCopyable(true);
	newObj.SetTranslatable(true);

    ScriptParams@ placeholderParams = newObj.GetScriptParams();
    //When a new pathpoint is created the hotspot ID is added to it's parameters.
    //This will be used when the level is closed and loaded again.
    placeholderParams.AddInt("BelongsTo", hotspot.GetID());
    placeholderParams.AddString("Playsound", "");
    newObj.SetTranslation(mainHotspot.GetTranslation() + unnoticableOffset);
}
