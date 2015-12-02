array<int> victim_ids;
array<int> arrow_ids;
bool triggered = false;
float time = 0.0f;
float last_time = 0.0f;
string arrowPath = "Data/Items/StandardArrow.xml";


void Init() {
}

void Reset(){
    //Clear the array with the character ids so that the hotspot will stop shooting.
    victim_ids.resize(0);
    //Remove all the arrows that have been shot.
    for(uint32 i = 0;i<arrow_ids.length();i++){
        DeleteObjectID(arrow_ids[i]);
    }
    arrow_ids.resize(0);
    triggered = false;
}

void SetParameters() {
    params.AddFloatSlider("Distance",5.0,"min:1,max:20,step:0.5,text_mult:1");
    params.AddFloatSlider("Interval",0.5,"min:0.1,max:1,step:0.1,text_mult:10");

    params.AddIntCheckbox("LimitArrows", false);
    params.AddInt("NrArrows", 1);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    int alreadyVictim = victim_ids.find(mo.GetID());
    if(alreadyVictim == -1){
        victim_ids.insertLast(mo.GetID());
        triggered = true;
    }
}

void OnExit(MovementObject @mo) {
    
}

void Update() {
    if(triggered){
        time += time_step;
        if((time - last_time)>params.GetFloat("Interval")){
            for(uint32 i = 0; i<victim_ids.length();i++){
                MovementObject@ victim = ReadCharacterID(victim_ids[i]);
                if(victim.GetIntVar("knocked_out") == _awake){
                    vec3 victimPos = victim.rigged_object().GetAvgIKChainPos("torso");
                    vec3 offset = vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f));
                    vec3 spawnPos = victimPos + normalize(offset) * params.GetFloat("Distance");

                    string command = "vec3 spawnPos = vec3("+ spawnPos +");" +
                                    "vec3 hit = col.GetRayCollision(this_mo.position, spawnPos);" +
                                    "blinking = false; " +
                                    "if(distance(hit, this_mo.position) < distance(this_mo.position, spawnPos)){ " +
                                    "   blinking = true;} ";
                    victim.Execute(command);
                    bool obstructed = victim.GetBoolVar("blinking");
                    if(obstructed == false){
                        int newArrowID = CreateObject(arrowPath);
                        arrow_ids.insertLast(newArrowID);
                        Object@ newArrowObject = ReadObjectFromID(newArrowID);
                        newArrowObject.SetTranslation(spawnPos);

                        quaternion rot;
                        vec3 dir = newArrowObject.GetRotation() * vec3(0,-1,0);
                        GetRotationBetweenVectors(dir, spawnPos - victimPos, rot);

                        newArrowObject.SetRotation(rot);
                        ItemObject@ newArrowItem = ReadItemID(newArrowID);
                        
                        //newArrowItem.ActivatePhysics();

                        newArrowItem.SetLinearVelocity((victimPos - spawnPos)*5.0f);
                        newArrowItem.SetThrown();
                        //newArrowItem.SetThrownStraight();

                        DebugDrawWireSphere(spawnPos, 0.1f, vec3(1), _fade);
                    }
                }
            }
            last_time = time;
        }
    }
}