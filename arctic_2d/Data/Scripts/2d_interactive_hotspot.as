bool triggered = false;
bool post_init_done = false;
float time = 0.0f;
float last_time = 0.0f;
Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
Object@ sprite = null;
float timer = 0.0f;
string type = "star";

void Init() {

}

void PreScriptReload(){
	/* Reset(); */
}

void Reset(){
	triggered = false;
	QueueDeleteObjectID(sprite.GetID());
	post_init_done = false;
}

void SetParameters() {
	params.AddString("Type", "star");
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter"){
		OnEnter(mo);
	} else if(event == "exit"){
		OnExit(mo);
	}
}

void OnEnter(MovementObject @mo) {
	if(mo.is_player && !triggered){
		triggered = true;
		sprite.SetEnabled(false);

		if(type == "star"){
			PlaySound("Data/Sounds/impactGlass_medium_000.wav", hotspot_obj.GetTranslation());
			level.SendMessage("collect_star");
		}else if(type == "coin"){
			PlaySound("Data/Sounds/impactGlass_light_000.wav", hotspot_obj.GetTranslation());
			level.SendMessage("collect_coin");
		}else if(type == "gem"){
			PlaySound("Data/Sounds/impactGlass_heavy_000.wav", hotspot_obj.GetTranslation());
			level.SendMessage("collect_gem");
		}
	}
}

void OnExit(MovementObject @mo) {

}

void PostInit(){
	post_init_done = true;
	type = params.GetString("Type");

	string path;
	if(type == "star"){
		path = "Data/Objects/star.xml";
		level.SendMessage("register_star");
	}else if(type == "coin"){
		path = "Data/Objects/coin_gold.xml";
		level.SendMessage("register_coin");
	}else if(type == "gem"){
		path = "Data/Objects/gem_red.xml";
		level.SendMessage("register_gem");
	}

	int obj_id = CreateObject(path, true);
	@sprite = ReadObjectFromID(obj_id);
	sprite.SetTranslation(hotspot_obj.GetTranslation());
}

void Update() {
	if(!post_init_done){
		PostInit();
	}

	timer += time_step;

	quaternion rotation = quaternion(0.0, sin(timer * 4.0) / 2.5, 0.0, 0.0);
	vec3 translation = hotspot_obj.GetTranslation() + vec3(0.0, sin(timer * 5.0) / 5.0, 0.0);

	if(hotspot_obj.IsSelected()){
		sprite.SetTranslation(translation);
		sprite.SetRotation(rotation);
	}else{
		sprite.SetTranslationRotationFast(translation, rotation);
	}
}
