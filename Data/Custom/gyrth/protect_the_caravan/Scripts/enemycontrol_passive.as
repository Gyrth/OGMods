#include "aschar.as"
#include "situationawareness.as"

Situation situation;

float startle_time;

bool has_jump_target = false;
vec3 jump_target_vel;

float awake_time = 0.0f;
const float AWAKE_NOTICE_THRESHOLD = 1.0f;

float enemy_seen = 0.0f;

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target_id = -1;
int old_waypoint_target_id = -1;
const float _throw_counter_probability = 0.2f;
bool will_throw_counter;
int ground_punish_decision = -1;

float notice_target_aggression_delay = 0.0f;
int notice_target_aggression_id = 0.0f;

float target_attack_range = 0.0f;
float strafe_vel = 0.0f;
const float _block_reflex_delay_min = 0.1f;
const float _block_reflex_delay_max = 0.2f;
float block_delay;
bool going_to_block = false;
float dodge_delay;
bool going_to_dodge = false;
float roll_after_ragdoll_delay;
bool throw_after_active_block;

bool combat_allowed = false;

class InvestigatePoint {
    vec3 pos;
    float seen_time;
};
array<InvestigatePoint> investigate_points;

const float kGetWeaponDelay = 0.4f;
float get_weapon_delay = kGetWeaponDelay;

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still};
AIGoal goal = _patrol;

enum AISubGoal {_unknown = -1, _punish_fall, _provoke_attack, _avoid_jump_kick, _wait_and_attack, _rush_and_attack, _defend, _surround_target, _escape_surround, 
    _investigate_slow, _investigate_urgent, _investigate_body, _investigate_around};
AISubGoal sub_goal = _wait_and_attack; 

AIGoal old_goal;
AISubGoal old_sub_goal;

int investigate_target_id = -1;
vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int chase_target_id = -1;
int weapon_target_id = -1;

float investigate_body_time;
float patrol_wait_until = 0.0f;

enum PathFindType {_pft_nav_mesh, _pft_climb, _pft_drop, _pft_jump};
PathFindType path_find_type = _pft_nav_mesh;
vec3 path_find_point;
float path_find_give_up_time;

enum ClimbStage {_nothing, _jump, _wallrun, _grab, _climb_up};
ClimbStage trying_to_climb = _nothing;
vec3 climb_dir;

void SetChaseTarget(int target){
    if(chase_target_id != target){
        target_history.Initialize();
        if(target != -1){
            MovementObject@ char = ReadCharacterID(target);
            target_history.Update(char.position, char.velocity, time);
        }
    }
    chase_target_id = target;
}

void AIMovementObjectDeleted(int id) {
    situation.MovementObjectDeleted(id);
    if(ally_id == id){
        ally_id = -1;
        if(goal == _get_help){
            SetGoal(_patrol);
        }
    }
    if(investigate_target_id == id){
        investigate_target_id = -1;
        if(goal == _investigate){
            SetGoal(_patrol);
        }
    }
    if(escort_id == id){
        escort_id = -1;
        if(goal == _escort){
            SetGoal(_patrol);
        }
    }
    if(chase_target_id == id){
        SetChaseTarget(-1);
        if(goal == _attack){
            SetGoal(_patrol);
        }   
    }
}

int IsUnaware() {
    return (goal == _patrol || startled)?1:0;
}

bool WantsToDragBody(){
    return false;
}

void ResetMind() {
    goal = _patrol;
    situation.clear();
    path_find_type = _pft_nav_mesh;
    float awake_time = 0.0f;
}

int IsIdle() {
    if(goal == _patrol){
        return 1;
    } else {
        return 0;
    }
}

int IsAggressive() {
    return (knocked_out == _awake && (goal == _attack || goal == _get_help))?1:0;
}

class TargetHistoryElement {
    vec3 position;
    vec3 velocity;
    float time_stamp;
}

const int kTargetHistorySize = 16;
class TargetHistory {
    private TargetHistoryElement[] elements;
    private int index;
    private bool first_update;
    void Initialize() {
        elements.resize(kTargetHistorySize);
        index = 0;
        first_update = true;
    }
    void Update(const vec3 &in pos, const vec3 &in vel, float time_stamp){
        if(first_update){
            for(int i=0; i<kTargetHistorySize; ++i){
                elements[i].position = pos;
                elements[i].velocity = vel;
                elements[i].time_stamp = time_stamp;
            }
            first_update = false;
        }
        elements[index].position = pos;
        elements[index].velocity = vel;
        elements[index].time_stamp = time_stamp;
        index = (index + 1) % kTargetHistorySize;
        /*for(int i=0; i<kTargetHistorySize; ++i){
            DebugDrawWireSphere(elements[i].position, 0.1f, vec3(1.0f), _delete_on_update);
        }*/
    }
    vec3 GetPos(float time_stamp){
        int prev_index, next_index;
        float t;
        GetInterp(time_stamp, prev_index, next_index, t);
        vec3 pos = mix(elements[prev_index].position, elements[next_index].position, t);// + elements[temp_index].velocity * elements[temp_index].time_elapsed;
        return pos;
    }
    vec3 GetVel(float time_stamp){
        int prev_index, next_index;
        float t;
        GetInterp(time_stamp, prev_index, next_index, t);
        vec3 vel = mix(elements[prev_index].velocity, elements[next_index].velocity, t);// + elements[temp_index].velocity * elements[temp_index].time_elapsed;
        return vel;
    }
    private void GetInterp(float time_stamp, int &out prev_index, int &out next_index, float &out t){
        prev_index = index;
        for(int i=0; i<kTargetHistorySize; ++i){
            next_index = prev_index;
            prev_index = (prev_index + kTargetHistorySize - 1)%kTargetHistorySize;
            if(elements[prev_index].time_stamp < time_stamp){
                break;
            }
        }
        t = 0.0f;
        float prev_time = elements[prev_index].time_stamp;
        float next_time = elements[next_index].time_stamp;
        if(next_time - prev_time != 0.0f){
            t = (time_stamp - prev_time)/(next_time - prev_time);
        }
        t = max(t, 0.0f);
    }
}

TargetHistory target_history;

void Startle() {
    startled = true;
    startle_time = 1.0f;    
}

void Notice(int character_id){
    MovementObject@ char = ReadCharacterID(character_id);
    if(!this_mo.OnSameTeam(char) && (goal != _attack || chase_target_id == -1)){
        SetChaseTarget(character_id);
        switch(goal){
            case _patrol:
                if(!situation.KnowsAbout(character_id)){
                    Startle();
                    this_mo.PlaySoundGroupVoice("engage",0.0f);
                }
                SetGoal(_attack);
                break;
            case _investigate:
                if(!situation.KnowsAbout(character_id)){
                    Startle();
                    this_mo.PlaySoundGroupVoice("engage",0.0f);
                }
                SetGoal(_attack);
                break;
            case _escort:
                SetGoal(_attack);
                break;
        }
    }
    situation.Notice(character_id);
}

void NotifySound(int created_by_id, vec3 pos) {
    if(!listening || awake_time < AWAKE_NOTICE_THRESHOLD || knocked_out != _awake || created_by_id == this_mo.GetID()){
        return;
    }
    if(goal == _patrol || goal == _investigate){
        bool same_team = false;
        character_getter.Load(this_mo.char_path);
        if(this_mo.OnSameTeam(ReadCharacterID(created_by_id)) && situation.KnowsAbout(created_by_id)){
            same_team = true;
        }
        if(!same_team){
            if(goal == _patrol){
                Startle();
                this_mo.PlaySoundGroupVoice("suspicious",0.0f);
                random_look_delay = 1.0f;
                random_look_dir = pos - this_mo.position;
            }
            nav_target = pos;
            SetGoal(_investigate);
            SetSubGoal(_investigate_slow);
            investigate_target_id = -1;
            if(chase_target_id == -1) {
                //DebugText("Player "+this_mo.GetID()+" hear", "Player "+this_mo.GetID()+" says: I heard something!", 1.0f);
            }
        }
    }
}

