void Init() {
}
void SetParameters() {
	params.AddString("Recovery time", "5.0");
	params.AddString("Damage dealt", "1.0");
	params.AddString("Upward force", "20.0");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
	else if(event == "exit"){
        OnExit(mo);
    }
}
void OnEnter(MovementObject @mo) {
		Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
		vec3 explosion_point = thisHotspot.GetTranslation();
		MakeMetalSparks(explosion_point);
		mo.Execute("TakeDamage("+params.GetFloat("Damage dealt")+");");
		float speed = 5.0f;
		for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
				MakeParticle("Data/Particles/explosion_smoke.xml",mo.position,
				vec3(RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed)));
		}
	  PlaySound("Data/Sounds/explosion.wav");
	  mo.velocity.y = params.GetFloat("Upward force");
		mo.Execute("SetOnGround(false);");
		mo.Execute("pre_jump = false;");
}
void OnExit(MovementObject @mo) {
	string ragdollType = "_RGDL_ANIMATION";
	mo.Execute("DropWeapon(); Ragdoll("+ragdollType+"); roll_recovery_time = "+params.GetFloat("Recovery time")+"; recovery_time = "+params.GetFloat("Recovery time")+";");
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
