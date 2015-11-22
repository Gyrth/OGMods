class Arrow {
    string type;
    float timeShot;
    int arrowID;
    int victimID = -1;
    vec3 explosionPos;
    bool triggered = false;
}

class BowAndArrow {

    //Bow and arrow variables.
    float previousTime;
    int aimAnimationID = -1;
    bool shortDrawAnim = false;
    int bowUpDownAnim;
    float start_throwing_time = 0.0f;
    uint32 aimingParticle;
    uint32 miscParticleID;
    bool isAiming = false;
    array<Arrow> arrows;
    bool longDrawAnim = false;

   void BowAiming(){
        if(start_throwing_time == 0.0f){
            start_throwing_time = time;
        }
        BoneTransform transform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kHeadIK]]);
        ItemObject@ primaryWeapon = ReadItemID(weapon_slots[primary_weapon_slot]);
        ItemObject@ secondaryWeapon = ReadItemID(weapon_slots[secondary_weapon_slot]);
        vec3 cameraFacing = camera.GetFacing();
        Object@ charObject = ReadObjectFromID(this_mo.GetID());
        
        quaternion head_rotation = transform.rotation;
        vec3 facing = camera.GetFacing();
        vec3 start = facing * 3.0f;
        //Limited aim enabled.        
        vec3 end = vec3(facing.x, max(-0.9, min(0.3f, facing.y)), facing.z) * 30.0f;
        //Collision check for non player objects
        vec3 hit = col.GetRayCollision(camera.GetPos() + start, camera.GetPos() + end);
        //Collision check for player objects.
        col.CheckRayCollisionCharacters(camera.GetPos() + start, camera.GetPos() + end);

        const CollisionPoint contact = sphere_col.GetContact(0);

        if(contact.position != vec3(0,0,0) && distance(transform.origin, hit) > distance(transform.origin ,contact.position)){
            throw_target_pos = contact.position;
        }else{
            throw_target_pos = hit;
        }

        aimingParticle = MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/aim.xml", throw_target_pos, vec3(0));

        fov = max(fov - ((time - start_throwing_time)), 40.0f);
        
        cam_pos_offset = vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5);

        int8 flags = _ANM_FROM_START;
        
        if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
            if(shortDrawAnim == false){
                PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);

            }

            this_mo.SetAnimation("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_stance.anm", 20.0f, flags);

            this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 5.0f);
            
            if(this_mo.GetFacing().y >0){
                bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_stance_aim_up.anm",(60*this_mo.GetFacing().y/2),flags);
            }else{
                bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_stance_aim_down.anm",-(60*this_mo.GetFacing().y/2),flags);
            }
            
            if(cameraFacing.y > -1.0f){
                this_mo.SetRotationFromFacing(normalize(cameraFacing + vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5)));
            }

            mat4 bowTransform = secondaryWeapon.GetPhysicsTransform();
            Object@ bowObject = ReadObjectFromID(secondaryWeapon.GetID());
            bowObject.SetScale(vec3(2));

            BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
            quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());

            shortDrawAnim = true;
            longDrawAnim = false;
        }else{
            shortDrawAnim = false;
            longDrawAnim = true;
        }
        isAiming = true;
    }
    void BowShoot(){
        if(weapon_slots[primary_weapon_slot] == -1){
            isAiming = false;
            start_throwing_time = 0.0f;

        }else{
            
            Print("The time while aiming was " + (time - start_throwing_time) + "\n");
            this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 1.0f);
            true_max_speed = _base_true_max_speed;  
            if((time - start_throwing_time) < 0.5f && fov > 50){
                shortDrawAnim = false;
                longDrawAnim = true;
                going_to_throw_item = true;
                going_to_throw_item_time = time;
            }
            Object@ mainArrow = ReadObjectFromID(weapon_slots[primary_weapon_slot]);
            ScriptParams@ arrowParams = mainArrow.GetScriptParams();

            Arrow arrowShot;
            arrowShot.arrowID = weapon_slots[primary_weapon_slot];
            arrowShot.timeShot = time;
            arrowShot.type = arrowParams.GetString("Type");
            Print("The type is " + arrowShot.type + "\n");
            arrows.insertLast(arrowShot);


            going_to_throw_item = true;
            going_to_throw_item_time = time;

            this_mo.SetRotationFromFacing(camera.GetFacing());
            
            isAiming = false;
            throw_anim = false;
        }
    }
    void BowShootAnim(){
        int8 flags = 0;
        SetState(_attack_state);
        string draw_type = "empty";
        if(shortDrawAnim){
            draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_short.anm";
            longDrawAnim = false;
        }else{
            PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);
            longDrawAnim = true;
            int number = rand()%3;
            switch(number){
            case 0: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow.anm";break;
            case 1: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_askew.anm";break;
            case 2: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_sideways.anm";break;
            }
        }

        this_mo.SetAnimation(draw_type, 8.0f, flags);
    }
    void BowShootAnimInAir(){
        int8 flags = 0;
        SetState(_movement_state);
        PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);
        throw_knife_layer_id = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_running.anm",20.0f,flags);
        throw_anim = true;
    }
    void HandleArrows(){
        if(arrows.size() > 0){
            for(uint32 i = 0; i<arrows.size(); i++){
                Arrow curArrow = arrows[i];
                float lifeTime;

                if(i == arrows.size() - 1 && inSlowMo){
                    ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                    cam_pos_offset = (arrowItem.GetPhysicsPosition() - this_mo.position);
                }

                if(curArrow.type == "impactexplosion"){

                    //This arrow has a maximum falltime of 60 seconds. But it will most likely explode before that.
                    lifeTime = 60.0f;
                    ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                    
                    //When the arrow leaves the hand of the character it will be active.
                    if(arrowItem.HeldByWhom() != this_mo.GetID()){
                        //When the velocity is low enough it is save to assume it has hit something.
                        if(length(arrowItem.GetLinearVelocity()) < 20.0f){
                            //Use the position of the arrow to calculate the exposion direction.
                            vec3 start = arrowItem.GetPhysicsPosition();
                            //A nice explosion video with a couple of smoke particles.
                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/fire_expanding.xml",start,vec3(0.0f,10.0f,0.0f));

                            for(int j=0; j<3; j++){
                                //This particle is just smoke.
                                MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosion_smoke.xml",start,
                                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(2.0f,5.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
                                //While this one leave a nice decal on the ground or objects that are near.
                                MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosiondecal.xml",start,
                                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*30.0f);
                            }
                            //A very loud explosion sound at the arrow position.
                            PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/explosion.wav", start);
                            //Now it's time to apply the forces and damage to any near characters.
                            array<int> nearbyCharacters;
                            //This explosion has a radius of 5.0f;
                            GetCharactersInSphere(start, 5.0f, nearbyCharacters);
                            for(uint32 k=0; k<nearbyCharacters.size(); ++k){
                                MovementObject@ char = ReadCharacterID(nearbyCharacters[k]);
                                //Every character will receive a velocity, damage and ragdoll state.
                                //If it's the character that shot the arrow in the first place, we don't have to use Execute.
                                if(char.GetID() == this_mo.GetID()){
                                    vec3 force = normalize(char.position - start) * 40000.0f;
                                    force.y += 1000.0f;
                                    HandleRagdollImpactImpulse(force, this_mo.rigged_object().GetAvgIKChainPos("torso"), 5.0f);
                                    ragdoll_limp_stun = 1.0f;
                                    recovery_time = 2.0f;
                                }else{
                                    vec3 force = normalize(char.position - start) * 40000.0f;
                                    force.y += 1000.0f;
                                    char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                                    "HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 5.0f);"+
                                    "ragdoll_limp_stun = 1.0f;"+
                                    "recovery_time = 2.0f;");
                                }
                            }
                            //DebugDrawWireSphere(start, 50.0f, vec3(0), _fade);
                            nearbyCharacters.resize(0);
                            GetCharactersInSphere(start, 50.0f, nearbyCharacters);
                            for(uint32 k=0; k<nearbyCharacters.size(); ++k){
                                MovementObject@ char = ReadCharacterID(nearbyCharacters[k]);
                                if(!char.controlled){
                                    char.Execute("vec3 pos = vec3("+start.x+", "+start.y+", "+start.z+");" +
                                        "NotifySound("+ this_mo.GetID() + ", pos);");
                                }
                            }
                            //DebugDrawWireSphere(start, 20.0f, vec3(1), _fade);
                            nearbyCharacters.resize(0);
                            GetCharactersInSphere(start, 20.0f, nearbyCharacters);
                            for(uint32 k=0; k<nearbyCharacters.size(); ++k){
                                MovementObject@ char = ReadCharacterID(nearbyCharacters[k]);
                                if(!char.controlled){
                                    char.Execute("SetGoal(_investigate);" +
                                        "SetSubGoal(_investigate_around);");
                                }
                            }
                            //If the arrow has explode it can be removed from the arrow array.
                            arrows.removeAt(i);
                            i--;
                        }
                    }

                }else if(curArrow.type == "poison"){
                    lifeTime = 10.0f;
                    ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                    
                    //If the arrow is stuck in someone it will apply damage.
                    if(curArrow.victimID == -1){

                        //Cannot write the victimID to the curArrow which is a copy. So write directly to the arrow on the correct index.
                        arrows[i].victimID = arrowItem.StuckInWhom();
                        //Once the victim is poisoned it will freak out and find who's shot him/her
                        if(curArrow.victimID != -1){
                            MovementObject@ char = ReadCharacterID(curArrow.victimID);
                            if(!char.controlled){
                                char.Execute("SetGoal(_investigate);" +
                                    "SetSubGoal(_investigate_around);");
                            }
                        }
                    }else{
                        
                        if (time - previousTime > 0.1f){
                            MovementObject@ victim = ReadCharacterID(curArrow.victimID);
                            if(victim.GetIntVar("knocked_out") == _awake){
                                victim.Execute("TakeDamage(0.02f);");
                            }
                            if(victim.GetIntVar("knocked_out") != _awake){
                                victim.Execute("Ragdoll(_RGDL_INJURED);");
                                //If the arrow has killed the victim it can be removed from the arrow array.
                                arrows.removeAt(i);
                                i--;
                            }
                            previousTime = time;
                        }
                        
                    }
                }else if(curArrow.type == "poisoncloud"){
                    lifeTime = 18.0f;
                    //Activate the green smoke trail after 0.7 seconds.
                    if((time - curArrow.timeShot) > 0.7f){
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        //On exactly 5 seconds the arrow will explode in green smoke.
                        if((time - curArrow.timeShot) > 5.0f && curArrow.triggered == false){
                            arrows[i].triggered = true;
                            //The position of the arrow will be the spawnpoint of all the particles
                            vec3 start = arrowItem.GetPhysicsPosition();
                            arrows[i].explosionPos = start;
                            for(int j =0; j < 20; j++){
                                MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/poison_smoke.xml", arrowItem.GetPhysicsPosition(), 
                                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*200.0f);
                            }
                        //Before 5 seconds a smoketrail add a green smoketrail.
                        }else if((time - curArrow.timeShot) < 5.0f){
                            if (time - previousTime > 0.1){
                                MakeParticle("Data/Particles/smoke.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)), vec3(0.0f,0.5f,0.0f));
                                previousTime = time;
                            }
                        }
                        //After 5 seconds all the characters that are near will receive damage
                        if((time - curArrow.timeShot) > 5.0f && curArrow.triggered && (time - previousTime) > 1.0f){
                            array<int> nearbyCharacters;
                            GetCharactersInSphere(curArrow.explosionPos, 5.0f, nearbyCharacters);
                            Print("apply damage "+ nearbyCharacters.size() + "\n");
                            for(uint32 j=0; j<nearbyCharacters.size(); ++j){
                                MovementObject@ victim = ReadCharacterID(nearbyCharacters[j]);

                                if(victim.GetID() == this_mo.GetID()){
                                    if(knocked_out == _awake){
                                        TakeDamage(0.25f);
                                    }
                                    if(knocked_out != _awake){
                                        Ragdoll(_RGDL_INJURED);
                                        Ragdoll(_RGDL_LIMP);
                                    }
                                }else{
                                    if(victim.GetIntVar("knocked_out") == _awake){
                                        victim.Execute("TakeDamage(0.25f);");
                                    }
                                    if(victim.GetIntVar("knocked_out") != _awake){
                                        //Once the character has no health left it will flail around a bit and die.
                                        victim.Execute("Ragdoll(_RGDL_INJURED);");
                                        //victim.Execute("Ragdoll(_RGDL_LIMP);");
                                    }
                                }

                            }
                            previousTime = time;
                        }
                    }
                }else if(curArrow.type == "smoke"){
                    //The smoke arrow will explode in 5 seconds.
                    lifeTime = 5.0f;
                    //Every .1 second a smoketrail particle will spawn on the arrow position.
                    if (time - previousTime > 0.1){
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        MakeParticle("Data/Particles/smoke.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
                        previousTime = time;
                    }
                    //Once the 5 second mark is reached it explodes.
                    if((curArrow.timeShot + lifeTime) < time){
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        vec3 start = arrowItem.GetPhysicsPosition();

                        array<int> nearbyCharacters;
                        GetCharactersInSphere(start, 7.0f, nearbyCharacters);
                        //DebugDrawWireSphere(start, 7.0f, vec3(0), _fade);
                        //The particles will go into a random direction from the arrow position.
                        for(int k =0; k < 10; k++){
                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/lasting_smoke.xml", arrowItem.GetPhysicsPosition(), 
                            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*200.0f);
                        }
                        //Every non player character will be startlet for 3 seconds and start looking around.
                        for(uint32 j=0; j<nearbyCharacters.size(); ++j){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[j]);
                            if(!char.controlled){
                                char.Execute("startled = true;" +
                                    "startle_time = 5.0f;" +
                                    "SetGoal(_investigate);" +
                                    "SetSubGoal(_investigate_around);");
                            }
                        }
                    }

                }else if(curArrow.type == "standard"){
                    //A standard arrow still has a 5 seconds lifetime because camera still needs to be zoomed in to see the impact.
                    lifeTime = 5.0f;
                    previousTime = time;
                }else if(curArrow.type == "timedexplosion"){
                    //The timed explosion has a lifetime of 5 seconds.
                    lifeTime = 5.0f;
                    if (time - previousTime > 0.01){
                        //These metalsparks are a sort of fuse effect that will trail behind.
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        miscParticleID = MakeParticle("Data/Particles/metalspark.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
                        previousTime = time;
                    }
                    //Once the 5 seconds are over the explosion starts. Just like the impact arrow.
                    if((curArrow.timeShot + lifeTime) < time){
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        vec3 start = arrowItem.GetPhysicsPosition();
                        array<int> nearbyCharacters;
                        GetCharactersInSphere(start, 5.0f, nearbyCharacters);
                        MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/fire_expanding.xml",start,vec3(0.0f,10.0f,0.0f));
                        for(int j=0; j<3; j++){
                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosion_smoke.xml",start,
                            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(2.0f,5.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosiondecal.xml",start,
                            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*30.0f);
                        }
                        PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/explosion.wav", start);
                        for(uint32 j=0; j<nearbyCharacters.size(); ++j){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[j]);
                            if(char.GetID() == this_mo.GetID()){
                                Print("Found player\n");
                                vec3 force = normalize(char.position - start) * 40000.0f;
                                force.y += 1000.0f;
                                HandleRagdollImpactImpulse(force, this_mo.rigged_object().GetAvgIKChainPos("torso"), 5.0f);
                                ragdoll_limp_stun = 1.0f;
                                recovery_time = 2.0f;
                            }else{
                                vec3 force = normalize(char.position - start) * 40000.0f;
                                force.y += 1000.0f;
                                char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                                "HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 5.0f);"+
                                "ragdoll_limp_stun = 1.0f;"+
                                "recovery_time = 2.0f;");
                            }
                        }
                        //DebugDrawWireSphere(start, 50.0f, vec3(0), _fade);
                        nearbyCharacters.resize(0);
                        GetCharactersInSphere(start, 50.0f, nearbyCharacters);
                        for(uint32 k=0; k<nearbyCharacters.size(); ++k){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[k]);
                            if(!char.controlled){
                                char.Execute("vec3 pos = vec3("+start.x+", "+start.y+", "+start.z+");" +
                                    "NotifySound("+ this_mo.GetID() + ", pos);");
                            }
                        }
                        //DebugDrawWireSphere(start, 20.0f, vec3(1), _fade);
                        nearbyCharacters.resize(0);
                        GetCharactersInSphere(start, 20.0f, nearbyCharacters);
                        for(uint32 k=0; k<nearbyCharacters.size(); ++k){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[k]);
                            if(!char.controlled){
                                char.Execute("SetGoal(_investigate);" +
                                    "SetSubGoal(_investigate_around);");
                            }
                        }
                    }
                    
                }else if(curArrow.type == "flashbang"){
                    lifeTime = 5.0f;
                    ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                    //The flashbang arrow has a trail of sparks as well as a fuse.
                    if (time - previousTime > 0.01){
                        miscParticleID = MakeParticle("Data/Particles/metalspark.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
                        previousTime = time;
                    }

                    if((curArrow.timeShot + lifeTime) < time){
                        vec3 start = arrowItem.GetPhysicsPosition();
                        //The flashbang sound is an explosion with a very annoying beep after it.
                        PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/flashbang.wav", start);
                        //This particle is a very short and big light particle to emulate a big flash.
                        MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/flashbang.xml", start, vec3(0));

                        array<int> nearbyCharacters;
                        GetCharactersInSphere(start, 5.0f, nearbyCharacters);
                        //All the nearby characters will be affected.
                        for(uint32 j=0; j<nearbyCharacters.size(); ++j){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[i]);
                            //Non player characters will roll around for 5 seconds and recover.
                            if(!char.controlled){
                                char.Execute("Ragdoll(_RGDL_INJURED);"+
                                             "recovery_time = 5.0f;"+
                                             "roll_after_ragdoll_delay += 200.0f;"+
                                             "DropWeapon();");
                            }else{
                                //The character that shot the arrow will can be affected without the Execute.
                                if(char.GetID() == this_mo.GetID()){
                                    HandleRagdollImpactImpulse(vec3(0), this_mo.rigged_object().GetAvgIKChainPos("torso"), 0.0f);
                                    ragdoll_limp_stun = 5.0f;
                                    recovery_time = 5.0f;
                                    DropWeapon();
                                }else{
                                    //Any other player characters will have seperate ragdoll code but the effect is the same.
                                    char.Execute("vec3 impulse = vec3(0);" +
                                    "HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 0.0f);"+
                                    "ragdoll_limp_stun = 5.0f;"+
                                    "recovery_time = 5.0f;"+
                                    "DropWeapon();");
                                }
                                //This particle will be seen on the entire screen if a player chracter is in range.
                                //MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/flashbangonscreen.xml", start, vec3(0));
                            }
                        }
                    }
                }else{

                }
                //Once the lifetime of the arrow is met the arrow is removed from the array.
                if((curArrow.timeShot + lifeTime) < time){
                    
                    arrows.removeAt(i);
                    i--;
                }
            }
        }

    }
    void HandleBow(){
        if(weapon_slots[primary_weapon_slot] == -1){
            isAiming = false;
            longDrawAnim = false;
            shortDrawAnim = false;
            start_throwing_time = 0.0f;
            throw_anim = false;
        }else{
            //If the bow is the only weapon the character is holding a single string needs to be drawn.
            ItemObject@ primaryWeapon = ReadItemID(weapon_slots[primary_weapon_slot]);
            if (primaryWeapon.GetLabel() == "bow"){

            }
        }
        if(weapon_slots[secondary_weapon_slot] != -1){
            ItemObject@ secondaryWeapon = ReadItemID(weapon_slots[secondary_weapon_slot]);
            if (secondaryWeapon.GetLabel() == "bow"){
                if(throw_anim){
                    if(longDrawAnim && ((time - start_throwing_time) < 0.5f && fov > 50)){
                        float throw_range = 50.0f;
                        int target = GetClosestCharacterID(throw_range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL);
                        SetTargetID(target);
                        if(target != -1){
                            throw_target_pos = ReadCharacterID(target).rigged_object().GetAvgIKChainPos("torso");
                        }
                    }
                    DrawDoubleSting(weapon_slots[secondary_weapon_slot]);
                }else if(isAiming && floor(length(this_mo.velocity)) < 2.0f && on_ground){
                    DrawDoubleSting(weapon_slots[secondary_weapon_slot]);
                }
                else{
                    DrawSingleString(weapon_slots[secondary_weapon_slot]);
                }
            }
        }
    }

    void DrawSingleString(int weaponID){
        ItemObject@ primaryWeapon = ReadItemID(weaponID);
        mat4 bowTransform = primaryWeapon.GetPhysicsTransform();
        BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kRightArmKey]]);
        quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());
        DebugDrawLine(primaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.13,-0.70,0)), primaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.13,0.70,0)), vec3(0), _delete_on_update);
    }
    void DrawDoubleSting(int weaponID){
        ItemObject@ secondaryWeapon = ReadItemID(weaponID);
        mat4 bowTransform = secondaryWeapon.GetPhysicsTransform();
        BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
        quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());

        DebugDrawLine(handTransform.origin, secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.13,0.70,0)), vec3(0), _delete_on_update);
        DebugDrawLine(handTransform.origin, secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.13,-0.70,0)), vec3(0), _delete_on_update);
    }
};