void HandleAIEvent(AIEvent event){
    switch(event){
    case _ragdolled:    
        roll_after_ragdoll_delay = RangedRandomFloat(0.1f,1.0f);
        break;
    case _jumped:
        has_jump_target = false;
        if(trying_to_climb == _jump){
            trying_to_climb = _wallrun;
        }   
        break;
    case _grabbed_ledge:
        if(trying_to_climb == _wallrun){
            trying_to_climb = _climb_up;
        }   
        break;
    case _climbed_up:
        if(trying_to_climb == _climb_up){
            trying_to_climb = _nothing;
            path_find_type = _pft_nav_mesh;
        }   
        break;
    case _thrown:
        will_throw_counter = RangedRandomFloat(0.0f,1.0f)<_throw_counter_probability;   
        break;
    case _can_climb:
        trying_to_climb = _jump;
        break;
    case _activeblocked: {
        float temp_block_followup = p_block_followup;
        if(sub_goal == _provoke_attack){
            temp_block_followup = 1.0 - (pow(1.0 - temp_block_followup, 2.0));
        }
        if(RangedRandomFloat(0.0f, 1.0f) < temp_block_followup){
            throw_after_active_block = RangedRandomFloat(0.0f,1.0f) > 0.7f;
            if(!throw_after_active_block){
                throw_after_active_block = false;
                SetSubGoal(_rush_and_attack);
            }
        }
        } break;
    case _choking: {
        MovementObject@ char = ReadCharacterID(tether_id);
        if(GetCharPrimaryWeapon(char) == -1){
            SetGoal(_struggle);
        } else {
            SetGoal(_hold_still);
        }
        } break;
    case _damaged:
        if(goal == _patrol){
            Print("Damaged!\n");
            nav_target = this_mo.position;
            SetGoal(_investigate);
            SetSubGoal(_investigate_around);
            investigate_target_id = -1;
        }
    }
}

void SetGoal(AIGoal new_goal){
    if(goal != new_goal){
        switch(new_goal){
        case _attack:
            notice_target_aggression_delay = 0.0f;
            target_history.Initialize();
            SetSubGoal(PickAttackSubGoal());
            break;
        case _patrol:
            patrol_wait_until = 0.0f;
            break;
        }
        goal = new_goal;
    }
}

float move_delay = 0.0f;
float repulsor_delay = 0.0f;

void MindReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "escort_me"){
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        SetGoal(_escort);
        escort_id = id;
    } else if(token == "excuse_me"){
        move_delay = 1.0f;
    } else if(token == "set_hostile"){
        token_iter.FindNextToken(msg);
        string second_token = token_iter.GetToken(msg);
        if(second_token == "true"){
            SetHostile(true);
        } else if(second_token == "false"){
            SetHostile(false);
        }
    } else if(token == "set_combat_allowed"){
        token_iter.FindNextToken(msg);
        string second_token = token_iter.GetToken(msg);
        if(second_token == "true"){
            combat_allowed = true;
            SetGoal(_attack);
        } else if(second_token == "false"){
            combat_allowed = false;
        }
    } else if(token == "notice"){
        Print("Received notice message\n");
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        situation.Notice(id);
    } else if(token == "collided"){
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        Notice(id);
    } else if(token == "nearby_sound"){
        vec3 pos;
        float max_range;
        int id;
        for(int i=0; i<5; ++i){
            token_iter.FindNextToken(msg);
            switch(i){
            case 0: pos.x = atof(token_iter.GetToken(msg)); break;
            case 1: pos.y = atof(token_iter.GetToken(msg)); break;
            case 2: pos.z = atof(token_iter.GetToken(msg)); break;
            case 3: max_range = atof(token_iter.GetToken(msg)); break;
            case 4: id = atoi(token_iter.GetToken(msg)); break;
            }
        }
        NotifySound(id, pos);
    }
}

AISubGoal PickAttackSubGoal() {
    AISubGoal target_goal = _defend;
    if(RangedRandomFloat(0.0f,1.0f) < p_aggression){
        if(RangedRandomFloat(0.0f,1.0f) < 0.5f){
            target_goal = _wait_and_attack;
        } else {
            target_goal = _rush_and_attack;
        }
    }
    if(notice_target_aggression_delay > 0.2f){
        target_goal = _provoke_attack;
    }
    return target_goal;
}

bool instant_range_change = true;

void SetSubGoal(AISubGoal sub_goal_) {
    if(sub_goal != sub_goal_){
        instant_range_change = true;
    }
    sub_goal = sub_goal_;
}

bool CheckRangeChange(const Timestep &in ts) {
    bool change = false;
    if(instant_range_change || rand()%(150/ts.frames())==0){
        change = true;
    }
    instant_range_change = false;
    return change;
}

void SetHostile(bool val){
    hostile = val;
    if(hostile){
        ai_attacking = true;
        listening = true;
    } else {
        SetGoal(_patrol);
        ResetWaypointTarget();
        listening = false;
    }
}

void DisplayGoals() {
    string label = "Player "+this_mo.GetID()+" goal: ";
    string text = label;
    switch(goal){
        case _patrol:       text += "_patrol"; break;
        case _attack:       text += "_attack"; break;
        case _investigate:  text += "_investigate"; break;
        case _get_help:     text += "_get_help"; break;
        case _escort:       text += "_escort"; break;
        case _get_weapon:   text += "_get_weapon"; break;
        case _navigate:     text += "_navigate"; break;
        case _struggle:     text += "_struggle"; break;
        case _hold_still:   text += "_hold_still"; break;
    }
    text += ", ";
    switch(sub_goal){
        case _unknown:         text += "_unknown"; break;
        case _punish_fall:     text += "_punish_fall"; break;
        case _provoke_attack:  text += "_provoke_attack"; break;
        case _avoid_jump_kick: text += "_avoid_jump_kick"; break;
        case _wait_and_attack: text += "_wait_and_attack"; break;
        case _defend:          text += "_defend"; break;
        case _rush_and_attack: text += "_rush_and_attack"; break;
        case _surround_target: text += "_surround_target"; break;
        case _escape_surround: text += "_escape_surround"; break;
        case _investigate_around: text += "_investigate_around"; break;
        case _investigate_slow: text += "_investigate_slow"; break;
        case _investigate_urgent: text += "_investigate_urgent"; break;
        case _investigate_body: text += "_investigate_body"; break;
        default: text += sub_goal; break;
    }
    DebugText(label, text,0.1f);
}

int GetClosestKnownThreat() {
    int closest_enemy = -1;
    float closest_dist = 0.0f;
    for(uint i=0; i<situation.known_chars.size(); ++i){
        if(!situation.known_chars[i].friendly && situation.known_chars[i].knocked_out == _awake){
            MovementObject@ char = ReadCharacterID(situation.known_chars[i].id);
            float dist = distance_squared(situation.known_chars[i].last_known_position, this_mo.position);
            if(closest_enemy == -1 || dist < closest_dist){
                closest_dist = dist;
                closest_enemy = situation.known_chars[i].id;
            }
        }
    }
    return closest_enemy;
}

