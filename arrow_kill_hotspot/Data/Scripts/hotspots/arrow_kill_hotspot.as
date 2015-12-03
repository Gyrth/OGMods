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
    //The distance from the character where the arrows are spawned.
    params.AddIntSlider("Distance",15,"min:2,max:20");
    //The speed at which the arrows are launched at the character.
    params.AddFloatSlider("Arrow Velocity",50.0,"min:1.0,max:200,step:1.0,text_mult:1");
    //The interval in which the arrows will be spawned.
    params.AddFloatSlider("Interval",1.0,"min:0.1,max:1,step:0.1,text_mult:10");
    //If you only want to shoot a certain number of arrows enable this.
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
    //If the character enters the hotspot twice it won't add it another time.
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
                //Stop shooting if the character is already dead.
                if(victim.GetIntVar("knocked_out") == _awake){
                    bool arrowShot = false;
                    //Keep finding a way to shoot the character until the arrow is not obstructed.
                    while(arrowShot == false){
                        vec3 victimPos = victim.rigged_object().GetAvgIKChainPos("torso");
                        vec3 offset = vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f));
                        vec3 spawnPos = victimPos + normalize(offset) * params.GetFloat("Distance");
                        //This script does not have access to the col object.
                        //So the character will check if the arrow is obstructed and save the result in a boolean named blinking.
                        string command = "vec3 spawnPos = vec3("+ spawnPos +");" +
                                        "vec3 hit = col.GetRayCollision(this_mo.position, spawnPos);" +
                                        "blinking = false; " +
                                        "if(distance(hit, this_mo.position) < distance(this_mo.position, spawnPos)){ " +
                                        "   blinking = true;} ";
                        victim.Execute(command);
                        //Now we fetch the boolean we just set.
                        bool obstructed = victim.GetBoolVar("blinking");
                        if(obstructed == false){
                            //Turns out the arrow is not obstructed.
                            int newArrowID = CreateObject(arrowPath);
                            //Add the arrow id to the array so that it can be deleted on Reset.
                            arrow_ids.insertLast(newArrowID);
                            //The Object is used to set the position and rotation of the arrow.
                            Object@ newArrowObject = ReadObjectFromID(newArrowID);
                            //Set the arrow to the position that's been randomly created before.
                            newArrowObject.SetTranslation(spawnPos);
                            quaternion rot;
                            vec3 dir = newArrowObject.GetRotation() * vec3(0,-1,0);
                            GetRotationBetweenVectors(dir, spawnPos - victimPos, rot);
                            //The ItemObject is used to set the velocity of the arrow.
                            ItemObject@ newArrowItem = ReadItemID(newArrowID);
                            newArrowItem.SetSafe();
                            //The rotation is set to point the tip to the character.
                            newArrowObject.SetRotation(rot);
                            vec3 direction = normalize(victimPos - spawnPos);
                            //Request the velocity that has been set and multiply it with the direction to shoot it at the victim.
                            newArrowItem.SetLinearVelocity(direction*params.GetInt("Arrow Velocity"));
                            newArrowItem.SetThrown();
                            newArrowItem.SetThrownStraight();
                            //The arrow has been shot. So end the while loop.
                            arrowShot = true;
                            //If the limit is set and the nr of arrows is met it will stop shooting.
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