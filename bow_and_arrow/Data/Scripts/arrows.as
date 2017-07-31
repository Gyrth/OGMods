class Arrow {
  int arrow_id = -1;
  int victim_id = -1;
  bool triggered = false;
  bool remove = false;
  float duration = 0.0f;
  float start_time = time;
  float interval_timer;
  void Update(){
      if(time - start_time > duration){
          Trigger();
          remove = true;
      }
      LocalUpdate();
  }
  void LocalUpdate(){
      //Print("wrong local update\n");
  }
  void Trigger(){}
}

class StandardArrow : Arrow {
    StandardArrow(){
        //A standard arrow still has a 2 seconds lifetime because camera still needs to be zoomed in to see the impact.
        duration = 2.0f;
    }
}

class TimedExplosionArrow : Arrow {
    TimedExplosionArrow(){
        //The timed explosion has a lifetime of 5 seconds.
        duration = 5.0f;
    }
    void LocalUpdate(){
        if (time - interval_timer > 0.1f){
            interval_timer = time;
            //These metalsparks are a sort of fuse effect that will trail behind.
            ItemObject@ arrow_item = ReadItemID(arrow_id);
            MakeParticle("Data/Particles/metalspark.xml", arrow_item.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
        }
    }
    void Trigger(){
        //Once the 5 seconds are over the explosion starts. Just like the impact arrow.
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        vec3 start = arrow_item.GetPhysicsPosition();
        array<int> nearby_characters;
        GetCharactersInSphere(start, 5.0f, nearby_characters);
        ArrowMetalSparks(start);
        ArrowSmoke(start);
        PlaySound("Data/Sounds/explosion_arrow.wav", start);
        for(uint32 j=0; j<nearby_characters.size(); ++j){
            MovementObject@ char = ReadCharacterID(nearby_characters[j]);
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
        //The noise will alarm any enemies that are near.
        //The closest enemies will go to the player.
        nearby_characters.resize(0);
        GetCharactersInSphere(start, 50.0f, nearby_characters);
        for(uint32 k = 0; k < nearby_characters.size(); k++){
            MovementObject@ char = ReadCharacterID(nearby_characters[k]);
            if(!char.controlled){
              char.Execute("vec3 pos = vec3("+start.x+", "+start.y+", "+start.z+");" +
              "NotifySound("+ this_mo.GetID() + ", pos);");
            }
        }
        nearby_characters.resize(0);
        //While enemies far away will just investigate the explosion.
        GetCharactersInSphere(start, 20.0f, nearby_characters);
        for(uint32 k = 0; k < nearby_characters.size(); k++){
            MovementObject@ char = ReadCharacterID(nearby_characters[k]);
            if(!char.controlled){
              char.Execute("SetGoal(_investigate);" +
              "SetSubGoal(_investigate_around);");
            }
        }
    }
}
class FlashBangArrow : Arrow {
    FlashBangArrow(){
        duration = 5.0f;
    }
    void LocalUpdate(){
        if (time - interval_timer > 0.1f){
            interval_timer = time;
            //The flashbang will also leave a fuse trail behind.
            ItemObject@ arrow_item = ReadItemID(arrow_id);
            MakeParticle("Data/Particles/metalspark.xml", arrow_item.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
        }
    }
    void Trigger(){
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        vec3 start = arrow_item.GetPhysicsPosition();
        //The flashbang sound is an explosion with a very annoying beep after it.
        PlaySound("Data/Sounds/flashbang_arrow.wav", start);
        ArrowMetalSparks(start);
        array<int> nearby_characters;
        GetCharactersInSphere(start, 5.0f, nearby_characters);
        //All the nearby characters will be affected.
        for(uint32 j = 0; j < nearby_characters.size(); j++){
            MovementObject@ char = ReadCharacterID(nearby_characters[j]);
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
            }
        }
    }
}
class SmokeArrow : Arrow {
    SmokeArrow(){
        //The smoke arrow will trigger in 5 seconds.
        duration = 5.0f;
    }
    void LocalUpdate(){
        if (time - interval_timer > 0.1f){
            interval_timer = time;
            //A smoketrail particle will spawn on the arrow position.
            ItemObject@ arrow_item = ReadItemID(arrow_id);
            MakeParticle("Data/Particles/smoke.xml", arrow_item.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)));
        }
    }
    void Trigger(){
        //Once the 5 second mark is reached it explodes.
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        vec3 start = arrow_item.GetPhysicsPosition();

        array<int> nearby_characters;
        GetCharactersInSphere(start, 7.0f, nearby_characters);
        //The particles will go into a random direction from the arrow position.
        for(int k = 0; k < 10; k++){
            MakeParticle("Data/Particles/bow_and_arrow_lasting_smoke.xml", arrow_item.GetPhysicsPosition(),
            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*200.0f);
        }
        //Every non player character will be startlet for 3 seconds and start looking around.
        for(uint32 j = 0; j < nearby_characters.size(); j++){
            MovementObject@ char = ReadCharacterID(nearby_characters[j]);
            if(!char.controlled){
                char.Execute("startled = true;" +
                "startle_time = 5.0f;" +
                "SetGoal(_investigate);" +
                "SetSubGoal(_investigate_around);");
            }
        }
    }
}
class PoisonCloudArrow : Arrow {
    bool trailing = false;
    vec3 explosion_position;
    PoisonCloudArrow(){
        //The smoke arrow will trigger in 5 seconds.
        duration = 18.0f;
    }
    void LocalUpdate(){
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        //Activate the green smoke trail after 0.7 seconds.
        if((time - start_time) > 0.7f && !trailing){
            trailing = true;
        }
        //After 5 seconds all the characters that are near will receive damage
        if((time - start_time) > 5.0f && !triggered){
            triggered = true;
            explosion_position = arrow_item.GetPhysicsPosition();
            //Add the green smoke.
            for(int j =0; j < 20; j++){
                MakeParticle("Data/Particles/bow_and_arrow_poison_smoke.xml", explosion_position,
                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*200.0f);
            }
        }
        if(triggered){
            if (time - interval_timer > 1.0f){
                interval_timer = time;
                array<int> nearby_characters;
                GetCharactersInSphere(explosion_position, 5.0f, nearby_characters);
                for(uint32 j = 0; j < nearby_characters.size(); j++){
                    MovementObject@ victim = ReadCharacterID(nearby_characters[j]);

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
                        }
                    }
                }
            }
        }else if(trailing){
            if (time - interval_timer > 0.1f){
                interval_timer = time;
                MakeParticle("Data/Particles/smoke.xml", arrow_item.GetPhysicsPosition(), vec3(RangedRandomFloat(-1.0f, 1.0f)), vec3(0.0f,0.5f,0.0f));
            }
        }
    }
}
class PoisonArrow : Arrow {
    PoisonArrow(){
        duration = 10.0f;
    }
    void LocalUpdate(){
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        //If the arrow is stuck in someone it will apply damage.
        if(victim_id == -1){
            victim_id = arrow_item.StuckInWhom();
            //Once the victim is poisoned it will freak out and find who's shot
            if(victim_id != -1){
                MovementObject@ char = ReadCharacterID(victim_id);
                if(!char.controlled){
                    char.Execute("SetGoal(_investigate);" +
                    "SetSubGoal(_investigate_around);");
                }
                interval_timer = time;
            }
        }else{
            if (time - interval_timer > 0.1f){
                interval_timer = time;
                MovementObject@ char = ReadCharacterID(victim_id);
                if(char.GetIntVar("knocked_out") == _awake){
                    char.Execute("TakeDamage(0.02f);");
                }else{
                    char.Execute("Ragdoll(_RGDL_INJURED);");
                    remove = true;
                }
            }
        }
    }
}
class ImpactExplosion : Arrow {
    ImpactExplosion(){
        //This arrow has a maximum falltime of 60 seconds. But it will most likely explode before that.
        duration = 60.0f;
    }
    void LocalUpdate(){
        ItemObject@ arrow_item = ReadItemID(arrow_id);
        //When the arrow leaves the hand of the character it will be active.
        if(arrow_item.HeldByWhom() != this_mo.GetID()){
            //When the velocity is low enough it is save to assume it has hit something.
            if(length(arrow_item.GetLinearVelocity()) < 75.0f){
                remove = true;
                //Use the position of the arrow to calculate the exposion direction.
                vec3 start = arrow_item.GetPhysicsPosition();
                //A nice explosion video with a couple of smoke particles.
                ArrowMetalSparks(start);
                ArrowSmoke(start);
                //A very loud explosion sound at the arrow position.
                PlaySound("Data/Sounds/explosion_arrow.wav", start);
                //Now it's time to apply the forces and damage to any near characters.
                array<int> nearby_characters;
                //This explosion has a radius of 5.0f;
                GetCharactersInSphere(start, 5.0f, nearby_characters);
                for(uint32 k = 0; k < nearby_characters.size(); k++){
                    MovementObject@ char = ReadCharacterID(nearby_characters[k]);
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
                nearby_characters.resize(0);
                GetCharactersInSphere(start, 50.0f, nearby_characters);
                for(uint32 k = 0; k < nearby_characters.size(); k++){
                    MovementObject@ char = ReadCharacterID(nearby_characters[k]);
                    if(!char.controlled){
                        char.Execute("vec3 pos = vec3("+start.x+", "+start.y+", "+start.z+");" +
                        "NotifySound("+ this_mo.GetID() + ", pos);");
                    }
                }
                nearby_characters.resize(0);
                GetCharactersInSphere(start, 20.0f, nearby_characters);
                for(uint32 k = 0; k < nearby_characters.size(); k++){
                    MovementObject@ char = ReadCharacterID(nearby_characters[k]);
                    if(!char.controlled){
                        char.Execute("SetGoal(_investigate);" +
                        "SetSubGoal(_investigate_around);");
                    }
                }
            }
        }
    }
}