void CheckForNearbyWeapons() {
    bool wants_to_get_weapon = false;
    if(weapon_slots[primary_weapon_slot] == -1 && hostile){
        int nearest_weapon = -1;
        float nearest_dist = 0.0f;
        const float _max_dist = 30.0f;
        for(int i=0, len=situation.known_items.size(); i<len; ++i){
            ItemObject @item_obj = ReadItemID(situation.known_items[i].id);
            if(item_obj.IsHeld() || item_obj.GetType() != _weapon){
                continue;
            }
            vec3 pos = situation.known_items[i].last_known_position;
            float dist = distance_squared(pos, this_mo.position);
            if(dist > _max_dist * _max_dist){
                continue;
            }
            if(nearest_weapon == -1 || dist < nearest_dist){ 
                nearest_weapon = item_obj.GetID();
                nearest_dist = dist;
            }

        }
        if(nearest_weapon != -1){
            wants_to_get_weapon = true;
            weapon_target_id = nearest_weapon;
        }
    }
    if(wants_to_get_weapon){
        if(get_weapon_delay >= 0.0f){
            get_weapon_delay -= time_step;
        } else {
            old_goal = goal;
            old_sub_goal = sub_goal;
            SetGoal(_get_weapon);
        }
    } else {
        get_weapon_delay = kGetWeaponDelay;
    }
}

float next_vision_check_time;

