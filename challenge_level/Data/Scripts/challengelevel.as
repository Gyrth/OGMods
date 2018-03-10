#include "threatcheck.as"
#include "music_load.as"
#include "menu_common.as"
#include "arena_meta_persistence.as"

IMGUI@ imGUI;
bool reset_allowed = true;
bool show_ui = false;
float time = 0.0f;
float no_win_time = 0.0f;
string level_name;
int in_victory_trigger = 0;
const float _reset_delay = 4.0f;
float reset_timer = _reset_delay;
IMContainer@ top_ribbon;
IMContainer@ bottom_ribbon;
array<string> mission_objectives;
array<string> mission_objective_colors;
bool success = true;
int controller_id = 0;

FontSetup greenValueFont("edosz", 65, HexColor("#0f0"));
FontSetup redValueFont("edosz", 65, HexColor("#f00"));
FontSetup tealValueFont("edosz", 65, HexColor("#028482"));

MusicLoad ml("Data/Music/challengelevel.xml");

void Init(string p_level_name) {
    level_name = p_level_name;
    @imGUI = CreateIMGUI();
}

void SetWindowDimensions(int w, int h)
{
	imGUI.doScreenResize();
}

void BuildUI(){
    show_ui = true;

    imGUI.clear();
    imGUI.setup();

    int fadein_time = 250;
    float ribbon_height = 200.0f;
    vec2 screen_size = vec2(2560, 1440);

    IMDivider mainDiv( "mainDiv", DOVertical );
    mainDiv.setClip(true);
	imGUI.getMain().setAlignment(CACenter, CACenter);
	imGUI.getMain().setElement(mainDiv);


    IMContainer top_container(screen_size.x, 600);
    //top_container.showBorder();
    @top_ribbon = top_container;
    IMContainer top_ribbon_holder(screen_size.x, ribbon_height);
    top_container.addFloatingElement(top_ribbon_holder, "top_ribbon_holder", vec2(0,0));
    imGUI.getMain().addFloatingElement(top_container, "top_container", vec2(0, -200));
    //mainDiv.append(top_container);

    IMDivider middle_divider( "middleDivider", DOVertical );

    IMText title(CheckMission(), title_font);
    middle_divider.append(title);

    IMImage divider_image("Textures/ui/challenge_mode/divider_strip_c.tga");
    divider_image.scaleToSizeY(40.0f);
    middle_divider.append(divider_image);

    IMText objectives_title("Objectives", button_font);
    middle_divider.append(objectives_title);

    for( uint i = 0; i < mission_objectives.size(); i++ ) {
        FontSetup new_font = button_font;
        if(mission_objective_colors[i] == "red") {
            new_font = redValueFont;
        } else {
            new_font = greenValueFont;
        }
        IMText objective(mission_objectives[i], new_font);
        middle_divider.append(objective);
    }

    IMDivider achievements_holder("achievements_holder", DOHorizontal);
    achievements_holder.setAlignment(CACenter, CATop);
    middle_divider.append(achievements_holder);

    IMDivider time_holder("time_holder", DOVertical);
    achievements_holder.append(time_holder);

    IMText time_title("Time", button_font);
    time_holder.append(time_title);

    FontSetup time_font = button_font;
    if(success){
        time_font = greenValueFont;
    } else {
        time_font = redValueFont;
    }
    IMText time_text(StringFromFloatTime(no_win_time), time_font);
    time_holder.append(time_text);

    SavedLevel @saved_level = GetSave();
    float best_time = atof(saved_level.GetValue("time"));
    if(best_time > 0.0f){
        IMText time_text_2(StringFromFloatTime(no_win_time),tealValueFont);
        time_holder.append( time_text_2 );
    }

    achievements_holder.appendSpacer(100.0f);

    IMDivider enemy_holder("enemy_holder", DOVertical);
    achievements_holder.append(enemy_holder);

    int player_id = GetPlayerCharacterID();
    if(player_id != -1){
        for(int i=0; i<level.GetNumObjectives(); ++i){
            string objective = level.GetObjective(i);
            if(objective == "destroy_all"){
                IMText titleEnemies("Enemies", button_font);
                enemy_holder.append( titleEnemies );
                IMDivider kills("Kills", DOHorizontal);
                enemy_holder.append( kills );
                MovementObject@ player_char = ReadCharacter(player_id);
                int num = GetNumCharacters();
                for(int j=0; j<num; ++j){
                    MovementObject@ char = ReadCharacter(j);
                    if(!player_char.OnSameTeam(char)){
                        int knocked_out = char.GetIntVar("knocked_out");
                        if(knocked_out == 1 && char.GetFloatVar("blood_health") <= 0.0f){
                            knocked_out = 2;
                        }
                        IMImage@ img;
                        switch(knocked_out){
                        case 0:
                            @img = IMImage("Textures/ui/challenge_mode/ok.png");
                            break;
                        case 1:
                            @img = IMImage("Textures/ui/challenge_mode/ko.png");
                            break;
                        case 2:
                            @img = IMImage("Textures/ui/challenge_mode/dead.png");
                            break;
                        }
                        img.scaleToSizeY(70);
                        kills.append(img);
                    }
                }
            }
        }
    }

    achievements_holder.appendSpacer(100.0f);

    IMDivider extra_holder("extra_holder", DOVertical);
    achievements_holder.append(extra_holder);

    IMText titleExtra("Extra", button_font);
    extra_holder.append( titleExtra );

    int num_achievements = level.GetNumAchievements();
    for(int i=0; i<num_achievements; ++i){
        string achievement = level.GetAchievement(i);
        string display_str;

        FontSetup new_font = button_font;

        if(saved_level.GetValue(achievement) == "true"){
            new_font = tealValueFont;
        }
        if(achievements.GetValue(achievement)){
            new_font = greenValueFont;
        }

        if(achievement == "flawless"){
            display_str += "flawless";
        } else if(achievement == "no_kills"){
            display_str += "no kills";
        } else if(achievement == "no_injuries"){
            display_str = "never hurt";
        } else if(achievement == "no_alert"){
            display_str = "never seen";
        }
        IMText extra_val(display_str, new_font);
        extra_holder.append( extra_val );
    }

    IMDivider button_pane("button_pane", DOHorizontal);

    IMDivider quit_button_pane("quit_button_pane", DOVertical);
    IMImage quitButton ("Textures/ui/challenge_mode/quit_icon_c.tga");
    quitButton.scaleToSizeX(250);
    quitButton.addMouseOverBehavior( mouseover_color_background , "");
    quitButton.addLeftMouseClickBehavior(IMFixedMessageOnClick("quit"), "");
    quit_button_pane.append(quitButton);
    IMText quit_key("(Q)", button_font_extra_small);
    quit_button_pane.append(quit_key);
    IMText quit_description("Quit to main menu.", button_font_extra_small);
    quit_button_pane.append(quit_description);
    button_pane.append(quit_button_pane);

    IMDivider retry_button_pane("retry_button_pane", DOVertical);
    IMImage retryButton("Textures/ui/challenge_mode/retry_icon_c.tga");
    retryButton.scaleToSizeX(250);
    retryButton.addMouseOverBehavior( mouseover_color_background , "");
    retryButton.addLeftMouseClickBehavior(IMFixedMessageOnClick("retry"), "");
    retry_button_pane.append(retryButton);
    IMText retry_key("(R)", button_font_extra_small);
    retry_button_pane.append(retry_key);
    IMText retry_description("Retry level.", button_font_extra_small);
    retry_button_pane.append(retry_description);
    button_pane.append(retry_button_pane);

    IMDivider continue_button_pane("continue_button_pane", DOVertical);
    IMImage continueButton("Textures/ui/challenge_mode/continue_icon_c.tga");
    continueButton.scaleToSizeX(250);
    continueButton.addMouseOverBehavior( mouseover_color_background , "");
    continueButton.addLeftMouseClickBehavior(IMFixedMessageOnClick("continue"), "");
    continue_button_pane.append(continueButton);
    IMText continue_key("(F)", button_font_extra_small);
    continue_button_pane.append(continue_key);
    IMText continue_description("Continue and don't show again.", button_font_extra_small);
    continue_button_pane.append(continue_description);
    button_pane.append(continue_button_pane);

    middle_divider.append(button_pane);

    mainDiv.append(middle_divider);

    IMContainer bottom_container( screen_size.x, 600);
    @bottom_ribbon = bottom_container;
    IMContainer bottom_ribbon_holder(screen_size.x, ribbon_height);
    bottom_container.addFloatingElement(bottom_ribbon_holder, "bottom_ribbon_holder", vec2(0,0));
    imGUI.getMain().addFloatingElement(bottom_container, "bottom_container", vec2(0, 1100));
    //mainDiv.append(bottom_container);

    IMImage main_background( "Textures/ui/challenge_mode/blue_gradient_c_nocompress.tga" );
    main_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
    main_background.setZOrdering(0);
	main_background.setSize(screen_size);
    main_background.setColor(vec4(1,1,1, 0.8));
    main_background.setClip(false);
	imGUI.getMain().addFloatingElement(main_background, "main_background", vec2(0.0f, 0.0f));

    AddRibbonElements(top_ribbon_holder, 7, true);
    AddRibbonElements(bottom_ribbon_holder, 7, false);
    //imGUI.getFooter().addFloatingElement(ribbon_element, "", vec2(0,0));
}

