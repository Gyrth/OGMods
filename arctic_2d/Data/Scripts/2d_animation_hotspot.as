array<int> victim_ids;
array<int> arrow_ids;
bool triggered = false;
float time = 0.0f;
float last_time = 0.0f;
string arrowPath = "Data/Items/StandardArrow.xml";
int obj_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
uint walk_animation_index = 0;

array<string> walk_animation = {	"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk01.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk02.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk03.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk04.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk05.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk06.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk07.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk08.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk09.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk10.png",
									"/home/gyrth/Documents/GitHub/OGMods/arctic_2d/Data/Textures/Base pack/Player/p1_walk/PNG/p1_walk11.png"
								};

void Init() {

}

void Reset(){

}

void SetParameters() {
	params.AddString("Image", "Data/Textures/");
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

void OnExit(MovementObject @mo) {

}

void Update() {
	walk_animation_index += 1;

	if(walk_animation_index == walk_animation.size()){
		walk_animation_index = 0;
	}

	Object@ this_obj = ReadObjectFromID(obj_id);
	PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(this_obj);
	placeholder_object.SetSpecialType(kPlayerConnect);
	placeholder_object.SetBillboard(walk_animation[walk_animation_index]);
	this_obj.SetTranslation(hotspot_obj.GetTranslation());
}