void UpdateBrain(const Timestep &in ts){    
    if(knocked_out != _awake){
        return;
    }
    awake_time += ts.step();
    const bool display_goals = false;
    if(display_goals){
        DisplayGoals();
    }
    if(DebugKeysEnabled() && GetInputDown(this_mo.controller_id, "c") && !GetInputDown(this_mo.controller_id, "ctrl")){
        if(hostile_switchable){
            SetHostile(!hostile);
        }
        hostile_switchable = false;
    } else {
        hostile_switchable = true;
    }

    if(startled){
        startle_time -= ts.step();
        if(startle_time <= 0.0f){
            startled = false;
            AchievementEvent("enemy_alerted");
        }
    }

    move_delay = max(0.0f, move_delay - ts.step());
    repulsor_delay = max(0.0f, repulsor_delay - ts.step());

    // Update vision
    if(hostile && awake_time > AWAKE_NOTICE_THRESHOLD){
        if(time > next_vision_check_time){
            next_vision_check_time = time + RangedRandomFloat(0.2f,0.3f);
            bool print_visible_chars = false;
            if(print_visible_chars) {
                array<int> characters;
                GetVisibleCharacters(0, characters);
                for(int i=0, len=characters.size(); i<len; ++i){
                    string desc;
                    MovementObject@ char = ReadCharacterID(characters[i]);
                    if(char.GetIntVar("knocked_out") == _awake){
                        desc += "awake";
                    } else {
                        desc += "unconscious";
                    }
                    desc += " ";
                    if(this_mo.OnSameTeam(char)){
                        desc += "ally";
                    } else {
                        desc += "enemy";
                    }
                    DebugText(this_mo.getID()+"visible_character"+i, this_mo.getID()+" sees character "+characters[i]+" ("+desc+")", 0.5f);
                }
            }

            array<int> visible_characters;
            GetVisibleCharacters(0, visible_characters);
            for(int i=0, len=visible_characters.size(); i<len; ++i){
                int id = visible_characters[i];
                MovementObject@ char = ReadCharacterID(id);
                if(id == chase_target_id){    
                    target_history.Update(char.position, char.velocity, time);
                }
                if(this_mo.OnSameTeam(char)){
                    if(char.GetIntVar("knocked_out") != _awake && goal == _patrol){
                        // Check if we already know that this character is unconscious 
                        bool already_known = false;
                        int known_id = situation.KnownID(id);
                        if(known_id != -1 && situation.known_chars[known_id].knocked_out != _awake){
                            already_known = true;
                        }        
                        if(!already_known){
                            // Investigate body of ally                
                            Startle();
                            this_mo.PlaySoundGroupVoice("suspicious",0.0f);
                            random_look_delay = 1.0f;
                            random_look_dir = char.position - this_mo.position;
                            SetGoal(_investigate);
                            SetSubGoal(_investigate_urgent);
                            investigate_target_id = id;
                        }
                    }
                    Notice(id);
                } else {
                    if(char.GetIntVar("knocked_out") == _awake){
                        enemy_seen += 1.0f / (distance_squared(this_mo.position, char.position) + 1.0f) * 30.0f;
                    }
                }
                if(situation.KnownID(id) != -1){
                    situation.Notice(id);
                }
            }
            // Notice enemy if alerted above threshold
            if(enemy_seen >= 1.0f){
                array<int> enemies;
                GetMatchingCharactersInArray(visible_characters, enemies, _TC_ENEMY | _TC_CONSCIOUS);
                int closest_id = GetClosestCharacterInArray(this_mo.position, enemies, 0.0f);
                if(closest_id != -1){
                    Notice(closest_id);
                }
            } else 
            if(enemy_seen > 0.1f){
                array<int> enemies;
                GetMatchingCharactersInArray(visible_characters, enemies, _TC_ENEMY | _TC_CONSCIOUS);
                int closest_id = GetClosestCharacterInArray(this_mo.position, enemies, 0.0f);
                if(closest_id != -1){
                    MovementObject@ target = ReadCharacterID(closest_id);
                    nav_target = this_mo.position + normalize(target.position-this_mo.position)*3.0f;
                    SetGoal(_investigate);
                    SetSubGoal(_investigate_slow);
                    investigate_target_id = -1;
                }
            }
        }
    } else {
        SetChaseTarget(-1);
        force_look_target_id = -1;
    }

    switch(goal){
    case _patrol:
    case _escort:
        ai_attacking = false;
        break;
    case _investigate:  {
        ai_attacking = false;
        GetPath(GetInvestigateTargetPos());
        if(path.NumPoints() > 0){
            vec3 path_end = path.GetPoint(path.NumPoints()-1);
            if(distance_squared(NavPoint(this_mo.position), path_end) < 1.0f){
                if(sub_goal == _investigate_slow){
                    SetGoal(_patrol);
                } else if(sub_goal == _investigate_urgent){
                    SetSubGoal(_investigate_body);
                    investigate_body_time = time + RangedRandomFloat(2.0f, 4.0f);
                }
            }      
        }
        if(sub_goal == _investigate_body && time > investigate_body_time){
            sub_goal = _investigate_around;
            investigate_target_id = -1;
            SetSubGoal(_investigate_around);
            investigate_points.resize(0);
        }
        if(sub_goal == _investigate_around){
            if(investigate_points.size() == 0){
                float range = 8.0f;
                investigate_points.resize(0);
                for(int i=-3; i<3; ++i){
                    for(int j=-3; j<3; ++j){
                        vec3 rand_offset(i*range + RangedRandomFloat(-range*0.5f,range*0.5f), RangedRandomFloat(-range, range), j*range + RangedRandomFloat(-range*0.5f,range*0.5f));
                        vec3 investigate = NavPoint(this_mo.position + rand_offset);
                        if(investigate != vec3(0.0f)){
                            NavPath path = GetPath(this_mo.position, investigate);
                            if(path.success){
                                InvestigatePoint point;
                                investigate.y += _leg_sphere_size;
                                point.pos = investigate;
                                point.seen_time = 0.0f;
                                investigate_points.push_back(point);
                            }
                        }
                    }
                }
            }
            mat4 transform = this_mo.rigged_object().GetAvgIKChainTransform("head");
            vec3 head_pos = transform * vec4(0.0f,0.0f,0.0f,1.0f);
            vec3 head_facing = normalize(transform * vec4(0.0f,0.8f,0.2f,0.0f));
            for(int i=investigate_points.size()-1; i>=0; --i){
                if(distance_squared(this_mo.position, investigate_points[i].pos) < 1.0f){
                    investigate_points[i].seen_time += ts.step() * 5.0f;
                } else if(dot(normalize(investigate_points[i].pos-head_pos), head_facing) > 0.5f){
                    if(col.GetRayCollision(head_pos, investigate_points[i].pos) == investigate_points[i].pos){
                        investigate_points[i].seen_time += ts.step() * 3.0f;
                    }
                }
                if(investigate_points[i].seen_time >= 1.0f){
                    investigate_points.removeAt(i);
                }
            }
            const bool debug_draw_investigate = false;
            float closest_dist = 0.0f;
            int closest_point_id = -1;
            for(int i=0, len=investigate_points.size(); i<len; ++i){
                if(debug_draw_investigate){
                    DebugDrawWireSphere(investigate_points[i].pos, 1.0f, vec3(1.0f), _fade);
                }
                NavPath path = GetPath(this_mo.position, investigate_points[i].pos);
                float dist = 0.0f;
                for(int i=0, len=path.NumPoints()-1; i<len; ++i){
                    dist += distance(path.GetPoint(i), path.GetPoint(i+1));
                }
                if(closest_point_id == -1 || dist < closest_dist){
                    closest_point_id = i;
                    closest_dist = dist;
                }
            }
            if(closest_point_id != -1){
                nav_target = investigate_points[closest_point_id].pos;
                if(debug_draw_investigate){
                    DebugDrawLine(this_mo.position, nav_target, vec3(1.0f), _fade);
                    NavPath path = GetPath(this_mo.position, nav_target);
                    if(path.success){
                        for(int i=0, len=path.NumPoints()-1; i<len; ++i){
                            DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(0.0f, 1.0f, 0.0f), _fade);
                        }
                    } else {
                        for(int i=0, len=path.NumPoints()-1; i<len; ++i){
                            DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(1.0f, 0.0f, 0.0f), _fade);
                        }
                    }
                }
            }
            CheckForNearbyWeapons();
        }
        break;}
    case _attack:{
        SetChaseTarget(GetClosestKnownThreat());
        if(!hostile || chase_target_id == -1){
            SetGoal(_patrol);
            break;
        }
        MovementObject@ target = ReadCharacterID(chase_target_id);

        if(notice_target_aggression_id != chase_target_id){
            notice_target_aggression_delay = 0.0f;
        }
        notice_target_aggression_id = chase_target_id;
        float target_threat_amount = target.GetFloatVar("threat_amount");
        if(target_threat_amount > 0.6f && length_squared(target.velocity) < 1.0){
            notice_target_aggression_delay += ts.step();
        } else {
            notice_target_aggression_delay = 0.0f;   
        }
                
        AISubGoal target_goal = _unknown;
                
        if(rand()%(150/ts.frames())==0){
            switch(sub_goal){
                case _wait_and_attack:
                case _rush_and_attack:
                case _defend:
                case _provoke_attack:
                    target_goal = PickAttackSubGoal();
                    break;
            }
        }

        if(target.GetIntVar("state") == _ragdoll_state){
            if(ground_punish_decision == -1){
                if((RangedRandomFloat(0.0f,1.0f) < p_ground_aggression)){
                    ground_punish_decision = 1;
                } else {
                    ground_punish_decision = 0;
                }
            }
        } else {
            ground_punish_decision = -1;
        }
                
        if(ground_punish_decision == 1){
            target_goal = _punish_fall;
        } else {
            if(sub_goal == _punish_fall){
                target_goal = PickAttackSubGoal();
            }
        }
                        
        if(!combat_allowed){
            target_goal = _defend;
        }

        if(!target.GetBoolVar("on_ground")){
            target_goal = _avoid_jump_kick;
        } else if(sub_goal == _avoid_jump_kick){
            target_goal = PickAttackSubGoal();
        } 
                               
        if(target_goal != _unknown){
            SetSubGoal(target_goal);
        }
                
        switch(sub_goal){
        case _wait_and_attack:
            if(CheckRangeChange(ts)){
                target_attack_range = RangedRandomFloat(1.5f, 3.0f);
            }
            ai_attacking = true;
            break;
        case _punish_fall:
        case _rush_and_attack:
            if(CheckRangeChange(ts)){
                target_attack_range = 0.0f;
            }
            ai_attacking = true;
            break;
        case _defend:
            if(CheckRangeChange(ts)){
                if(!combat_allowed){
                    target_attack_range = RangedRandomFloat(3.0f, 5.0f);
                } else {
                    target_attack_range = RangedRandomFloat(1.5f, 3.0f);
                }
            }
            ai_attacking = false;
            break;
        case _provoke_attack:
            if(CheckRangeChange(ts)){
                target_attack_range = 0.0f;
            }
            ai_attacking = false;
            break;
        case _avoid_jump_kick:
            if(CheckRangeChange(ts)){
                target_attack_range = RangedRandomFloat(3.0f, 4.0f);
            }
            ai_attacking = false;
            break;
        }
        if(rand()%(150/ts.frames())==0){
            strafe_vel = RangedRandomFloat(-0.2f, 0.2f);
        }
        if(temp_health < 0.5f){
            ally_id = GetClosestCharacterID(1000.0f, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE | _TC_KNOWN );
            if(ally_id != -1){
                //DebugDrawLine(this_mo.position, ReadCharacterID(ally_id).position, vec3(0.0f,1.0f,0.0f), _fade);
                SetGoal(_get_help);
            }
        }

        bool print_potential_allies = false;
        if(print_potential_allies){
            array<int> characters;
            GetCharacters(characters);
            array<int> matching_characters;
            GetMatchingCharactersInArray(characters, matching_characters, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE | _TC_KNOWN);
            string allies;
            for(int i=0, len=matching_characters.size(); i<len; ++i){
                allies += matching_characters[i] + " ";
            }
            DebugText(this_mo.getID()+"Known allies: ", this_mo.getID()+" Known allies: "+allies, 0.5f);
        }

        // Assume target is moving in a straight line at slowly-decreasing velocity
        //last_seen_target_position += last_seen_target_velocity * ts.step();
        //last_seen_target_velocity *= pow(0.995f, ts.frames());

        // If ray check is successful, update knowledge of target position and velocity
        vec3 real_target_pos = ReadCharacterID(chase_target_id).position;
        vec3 head_pos = this_mo.rigged_object().GetAvgIKChainPos("head");
        CheckForNearbyWeapons();
        break;}
    case _get_help: {
        if(ally_id == -1){
            SetGoal(_patrol);
            break;
        }
        MovementObject@ char = ReadCharacterID(ally_id);
        if(distance_squared(this_mo.position, char.position) < 5.0f){
            SetGoal(_attack);
            char.ReceiveMessage("escort_me "+this_mo.getID());
        }
        CheckForNearbyWeapons();
        break; }
    case _get_weapon:
        if(weapon_slots[primary_weapon_slot] != -1 || !ObjectExists(weapon_target_id) || ReadItemID(weapon_target_id).IsHeld()){
            SetGoal(old_goal);
            SetSubGoal(old_sub_goal);
        }
        break;
    case _struggle:
        if(tethered == _TETHERED_FREE){
            SetGoal(_patrol);
        }
        struggle_change_time = max(0.0f, struggle_change_time - ts.step());
        if(struggle_change_time <= 0.0f){
            struggle_dir = normalize(vec3(RangedRandomFloat(-1.0f,1.0f), 
                                     0.0f, 
                                     RangedRandomFloat(-1.0f,1.0f)));
            struggle_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        struggle_crouch_change_time = max(0.0f,  struggle_crouch_change_time - ts.step());
        if(struggle_crouch_change_time <= 0.0f){
            struggle_crouch = (rand()%2==0);
            struggle_crouch_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        break;
    case _hold_still:
        if(tethered == _TETHERED_FREE){
            SetGoal(_patrol);
        }
        break;
    }

    if(path_find_type != _pft_nav_mesh){
        path_find_give_up_time -= ts.step();
        if(path_find_give_up_time <= 0.0f){
            path_find_type = _pft_nav_mesh;
        }
    }

    //MouseControlPathTest();
    //HandleDebugRayDraw();

    if(hostile){
        force_look_target_id = situation.GetForceLookTarget();
        if(goal == _attack && chase_target_id != -1){
            force_look_target_id = chase_target_id;
        }
    }
}

