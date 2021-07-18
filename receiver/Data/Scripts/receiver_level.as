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
bool show_red = false;

float fade_out_start;
float fade_out_end = -1.0f;

float fade_in_start;
float fade_in_end = -1.0f;

bool resetting = false;

FontSetup greenValueFont("edosz", 65, HexColor("#0f0"));
FontSetup redValueFont("edosz", 65, HexColor("#f00"));
FontSetup tealValueFont("edosz", 65, HexColor("#028482"));

MusicLoad ml("Data/Music/receiver_music.xml");

void Init(string p_level_name) {
	level_name = p_level_name;
	@imGUI = CreateIMGUI();
}

void SetWindowDimensions(int w, int h)
{
	imGUI.doScreenResize();
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
	show_red = false;
	fade_in_start = the_time;
	fade_in_end = the_time+0.4f;
	reset_timer = _reset_delay;

	/* const float fade_time = 0.2f;
	fade_out_start = the_time;
	fade_out_end = the_time+fade_time;
	fade_in_start = the_time+fade_time;
	fade_in_end = the_time+fade_time*2.0f; */

	achievements.Init();
}

void DrawGUI() {

	if(show_red){
		fade_in_start = the_time;
		fade_in_end = the_time + 0.2;
	}

	if(fade_out_end != -1.0f){
        float blackout_amount = min(1.0, 1.0 - ((fade_out_end - the_time) / (fade_out_end - fade_out_start)));
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        if(fade_out_end <= the_time){
            fade_out_end = -1.0f;
        }
    } else if(fade_in_end != -1.0f && show_red){
        float blackout_amount = min(0.5, ((fade_in_end - the_time) / (fade_in_end - fade_in_start)));
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(1.0f,0.0f,0.0f,blackout_amount);
        if(fade_in_end <= the_time){
            fade_in_end = -1.0f;
        }
    }
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

	if(!resetting){
		int player_id = GetPlayerCharacterID();
		if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
			show_red = true;
		}
	}

	ProcessMessages();
	UpdateMusic();
	// Do the general GUI updating
	imGUI.update();
	resetting = false;
}

void ProcessMessages(){
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "quit" ) {

		} else if( message.name == "retry" ) {
			imGUI.clear();
			show_ui = false;
		}
	}
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
		resetting = true;
        Reset();
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

void UpdateMusic() {
	int player_id = GetPlayerCharacterID();
	if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
		PlaySong("receiver_death");
		return;
	}
	PlaySong("receiver_music");
}