void AddRibbonElements(IMContainer@ container, int amount, bool flip){
    float starting_x = -600;
    for(int i = 0; i < amount; i++){
        IMImage ribbon_element("Textures/ui/challenge_mode/red_gradient_border_c.tga");
        ribbon_element.setClip(false);
        ribbon_element.setSize(vec2(600.0, 600.0));
        if (flip){
            ribbon_element.setRotation(180.0f);
        }
        container.addFloatingElement(ribbon_element, "element" + i, vec2(starting_x + 600.0f * i, 0.0f));
    }
}

string CheckMission(){

    mission_objectives.resize(0);
    mission_objective_colors.resize(0);

    for(int i=0; i<level.GetNumObjectives(); ++i){
        string objective = level.GetObjective(i);
        string mission_objective;
        string mission_objective_color;
        if(objective == "destroy_all"){
            int threats_possible = ThreatsPossible();
            int threats_remaining = ThreatsRemaining();
            if(threats_possible <= 0){
                mission_objective = "  Defeat all enemies (N/A)";
                mission_objective_color = "red";
            } else {
                if(threats_remaining == 0){
                    mission_objective += "v ";
                    mission_objective_color = "green";
                } else {
                    mission_objective += "x ";
                    mission_objective_color = "red";
                    success = false;
                }
                mission_objective += "defeat all enemies (" ;
                mission_objective += (threats_possible - threats_remaining);
                mission_objective += "/" ;
                mission_objective += threats_possible;
                mission_objective += ")";
            }
        }
        if(objective == "reach_a_trigger"){
            if(in_victory_trigger > 0){
                mission_objective += "v ";
                mission_objective_color = "green";
            } else {
                mission_objective += "x ";
                mission_objective_color = "red";
                success = false;
            }
            mission_objective += "Reach the goal";
        }
        if(objective == "must_visit_trigger"){
            if(NumUnvisitedMustVisitTriggers() == 0){
                mission_objective += "v ";
                mission_objective_color = "green";
            } else {
                mission_objective += "x ";
                mission_objective_color = "red";
                success = false;
            }
            mission_objective += "Visit all checkpoints";
        }
        if(objective == "reach_a_trigger_with_no_pursuers"){
            if(in_victory_trigger > 0 && NumActivelyHostileThreats() == 0){
                mission_objective += "v ";
                mission_objective_color = "green";
            } else {
                mission_objective += "x ";
                mission_objective_color = "red";
                success = false;
            }
            mission_objective += "Reach the goal without any pursuers";
        }

        if(objective == "collect"){
            if(NumUnsatisfiedCollectableTargets() != 0){
                success = false;
                mission_objective += "x ";
                mission_objective_color = "red";
            }  else {
                mission_objective += "v ";
                mission_objective_color = "green";
            }
            mission_objective += "Collect items";
        }

        mission_objectives.insertLast(mission_objective);
        mission_objective_colors.insertLast(mission_objective_color);
    }
    string title = success ? 'challenge complete' : 'challenge incomplete';
    return title;
}

