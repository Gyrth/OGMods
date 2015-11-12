void HandleSpecialKeyPresses() {
    if(!DebugKeysEnabled()){
        return;
    }
    if(GetInputDown(this_mo.controller_id, ragdoll_key) && !GetInputDown(this_mo.controller_id, ctrl_key)){
        GoLimp();
    }
    if(GetInputDown(this_mo.controller_id, injured_ragdoll_key)){                
        if(state != _ragdoll_state){
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
        }
        Ragdoll(_RGDL_INJURED);
    }
    if(GetInputPressed(this_mo.controller_id, cut_throat_key)){   
        CutThroat();
    }
    if(GetInputDown(this_mo.controller_id, limp_ragdoll_key)){        
        Ragdoll(_RGDL_LIMP);
    }
    if(GetInputDown(this_mo.controller_id, recover_key)){      
        Recover();
    }

    if(this_mo.controlled){
        if(GetInputDown(this_mo.controller_id, scream_key)){
            string sound = "Data/Sounds/voice/torikamal/fallscream.xml";
            this_mo.ForceSoundGroupVoice(sound, 0.0f);
        }
        if(GetInputPressed(this_mo.controller_id, lightning_key)){
            int num_chars = GetNumCharacters();
            for(int i=0; i<num_chars; ++i){
                MovementObject @char = ReadCharacter(i);
                if(char.getID() == this_mo.getID()){
                    continue;
                }
                vec3 start = this_mo.rigged_object().GetAvgIKChainPos("head");
                vec3 end = char.rigged_object().GetAvgIKChainPos("torso");
                float length = distance(end, start);
                if(length > 10){
                    continue;
                }
                PlaySound("Data/Sounds/ambient/amb_canyon_rock_1.wav", this_mo.position);
                MakeMetalSparks(start);
                MakeMetalSparks(end);
                int num_sparks = int(length * 5);
                for(int j=0; j<num_sparks; ++j){
                    MakeMetalSparks(mix(start, end, j/float(num_sparks)));
                }
                vec3 force = normalize(char.position - this_mo.position) * 40000.0f;
                force.y += 1000.0f;
                char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                             "HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 5.0f);"+
                             "ragdoll_limp_stun = 1.0f;"+
                             "recovery_time = 2.0f;");
            }
        }
        if(GetInputPressed(this_mo.controller_id, combat_rabbit_key)){ 
            int rand_int = rand()%3;
            switch(rand_int){
            case 0:
                SwitchCharacter("Data/Characters/guard.xml");
                break;
            case 1:
                SwitchCharacter("Data/Characters/raider_rabbit.xml");
                break;
            case 2:
                SwitchCharacter("Data/Characters/pale_turner.xml");
                break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, civ_rabbit_key)){
            int rand_int = rand()%8;
            switch(rand_int){
            case 0: 
                SwitchCharacter("Data/Characters/male_rabbit_1.xml"); break;
            case 1: 
                SwitchCharacter("Data/Characters/male_rabbit_2.xml"); break;
            case 2: 
                SwitchCharacter("Data/Characters/male_rabbit_3.xml"); break;
            case 3: 
                SwitchCharacter("Data/Characters/female_rabbit_1.xml"); break;
            case 4:
                SwitchCharacter("Data/Characters/female_rabbit_2.xml"); break;
            case 5: 
                SwitchCharacter("Data/Characters/female_rabbit_3.xml"); break;
            case 6: 
            case 7: 
                SwitchCharacter("Data/Characters/pale_rabbit_civ.xml"); break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, cat_key)){
            int rand_int = rand()%4;
            switch(rand_int){
            case 0: 
                SwitchCharacter("Data/Characters/fancy_striped_cat.xml"); break;
            case 1: 
                SwitchCharacter("Data/Characters/female_cat.xml"); break;
            case 2: 
                SwitchCharacter("Data/Characters/male_cat.xml"); break;
            case 3: 
                SwitchCharacter("Data/Characters/striped_cat.xml"); break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, rat_key)){
            int rand_int = rand()%3;
            switch(rand_int){
            case 0: 
                SwitchCharacter("Data/Characters/rat.xml"); break;
            case 1: 
                SwitchCharacter("Data/Characters/hooded_rat.xml"); break;
            case 2: 
                SwitchCharacter("Data/Characters/female_rat.xml"); break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, wolf_key)){
            int rand_int = rand()%6;
            switch(rand_int){
            case 0: 
                SwitchCharacter("Data/Characters/wolf.xml"); break;
            default: 
                SwitchCharacter("Data/Characters/male_wolf.xml"); break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, dog_key)){
            int rand_int = rand()%4;
            switch(rand_int){
            case 0: 
                SwitchCharacter("Data/Characters/lt_dog_big.xml"); break;
            case 1: 
                SwitchCharacter("Data/Characters/lt_dog_female.xml"); break;
            case 2: 
                SwitchCharacter("Data/Characters/lt_dog_male_1.xml"); break;
            case 3: 
                SwitchCharacter("Data/Characters/lt_dog_male_2.xml"); break;
            }
        }
        if(GetInputPressed(this_mo.controller_id, rabbot_key)){
            SwitchCharacter("Data/Characters/rabbot.xml");
        }
        if(GetInputPressed(this_mo.controller_id, misc_key)){
            //SwapWeaponHands();
        }
    }
    if(GetInputPressed(this_mo.controller_id, path_key) && target_id != -1){
        Print("Getting path");
        NavPath temp = GetPath(this_mo.position,
                               ReadCharacterID(target_id).position);
        int num_points = temp.NumPoints();
        for(int i=0; i<num_points-1; i++){
            DebugDrawLine(temp.GetPoint(i),
                          temp.GetPoint(i+1),
                          vec3(1.0f,1.0f,1.0f),
                          _fade);
        }
    }
}