bool IsAware(){
    return hostile;
}

array<int> ray_lines;
void HandleDebugRayDraw() {
    for(int i=0; i<int(ray_lines.length()); ++i){
        DebugDrawRemove(ray_lines[i]);
    }
    ray_lines.resize(0);
    
    if(hostile){
        vec3 front = this_mo.GetFacing();
        vec3 right;
        right.x = front.z;
        right.z = -front.x;
        vec3 ray;
        float ray_len;
        for(int i = -90; i <= 90; i += 10){
            float angle = float(i)/180.0f * 3.1415f;
            ray = front * cos(angle) + right * sin(angle);
            //Print(""+ray.x+" "+ray.y+" "+ray.z+"\n");
            ray_len = GetVisionDistance(this_mo.position+ray); 
            //Print(""+ray_len+"\n");
            vec3 head_pos = this_mo.rigged_object().GetAvgIKChainPos("head");
            head_pos += vec3(0.0f,0.06f,0.0f);
            int line = DebugDrawLine(head_pos, 
                                     head_pos + ray * ray_len,
                                     vec3(1.0f),
                                     _persistent);
            ray_lines.insertLast(line);
        }
    }
}

bool WantsToSheatheItem() {
    return false;
}

bool WantsToUnSheatheItem(int &out src) {
    if(startled || goal != _attack || weapon_slots[primary_weapon_slot] != -1){
        return false;
    }
    src = -1; 
    if(weapon_slots[_sheathed_right] != -1 && ReadItemID(weapon_slots[_sheathed_right]).GetType() == _weapon){
        src = _sheathed_right;
    } else if(weapon_slots[_sheathed_left] != -1 && ReadItemID(weapon_slots[_sheathed_left]).GetType() == _weapon){
        src = _sheathed_left;
    }
    return true;
}

bool struggle_crouch = false;
float struggle_crouch_change_time = 0.0f;

bool WantsToCrouch() {
    if(goal == _struggle){
        return struggle_crouch;
    }
    if(goal == _investigate && sub_goal == _investigate_body){
        return true;
    }
    return false;
}

bool WantsToPickUpItem() {
    return goal == _get_weapon;
}

bool WantsToDropItem() {
    return false;
}

bool WantsToThrowItem() {
    return false;
}

bool WantsToThrowEnemy() {
    return throw_after_active_block;
}

bool WantsToCounterThrow(){
    return will_throw_counter;    
}

bool WantsToRoll() {
    return false;
}

bool WantsToFeint(){
    return false;
}

vec3 GetTargetJumpVelocity() {
    return vec3(jump_target_vel);
}

bool TargetedJump() {
    return has_jump_target;
}

bool WantsToJump() {
    return has_jump_target || trying_to_climb == _jump;
}

bool WantsToAttack() { 
    if(ai_attacking && !startled){
        return true;
    } else {
        return false;
    }
}

bool WantsToRollFromRagdoll(){
    if(ragdoll_time > roll_after_ragdoll_delay && combat_allowed){
        return true;
    } else {
        return false;
    }
}

enum BlockOrDodge{BLOCK, DODGE};

bool ShouldDefend(BlockOrDodge bod){
    float recharge;
    if(bod == BLOCK){
        recharge = active_block_recharge;
    } else if(bod == DODGE){
        recharge = active_dodge_recharge;
    }
    if(goal != _attack || startled || recharge > 0.0f || 
       chase_target_id == -1 || !hostile)
    {
        return false;
    }
    MovementObject @char = ReadCharacterID(chase_target_id);
    if((bod == BLOCK && char.GetIntVar("state") == _attack_state) || 
       (bod == DODGE && char.GetIntVar("knife_layer_id") != -1))
    {
        return true;
    } else {
        return false;
    }
}

bool WantsToStartActiveBlock(const Timestep &in ts){
    bool should_block = ShouldDefend(BLOCK);
    if(should_block && !going_to_block){
        MovementObject @char = ReadCharacterID(chase_target_id);
        block_delay = char.rigged_object().anim_client().GetTimeUntilEvent("blockprepare");
        if(block_delay != -1.0f){
            going_to_block = true;
        }
        float temp_block_skill = p_block_skill;
        float temp_block_skill_power = 0.5 * pow(4.0, char.GetFloatVar("attack_predictability"));
        //DebugText("temp_block_skill_power", "temp_block_skill_power: "+temp_block_skill_power, 2.0f);
        if(sub_goal == _provoke_attack){
            temp_block_skill_power += 1.0;
        }
        temp_block_skill = 1.0 - pow((1.0 - temp_block_skill),temp_block_skill_power);
        //DebugText("temp_block_skill", "temp_block_skill: "+temp_block_skill, 2.0f);
        if(RangedRandomFloat(0.0f,1.0f) > temp_block_skill){
            block_delay += 0.4f;
        }
    }
    if(!going_to_block && goal == _attack){
        int nearby_weapon = GetNearestThrownWeapon(this_mo.position, 2.0f);
        if(nearby_weapon != -1){
            ItemObject@ item_obj = ReadItemID(nearby_weapon);
            if(length_squared(item_obj.GetLinearVelocity())>1.0f){
                going_to_block = true;
                const float kKnifeCatchProbability = 0.7f;
                block_delay = 0.0f;
                if(RangedRandomFloat(0.0f,1.0f) > kKnifeCatchProbability){
                    block_delay += 0.4f;
                }
            }
        }
    }
    if(going_to_block){
        block_delay -= ts.step();
        block_delay = min(1.0f, block_delay);
        if(block_delay <= 0.0f){
            going_to_block = false;
            return true;
        }
    }
    return false;
}

bool WantsToDodge(const Timestep &in ts){
    bool should_block = ShouldDefend(DODGE);
    if(should_block && !going_to_dodge){
        MovementObject @char = ReadCharacterID(chase_target_id);
        dodge_delay = char.rigged_object().anim_client().GetTimeUntilEvent("blockprepare");
        if(dodge_delay != -1.0f){
            going_to_dodge = true;
        }
        float temp_block_skill = p_block_skill;
        float temp_block_skill_power = 0.5 * pow(4.0, char.GetFloatVar("attack_predictability"));
        if(sub_goal == _provoke_attack){
            temp_block_skill_power += 1.0;
        }
        temp_block_skill = 1.0 - pow((1.0 - temp_block_skill),temp_block_skill_power);
        if(RangedRandomFloat(0.0f,1.0f) > temp_block_skill){
            dodge_delay += 0.4f;
        }
    }
    if(going_to_dodge){
        dodge_delay -= ts.step();
        dodge_delay = min(1.0f, dodge_delay);
        if(dodge_delay <= 0.0f){
            going_to_dodge = false;
            return true;
        }
    }
    return false;
}

