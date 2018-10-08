#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"

string level_name;
EntityType _group = EntityType(29);

MusicLoad ml("Data/Music/killer_pumpkin.xml");
IMGUI@ imGUI;
IMText@ kill_counter;
float header_height = 30.0f;
FontSetup main_font("OptimusPrinceps", 125, HexColor("#ffffff"), true);
array<int> spawnpoint_ids;
float spawn_timer = 15.0;
float starting_spawn_frequency = 15.0;
float spawn_frequency = starting_spawn_frequency;
float frequency_ramp = 0.25;
int nr_kills = 0;
string kill_label_text = "Pumpkins squashed: ";
array<int> forget_character_ids;
float death_timeout = 0.0;

void ForgetCharacter(int id){
	array<int> mos = GetObjectIDsType(_movement_object);
	for(uint i = 0; i < mos.size(); i++){
		MovementObject@ char = ReadCharacterID(mos[i]);
		char.Execute("situation.MovementObjectDeleted(" + id + ");");
	}
}

void Init(string p_level_name) {
	level_name = p_level_name;
	PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
	ReadScriptParameters();
	@imGUI = CreateIMGUI();
	imGUI.setHeaderHeight(header_height);
	imGUI.setup();
	AddCounter();
}

void AddCounter(){
	IMDivider label_holder("label_holder", DOVertical);
	@kill_counter = IMText(kill_label_text + nr_kills, main_font);
	label_holder.append(kill_counter);

	imGUI.getHeader().setAlignment(CACenter, CATop);
	imGUI.getHeader().setElement(label_holder);
}

void ReadScriptParameters(){
	ScriptParams@ level_params = level.GetScriptParams();
}

bool HasFocus(){
	return false;
}

void Reset(){
	ReadScriptParameters();
	ResetLevel();
	imGUI.clear();
	imGUI.setHeaderHeight(header_height);
	imGUI.setup();
	nr_kills = 0;
	AddCounter();
	GetSpawnPoints();
	spawn_frequency = starting_spawn_frequency;
	DeletePumpkins();
}

void DeletePumpkins(){
	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);
		if(!char.controlled){
			QueueDeleteObjectID(char.GetID());
			forget_character_ids.insertLast(char.GetID());
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
		Reset();
	}else if(token == "pumpkin_died"){
		token_iter.FindNextToken(msg);
        token = token_iter.GetToken(msg);
        int pumpkin_id = atoi(token);
		forget_character_ids.insertLast(pumpkin_id);
		nr_kills += 1;
		kill_counter.setText(kill_label_text + nr_kills);
	}
}

void DrawGUI() {
	imGUI.render();
}

void Update() {
	UpdateMusic();
	UpdateSounds();
	UpdateReviving();
	while(imGUI.getMessageQueueSize() > 0){
        IMMessage@ message = imGUI.getNextMessage();
        if(message.name == "message"){
			Log(info, "messsage");
		}
	}
	imGUI.update();
	if(spawnpoint_ids.size() == 0){
		GetSpawnPoints();
	}
	UpdateSpawning();
	SetPlaceholderPreviews();
	if(forget_character_ids.size() > 0){
		ForgetCharacter(forget_character_ids[0]);
		forget_character_ids.removeAt(0);
	}
}

// Attach a specific preview path to a given placeholder object
void SetSpawnPointPreview(Object@ spawn, string &in path){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);
}

// Find spawn points and set which object is displayed as a preview
void SetPlaceholderPreviews() {
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("enemy_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/IGF_Characters/IGF_Guard.xml");
            }else if("weapon_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Weapons/rabbit_weapons/rabbit_knife.xml");
            }else if("bush_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Plants/Trees/temperate/green_bush.xml");
            }else if("pillar_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Buildings/pillar1.xml");
            }
        }
    }
}

void GetSpawnPoints(){
	spawnpoint_ids = GetObjectIDsType(_placeholder_object);
}

void UpdateSpawning(){
	if(EditorModeActive()){
		return;
	}
	if(spawn_timer > spawn_frequency){
		spawn_timer = 0.0;
		spawn_frequency = max(1.0, spawn_frequency - frequency_ramp);
		Log(info, "spawn rate " + spawn_frequency);
		SpawnKillerPumpking();
	}else{
		spawn_timer += time_step;
	}
}

void SpawnKillerPumpking(){
	if(spawnpoint_ids.size() == 0){
		Log(info, "No spawnpoints found");
		return;
	}
	MovementObject@ player_character = ReadCharacter(GetPlayerCharacterID());
	Object@ spawn_obj;

	for(uint i = 0; i <= 10; i++){
		int random_spawnpoint_id = spawnpoint_ids[rand() % spawnpoint_ids.size()];
		@spawn_obj = ReadObjectFromID(random_spawnpoint_id);
		//Player is too close to the spawnpoint to use this spawnpoint.
		if(distance(player_character.position, spawn_obj.GetTranslation()) > 25.0){
			break;
		}else if(i == 10){
			return;
		}
	}

	int new_killer_pumpkin_id = CreateObject("Data/Characters/killer_pumpkin_actor.xml");
	Object@ new_killer_pumpkin = ReadObjectFromID(new_killer_pumpkin_id);
	new_killer_pumpkin.SetTranslation(spawn_obj.GetTranslation());

	ScriptParams@ pumpkin_params = new_killer_pumpkin.GetScriptParams();
	pumpkin_params.SetFloat("Character Scale", RangedRandomFloat(0.25, 1.5));
	ReadCharacterID(new_killer_pumpkin_id).Execute("SetParameters();");
}

void UpdateMusic() {
	int player_id = GetPlayerCharacterID();
	if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
		PlaySong("sad");
		return;
	}
	if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
		PlaySong("combat");
		return;
	}
	PlaySong("ambient-tense");
}

float delay = 5.0f;
float radius = 5.0f;
array<string> sounds = {"Data/Sounds/ambient/amb_forest_wood_creak_1.wav",
						"Data/Sounds/ambient/amb_forest_wood_creak_2.wav",
						"Data/Sounds/ambient/amb_forest_wood_creak_3.wav"};

void UpdateSounds(){
	delay -= time_step;
	if(delay < 0.0f){
		delay = RangedRandomFloat(3.0, 20.0f);
		int player_id = GetPlayerCharacterID();
		if(player_id != -1){
			MovementObject@ player = ReadCharacter(player_id);
			vec3 position = player.position + vec3(RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius));
			PlaySound(sounds[rand() % sounds.size()], position);
		}
	}
}

void UpdateReviving(){
	int player_id = GetPlayerCharacterID();
	if(player_id != -1){
		MovementObject@ player = ReadCharacter(player_id);
		if(!EditorModeActive() && player.GetIntVar("knocked_out") == _dead){
			if(death_timeout <= 5.0){
				death_timeout += time_step;
				if(death_timeout > 5.0){
					kill_counter.setText("Click LMB to restart.");
				}
			}else if(GetInputPressed(0, "mouse0")){
				death_timeout = 0.0;
				Reset();
			}
		}
	}
}
