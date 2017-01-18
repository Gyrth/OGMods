Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
array<int> wheel_ids;
int body_id;
mat4 old_body_physics_transform;
vec3 old_body_linear_velocity;
vec3 old_body_angular_velocity;
vec3 offset = vec3(-0.198593f, 0.505668f, 0.0f);
vec3 hotspot_pos;
quaternion hotspot_rot;
bool first_update = true;
float debugSphereSize = 0.1f;
float bodyLength = 4.2f;
float bodyWidth = 1.7f;
float maxUpForce = 1.0f;
float suspensionHeight = 1.5f;
float suspensionHardness = 1.0f;
float height = -0.3f;
float sidewaysDrag = 0.2f;
float suspensionDrag = 0.05f;
vec3 up;
vec3 down;
vec3 right;
vec3 forward;

void Init() {
    wheel_ids.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheel_ids.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheel_ids.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheel_ids.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    body_id = CreateObject("Data/Items/body.xml", true);
    Object@ body_obj = ReadObjectFromID(body_id);
    body_obj.SetTranslation(thisHotspot.GetTranslation());
    for(uint a =0;a<wheel_ids.length();a++){
        Object@ wheel = ReadObjectFromID(wheel_ids[a]);
        wheel.SetTranslation(thisHotspot.GetTranslation());
    }
}

void Reset(){
    MovementObject@ this_mo = ReadCharacter(0);
    //this_mo.Execute("ReceiveMessage(\"set_dialogue_control true\");");
}

