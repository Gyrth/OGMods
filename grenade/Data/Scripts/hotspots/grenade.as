int grenade_id = CreateObject("Data/Items/grenade.xml", true);
Object@ grenade = ReadObjectFromID(grenade_id);
Object@ grenade_hotspot = ReadObjectFromID(hotspot.GetID());
ItemObject@ io = ReadItemID(grenade_id);
vec3 hotspot_pos = grenade_hotspot.GetTranslation();
float time = 0.0f;
float grenade_time = 0.0f;
float delay = 5.0f;
bool grenade_thrown = false;
int PublicProp;
int char_id = -1;
int id = -1;

void Init() {
    vec3 spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+0.2f, hotspot_pos.z);
    grenade.SetTranslation(spawn_point);
    grenade.SetSelectable(true);
    grenade.SetTranslatable(true);
    grenade_hotspot.SetScale(vec3(0.1f,0.1f,0.1f));
}

void SetParameters() {

}

void Reset(){
  grenade_time = 0.0f;
  grenade_thrown = false;
}

void Update() {
    time += time_step;
    if(grenade_thrown){
        if((time - grenade_time)>delay && grenade_id != -1){
          vec3 start = io.GetPhysicsPosition();
          MakeMetalSparks(start);
          for(int i=0; i<3; i++){
                MakeParticle("Data/Particles/explosion_smoke.xml",start,
                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
          }
          PlaySound("Data/Sounds/explosion.wav", start);
          array<int> nearby_characters;
          GetCharactersInSphere(start, 10.0f, nearby_characters);
          int num_chars = nearby_characters.size();
          for(int i=0; i<num_chars; ++i){
              MovementObject@ char = ReadCharacterID(nearby_characters[i]);
              vec3 force = normalize(char.position - start) * 40000.0f;
              force.y += 1000.0f;
              char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
               "HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 5.0f);"+
               "ragdoll_limp_stun = 1.0f;"+
               "recovery_time = 2.0f;");
          }
          grenade_time = 0.0f;
          grenade_thrown = false;
        }
    }
    else{
        if(char_id != -1){
          MovementObject@ mo = ReadCharacterID(char_id);
          if( id == grenade_id && mo.QueryIntFunction("bool WantsToDropItem()") == 1 ||
              id == grenade_id && mo.QueryIntFunction("bool WantsToThrowItem()") == 1 && mo.QueryIntFunction("int GetThrowTarget()") != -1){
            PlaySound("Data/Sounds/pin_pull_mono.wav", mo.position);
            grenade_time = time;
            grenade_thrown = true;
          }
          id = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
        }
        char_id = io.HeldByWhom();
    }
}

void MakeMetalSparks(vec3 pos){
  int num_sparks = 60;
	float speed = 20.0f;
    for(int i=0; i<num_sparks; ++i){
        MakeParticle("Data/Particles/explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
                                                                  RangedRandomFloat(-speed,speed),
                                                                  RangedRandomFloat(-speed,speed)));
    }
}