void ScriptReloaded() {
	Log(info, "Script reloaded!\n");
}

SavedLevel@ GetSave() {
    SavedLevel @saved_level;
    if(save_file.GetLoadedVersion() == 1 && save_file.SaveExist("","",level_name)) {
        @saved_level = save_file.GetSavedLevel(level_name);
        saved_level.SetKey(GetCurrentLevelModsourceID(),"challenge_level",level_name);
    } else {
        @saved_level = save_file.GetSave(GetCurrentLevelModsourceID(),"challenge_level",level_name);
    }
    return saved_level;
}

class Achievements {
    bool flawless_;
    bool no_first_strikes_;
    bool no_counter_strikes_;
    bool no_kills_;
    bool no_alert_;
    bool injured_;
    float total_block_damage_;
    float total_damage_;
    float total_blood_loss_;
    void Init() {
        flawless_ = true;
        no_first_strikes_ = true;
        no_counter_strikes_ = true;
        no_kills_ = true;
        no_alert_ = true;
        injured_ = false;
        total_block_damage_ = 0.0f;
        total_damage_ = 0.0f;
        total_blood_loss_ = 0.0f;
    }
    Achievements() {
        Init();
    }
    void UpdateDebugText() {
        DebugText("achmt0", "Flawless: "+flawless_, 0.5f);
        DebugText("achmt1", "No Injuries: "+!injured_, 0.5f);
        DebugText("achmt2", "No First Strikes: "+no_first_strikes_, 0.5f);
        DebugText("achmt3", "No Counter Strikes: "+no_counter_strikes_, 0.5f);
        DebugText("achmt4", "No Kills: "+no_kills_, 0.5f);
        DebugText("achmt5", "No Alerts: "+no_alert_, 0.5f);
        DebugText("achmt6", "Time: "+no_win_time, 0.5f);
        //DebugText("achmt_damage0", "Block damage: "+total_block_damage_, 0.5f);
        //DebugText("achmt_damage1", "Impact damage: "+total_damage_, 0.5f);
        //DebugText("achmt_damage2", "Blood loss: "+total_blood_loss_, 0.5f);

        SavedLevel @level = GetSave();
        DebugText("saved_achmt0", "Saved Flawless: "+(level.GetValue("flawless")=="true"), 0.5f);
        DebugText("saved_achmt1", "Saved No Injuries: "+(level.GetValue("no_injuries")=="true"), 0.5f);
        DebugText("saved_achmt2", "Saved No Kills: "+(level.GetValue("no_kills")=="true"), 0.5f);
        DebugText("saved_achmt3", "Saved No Alert: "+(level.GetValue("no_alert")=="true"), 0.5f);
        DebugText("saved_achmt4", "Saved Time: "+level.GetValue("time"), 0.5f);
    }
    void Save() {
        SavedLevel @saved_level = GetSave();
        if(flawless_) saved_level.SetValue("flawless","true");
        if(!injured_) saved_level.SetValue("no_injuries","true");
        if(no_kills_) saved_level.SetValue("no_kills","true");
        if(no_alert_) saved_level.SetValue("no_alert","true");
        string time_str = saved_level.GetValue("time");
        if(time_str == "" || no_win_time < atof(saved_level.GetValue("time"))){
            saved_level.SetValue("time", ""+no_win_time);
        }
        save_file.WriteInPlace();
    }
    void PlayerWasHit() {
        flawless_ = false;
    }
    void PlayerWasInjured() {
        injured_ = true;
        flawless_ = false;
    }
    void PlayerAttacked() {
        no_first_strikes_ = false;
    }
    void PlayerSneakAttacked() {
        no_first_strikes_ = false;
    }
    void PlayerCounterAttacked() {
        no_counter_strikes_ = false;
    }
    void EnemyDied() {
        no_kills_ = false;
    }
    void EnemyAlerted() {
        no_alert_ = false;
    }
    void PlayerBlockDamage(float val) {
        total_block_damage_ += val;
        PlayerWasHit();
    }
    void PlayerDamage(float val) {
        total_damage_ += val;
        PlayerWasInjured();
    }
    void PlayerBloodLoss(float val) {
        total_blood_loss_ += val;
        PlayerWasInjured();
    }
    bool GetValue(const string &in key){
        if(key == "flawless"){
            return flawless_;
        } else if(key == "no_kills"){
            return no_kills_;
        } else if(key == "no_injuries"){
            return !injured_;
        }
        return false;
    }
};