void SetParameters() {
    params.AddFloatSlider("Pull Speed",1,"min:0,max:10,step:0.1,text_mult:100");
    params.AddIntCheckbox("Left Leg", true);
    params.AddIntCheckbox("Right Leg", true);
    params.AddIntCheckbox("Left Arm", false);
    params.AddIntCheckbox("Right Arm", false);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {

}

void Update(){
    ItemObject@ body_io = ReadItemID(body_id);
    mat4 body_transform = body_io.GetPhysicsTransform();
    MovementObject@ this_mo = ReadCharacter(0);
    array<float> wheel_distances;
    array<vec3> wheel_positions;
    vec3 new_linear_velocity = body_io.GetLinearVelocity();
    vec3 new_angular_velocity = body_io.GetAngularVelocity();

    if(UpdateCarInEditor(body_io)){
        return;
    }

    down = normalize(body_transform.GetRotationPart() * vec3(0,-1,0));
    up = normalize(body_transform.GetRotationPart() * vec3(0,1,0));
    right = normalize(body_transform.GetRotationPart() * vec3(0,0,1));
    forward = normalize(body_transform.GetRotationPart() * vec3(1,0,0));
    //backwards = normalize(body_transform.GetRotationPart() * vec3(-1,0,0));

    UpdateCamera(body_io);
    UpdateWheels(body_transform, wheel_distances, wheel_positions, wheel_ids);
    UpdateLinearVelocity(new_linear_velocity, new_linear_velocity, wheel_distances, body_io);
    UpdateAngularVelocity(new_angular_velocity, new_angular_velocity, wheel_positions, body_io);
    UpdateControls(this_mo, new_linear_velocity, new_linear_velocity, new_angular_velocity, new_angular_velocity);

    KeepCarAlive(body_io, new_linear_velocity, new_angular_velocity);
}

bool UpdateCarInEditor(ItemObject@ body_io){
    if(EditorModeActive()){
        Object@ body_o = ReadObjectFromID(body_io.GetID());
        if(thisHotspot.IsSelected()){
            if(thisHotspot.GetTranslation() != hotspot_pos){
                body_o.SetTranslation(thisHotspot.GetTranslation());
                hotspot_pos = thisHotspot.GetTranslation();
                old_body_linear_velocity = vec3(0);
                old_body_angular_velocity = vec3(0);
                return true;
            }else if(thisHotspot.GetRotation().x != hotspot_rot.x &&
                      thisHotspot.GetRotation().y != hotspot_rot.y &&
                      thisHotspot.GetRotation().z != hotspot_rot.z &&
                      thisHotspot.GetRotation().w != hotspot_rot.w){
                body_o.SetRotation(thisHotspot.GetRotation());
                hotspot_rot = thisHotspot.GetRotation();
                old_body_linear_velocity = vec3(0);
                old_body_angular_velocity = vec3(0);
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }else{
        return false;
    }
}

void KeepCarAlive(ItemObject@ body_io, vec3 new_linear_velocity, vec3 new_angular_velocity){
    if(length(body_io.GetLinearVelocity()) == 0.0f){
        //DebugDrawWireSphere(thisHotspot.GetTranslation(), debugSphereSize, vec3(0.0), _fade);

        old_body_physics_transform.SetTranslationPart(old_body_physics_transform.GetTranslationPart() - offset);
        body_io.SetPhysicsTransform(old_body_physics_transform);

        //DebugDrawWireSphere(body_io.GetPhysicsPosition(), debugSphereSize, vec3(1, 0, 0), _fade);
        body_io.SetLinearVelocity(old_body_linear_velocity);
        body_io.SetAngularVelocity(old_body_angular_velocity);
        body_io.ActivatePhysics();

    }else{
        if(body_io.GetLinearVelocity().x > 0.01f || body_io.GetLinearVelocity().x < -0.01f){
            old_body_linear_velocity = body_io.GetLinearVelocity();
            old_body_angular_velocity = body_io.GetAngularVelocity();
        }else{
            //body_io.SetLinearVelocity(old_body_linear_velocity);
            //body_io.SetAngularVelocity(old_body_angular_velocity);
        }
        old_body_physics_transform = body_io.GetPhysicsTransform();
        body_io.SetLinearVelocity(new_linear_velocity);
        body_io.SetAngularVelocity(new_angular_velocity);
    }
}

void UpdateLinearVelocity(vec3 &in in_new_linear_velocity, vec3 &out out_new_linear_velocity, array<float> &in wheel_distances, ItemObject@ body_io){
    float collectiveUpForce = 0.0f;
    for(uint i = 0;i<wheel_distances.length();i++){
        collectiveUpForce += wheel_distances[i];
    }
    out_new_linear_velocity = in_new_linear_velocity;

    //DebugText("off", "collectiveUpForce = " + collectiveUpForce + ";", _fade);

    //If the wheels are touching the ground
    if(collectiveUpForce > 0.1f){
        float upForce = collectiveUpForce / wheel_distances.length();
        vec3 newCarPos = body_io.GetPhysicsPosition() + up * upForce;
        //DebugDrawWireSphere(newCarPos, debugSphereSize, vec3(0.5), _delete_on_update);
        //DebugDrawWireSphere(body_io.GetPhysicsPosition(), debugSphereSize, vec3(1, 0, 0), _delete_on_update);
        vec3 direction = newCarPos - body_io.GetPhysicsPosition();
        vec3 suspensionUpForce = direction *  distance(newCarPos, body_io.GetPhysicsPosition());
        out_new_linear_velocity += suspensionUpForce * suspensionHardness;

        float sidewaysVel = dot(right, out_new_linear_velocity);
        out_new_linear_velocity -= (right * sidewaysVel) * sidewaysDrag;

        float updownVel = dot(up, out_new_linear_velocity);
        out_new_linear_velocity -= (up * updownVel) * suspensionDrag;
    }
}

void UpdateAngularVelocity(vec3 &in in_new_angular_velocity, vec3 &out out_new_angular_velocity, array<vec3> &in wheel_positions, ItemObject@ body_io){

    DebugText("hmm", in_new_angular_velocity + "", _fade);
    DebugText("hmm2", (time_step * 2.0f) + " damping", _fade);
    out_new_angular_velocity = in_new_angular_velocity / 1.05f;

    vec3 collectiveAng = vec3(0.0f);
    collectiveAng += cross(wheel_positions[0], wheel_positions[1]);
    collectiveAng += cross(wheel_positions[1], wheel_positions[2]);
    collectiveAng += cross(wheel_positions[2], wheel_positions[3]);
    collectiveAng += cross(wheel_positions[3], wheel_positions[0]);
    quaternion newQuat;
    GetRotationBetweenVectors(wheel_positions[2], wheel_positions[0], newQuat);
    vec3 newAngVelocity = collectiveAng / 4;
    mat4 debugTransform;
    debugTransform.SetTranslationPart(body_io.GetPhysicsTransform().GetTranslationPart());
    debugTransform.SetRotationPart(Mat4FromQuaternion(newQuat));

    //DebugDrawWireMesh("Data/Models/body.obj", debugTransform , vec4(1), _delete_on_update);
    //Print("old " + wheel_positions.size() + "\n");
    //Print("new " + wheel_distances.size() + "\n");
    quaternion cur_rot = QuaternionFromMat4(body_io.GetPhysicsTransform().GetRotationPart());
    //vec3 ang_vel = Mult(, newAngVelocity);
    vec3 ang_vel = Mult(cur_rot, vec3(newQuat.x, newQuat.y, newQuat.z));

    //body_io.SetAngularVelocity(out_new_angular_velocity);

    //Print("Ang vel " + ang_vel + "\n");
    //Print("vel " + newAngVelocity + "\n");
    //body_io.SetAngularVelocity(ang_vel);
    //Print("" + newQuat.x + " " + newQuat.y + " " + newQuat.z + "\n");
    //Print("" + cur_rot.x + " " + cur_rot.y + " " + cur_rot.z + "\n");
}

void UpdateCamera(ItemObject@ body){
    if(!EditorModeActive()){
        MovementObject@ this_mo = ReadCharacter(0);
        if(this_mo.GetIntVar("dialogue_control") == 0){
            //this_mo.Execute("ReceiveMessage(\"set_dialogue_control true\");");
            this_mo.Execute("dialogue_control = true;");
        }
        DebugText("asx", "Control " + this_mo.GetIntVar("dialogue_control"), _fade);

        vec3 newCamPos = body.GetPhysicsPosition() + (forward * -1 + vec3(0.0f, 0.5f, 0.0f));
        vec3 offset = newCamPos - this_mo.position;
        //this_mo.Execute("cam_pos_offset = " + offset + ";");
        //this_mo.Execute("old_cam_pos = " + body.GetPhysicsPosition() + ";");
        //camera.SetFlags(kEditorCamera);
        camera.SetPos(newCamPos);
        //camera.SetVelocity(body.GetLinearVelocity());
        camera.SetDistance(3.0f);
        camera.LookAt(body.GetPhysicsPosition());
        //camera.SetInterpSteps(60);
        //level.SendMessage("load_dialogue_pose Data/Animations/r_dialogue_facepalm.anm");
        //level.SendMessage("preview_dialogue");

    }
}

void UpdateControls(MovementObject@ this_mo, vec3 &in in_new_linear_velocity, vec3 &out out_new_linear_velocity, vec3 &in in_new_angular_velocity, vec3 &out out_new_angular_velocity){
    if(GetInputDown(this_mo.controller_id, "up")){
        out_new_linear_velocity = in_new_linear_velocity + forward * 0.1f;
    }else if(GetInputDown(this_mo.controller_id, "down")){
        out_new_linear_velocity = in_new_linear_velocity - forward * 0.1f;
    }else{
        out_new_linear_velocity = in_new_linear_velocity;
    }
    if(GetInputDown(this_mo.controller_id, "left")){
        out_new_angular_velocity = in_new_angular_velocity + vec3(0.0f, 0.05f, 0.0f);
    }else if(GetInputDown(this_mo.controller_id, "right")){
        out_new_angular_velocity = in_new_angular_velocity - vec3(0.0f, 0.05f, 0.0f);
    }else{
        out_new_angular_velocity = in_new_angular_velocity;
    }
}

void UpdateWheels(mat4 body_transform, array<float>@ wheel_distances, array<vec3>@ wheel_positions, array<int> wheel_ids){
    for(uint i = 0; i < wheel_ids.size(); i++){
        Object@ wheelObj = ReadObjectFromID(wheel_ids[i]);

        //quaternion rot;
        vec3 dir;
        if(i == 0){
            dir = body_transform.GetRotationPart() * vec3(bodyLength/2,height,(bodyWidth/2)*-1);
        }else if(i == 1){
            dir = body_transform.GetRotationPart() * vec3(bodyLength/2,height,bodyWidth/2);
        }else if(i == 2){
            dir = body_transform.GetRotationPart() * vec3((bodyLength/2)*-1,height,bodyWidth/2);
        }else{
            dir = body_transform.GetRotationPart() * vec3((bodyLength/2)*-1,height,(bodyWidth/2)*-1);
        }
        vec3 newWheelPos = body_transform.GetTranslationPart() + dir;
        //GetRotationBetweenVectors(dir, thisHotspot.GetTranslation(), rot);


        //vec3 direction = newWheelPos - wheelIO.GetPhysicsPosition();
        //        vec3 angVel = wheelIO.GetAngularVelocity();
        //angVel.x = 0.0f;
        //angVel.y = 0.0f;
        //vec3 emptyVec = vec3(0.0f);
        //DebugText("ok", length(angVel)+"", _fade);
        //wheelIO.SetAngularVelocity(angVel);

        DebugDrawWireSphere(newWheelPos, debugSphereSize, vec3(1.0f), _delete_on_update);
        vec3 collisionEnd = newWheelPos + down * suspensionHeight;
        vec3 collisionPoint = col.GetRayCollision(newWheelPos, collisionEnd);
        wheel_distances.insertLast(distance(collisionEnd, collisionPoint));
        wheel_positions.insertLast(collisionPoint);
        //wheelIO.SetLinearVelocity((direction * 20.0f) * distance(newWheelPos, wheelIO.GetPhysicsPosition()));
        DebugDrawWireSphere(collisionPoint, debugSphereSize, vec3(1.0f), _delete_on_update);
        wheelObj.SetTranslation(collisionPoint + (vec3(0, 0.5f, 0)));
    }
}

void OnExit(MovementObject @mo) {

}
