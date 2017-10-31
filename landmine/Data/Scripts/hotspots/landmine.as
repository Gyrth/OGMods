string ragdollType = "_RGDL_ANIMATION";
float speed = 5.0f;
const int _ragdoll_state = 4;

void Init() {
}
void SetParameters() {
	params.AddFloatSlider("Recovery time", 5.0, "min:0.0,max:60.0,step:1,text_mult:1");
	params.AddFloatSlider("Damage dealt", 1.0, "min:0.0,max:20.0,step:1,text_mult:1");
	params.AddFloatSlider("Upward force", 20.0, "min:1.0,max:100.0,step:1,text_mult:1");
	params.AddIntSlider("Smoke particle amount",20,"min:1,max:500,step:1,text_mult:1");
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
	if(mo.GetIntVar("state") == _ragdoll_state){
		mo.Execute("vec3 impulse = vec3("+0.0f+", "+3000.0f * params.GetFloat("Upward force")+", "+0.0f+");" +
					"HandleRagdollImpactImpulse(impulse, this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), 0.0f);");
	}else{
		mo.Execute("TakeDamage("+params.GetFloat("Damage dealt")+");");
		mo.velocity.y = params.GetFloat("Upward force");
		mo.Execute("SetOnGround(false);");
		mo.Execute("pre_jump = false;");
	}
	Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
	vec3 explosion_point = thisHotspot.GetTranslation();
	MakeMetalSparks(explosion_point);
	for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
		MakeParticle("Data/Particles/landmine_explosion_smoke.xml",mo.position,
		vec3(RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed)));
	}
	PlaySound("Data/Sounds/landmine_explosion.wav");
}
void OnExit(MovementObject @mo) {
	mo.Execute("DropWeapon(); Ragdoll("+ragdollType+"); roll_recovery_time = "+params.GetFloat("Recovery time")+"; recovery_time = "+params.GetFloat("Recovery time")+";");
}
void MakeMetalSparks(vec3 pos){
    int num_sparks = 60;
	float speed = 20.0f;
    for(int i=0; i<num_sparks; ++i){
        MakeParticle("Data/Particles/landmine_explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed)));
    }
}
