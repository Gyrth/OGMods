bool post_init_done = false;
array<int> characters;
vec3 old_position;
float old_time;

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
            /*vec3 new_vel = (new_position - old_position) / (the_time - old_time);*/
            if(char.GetBoolVar("on_ground") || char.QueryIntFunction("int IsOnLedge()") == 1){
                /*char.velocity = new_vel;*/
                char.position += new_position - old_position;
            }
        }
        old_time = the_time;
        old_position = new_position;
    }else{
        old_time = the_time;
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
