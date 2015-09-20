int grenade_id = CreateObject("Data/Custom/gyrth/grenade/Items/grenade.xml");
Object@ grenade = ReadObjectFromID(grenade_id);
Object@ grenade_hotspot = ReadObjectFromID(hotspot.GetID());
ItemObject@ io = ReadItemID(grenade_id);
vec3 hotspot_pos = grenade_hotspot.GetTranslation();
float time = 0.0f;
float grenade_time = 0.0f;
float delay = 5.0f;
bool grenade_thrown = false;
int PublicProp;

void Init() {
  vec3 spawn_point = vec3(hotspot_pos.x, hotspot_pos.y+0.2f, hotspot_pos.z);
  grenade.SetTranslation(spawn_point);
  grenade_hotspot.SetScale(vec3(0.1f,0.1f,0.1f));
  ScriptParams@ grenade_params = grenade.GetScriptParams();
  grenade_params.AddIntCheckbox("No Save", true);
}

void SetParameters() {

}
void Update() {
  time += time_step;
  if(grenade_thrown){
    if((time - grenade_time)>delay && grenade_id != -1){
      vec3 start = io.GetPhysicsPosition();
      MakeParticle("Data/Custom/gyrth/grenade/Scripts/propane.xml",start,vec3(0.0f,15.0f,0.0f));

      for(int i=0; i<3; i++){
          MakeParticle("Data/Custom/gyrth/grenade/Scripts/explosion_smoke.xml",start,
              vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
      }
      PlaySound("Data/Custom/gyrth/grenade/Sounds/explosion.wav", start);


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
    array<int> nearby_characters;
    GetCharactersInSphere(io.GetPhysicsPosition(), 1.0f, nearby_characters);
    int num_chars = nearby_characters.size();
    for(int i=0; i<num_chars; ++i){
      MovementObject@ mo = ReadCharacterID(nearby_characters[i]);


        int id = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
        int id2 = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("secondary_weapon_slot"));
        Print("Prim: "+id+ " sec: "+ id2 +"\n");
        if(id == grenade_id && mo.QueryIntFunction("bool WantsToThrowItem()")==1){
            PlaySound("Data/Custom/gyrth/grenade/Sounds/pin_pull_mono.wav", mo.position);
            grenade_time = time;
            grenade_thrown = true;
        }
    }
  }
}