bool WantsToFlip() {
    return false;
}

bool WantsToAccelerateJump() {
    return trying_to_climb == _wallrun;
}

bool WantsToGrabLedge() {
    return trying_to_climb == _wallrun || trying_to_climb == _climb_up;
}

bool WantsToJumpOffWall() {
    return false;
}

bool WantsToFlipOffWall() {
    return false;
}

bool WantsToCancelAnimation() {
    return true;
}

NavPath path;
int current_path_point = 0;
void GetPath(vec3 target_pos) {
    path = GetPath(this_mo.position,
                   target_pos);
    current_path_point = 0;
}


array<int> path_lines;
void DrawPath() {
    for(int i=0; i<int(path_lines.length()); ++i){
        DebugDrawRemove(path_lines[i]);
    }
    path_lines.resize(0);
    int num_points = path.NumPoints();
    for(int i=0; i<num_points-1; i++){
        int line = DebugDrawLine(path.GetPoint(i),
                                 path.GetPoint(i+1),
                                 vec3(1.0f,1.0f,1.0f),
                                 _persistent);
        path_lines.insertLast(line);
    }
}

vec3 GetNextPathPoint() {
    int num_points = path.NumPoints();
    if(num_points < current_path_point-1){
        return vec3(0.0f);
    }

    vec3 next_point;
    for(int i=1; i<num_points; ++i){   
        next_point = path.GetPoint(i);
        if(xz_distance_squared(this_mo.position, next_point) > 1.0f){
             //Print("Next path point\n "+i);
            break;
        }
    }
    return next_point;
}

class WaypointInfo {
    bool success;
    vec3 target_point;
    bool following_friend;
}

// id could be id of a waypoint or of another character
WaypointInfo GetWaypointInfo(int id){
    WaypointInfo info;
    info.success = false;
    if(id != -1 && ObjectExists(id)){
        Object@ object = ReadObjectFromID(id);
        if(object.GetType() == _path_point_object){
            info.target_point = object.GetTranslation();
            info.success = true;
            info.following_friend = false;
        } else if(object.GetType() == _movement_object){
            if(situation.KnowsAbout(id)){
                info.target_point = ReadCharacterID(id).position;
                info.success = true;
                info.following_friend = true;
            }
        }
    }
    return info;
}

string patrol_idle_override;
   
string GetIdleOverride(){
    if(goal == _patrol && time < patrol_wait_until){
        return patrol_idle_override;
    } else {
        return "";
    }
}

vec3 GetCheckedRepulsorForce() {
    vec3 repulsor_force = GetRepulsorForce();
    if(length_squared(repulsor_force) > 0.0f){
        vec3 raycast_point = NavRaycast(this_mo.position, this_mo.position + repulsor_force);
        raycast_point.y = this_mo.position.y;
        repulsor_force *= distance(raycast_point, this_mo.position)/length(repulsor_force);
    }
    return repulsor_force;
}

vec3 GetPatrolMovement(){
    if(time < patrol_wait_until){
    	return vec3(0.0f);
    }

    WaypointInfo waypoint_info = GetWaypointInfo(waypoint_target_id);
    if(!waypoint_info.success){
        // current target is invalid, go to waypoint that character
        // is directly attached to
        old_waypoint_target_id = -1;
        waypoint_target_id = this_mo.GetWaypointTarget();
        waypoint_info = GetWaypointInfo(waypoint_target_id);
    }
    bool following_friend = false;
    vec3 target_point = this_mo.position;
    if(waypoint_info.success){
        target_point = waypoint_info.target_point;
        following_friend = waypoint_info.following_friend;
    }

    if( xz_distance_squared(this_mo.position, target_point) < 1.0f ){
        // we have reached target point
        if(waypoint_target_id != -1 && ObjectExists(waypoint_target_id)){
            Object@ object = ReadObjectFromID(waypoint_target_id);
            if(object.GetType() == _path_point_object){
                // Check for wait command
                ScriptParams@ script_params = object.GetScriptParams();
                if(script_params.HasParam("Wait")){
                    float wait_time = script_params.GetFloat("Wait");
                    patrol_wait_until = time + wait_time;
                }
                if(script_params.HasParam("Type")){
                    string type = script_params.GetString("Type");
                    if(type == "Stand"){
                        patrol_idle_override = "";
                    } else if(type == "Sit"){
                        patrol_idle_override = "Data/Animations/r_sit_cross_legged.anm";                        
                    } else if(type == "Sleep"){
                        patrol_idle_override = "Data/Animations/r_sleep.anm";                        
                    }
                } else {
                    patrol_idle_override = "";
                }
                int temp_waypoint_target_id = waypoint_target_id;
                PathPointObject@ path_point_object = cast<PathPointObject>(object);
                int num_connections = path_point_object.NumConnectionIDs();
                if(num_connections != 0){
                    waypoint_target_id = path_point_object.GetConnectionID(0);
                }
                for(int i=0; i<num_connections; ++i){
                    if(path_point_object.GetConnectionID(i) != old_waypoint_target_id){
                        waypoint_target_id = path_point_object.GetConnectionID(i);
                        break;
                    }
                }
                old_waypoint_target_id = temp_waypoint_target_id;
                // Find next waypoint and set that to be the target
                /*int temp = waypoint_target_id;
                waypoint_target_id = path_script_reader.GetOtherConnectedPoint(
                    waypoint_target_id, old_waypoint_target_id);
                old_waypoint_target_id = temp; 
                if(waypoint_target_id == -1){ 
                    // Double back if we've reached the end of the path
                    waypoint_target_id = path_script_reader.GetConnectedPoint(old_waypoint_target_id);
                }*/
            }
        }
    }

    if(move_delay > 0.0f){
        target_point = this_mo.position;
    }
    vec3 target_velocity;
    if(following_friend) {
        target_velocity = GetMovementToPoint(target_point, 1.0f, 1.0f, 0.0f);
    } else {
        if(target_point != this_mo.position){
            target_velocity = GetMovementToPoint(target_point, 0.0f);
            float target_speed = 0.2f;
            if(length_squared(target_velocity) > target_speed){
                target_velocity = normalize(target_velocity) * target_speed;
            }
        }
    }

    target_velocity += GetCheckedRepulsorForce();

    return target_velocity;
}

vec3 GetMovementToPoint(vec3 point, float slow_radius){
    return GetMovementToPoint(point, slow_radius, 0.0f, 0.0f);
}

const bool _debug_draw_jump_path = false;

bool JumpToTarget(vec3 jump_target, vec3 &out vel){
    vec3 start_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
    if(start_vel.y != 0.0f){
        bool low_success = false;
        bool med_success = false;
        bool high_success = false;
        const float _success_threshold = 0.1f;
        vec3 end;
        vec3 low_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.15f, time);
        jump_info.jump_start_vel = low_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(1.0f,0.0f,0.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                low_success = true;
            }
        } 
        vec3 med_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
        jump_info.jump_start_vel = med_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(0.0f,0.0f,1.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                med_success = true;
            }
        } 
        vec3 high_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 1.0f, time);
        jump_info.jump_start_vel = high_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(0.0f,1.0f,0.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                high_success = true;
            }
        }
        jump_info.jump_path.resize(0);

        if(low_success){
            vel = low_vel;
            return true;
        } else if(med_success){
            vel = med_vel;
            return true;
        } else if(high_success){
            vel = high_vel;
            return true;
        } else {
            vel = vec3(0.0f);
            return false;
        }

        /*
        if(GetInputPressed(this_mo.controller_id, "mouse0") && start_vel.y != 0.0f){
            jump_info.StartJump(start_vel, true);
            SetOnGround(false);
        }*/
    }
    return false;
}