Achievements achievements;

bool HasFocus(){
    return show_ui;
}

void Reset(){
    time = 0.0f;
    reset_allowed = true;
    reset_timer = _reset_delay;
    achievements.Init();
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        Reset();
    } else if(token == "achievement_event"){
        token_iter.FindNextToken(msg);
        AchievementEvent(token_iter.GetToken(msg));
    } else if(token == "achievement_event_float"){
        token_iter.FindNextToken(msg);
        string str = token_iter.GetToken(msg);
        token_iter.FindNextToken(msg);
        float val = atof(token_iter.GetToken(msg));
        AchievementEventFloat(str, val);
    } else if(token == "victory_trigger_enter"){
        ++in_victory_trigger;
        in_victory_trigger = max(1,in_victory_trigger);
    } else if(token == "victory_trigger_exit"){
        --in_victory_trigger;
    }
}

void DrawGUI() {
    imGUI.render();
}

void AchievementEvent(string event_str){
    if(event_str == "player_was_hit"){
        achievements.PlayerWasHit();
    } else if(event_str == "player_was_injured"){
        achievements.PlayerWasInjured();
    } else if(event_str == "player_attacked"){
        achievements.PlayerAttacked();
    } else if(event_str == "player_sneak_attacked"){
        achievements.PlayerSneakAttacked();
    } else if(event_str == "player_counter_attacked"){
        achievements.PlayerCounterAttacked();
    } else if(event_str == "enemy_died"){
        achievements.EnemyDied();
    } else if(event_str == "enemy_alerted"){
        achievements.EnemyAlerted();
    }
}

