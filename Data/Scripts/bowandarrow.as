class Arrow {
    string type;
    float timeShot;
    int arrowID;
}

class BowAndArrow {

    //Bow and arrow variables.
    float previousTime;
    int aimAnimationID = -1;
    bool shortDrawAnim = false;
    int bowUpDownAnim;
    float start_throwing_time = 0.0f;
    uint32 aimingParticle;
    //vec3 throw_target_pos = -1;
    bool isAiming = false;
    array<Arrow> arrows;

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
        
        //vec3 axis = head_rotation * vec3(0,30,20);
        vec3 facing = camera.GetFacing();
        vec3 start = facing * 3.0f;
        //Limited aim enabled.        
        vec3 end = vec3(facing.x, max(-0.9, min(0.3f, facing.y)), facing.z) * 30.0f;
        //vec3 end = facing * 30.0f;
        //Collision check for non player objects
        Print(cameraFacing.y + "\n");
        vec3 hit = col.GetRayCollision(camera.GetPos() + start, camera.GetPos() + end);
        //Collision check for player objects.
        col.CheckRayCollisionCharacters(camera.GetPos() + start, camera.GetPos() + end);

        const CollisionPoint contact = sphere_col.GetContact(0);
            
            //DebugDrawWireSphere(camera.GetPos() + facing, 0.2f, vec3(1.0f,1.0f,1.0f), _delete_on_update);

        if(contact.position != vec3(0,0,0) && distance(transform.origin, hit) > distance(transform.origin ,contact.position)){
            //Print("Found character\n");
            throw_target_pos = contact.position;
        }else{
            throw_target_pos = hit;
        }
        //DebugDrawLine(camera.GetPos() + start, transform.origin + end, vec3(1), _delete_on_update);

        aimingParticle = MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/aim.xml", throw_target_pos, vec3(0));
        //Print(aimingParticle + "\n");
        //cam_distance = 1.0f;

        fov = max(fov - ((time - start_throwing_time)) ,40);
        //Print(facing + "\n");
        
