vec3 laser_color = vec3(5.0f,0.0f,0.0f);
vec3 laser_smoke_color = vec3(0.5f);
float start_throwing_time = 0.0f;
bool the_force_active = false;
float the_force_fov = 90;
float max_distance = 200.0f;
float orig_sensitivity = -1.0f;
float aim_sensitivity = 0.1f;
float part_mult = 2.0f;
int laser_loop_id = -1;
int victim_id = -1;
float max_force_distance = 20.0f;

bool init_done = ForceInit();

void UpdateTheForce(){
  if(this_mo.controlled){
    if(GetInputDown(this_mo.controller_id, lightning_key) && length(this_mo.velocity) < 1.0f){
      ActivateTheForce();
    }else{
      DeactivateTheForce();
    }
  }
}

bool ForceInit(){
  orig_sensitivity = GetConfigValueFloat("mouse_sensitivity");
  return true;
}

void ActivateTheForce(){
  if(!the_force_active){
    start_throwing_time = time;
    SetConfigValueFloat("mouse_sensitivity", aim_sensitivity);
  }
  this_mo.SetAnimation("Data/Animations/r_dialogue_point.anm", 20.0f, 0);
  if(victim_id == -1){
    GetNewVictim();
    if(victim_id != -1){
      MovementObject@ victim = ReadCharacterID(victim_id);
      //victim.Ragdoll();
      /*victim.Execute("SetState(_ragdoll_state);");
      victim.rigged_object().DisableSleep();
      victim.rigged_object().SetRagdollStrength(1.0);*/

      /*victim.Execute("recovery_time = 10.0f;");*/
      victim.Execute("Ragdoll(_RGDL_INJURED);");

      /*victim.Execute("SetState(_ragdoll_state);");
      victim.Execute("no_freeze = false;");*/
      //victim.Ragdoll();

      /*victim.rigged_object().DisableSleep();
      victim.rigged_object().SetRagdollStrength(1.0);
      victim.rigged_object().SetRagdollDamping(1.0f);*/

      /*victim.SetAnimation("Data/Animations/r_rearchokedstance.anm",4.0f,_ANM_FROM_START);
      victim.rigged_object().anim_client().AddLayer("Data/Animations/r_stomachcut.anm",4.0f,_ANM_FROM_START);*/

      victim.SetAnimation("Data/Animations/r_writhe.anm",1.0f,_ANM_FROM_START);
      victim.rigged_object().anim_client().AddLayer("Data/Animations/r_rearchokedstance.anm",4.0f,_ANM_FROM_START);

      //victim.SetAnimation("Data/Animations/r_rearchokedstance.anm",20.0f,0);
    }
  }else{
    MovementObject@ victim = ReadCharacterID(victim_id);
    float curr_distance = distance(this_mo.position, victim.position);
    victim.Execute("recovery_time = 1.0f;");
    vec3 cameraFacing = camera.GetFacing();
    //victim.position = this_mo.position + (cameraFacing * curr_distance);
    vec3 end_pos = this_mo.position + (cameraFacing * curr_distance);
    vec3 force = vec3((end_pos - victim.position) * 300.0f);
    mat4 transform = victim.rigged_object().GetAvgIKChainTransform("head");

    victim.rigged_object().ApplyForceToRagdoll(force, transform.GetTranslationPart());


    //victim.Execute("Ragdoll(_RGDL_ANIMATION);");

    //victim.Execute("state = _ragdoll_state;");
    /*victim.SetAnimation("Data/Animations/r_rearchokedstance.anm", 20.0f, 0);*/
    //victim.Ragdoll();
    //victim.Execute("Ragdoll(_RGDL_ANIMATION);");
    //victim.rigged_object().anim_client().AddLayer("Data/Animations/r_stomachcut.anm",4.0f,_ANM_FROM_START);
  }
  Update3rdPersonCamera();
  the_force_active = true;
}

void DeactivateTheForce(){
  if(the_force_active){
  }
  victim_id = -1;
  the_force_active = false;
  cam_pos_offset = vec3(0);
  start_throwing_time= 0.0f;
  the_force_fov = 90;
  if(orig_sensitivity != -1.0f){
    SetConfigValueFloat("mouse_sensitivity", orig_sensitivity);
  }
}

void Update3rdPersonCamera(){
  vec3 cameraFacing = camera.GetFacing();
  the_force_fov = max(the_force_fov - ((time - start_throwing_time)), 40.0f);
  cam_pos_offset = vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5);
  if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
    if(cameraFacing.y > -1.0f){
      this_mo.SetRotationFromFacing(normalize(cameraFacing + vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5)));
    }
  }
}

void GetNewVictim(){
  mat4 transform = this_mo.rigged_object().GetAvgIKChainTransform("head");
  mat4 transform_offset;
  transform_offset.SetRotationX(-70);
  transform.SetRotationPart(transform.GetRotationPart()*transform_offset);
  array<int> nearby_characters;
  GetCharactersInHull("Data/Models/fov.obj", transform, nearby_characters);
  //DebugDrawWireMesh("Data/Models/fov.obj", transform, vec4(1.0f), _delete_on_update);

  for(uint i = 0; i < nearby_characters.size(); i++){
    if(nearby_characters[i] == this_mo.GetID() || distance(ReadCharacterID(nearby_characters[i]).position, this_mo.position) > max_force_distance){
      break;
    }
    Print("Found character " + nearby_characters[i] + "\n");
    victim_id = nearby_characters[i];
  }
}

float GetTheForceFOV(){
  return the_force_fov;
}
