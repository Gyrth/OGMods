bool post_init_done = false;
array<int> characters;
vec3 old_position;

void Init(){

}
void SetParameters() {

}
void Update(){
    if(!post_init_done){
        old_position = ReadObjectFromID(hotspot.GetID()).GetTranslation();
        post_init_done = true;
        return;
    }

    vec3 new_position = ReadObjectFromID(hotspot.GetID()).GetTranslation();
    if(new_position != old_position){
        for(uint i = 0; i < characters.size(); i++){
            MovementObject@ char = ReadCharacterID(characters[i]);
            char.velocity = distance(new_position, old_position) / time_step;
        }
        old_position = new_position;
    }
}
void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    characters.insertLast(mo.GetID());
}

void OnExit(MovementObject @mo) {
    int index = characters.find(mo.GetID());
    if(index != -1){
        characters.removeAt(index);
    }
}
