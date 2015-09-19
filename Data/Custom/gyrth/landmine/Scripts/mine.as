void Init() {
}
void SetParameters() {
	params.AddString("Recovery time", "5.0");
	params.AddString("Damage dealt", "1.0");
	params.AddString("Upward force", "20.0");
	params.AddString("Smoke particle amount", "15");
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
		vec3 explosion_point(mo.position.x,mo.position.y-4,mo.position.z);
		MakeParticle("Data/Custom/Gyrth/landmine/Scripts/propane.xml",explosion_point,vec3(0.0f,15.0f,0.0f));
		mo.Execute("TakeDamage("+params.GetFloat("Damage dealt")+");");
		for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
			MakeParticle("Data/Custom/Gyrth/landmine/Scripts/explosion_smoke.xml",mo.position,
				vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
			}
	    PlaySound("Data/Custom/Gyrth/landmine/Sounds/explosion.wav");
	    mo.velocity.y = params.GetFloat("Upward force");
		mo.Execute("SetOnGround(false);");
		mo.Execute("pre_jump = false;");
}
void OnExit(MovementObject @mo) {
	string ragdollType = "_RGDL_ANIMATION";
	mo.Execute("DropWeapon(); Ragdoll("+ragdollType+"); roll_recovery_time = "+params.GetFloat("Recovery time")+"; recovery_time = "+params.GetFloat("Recovery time")+";");
}