// Pathfinding options
// Find ground path on nav mesh
// Run straight towards target (fall off edge)
// Run straight towards target and climb up wall
// Jump towards target (and possibly climb wall)

vec3 GetMovementToPoint(vec3 point, float slow_radius, float target_dist, float strafe_vel){
    if(path_find_type == _pft_nav_mesh){
        //Print("NAV MESH\n");
        return GetNavMeshMovement(point, slow_radius, target_dist, strafe_vel);
    } else if(path_find_type == _pft_climb){
        //Print("CLIMB\n");
        vec3 dir = path_find_point - this_mo.position;
        dir.y = 0.0f;
        if(trying_to_climb != _nothing && trying_to_climb != _jump && on_ground){
            trying_to_climb = _nothing;
            path_find_type = _pft_nav_mesh;
        }
        if(length_squared(dir) < 0.5f && trying_to_climb == _nothing){
            trying_to_climb = _jump;
        }
        if(trying_to_climb != _nothing){
            return climb_dir;
        }
        dir = normalize(dir);
        return dir;
    } else if(path_find_type == _pft_drop){
        //Print("DROP\n");
        vec3 dir = path_find_point - this_mo.position;
        dir.y = 0.0f;
        dir = normalize(dir);
        if(!on_ground){
            path_find_type = _pft_nav_mesh;
        }
        return dir;
    }

    return vec3(0.0f);
}

vec3 GetNavMeshMovement(vec3 point, float slow_radius, float target_dist, float strafe_vel){
    // Get path to estimated target position
    vec3 target_velocity;
    vec3 target_point = point;
    if(distance_squared(target_point, this_mo.position) > 0.2f){
        target_point = NavPoint(point);
    }
    GetPath(target_point);
    vec3 next_path_point = GetNextPathPoint();
    if(next_path_point != vec3(0.0f)){
        target_point = next_path_point;
    }

    //for(int i=0; i<path.NumPoints()-1; ++i){
    //    DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(1.0f), _fade);
    //}

    if(path.NumPoints() > 0 && on_ground){
       // If path cannot reach target point, check if we can climb or drop to it 
       if(distance_squared(path.GetPoint(path.NumPoints()-1), NavPoint(point)) > 1.0f){
           PredictPathOutput predict_path_output = PredictPath(this_mo.position, point);
           if(predict_path_output.type == _ppt_climb){
               path_find_type = _pft_climb;
               path_find_point = predict_path_output.start_pos;
               climb_dir = predict_path_output.normal;
               path_find_give_up_time = 2.0f;
           } else if(predict_path_output.type == _ppt_drop){
               path_find_type = _pft_drop;
               path_find_point = predict_path_output.start_pos;
               path_find_give_up_time = 2.0f;
           }
       }
       // If pathfind failed, then check for jump path
       /*if(distance_squared(path.GetPoint(path.NumPoints()-1), NavPoint(point)) > 1.0f){
            NavPath back_path;
            back_path = GetPath(NavPoint(point), this_mo.position); 
            if(back_path.NumPoints() > 0){
                vec3 targ_point = back_path.GetPoint(back_path.NumPoints()-1);
                targ_point = NavRaycast(targ_point, targ_point + vec3(RangedRandomFloat(-3.0f,3.0f),
                                                                      0.0f,
                                                                      RangedRandomFloat(-3.0f,3.0f)));
                targ_point.y += _leg_sphere_size;
                //DebugDrawWireSphere(targ_point, 1.0f, vec3(1.0f), _delete_on_update);
                vec3 vel;
                if(JumpToTarget(targ_point, vel)){
                    //Print("Jump target success\n");
                    has_jump_target = true;
                    jump_target_vel = vel;
                } else {
                    //Print("Jump target fail\n");
                }
            //    DebugDrawWireSphere(back_path.GetPoint(back_path.NumPoints()-1), 1.0f, vec3(1.0f), _fade);    
            }
            for(int i=0; i<back_path.NumPoints()-1; ++i){
            //    DebugDrawLine(back_path.GetPoint(i), back_path.GetPoint(i+1), vec3(1.0f), _fade);
            }
            
            //has_jump_target = true;

            //jump_target_vel = vec3(0.0f,10.0f,0.0f);
       }*/
    }

    // Get flat direction to next point
    vec3 rel_dir = point - this_mo.position;
    rel_dir.y = 0.0f;
    rel_dir = normalize(rel_dir);

    // If target point is closer than we want to be, then project it backwards (staying within walkable bounds)
    if(distance_squared(target_point, point) < target_dist*target_dist){
        vec3 right_dir(rel_dir.z, 0.0f, -rel_dir.x);
        vec3 raycast_point = NavRaycast(point, point - rel_dir * target_dist + right_dir * strafe_vel);
        if(raycast_point != vec3(0.0f)){                    
            target_point = raycast_point;
            GetPath(target_point);
            vec3 next_path_point = GetNextPathPoint();
            if(next_path_point != vec3(0.0f)){
                target_point = next_path_point;
            }
        }
    } 

    // Set target velocity to flat vector from character to target
    target_velocity = target_point - this_mo.position;
    target_velocity.y = 0.0;

    // Decompose target_vel into components going towards target, and perpendicular
    vec3 target_vel_indirect = target_velocity - dot(rel_dir, target_velocity) * rel_dir;
    vec3 target_vel_direct = target_velocity - target_vel_indirect;
 
    // 
    float dist = length(target_vel_direct);
    float seek_dist = slow_radius;
    dist = max(0.0, dist-seek_dist);
    target_velocity = normalize(target_vel_direct) * dist + target_vel_indirect;

    target_velocity += GetCheckedRepulsorForce();

    if(length_squared(target_velocity) > 1.0){
        target_velocity = normalize(target_velocity);
    }
    return target_velocity;

    // Test direct running
    /*vec3 direct_move = point - this_mo.position;
    direct_move.y = 0.0f;
    if(length(direct_move) > 0.6f){
        return normalize(direct_move);
    } else {
        return vec3(0.0f);
    }*/
}

vec3 GetDodgeDirection() {
    MovementObject @char = ReadCharacterID(chase_target_id);
    return normalize(this_mo.position - char.position);
}

vec3 GetAttackMovement() {
    if(combat_allowed){
        float target_react_time = 0.2f; // How slow AI is to react to changes
        vec3 target_react_pos = target_history.GetPos(time-target_react_time);
        vec3 target_react_vel = target_history.GetVel(time-target_react_time);
        float predict_dist = distance(target_react_pos, this_mo.position);
        float estimated_run_speed = run_speed * 0.8f;
        float predict_time = (predict_dist / estimated_run_speed); // How long it will take to reach target
        // Update predicted time to take into account velocity
        vec3 nav_target_react_pos = NavPoint(target_react_pos);
        vec3 target_point = target_react_pos;
        //DebugText("LastSeen", "Last seen time: T - "+ (situation.known_chars[situation.KnownID(chase_target_id)].last_seen_time-time), 0.5f);
        if(situation.known_chars[situation.KnownID(chase_target_id)].last_seen_time > time - 1.0f){
            if(nav_target_react_pos != vec3(0.0f)){
                target_point = NavRaycast(nav_target_react_pos, nav_target_react_pos + target_react_vel * predict_time);
                predict_dist = distance(target_point, this_mo.position);
                predict_time = (predict_dist / estimated_run_speed);
                predict_time += target_react_time;
                predict_time = min(predict_time, 8.0f); // Cap prediction at 8 seconds to avoid weirdness when out of sight
                vec3 predict_point = nav_target_react_pos + target_react_vel * predict_time;
                target_point = NavRaycast(nav_target_react_pos, predict_point);
            }
        }
        return GetMovementToPoint(target_point, max(0.2f,1.0f-target_attack_range), target_attack_range, strafe_vel);
    } else {
        return vec3(0.0f);
    }
    //CheckJumpTarget(last_seen_target_position);
}