void AchievementEventFloat(string event_str, float val){
    if(event_str == "player_block_damage"){
        achievements.PlayerBlockDamage(val);
    } else if(event_str == "player_damage"){
        achievements.PlayerDamage(val);
    } else if(event_str == "player_blood_loss"){
        achievements.PlayerBloodLoss(val);
    }
}

string StringFromFloatTime(float time){
    string time_str;
    int minutes = int(time) / 60;
    int seconds = int(time)-minutes*60;
    time_str += minutes + ":";
    if(seconds < 10){
        time_str += "0";
    }
    time_str += seconds;
    return time_str;
}

void Update() {
    time += time_step;
    VictoryCheckNormal();
    UpdateRibbons();
    UpdateKeyPresses();
    ProcessMessages();
    // Do the general GUI updating
    imGUI.update();
}

void ProcessMessages(){
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
        if( message.name == "quit" ) {
            level.SendMessage("go_to_main_menu");
        } else if( message.name == "retry" ) {
            level.SendMessage("reset");
            imGUI.clear();
            show_ui = false;
        } else if( message.name == "continue" ) {
            imGUI.clear();
            show_ui = false;
            SendGlobalMessage("levelwin");
        }
    }
}

void UpdateKeyPresses(){
    if(show_ui){
        if (GetInputPressed(controller_id, "r")){
            imGUI.receiveMessage( IMMessage("retry"));
        }
        else if(GetInputPressed(controller_id, "f")){
            imGUI.receiveMessage( IMMessage("continue"));
        }
        else if(GetInputPressed(controller_id, "q")){
            imGUI.receiveMessage( IMMessage("quit"));
        }
    }
}

