Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
array<int> wheelIds;
int bodyID;

void Init() {
    wheelIds.insertLast(CreateObject("Data/Items/wheel.xml"));
    wheelIds.insertLast(CreateObject("Data/Items/wheel.xml"));
    wheelIds.insertLast(CreateObject("Data/Items/wheel.xml"));
    wheelIds.insertLast(CreateObject("Data/Items/wheel.xml"));
    bodyID = CreateObject("Data/Items/body.xml");
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
    float bodyWidth = 2.0f;
    float maxUpForce = 1.0f;
    float suspensionHeight = 2.0f;
    float suspensionHardness = 0.9f;
    //quaternion bodyRotation = QuaternionFromMat4(bodyTransform.GetRotationPart());
    array<float> wheelDistances;

    for(uint i = 0; i < wheelIds.size(); i++){
        Object@ wheelObj = ReadObjectFromID(wheelIds[i]);
        ItemObject@ wheelIO = ReadItemID(wheelIds[i]);

        //quaternion rot;
        vec3 dir;
        int height = 0;
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
        vec3 down = normalize(bodyTransform.GetRotationPart() * vec3(0,-1,0));
        //GetRotationBetweenVectors(dir, thisHotspot.GetTranslation(), rot);


        vec3 direction = newWheelPos - wheelIO.GetPhysicsPosition();
                vec3 angVel = wheelIO.GetAngularVelocity();
        angVel.x = 0.0f;
        angVel.y = 0.0f;
        vec3 emptyVec = vec3(0.0f);
        DebugText("ok", length(angVel)+"", _fade);
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

        wheelIO.SetLinearVelocity((direction * 20.0f) * distance(newWheelPos, wheelIO.GetPhysicsPosition()));

        DebugDrawWireSphere(collisionPoint, debugSphereSize, vec3(1.0f), _delete_on_update);

        if(length(angVel) == 0.0f){
            //wheelObj.SetTranslation(newWheelPos);
            //wheelIO.ActivatePhysics();
        }
    }
    float collectiveUpForce = 0.0f;
    for(uint i = 0;i<wheelDistances.length();i++){
        collectiveUpForce += wheelDistances[i];
    }
    float upForce = collectiveUpForce / wheelDistances.length();
    vec3 up = normalize(bodyTransform.GetRotationPart() * vec3(0,1,0));
    vec3 newCarPos = bodyIO.GetPhysicsPosition() + up * upForce;
    DebugDrawWireSphere(newCarPos, debugSphereSize, vec3(0.5), _delete_on_update);
    DebugDrawWireSphere(bodyIO.GetPhysicsPosition(), debugSphereSize, vec3(0), _delete_on_update);
    vec3 direction = newCarPos - bodyIO.GetPhysicsPosition();

    vec3 suspensionUpForce = direction *  distance(newCarPos, bodyIO.GetPhysicsPosition());
    DebugText("sus", suspensionUpForce + "", _fade);

    vec3 newVelocity = bodyIO.GetLinearVelocity() + (suspensionUpForce * suspensionHardness);
    bodyIO.SetLinearVelocity(newVelocity * 0.995f);


    if(GetInputDown(this_mo.controller_id, "up")){

        vec3 carVelocity = normalize(bodyTransform.GetRotationPart() * vec3(1,0,0)) * 0.1f + bodyIO.GetLinearVelocity();
        //DebugText("asd", "Pressing up" + carVelocity, _fade);
        bodyIO.SetLinearVelocity(carVelocity);
    }
    if(!EditorModeActive()){
        vec3 dir = bodyTransform.GetRotationPart() * vec3(-5,5,0);
        vec3 newCamPos = bodyPosition + dir;
        vec3 offset = newCamPos - this_mo.position;
        this_mo.Execute("cam_pos_offset = " + offset + ";");
        DebugText("off", "cam_pos_offset = " + offset + ";", _fade);
        //camera.SetPos(newCamPos);
        ///camera.LookAt(bodyPosition);

    }

}

void OnExit(MovementObject @mo) {

}