void MouseControlPathTest() {
    vec3 start = camera.GetPos();
    vec3 end = camera.GetPos() + camera.GetMouseRay()*400.0f;
    col.GetSweptSphereCollision(start, end, _leg_sphere_size);
    //DebugDrawWireSphere(sphere_col.position, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    
    if(GetInputDown(this_mo.controller_id, "g") ){
        goal = _navigate;
        nav_target = sphere_col.position;
        path_find_type = _pft_nav_mesh;
    }
}

float struggle_change_time = 0.0f;
vec3 struggle_dir;

vec3 GetInvestigateTargetPos(){
    if(investigate_target_id == -1){
        return nav_target;
    } else {
        return ReadCharacterID(investigate_target_id).position; 
    }    
}

int last_seen_sphere = -1;
vec3 GetBaseTargetVelocity() {
    if(startled){
        return vec3(0.0f);
    } else if(goal == _patrol){
        return GetPatrolMovement();
    } else if(goal == _attack){
        return GetAttackMovement(); 
    } else if(goal == _get_help){
        return GetMovementToPoint(ReadCharacterID(ally_id).position, 1.0f); 
    } else if(goal == _get_weapon){
        vec3 pos = ReadItemID(weapon_target_id).GetPhysicsPosition();
        return GetMovementToPoint(pos, 0.0f); 
    } else if(goal == _escort){
        return GetMovementToPoint(ReadCharacterID(escort_id).position, 1.0f); 
    } else if(goal == _navigate){
        DebugDrawWireSphere(nav_target, 0.2f, vec3(1.0f), _fade);
        return GetMovementToPoint(nav_target, 1.0f); 
    } else if(goal == _investigate){
        float speed = 0.2f;
        if(sub_goal == _investigate_urgent || sub_goal == _investigate_body){
            speed = 1.0f;
        }
        if(sub_goal == _investigate_urgent || sub_goal == _investigate_body || sub_goal == _investigate_around){
            speed = 0.7f;
        }
        if(sub_goal == _investigate_body){
            speed = 0.0f;
        }
        float slow_radius = 0.0f;
        if(sub_goal == _investigate_urgent){
            slow_radius = 1.0f;
        }
        if(move_delay <= 0.0f){
            return GetMovementToPoint(GetInvestigateTargetPos(), slow_radius) * speed;
        } else {
            return GetMovementToPoint(this_mo.position, 0.0f) * speed;
        }
    } else if(goal == _struggle){
        return struggle_dir; 
    } else {
        return vec3(0.0f);
    }
}

vec3 GetRepulsorForce(){
    array<int> nearby_characters;
    const float _avoid_range = 1.5f;
    GetCharactersInSphere(this_mo.position, _avoid_range, nearby_characters);

    vec3 repulsor_total;

    for(uint i=0; i<nearby_characters.size(); ++i){
        if(this_mo.getID() == nearby_characters[i]){
            continue;
        }
        MovementObject@ char = ReadCharacterID(nearby_characters[i]);
        if(!this_mo.OnSameTeam(char)){
            continue;
        }
        float dist = length(this_mo.position - char.position);
        if(dist == 0.0f || dist > _avoid_range){
            continue;
        }
        vec3 repulsion = (this_mo.position - char.position)/dist * (_avoid_range - dist) / _avoid_range;
        if(length_squared(repulsion) > 0.0f && move_delay <= 0.0f){
            char.ReceiveMessage("excuse_me "+this_mo.getID());
            repulsor_delay = 1.0f;
        }
        repulsor_total += repulsion;
    }

    return repulsor_total;
}

vec3 GetTargetVelocity(){
    vec3 base_target_velocity = GetBaseTargetVelocity();
    vec3 target_vel = base_target_velocity;

    return target_vel;
}

// Called from aschar.as, bool front tells if the character is standing still. 
void ChooseAttack(bool front) {
    curr_attack = "";
    if(on_ground){
        int choice = rand()%3;
        if(choice==0){
            curr_attack = "stationary";            
        } else if(choice == 1){
            curr_attack = "moving";
        } else {
            curr_attack = "low";
        }    
    } else {
        curr_attack = "air";
    }
}

void ResetWaypointTarget() {
    waypoint_target_id = -1;
    old_waypoint_target_id = -1;
}

WalkDir WantsToWalkBackwards() {
    if(goal == _patrol && waypoint_target_id == -1){
        if(repulsor_delay > 0){
            return WALK_BACKWARDS;
        } else {
            return STRAFE;
        }
    } else {
        return FORWARDS;
    }
}

bool WantsReadyStance() {
    return (goal != _patrol);
}

bool _debug_draw_jump = false;

void CheckJumpTarget(vec3 target) {
    NavPath old_path;
    old_path = GetPath(this_mo.position, target);
    float old_path_length = 0.0f;
    for(int i=0; i<old_path.NumPoints() - 1; ++i){
        old_path_length += distance(old_path.GetPoint(i), old_path.GetPoint(i+1));
    }

    float max_horz = run_speed * 1.5f;
    float max_vert = _jump_vel * 1.7f;

    vec3 jump_vel(RangedRandomFloat(-max_horz,max_horz),
                  RangedRandomFloat(3.0f,max_vert),
                  RangedRandomFloat(-max_horz,max_horz));
    JumpTestEq(this_mo.position, jump_vel, jump_info.jump_path); 
    vec3 end = jump_info.jump_path[jump_info.jump_path.size()-1];
    if(_debug_draw_jump){
        for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
            DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                vec3(1.0f,0.0f,0.0f), 
                _delete_on_update);
        }
    }
    if(jump_info.jump_path.size() != 0){
        vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump){
            DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _fade);
        }
        
        bool old_path_fail = false;
        if(old_path.NumPoints() == 0 ||
           distance_squared(old_path.GetPoint(old_path.NumPoints()-1), NavPoint(target)) > 1.0f){
            old_path_fail = true;
        }

        NavPath new_path;
        new_path = GetPath(land_point, target);

        bool new_path_fail = false;
        if(new_path.NumPoints() == 0 ||
           distance_squared(new_path.GetPoint(new_path.NumPoints()-1), NavPoint(target)) > 1.0f){
            new_path_fail = true;
        }

        float new_path_length = 0.0f;
        for(int i=0; i<new_path.NumPoints() - 1; ++i){
            new_path_length += distance(new_path.GetPoint(i), new_path.GetPoint(i+1));
        }

        if(new_path_fail){
            return;
        }
        if(!old_path_fail && !new_path_fail && new_path_length >= old_path_length){
            return;
        }
        Print("Old path fail: "+old_path_fail+"\nNew path fail: "+new_path_fail+"\n");
        Print("Old path length: "+old_path_length+"\nNew path length: "+new_path_length+"\n");
        Print("Path ok!\n");
        has_jump_target = true;
        jump_target_vel = jump_vel;
    } 
}

int IsThreatToCharacter(int char_id){
    if(chase_target_id == char_id && goal == _attack){
        return 1;
    } else {
        return 0;
    }
}