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
    params.AddIntSlider("Distance",15,"min:2,max:20");
    params.AddFloatSlider("Arrow Velocity",50.0,"min:1.0,max:200,step:1.0,text_mult:1");
    params.AddFloatSlider("Interval",1.0,"min:0.1,max:1,step:0.1,text_mult:10");
    params.AddIntCheckbox("LimitArrows", false);
    params.AddInt("NrArrows", 5);
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
                    bool arrowShot = false;
                    while(arrowShot == false){
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

                            
                            ItemObject@ newArrowItem = ReadItemID(newArrowID);
                            newArrowItem.SetSafe();
                            
                            //newArrowItem.ActivatePhysics();
                            newArrowObject.SetRotation(rot);
                            vec3 direction = normalize(victimPos - spawnPos);

                            newArrowItem.SetLinearVelocity(direction*params.GetInt("Arrow Velocity"));
                            DebugText("a","Vel: "+(direction*params.GetInt("Arrow Velocity")), _delete_on_update);
                            newArrowItem.SetThrown();
                            newArrowItem.SetThrownStraight();

                            DebugDrawWireSphere(spawnPos, 0.1f, vec3(1), _fade);
                            arrowShot = true;
                            if(params.GetInt("LimitArrows") == 1 && params.GetInt("NrArrows") == int(arrow_ids.size())){
                                triggered = false;
                            }
                        }
                    }
                }
            }
            last_time = time;
        }
    }
}