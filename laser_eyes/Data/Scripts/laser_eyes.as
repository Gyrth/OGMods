vec3 laser_color = vec3(5.0f,0.0f,0.0f);
vec3 laser_smoke_color = vec3(0.5f);
float start_throwing_time = 0.0f;
bool laser_eyes_active = false;
float laser_eyes_fov = 90;
float max_distance = 200.0f;
float orig_sensitivity = -1.0f;
float aim_sensitivity = 0.1f;
float part_mult = 2.0f;
int laser_loop_id = -1;

bool init_done = LaserInit();

void UpdateLaserEyes(){
  if(this_mo.controlled){
    if(GetInputDown(this_mo.controller_id, lightning_key) && length(this_mo.velocity) < 1.0f){
      ActivateLaserEyes();
    }else{
      DeactivateLaserEyes();
    }
  }
}

bool LaserInit(){
  orig_sensitivity = GetConfigValueFloat("mouse_sensitivity");
  return true;
}

void ActivateLaserEyes(){
  if(!laser_eyes_active){
    start_throwing_time = time;
    laser_loop_id = PlaySoundLoopAtLocation("Data/Sounds/laser_middle.wav", this_mo.position, 2.0f);
  }
  SetConfigValueFloat("mouse_sensitivity", aim_sensitivity);
  vec3 collision_point;

  BoneTransform transform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kHeadIK]]);
  vec3 cameraFacing = camera.GetFacing();
  Object@ charObject = ReadObjectFromID(this_mo.GetID());

  if(!laser_eyes_active){
    this_mo.PlaySoundAttached("Data/Sounds/laser_start.wav",this_mo.position);
  }
  laser_eyes_active = true;

  quaternion head_rotation = transform.rotation;
  vec3 facing = camera.GetFacing();
  vec3 start = facing * 3.0f;
  //Limited aim enabled.
  vec3 end = vec3(facing.x, max(-0.9, min(0.8f, facing.y)), facing.z) * max_distance;
  //Collision check for non player objects
  vec3 hit = col.GetRayCollision(camera.GetPos() + start, camera.GetPos() + end);
  //Collision check for player objects.
  col.CheckRayCollisionCharacters(camera.GetPos() + start, camera.GetPos() + end);

  if(sphere_col.NumContacts() != 0){
      const CollisionPoint contact = sphere_col.GetContact(0);
      if(contact.position != vec3(0,0,0) && distance(transform.origin, hit) > distance(transform.origin ,contact.position)){
        collision_point = contact.position;
        if(rand()%2 == 0){
          MakeParticle("Data/Particles/laser_smoke.xml", collision_point, contact.normal * part_mult, laser_smoke_color);
        }else{
          MakeParticle("Data/Particles/laser_spark.xml", collision_point, contact.normal + vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f) * part_mult), laser_smoke_color);
        }
      }else{
        return;
      }
      MovementObject@ victim = ReadCharacterID(contact.id);
      vec3 force = camera.GetFacing() * 1000.0f;
      victim.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                      "SetOnFire(true);" +
                      "vec3 pos = vec3("+collision_point.x+", "+collision_point.y+", "+collision_point.z+");" +
                      "HandleRagdollImpactImpulse(impulse, pos, 5.0f);");
  } else{
      collision_point = hit;
      if(rand()%2 == 0){
        MakeParticle("Data/Particles/laser_smoke.xml", collision_point, vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f) * part_mult), laser_smoke_color);
      }else{
        MakeParticle("Data/Particles/laser_spark.xml", collision_point, vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f) * part_mult), laser_smoke_color);
      }
  }
  SetSoundPosition(laser_loop_id, collision_point);

  laser_eyes_fov = max(laser_eyes_fov - ((time - start_throwing_time)), 40.0f);

  cam_pos_offset = vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5);

  if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
    if(cameraFacing.y > -1.0f){
      this_mo.SetRotationFromFacing(normalize(cameraFacing + vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5)));
    }
  }
  vec3 eye_offset = cam_pos_offset * 0.05f;
  DebugDrawLine(transform.origin + eye_offset, collision_point, laser_color, _delete_on_update);
  DebugDrawLine(transform.origin - eye_offset, collision_point, laser_color, _delete_on_update);
}
void DeactivateLaserEyes(){
  if(laser_eyes_active){
    BoneTransform transform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kHeadIK]]);
    this_mo.PlaySoundAttached("Data/Sounds/laser_end.wav",this_mo.position);
    StopSound(laser_loop_id);
  }
  laser_eyes_active = false;
  cam_pos_offset = vec3(0);
  start_throwing_time= 0.0f;
  if(orig_sensitivity != -1.0f){
    SetConfigValueFloat("mouse_sensitivity", orig_sensitivity);
  }
}

float GetLaserEyesFOV(){
  return laser_eyes_fov;
}
