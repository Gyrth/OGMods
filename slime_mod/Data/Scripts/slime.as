#include "aschar_aux.as"

enum SoundType {
    _sound_type_foley,
    _sound_type_loud_foley,
    _sound_type_voice,
    _sound_type_combat
}

enum AIEvent{_ragdolled, _activeblocked, _thrown, _choking, _jumped, _can_climb,
             _grabbed_ledge, _climbed_up, _damaged, _dodged, _defeated, _attacking};

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still, _flee};
AIGoal goal = _patrol;

enum AISubGoal {_unknown = -1, _provoke_attack, _avoid_jump_kick, _knock_off_ledge, _wait_and_attack, _rush_and_attack, _defend, _surround_target, _escape_surround,
            _investigate_slow, _investigate_urgent, _investigate_body, _investigate_around};

void Init(string character_path) {
    this_mo.char_path = character_path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    /*last_col_pos = this_mo.position;
    SetState(_movement_state);
    PostReset();*/
}

void SetParameters() {
}

int NeedsAnimFrames() {
    return 1;
}

void SetChaseTarget(int target){
}

bool ActiveDodging(int attacker_id) {
    return true;
}

bool ActiveBlocking() {
    return true;
}

void AIMovementObjectDeleted(int id) {
}

int IsUnaware() {
    return 1;
}

int IsAggro() {
    return 1;
}

int IsPassive() {
    return 0;
}

bool WantsToDragBody(){
    return false;
}

void ResetMind() {

}

int IsIdle() {
    return 0;
}

int IsAggressive() {
    return 0;
}

void Startle() {
}

void Notice(int character_id){

}

void NotifySound(int created_by_id, vec3 pos, SoundType type) {

}

void HandleAIEvent(AIEvent event){

}

void SetGoal(AIGoal new_goal){

}

void MindReceiveMessage(string msg){

}

void Update(int num_frames) {
    Print("Update\n");
}

bool IsAware(){
    return true;
}
