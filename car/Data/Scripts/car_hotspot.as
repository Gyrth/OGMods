Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
array<int> wheelIds;
int bodyID;
mat4 oldBodyPhysicsTransform;
mat4 previousTransform;
vec3 oldBodyLinVel;
vec3 oldBodyAngVel;
array<mat4> oldTransforms(100);
vec3 offset = vec3(-0.198593f, 0.505668f, 0.0f);

void Init() {
    wheelIds.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheelIds.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheelIds.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    wheelIds.insertLast(CreateObject("Data/Objects/wheel.xml", true));
    bodyID = CreateObject("Data/Items/body.xml", true);
    Object@ bodyObj = ReadObjectFromID(bodyID);
    bodyObj.SetTranslation(thisHotspot.GetTranslation());
    for(uint a =0;a<wheelIds.length();a++){
        Object@ wheel = ReadObjectFromID(wheelIds[a]);
        wheel.SetTranslation(thisHotspot.GetTranslation());
    }
}

void Reset(){

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
    ItemObject@ bodyIO = ReadItemID(bodyID);
    mat4 bodyTransform = bodyIO.GetPhysicsTransform();
    vec3 bodyPosition = bodyTransform.GetTranslationPart();
    quaternion bodyRotation;
    MovementObject@ this_mo = ReadCharacter(0);
    float debugSphereSize = 0.1f;
    float bodyLength = 4.2f;
    float bodyWidth = 1.7f;
    float maxUpForce = 1.0f;
    float suspensionHeight = 1.5f;
    float suspensionHardness = 1.0f;
    float height = -0.3f;
    float sidewaysDrag = 0.2f;
    float suspensionDrag = 0.05f;
    //quaternion bodyRotation = QuaternionFromMat4(bodyTransform.GetRotationPart());
    array<float> wheelDistances;
    array<vec3> wheelPositions;

    vec3 down = normalize(bodyTransform.GetRotationPart() * vec3(0,-1,0));
    vec3 up = normalize(bodyTransform.GetRotationPart() * vec3(0,1,0));
    vec3 right = normalize(bodyTransform.GetRotationPart() * vec3(0,0,1));

    for(uint i = 0; i < wheelIds.size(); i++){
        Object@ wheelObj = ReadObjectFromID(wheelIds[i]);
        //ItemObject@ wheelIO = ReadItemID(wheelIds[i]);

        //quaternion rot;
        vec3 dir;
        if(i == 0){
            dir = bodyTransform.GetRotationPart() * vec3(bodyLength/2,height,(bodyWidth/2)*-1);
        }else if(i == 1){
            dir = bodyTransform.GetRotationPart() * vec3(bodyLength/2,height,bodyWidth/2);
        }else if(i == 2){
            dir = bodyTransform.GetRotationPart() * vec3((bodyLength/2)*-1,height,bodyWidth/2);
        }else{
            dir = bodyTransform.GetRotationPart() * vec3((bodyLength/2)*-1,height,(bodyWidth/2)*-1);
        }
        vec3 newWheelPos = bodyPosition + dir;
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

        this_mo.Execute("vec3 tempVec = col.GetRayCollision(" + newWheelPos + ", " + collisionEnd + ");" +
                        "smear_sound_time = tempVec.x;"+
                        "left_smear_time = tempVec.y;"+
                        "right_smear_time = tempVec.z;");
        vec3 collisionPoint;
        collisionPoint.x = this_mo.GetFloatVar("smear_sound_time");
        collisionPoint.y = this_mo.GetFloatVar("left_smear_time");
        collisionPoint.z = this_mo.GetFloatVar("right_smear_time");

        wheelDistances.insertLast(distance(collisionEnd, collisionPoint));
        wheelPositions.insertLast(collisionPoint);

        //wheelIO.SetLinearVelocity((direction * 20.0f) * distance(newWheelPos, wheelIO.GetPhysicsPosition()));

        DebugDrawWireSphere(collisionPoint, debugSphereSize, vec3(1.0f), _delete_on_update);

        //if(length(angVel) == 0.0f){
            wheelObj.SetTranslation(collisionPoint + (vec3(0, 0.5f, 0)));
            //wheelIO.ActivatePhysics();
        //}
    }
    float collectiveUpForce = 0.0f;
    for(uint i = 0;i<wheelDistances.length();i++){
        collectiveUpForce += wheelDistances[i];
    }



    //Controls
    //If the wheels are touching the ground
    //DebugText("off", "collectiveUpForce = " + collectiveUpForce + ";", _fade);
    vec3 newVelocity = bodyIO.GetLinearVelocity();
    if(collectiveUpForce > 0.1f){
        float upForce = collectiveUpForce / wheelDistances.length();
        vec3 newCarPos = bodyIO.GetPhysicsPosition() + up * upForce;
        //DebugDrawWireSphere(newCarPos, debugSphereSize, vec3(0.5), _delete_on_update);
        //DebugDrawWireSphere(bodyIO.GetPhysicsPosition(), debugSphereSize, vec3(1, 0, 0), _delete_on_update);
        vec3 direction = newCarPos - bodyIO.GetPhysicsPosition();

        vec3 suspensionUpForce = direction *  distance(newCarPos, bodyIO.GetPhysicsPosition());


        newVelocity += suspensionUpForce * suspensionHardness;

        if(GetInputDown(this_mo.controller_id, "up")){
            newVelocity += normalize(bodyTransform.GetRotationPart() * vec3(1,0,0)) * 0.1f;
        }else if(GetInputDown(this_mo.controller_id, "down")){
            newVelocity += normalize(bodyTransform.GetRotationPart() * vec3(-1,0,0)) * 0.1f;
        }
        //newVelocity -= dot(down, newVelocity);
        //DebugText("hmm", bodyTransform.GetRotationPart() * vec3(1,1,1) + "", _fade);

        float sidewaysVel = dot(right, newVelocity);
        newVelocity -= (right * sidewaysVel) * sidewaysDrag;

        float updownVel = dot(up, newVelocity);
        newVelocity -= (up * updownVel) * suspensionDrag;

        vec3 collectiveAng = vec3(0.0f);
        collectiveAng += cross(wheelPositions[0], wheelPositions[1]);
        collectiveAng += cross(wheelPositions[1], wheelPositions[2]);
        collectiveAng += cross(wheelPositions[2], wheelPositions[3]);
        collectiveAng += cross(wheelPositions[3], wheelPositions[0]);
        quaternion newQuat;
        GetRotationBetweenVectors(wheelPositions[2], wheelPositions[1], newQuat);
        vec3 newAngVelocity = collectiveAng / 4;
        mat4 debugTransform;
        debugTransform.SetTranslationPart(bodyPosition);
        debugTransform.SetRotationPart(Mat4FromQuaternion(newQuat));

        //DebugDrawWireMesh("Data/Models/body.obj", debugTransform , vec4(1), _delete_on_update);
        //bodyIO.SetAngularVelocity(bodyIO.GetAngularVelocity() - newAngVelocity);

        //newVelocity.y *= 0.95f;

    }
    if(!EditorModeActive()){
        vec3 dir = bodyTransform.GetRotationPart() * vec3(-5,5,0);
        vec3 newCamPos = bodyPosition + dir;
        vec3 offset = newCamPos - this_mo.position;
        this_mo.Execute("cam_pos_offset = " + offset + ";");
        //camera.SetPos(newCamPos);
        ///camera.LookAt(bodyPosition);

    }
    //DebugText("vel", "Vel : " + bodyIO.GetLinearVelocity(), _fade);


    if(length(bodyIO.GetLinearVelocity()) == 0.0f){
        //DebugText("ang", "ang : " + bodyIO.GetAngularVelocity(), _fade);
        //DebugText("vel", "Vel : " + bodyIO.GetLinearVelocity(), _fade);

        //bodyIO.SetPhysicsTransform(oldBodyPhysicsTransform);
        //bodyIO.SetLinearVelocity(oldBodyLinVel);
        //bodyIO.SetAngularVelocity(oldBodyAngVel);

        DebugDrawWireSphere(thisHotspot.GetTranslation(), debugSphereSize, vec3(0.0), _fade);

        oldBodyPhysicsTransform.SetTranslationPart(oldBodyPhysicsTransform.GetTranslationPart() - offset);
        bodyIO.SetPhysicsTransform(oldBodyPhysicsTransform);

        DebugDrawWireSphere(bodyIO.GetPhysicsPosition(), debugSphereSize, vec3(1, 0, 0), _fade);
        bodyIO.SetLinearVelocity(oldBodyLinVel);
        bodyIO.ActivatePhysics();

    }else{

        //DebugText("ang", "ang : " + bodyIO.GetAngularVelocity(), _fade);
        //DebugText("vel", "Vel : " + bodyIO.GetLinearVelocity(), _fade);
        //Print("vel : " + oldBodyLinVel + "\n");
        //DebugText("vel3", "old Vel : " + oldBodyLinVel, _fade);
        if(bodyIO.GetLinearVelocity().x > 0.01f || bodyIO.GetLinearVelocity().x < -0.01f){
            oldBodyLinVel = bodyIO.GetLinearVelocity();
            oldBodyAngVel = bodyIO.GetAngularVelocity();
        }else{
            bodyIO.SetLinearVelocity(oldBodyLinVel);
            bodyIO.SetAngularVelocity(oldBodyAngVel);
        }
        oldBodyPhysicsTransform = bodyIO.GetPhysicsTransform();
        bodyIO.SetLinearVelocity(newVelocity);
    }
}

void OnExit(MovementObject @mo) {

}