vec2 top_ribbon_position(0.0f, 0.0f);
vec2 bottom_ribbon_position(0.0f, 0.0f);
float move_speed = 50.0f;

void UpdateRibbons(){
    if(!show_ui){
        return;
    }
    top_ribbon_position.x = top_ribbon_position.x + time_step * move_speed;
    bottom_ribbon_position.x = bottom_ribbon_position.x - time_step * move_speed;

    if(top_ribbon_position.x > 600.0){
        top_ribbon_position.x = 0.0f;
    }
    if(bottom_ribbon_position.x < -600.0){
        bottom_ribbon_position.x = 0.0f;
    }
    top_ribbon.moveElement("top_ribbon_holder", top_ribbon_position);
    bottom_ribbon.moveElement("bottom_ribbon_holder", bottom_ribbon_position);
}

int NumUnvisitedMustVisitTriggers() {
    int num_hotspots = GetNumHotspots();
    int return_val = 0;
    for(int i=0; i<num_hotspots; ++i){
        Hotspot@ hotspot = ReadHotspot(i);
        if(hotspot.GetTypeString() == "must_visit_trigger"){
            if(!hotspot.GetBoolVar("visited")){
                ++return_val;
            }
        }
    }
    return return_val;
}

int NumUnsatisfiedCollectableTargets() {
    int num_hotspots = GetNumHotspots();
    int return_val = 0;
    for(int i=0; i<num_hotspots; ++i){
        Hotspot@ hotspot = ReadHotspot(i);
        if(hotspot.GetTypeString() == "collectable_target"){
            if(!hotspot.GetBoolVar("condition_satisfied")){
                ++return_val;
            }
        }
    }
    return return_val;
}

void VictoryCheckNormal() {
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    bool victory = true;
    bool display_victory_conditions = false;

    float max_reset_delay = _reset_delay;
    for(int i=0; i<level.GetNumObjectives(); ++i){
        string objective = level.GetObjective(i);
        if(objective == "destroy_all"){
            int threats_remaining = ThreatsRemaining();
            int threats_possible = ThreatsPossible();
            if(threats_remaining > 0 || threats_possible == 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_a","Did not yet defeat all enemies",0.5f);
                }
            }
        }
        if(objective == "reach_a_trigger"){
            max_reset_delay = 1.0;
            if(in_victory_trigger <= 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_b","Did not yet reach trigger",0.5f);
                }
            }
        }
        if(objective == "reach_a_trigger_with_no_pursuers"){
            max_reset_delay = 1.0;
            if(in_victory_trigger <= 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_c","Did not yet reach trigger",0.5f);
                }
            } else if(NumActivelyHostileThreats() > 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_c","Reached trigger, but still pursued",0.5f);
                }
            }
        }
        if(objective == "must_visit_trigger"){
            max_reset_delay = 1.0;
            if(NumUnvisitedMustVisitTriggers() != 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_d","Did not visit all must-visit triggers",0.5f);
                }
            }
        }
        if(objective == "collect"){
            max_reset_delay = 1.0;
            if(NumUnsatisfiedCollectableTargets() != 0){
                victory = false;
                if(display_victory_conditions){
                    DebugText("victory_d","Did not visit all must-visit triggers",0.5f);
                }
            }
        }
    }
    reset_timer = min(max_reset_delay, reset_timer);

    bool failure = false;
    MovementObject@ player_char = ReadCharacter(player_id);
    if(player_char.GetIntVar("knocked_out") != _awake){
        failure = true;
    }
    if(reset_timer > 0.0f && (victory || failure)){
        reset_timer -= time_step;
        if(reset_timer <= 0.0f){
            if(reset_allowed){
                //Show end screen UI
                BuildUI();
                reset_allowed = false;
            }
            if(victory){
                achievements.Save();
            }
        }
    } else {
        reset_timer = _reset_delay;
        no_win_time = time;
    }
}

void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}