        cam_pos_offset = vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5);
        
        //vec3 charFacing = this_mo.GetFacing();
        //cam_pos_offset = vec3(charFacing.x,charFacing.y,charFacing.z);

        //cam_pos_offset = transform.rotation * vec3(0.7,0,0);
        //Print("offset: " + cam_pos_offset + "\n");        


        int8 flags = _ANM_FROM_START;
        
        if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
            //old_use_foot_plants = true;
            //HandleFootStance(ts);
            //true_max_speed = 2.0f;
            if(shortDrawAnim == false){
                PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);

            }

            this_mo.SetAnimation("Data/Custom/Gyrth/bow_and_arrow/Animations/r_draw_bow_stance.anm", 20.0f, flags);

            this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 5.0f);
            
           // Print((this_mo.GetFacing().y) + "\n");
            if(this_mo.GetFacing().y >0){
                bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_stance_aim_up.anm",(40*this_mo.GetFacing().y/1),flags);
            }else{
                bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_stance_aim_down.anm",-(40*this_mo.GetFacing().y/1),0);
            }
            
            if(cameraFacing.y > -1.0f){
                this_mo.SetRotationFromFacing(normalize(cameraFacing + vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5)));
            }

            mat4 bowTransform = secondaryWeapon.GetPhysicsTransform();
            Object@ bowObject = ReadObjectFromID(secondaryWeapon.GetID());
            bowObject.SetScale(vec3(2));
            //mat4 bowMat4Rotation = bowTransform.GetRotationPart();
            BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
            quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());
            //Print("w: " + bowRotation * vec3(0,0,1) + "\n");
            shortDrawAnim = true;
        }else{
            //true_max_speed = _base_true_max_speed;
            shortDrawAnim = false;
        }
        isAiming = true;
        //DebugDrawLine(camera.GetPos(), throw_target_pos, vec3(1.0f,1.0f,1.0f), _delete_on_update);

        
        //SetState(_movement_state);
        //
        //DebugDrawWireSphere(hit, 0.1f, vec3(1.0f,1.0f,1.0f), _delete_on_update);
        //camera.AddShake((time - start_throwing_time)/2000.0f);
    }
    void BowShoot(){
        
        Print("The time while aiming was " + (time - start_throwing_time) + "\n");
        this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 1.0f);
        true_max_speed = _base_true_max_speed;  
        if((time - start_throwing_time) < 0.5f && fov > 50){
            shortDrawAnim = false;
            float throw_range = 50.0f;
            int target = GetClosestCharacterID(throw_range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL);
            if(target != -1 && (on_ground || flip_info.IsFlipping())){
                SetTargetID(target);
                throw_target_pos = ReadCharacterID(target).position;
                going_to_throw_item = true;
                going_to_throw_item_time = time;
            }
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
        start_throwing_time = 0.0f;
    }
    void BowShootAnim(){
        int8 flags = 0;
        SetState(_attack_state);
        float throw_range = 150.0f;
        //int target = GetClosestCharacterID(throw_range, _TC_ENEMY);
        //SetTargetID(target);
        
        //throw_knife_layer_id = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_running.anm",10.0f,0);
        string draw_type = "empty";
        if(shortDrawAnim){
            draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_short.anm";
        }else{
            PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);
            int number = rand()%3;
            switch(number){
            case 0: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow.anm";break;
            case 1: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_askew.anm";break;
            case 2: draw_type = "Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_sideways.anm";break;
            }
        }

        this_mo.SetAnimation(draw_type, 8.0f, flags);
        shortDrawAnim = false;
    }
    void BowShootAnimInAir(){
        int8 flags = 0;
        SetState(_movement_state);
        float throw_range = 20.0f;
        //int target = GetClosestCharacterID(throw_range, _TC_ENEMY);
        //SetTargetID(target);
        PlaySound("Data/Custom/gyrth/bow_and_arrow/Sounds/draw.wav", this_mo.position);
        throw_knife_layer_id = this_mo.rigged_object().anim_client().AddLayer("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_running.anm",20.0f,flags);
        //this_mo.SetAnimation("Data/Custom/gyrth/bow_and_arrow/Animations/r_draw_bow_running.anm", 8.0f, flags);
        throw_anim = true;
    }
    void HandleArrows(){
        if(arrows.size() > 0){
            for(uint32 i = 0; i<arrows.size(); i++){
                Arrow curArrow = arrows[i];
                float lifeTime;
                if(curArrow.type == "impactexplosion"){
                    lifeTime = 5.0f;
                    previousTime = time;

                }else if(curArrow.type == "poison"){
                    lifeTime = 5.0f;
                    previousTime = time;

                }else if(curArrow.type == "smoke"){
                    //Print(floor(time * 10) / 10 + "\n");
                    lifeTime = 5.0f;
                    if (time - previousTime > 0.05){

                        Print((floor(time * 100) / 100) + "\n");
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        MakeParticle("Data/Particles/smoke.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
                        previousTime = time;
                    }
                    

                }else if(curArrow.type == "standard"){
                    Print("Standard " + "\n");
                    lifeTime = 5.0f;
                    previousTime = time;
                }else if(curArrow.type == "timedexplosion"){
                    lifeTime = 5.0f;

                    if (time - previousTime > 0.01){

                        //Print((floor(time * 100) / 100) + "\n");
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        MakeParticle("Data/Particles/metalspark.xml", arrowItem.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
                        
                    }

                    if((curArrow.timeShot + lifeTime) < time){
                        ItemObject@ arrowItem = ReadItemID(curArrow.arrowID);
                        vec3 start = arrowItem.GetPhysicsPosition();

                        array<int> nearbyCharacters;
                        GetCharactersInSphere(start, 5.0f, nearbyCharacters);

                        MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/propane.xml",start,vec3(0.0f,2.0f,0.0f));

                        for(int i=0; i<3; i++){
                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosion_smoke.xml",start,
                            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);

                            MakeParticle("Data/Custom/gyrth/bow_and_arrow/Particles/explosiondecal.xml",start,
                            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*30.0f);
                        }

                        PlaySound("Data/Custom/gyrth/grenade/Sounds/explosion.wav", start);
                        

                        for(uint32 i=0; i<nearbyCharacters.size(); ++i){
                            MovementObject@ char = ReadCharacterID(nearbyCharacters[i]);
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
                    }

                }else{

                }
                if((curArrow.timeShot + lifeTime) < time){
                    
                    arrows.removeAt(i);
                    i--;
                }
            }
        }

    }
    void HandleBow(){
        
        

        if(weapon_slots[primary_weapon_slot] != -1){
            ItemObject@ primaryWeapon = ReadItemID(weapon_slots[primary_weapon_slot]);
            if(primaryWeapon.GetLabel() == "bow"){
                mat4 bowTransform = primaryWeapon.GetPhysicsTransform();
                BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
                quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());
                DebugDrawLine(primaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.1,-0.78,0)), primaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.1,0.78,0)), vec3(0), _delete_on_update);
            }
        }
        if(weapon_slots[secondary_weapon_slot] != -1){
            ItemObject@ secondaryWeapon = ReadItemID(weapon_slots[secondary_weapon_slot]);
            if (secondaryWeapon.GetLabel() == "bow"){
                mat4 bowTransform = secondaryWeapon.GetPhysicsTransform();
                
                if(isAiming && floor(length(this_mo.velocity)) < 2.0f && on_ground){
                    BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
                    quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());

                    DebugDrawLine(handTransform.origin, secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.1,0.78,0)), vec3(0), _delete_on_update);
                    DebugDrawLine(handTransform.origin, secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.1,-0.78,0)), vec3(0), _delete_on_update);
                }else{
                    BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
                    quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());
                    DebugDrawLine(secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.1,-0.77,0)), secondaryWeapon.GetPhysicsPosition() + (bowRotation * vec3(0.132,0.77,0)), vec3(0), _delete_on_update);
                }
            }
        }
    }

};

