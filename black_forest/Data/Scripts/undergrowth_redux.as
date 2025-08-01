#include "ui_effects.as"
#include "threatcheck.as"
#include "music_load.as"
#include "black_forest_save_load.as"

#include "undergrowth_beltSystem.as"
#include "undergrowth_saveSystem.as"
#include "undergrowth_ui.as"
#include "undergrowth_spawns.as"
#include "undergrowth_updates.as"
#include "undergrowth_includes.as"

//-----------------------------------------------------------------------------------------------------------------------------------------------------------
array<string> adjectives = {"Blue", "Black", "Green", "Moss", "Pale", "Grey", "Dark", "Bright", "White", "Silver", "Golden", "Sage", "Wise", "Strong", "Small", "Sturdy", "Quick", "Fast", "Intrepid", "Chosen", "Wind", "Forest", "Wooden", "Breeze", "Snow", "Winter", "Spring", "Summer", "Autumn", "Moon", "Sun", "Star", "Cloud", "Sky", "Cotton", "Fluffy", "Candy", "Furry", "Fuzzy", "Lucky", "Hoppy", "Clover", "Pumkin", "Vanilla", "Velvet"};
array<string> names = {"Carrot", "Leaf", "Oak", "Maple", "Bunny", "Walker", "Runner", "Courier", "Foot", "Ears", "Tail", "Lapin", "Butt", "Hare", "Berry", "Nugget", "Cookie", "Ball", "Arrow", "Fist", "Kick", "Punt", "Strike", "Blade", "Knife", "Dagger", "Whisker", "Knife", "Katana", "Storm", "Wind", "Strider", "Traveler", "Voyager", "Scout", "Trailblazer", "Pathfinder", "Ranger", "Warden", "Patch", "Hop", "Rabbit", "Baggins", "Thumper", "Dash", "Benjamin", "Peter", "Jumper", "Blaze", "Buttons", "Butter", "Scotch", "Nibbles"};
array<string> jailSounds = {"Data/Sounds/jailSound1.wav", "Data/Sounds/jailSound2.wav", "Data/Sounds/jailSound3.wav", "Data/Sounds/jailSound4.wav", "Data/Sounds/jailSound5.wav", "Data/Sounds/jailSound6.wav", "Data/Sounds/jailSound7.wav", "Data/Sounds/jailSound8.wav", "Data/Sounds/jailSound9.wav", "Data/Sounds/jailSound10.wav"};
array<string> summerSounds = {"Data/Sounds/ambient/amb_forest_wood_creak_1.wav", "Data/Sounds/ambient/amb_forest_wood_creak_2.wav", "Data/Sounds/ambient/amb_forest_wood_creak_3.wav", "Data/Sounds/pecker1.wav", "Data/Sounds/pecker2.wav", "Data/Sounds/pecker3.wav", "Data/Sounds/pecker4.wav", "Data/Sounds/pecker5.wav", "Data/Sounds/sumbird1.wav", "Data/Sounds/sumbird2.wav", "Data/Sounds/sumbird3.wav", "Data/Sounds/sumbird4.wav", "Data/Sounds/sumbird5.wav", "Data/Sounds/sumbird6.wav", "Data/Sounds/sumbird7.wav", "Data/Sounds/sumbird8.wav", "Data/Sounds/sumbird9.wav", "Data/Sounds/crow1.wav", "Data/Sounds/crow1.wav", "Data/Sounds/crow2.wav", "Data/Sounds/moose2.wav", "Data/Sounds/moose3.wav"};
array<string> nightSummerSounds = {"Data/Sounds/ambient/amb_forest_wood_creak_1.wav", "Data/Sounds/ambient/amb_forest_wood_creak_2.wav", "Data/Sounds/ambient/amb_forest_wood_creak_3.wav", "Data/Sounds/owl1.wav", "Data/Sounds/owl2.wav", "Data/Sounds/wolf1.wav", "Data/Sounds/wolf2.wav", "Data/Sounds/wolf3.wav", "Data/Sounds/wolf4.wav", "Data/Sounds/wolf5.wav", "Data/Sounds/nightbird1.wav", "Data/Sounds/nightbird2.wav", "Data/Sounds/nightbird3.wav", "Data/Sounds/nightbird4.wav", "Data/Sounds/cricket1.wav", "Data/Sounds/cricket2.wav", "Data/Sounds/cricket3.wav", "Data/Sounds/cricket4.wav"};
array<string> winterSounds = {"Data/Sounds/amb_win1.wav", "Data/Sounds/amb_win2.wav", "Data/Sounds/amb_win3.wav", "Data/Sounds/amb_win4.wav", "Data/Sounds/amb_win5.wav", "Data/Sounds/crow3.wav"};
array<string> nightWinterSounds = {"Data/Sounds/amb_win1.wav", "Data/Sounds/amb_win2.wav", "Data/Sounds/amb_win3.wav", "Data/Sounds/amb_win4.wav", "Data/Sounds/amb_win5.wav", "Data/Sounds/wolf5.wav", "Data/Sounds/owl2.wav"};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------

//Parameters for user to change
int world_size = 4;
float block_size = 10.0f;
int cull_distance = 6;
bool distance_cull = false;
bool add_detail_objects = false;
//Variables not to be manually changed
int rain_sound_id = -1;
string level_name;
int player_id = -1;
float floor_height;
ivec2 grid_position(0, 0);
ivec2 cull_grid_position(0, 0);
bool rebuild_world = false;
EntityType _group = EntityType(29);
bool post_init_done = false;
IMGUI@ imGUI;
IMContainer@ text_container;
FontSetup default_font("Lato-Regular", 100 , HexColor("#CCCCCC"), true);
float blackout_amount = 0.0;
array<int> character_reset_list;
bool released_player = false;
vec3 starting_pos;
ivec2 array_offset(0, 0);
string wall_path = "Data/Objects/Buildings/Ruins/mysterious/ruin_wall.xml";
const float PI = 3.14159265359f;
double deg2rad = (PI / 180.0f);
bool wall_created = false;
game_modes game_mode = dynamic_world;
vec3 player_pos;
float enemy_spawn_mult = 1.0f;
weather_states weather_state = foggy;
int update_block_index = 0;
bool updated_global_reflection = false;
int updated_global_reflection_counter = 0;

//Undergrowth
bool uiIsOn = false;
bool cc_ui_added = false;
FontSetup small_font("arial", 45, HexColor("#CCCCCC"), true);
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string side_picture = "Images/character.png";
FontSetup client_connect_font("arial", 25 , vec4(1,1,1,0.75), true);
float trinketChances = 0.0f;
string white_background = "Textures/ui/menus/main/white_square.png";
float rogueUI_timer = 2.0f;
float rogueUI_priorityTimer = 0.0f;
int spam = 0;
vec3 g_pos_previous = vec3(0.0);
const float k_base_spawn_rate = 480.0f;
bool g_is_spawn_always_on = true;
float g_time_per_spawn = 1.0f / k_base_spawn_rate;
int g_player_in_hotspot_count = 0;
float g_elapsed_time = 0;
float fortChances = 1.0f;
int winterIsComing = 0;
float delay = 5.0f;
float radius = 15.0f;
int rogueTimer;
float reviveTimer = 5.0f;
float hunger_timer = 5.0f;
float questLoot_timer = -4.0;
float thirst_timer = 5.0f;
float sick_timer = 6.0f;
float poison_timer = 5.0f;
float bless_timer = 5.0f;
float totalMalus;
int postKnocked = 0;
float throwFlag_timer = 0;
float winter_timer = 0.1f;
int summer_sound_id = -1;
int winter_sound_id = -1;
int bombTimer = 0;
int noSave = 0;
int playerFood = 100;
int playerWater = 100;
int playerFatigue = 0;
int playerXp = 0;
int playerGold = 0;
int wendigoTimer = 0;
int attacker_set_on_fire = -1;
int attacker_set_ko = -1;
int attacker_set_bleeding = -1;
float daytimer =  30.0f;
float caravanTimer = 15.0f;
float huntTimer = 30.0f;
float garbageTimer = 60.0f;
int wantedOnce = 0;
int pausez = 0;
int once = 1;
int weaponTell = 0;
string sadTune = "sad"+rand()%2;
string chillTune = "chill"+rand()%10;
string fightTune = "fight"+rand()%3;
string deathTune = "death";

MusicLoad ml("Data/Music/black_forest.xml");

World world;

enum block_creation_states{
	duplicate_block,
	translate_block,
	skip_state,
	make_connections
}

array<BlockType@> block_types = {
									BlockType("Data/Objects/Undergrowth/block_house_1.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_house_2.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_house_3.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_falen.xml", 1.0f, 1),

									BlockType("Data/Objects/Undergrowth/special_1.xml", 0.001f, 1),
									BlockType("Data/Objects/Undergrowth/special_2.xml", 0.001f, 1),
									BlockType("Data/Objects/Undergrowth/special_3.xml", 0.001f, 1),
									BlockType("Data/Objects/Undergrowth/special_4.xml", 0.001f, 1),
									BlockType("Data/Objects/Undergrowth/special_5.xml", 0.001f, 1),

									BlockType("Data/Objects/Undergrowth/block_wolf_den_1.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_wolf_den_2.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_wolf_den_3.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_wolf_den_4.xml", 0.25f, 1),

									BlockType("Data/Objects/Undergrowth/block_lake_1.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_2.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_3.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_4.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_5.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_6.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_lake_7.xml", 0.5f, 1),
									
									BlockType("Data/Objects/Undergrowth/block_quest_2.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_quest_8.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_quest_9.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_quest_10.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_quest_11.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trinket.xml", 0.0001f, 1),

									BlockType("Data/Objects/Undergrowth/block_guard_patrol1.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_guard_patrol2.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_guard_patrol3.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_guard_patrol4.xml", 0.0001f, 1),
									
									BlockType("Data/Objects/Undergrowth/block_camp_1.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_2.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_3.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_4.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_5.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_6.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_camp_7.xml", 0.001f, 1),
								   
									BlockType("Data/Objects/Undergrowth/block_ruins_1.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_2.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_3.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_4.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_5.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_6.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_ruins_7.xml", 1.0f, 1),

									BlockType("Data/Objects/Undergrowth/block_trees_1.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_2.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_3.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_4.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_5.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_6.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_7.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_8.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_9.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_10.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_11.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_12.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_13.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_14.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_15.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_16.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_17.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_18.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_19.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_20.xml", 10.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_21.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_22.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_23.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_24.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_25.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_26.xml", 0.2f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_27.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_28.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_29.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_30.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_31.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_32.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_33.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_34.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_35.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_36.xml", 0.5f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_37.xml", 3.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_38.xml", 3.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_39.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_40.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_41.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_42.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_43.xml", 0.3f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_44.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_45.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_46.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_47.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_48.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_49.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_50.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_51.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_52.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_53.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_54.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_55.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_56.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_57.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_58.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_59.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_60.xml", 0.25f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_61.xml", 0.50f, 1),
									BlockType("Data/Objects/Undergrowth/block_trees_62.xml", 0.50f, 1),

									BlockType("Data/Objects/block_gatehouse.xml", 2.0f, 2),
									BlockType("Data/Objects/block_stucco_house.xml", 2.0f, 4),
									BlockType("Data/Objects/block_hole_01.xml", 2.0f, 1),
									BlockType("Data/Objects/block_trees_29.xml", 2.0f, 4)
									};

array<BlockType@> city_block_types = {
									BlockType("Data/Objects/Undergrowth/city_block_1.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_2.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_3.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_4.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_5.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_6.xml", 0.1f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_7.xml", 1.0f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_8.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_9.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_10.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_11.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_12.xml", 0.025f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_13.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_14.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_15.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_16.xml", 0.08f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_17.xml", 0.0001f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_18.xml", 1.5f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_19.xml", 0.05f, 1),
									BlockType("Data/Objects/Undergrowth/city_block_20.xml", 0.05f, 1)};

class BlockType{
	string path;
	float probability;
	Object@ original;
	array<int> children_ids;
	vec3 target_translation = vec3(0.0f, -10000.0f, 0.0f);
	int block_size_mult;
	bool contains_enemy = false;

	BlockType(string _path, float _probability, int _block_size_mult){
		path = _path;
		probability = _probability;
		block_size_mult = _block_size_mult;
	}

	void Preload(){
		int id = CreateObject(path);
		@original = ReadObjectFromID(id);
		GetBlockChildrenIds(original);
		original.SetTranslation(starting_pos);
		original.SetTranslationRotationFast(starting_pos, quaternion());

		if(!preload_done){
			for(uint i = 0; i < children_ids.size(); i++){
				Object@ obj = ReadObjectFromID(children_ids[i]);

				if(obj.GetType() == _placeholder_object){
					ScriptParams @obj_params = obj.GetScriptParams();
					if(obj_params.HasParam("Name") && obj_params.GetString("Name") == "enemy_spawn"){
						contains_enemy = true;
					}
				}else if(obj.GetType() == _group || obj.GetType() == _movement_object || obj.GetType() == _hotspot_object || obj.GetType() == _item_object){
					DeleteObjectID(children_ids[i]);
					// obj.SetEnabled(false);
				}
			}
		}
	}

	void DeletePreload(){
		QueueDeleteObjectID(original.GetID());
	}

	void SetFinalTranslation(){
		if(original.GetTranslation() != target_translation){
			original.SetTranslation(target_translation);
			original.SetEnabled(false);
		}
	}

	void GetBlockChildrenIds(Object@ start_at){
		array<int> ids = start_at.GetChildren();

		for(uint i = 0; i < ids.size(); i++){
			Object@ obj = ReadObjectFromID(ids[i]);
			/* obj.SetEnabled(false); */
			if(obj.GetType() == _group){
				GetBlockChildrenIds(obj);
			}else if(!add_detail_objects && obj.GetType() == _env_object){
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("DetailObjects")){
					DeleteObjectID(ids[i]);
					continue;
				}
			}
			children_ids.insertLast(ids[i]);
		}
	}
}

void BlockTypeUpdate(string pathz, float valuez){
	for(uint i = 0; i < block_types.size(); i++){
		if(block_types[i].path == pathz){
			block_types[i].probability = valuez;
			//DisplayError("Ohno", "block "+pathz+" found and updated to "+block_types[i].probability);
			break;
		}
	}
}

void cityBlockTypeUpdate(string pathz, float valuez){
	for(uint i = 0; i < city_block_types.size(); i++){
		if(city_block_types[i].path == pathz){
			city_block_types[i].probability = valuez;
			break;
		}
	}
}

float preload_progress = 0.0f;
int preload_counter = 0;
bool skip_one_preload = false;

void PreloadBlocks(){
	if(!post_init_done || preload_done){return;}

	if(skip_one_preload){
		skip_one_preload = false;
	}else if(preload_counter < int(block_types.size())){
		preload_progress = (preload_counter + 1) * 100.0f / block_types.size();
		block_types[preload_counter].Preload();
		preload_counter += 1;
		ShowPreloadProgress();
		skip_one_preload = true;
	}else{
		preload_done = true;
		for(uint i = 0; i < block_types.size(); i++){
			block_types[i].DeletePreload();
		}
	}
}

bool final_translation_done = false;

void SetBlockFinalTranslation(){
	if(!post_init_done || !preload_done || final_translation_done){return;}

	for(uint i = 0; i < block_types.size(); i++){
		block_types[i].SetFinalTranslation();
	}
	final_translation_done = true;
}

BlockType@ GetRandomBlockType(int available_space){
	SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
	string jailed = saved_level.GetValue("jailed");

	float sum = 0.0f;
	array<BlockType@> filtered_block_types;

	if(jailed == "yes"){
		for(uint i = 0; i < city_block_types.size(); i++){
		if(city_block_types[i].block_size_mult <= available_space){
				filtered_block_types.insertLast(city_block_types[i]);
			}
		}

		for(uint i = 0; i < filtered_block_types.size(); i++){
			sum += (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f));
		}

		float random = RangedRandomFloat(0.0f, sum);
		for(uint i = 0; i < filtered_block_types.size(); i++){
			if(random < (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f))){
				return filtered_block_types[i];
			}
			random -= (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f));
		}

		DisplayError("Ohno", "Random city block did not return anything.");
		return city_block_types[0];
	}else{
		for(uint i = 0; i < block_types.size(); i++){
			if(block_types[i].block_size_mult <= available_space){
				filtered_block_types.insertLast(block_types[i]);
			}
		}

		for(uint i = 0; i < filtered_block_types.size(); i++){
			sum += (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f));
		}

		float random = RangedRandomFloat(0.0f, sum);
		for(uint i = 0; i < filtered_block_types.size(); i++){
			if(random < (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f))){
				return filtered_block_types[i];
			}
			random -= (filtered_block_types[i].probability * (filtered_block_types[i].contains_enemy?enemy_spawn_mult:1.0f));
		}
	}

	DisplayError("Ohno", "Random block did not return anything.");
	return filtered_block_types[0];
}

void ForgetCharacter(int id){
	array<int> mos = GetObjectIDsType(_movement_object);
	for(uint i = 0; i < mos.size(); i++){
		MovementObject@ char = ReadCharacterID(mos[i]);
		char.Execute("situation.MovementObjectDeleted(" + id + ");");
	}
}

class Garbage{
	array<int> item_objects;
	array<int> movement_objects;
	int group = -1;
	Garbage(){}
}

class Block{
	array<int> obj_ids;
	int main_block_id = -1;
	vec3 position;
	array<SpawnObject@> objects_to_spawn;
	bool deleted = false;
	BlockType@ type;
	int on_grid = 0;
	int available_space;
	array<int> char_ids;
	int num_enabled = 0;
	array<vec3> orig_tints;

	Block(int _available_space){
		available_space = _available_space;
		@type = @GetRandomBlockType(available_space);
	}

	void Disable(){
		if(num_enabled > 0){
			num_enabled -= 1;
		}

		if(num_enabled == 0){
			if(orig_tints.size() == 0){
				GetOriginalTint();
			}
			for(uint i = 0; i < obj_ids.size(); i++){
				Object@ obj = ReadObjectFromID(obj_ids[i]);
				obj.SetTint(vec3(0.123f));
				/* obj.SetEnabled(false); */
			}
		}
	}

	void Enable(){
		num_enabled += 1;

		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			obj.SetTint(orig_tints[i]);
			/* obj.SetEnabled(true); */
		}
	}

	void GetOriginalTint(){
		if(distance_cull){
			for(uint i = 0; i < obj_ids.size(); i++){
				Object@ obj = ReadObjectFromID(obj_ids[i]);
				orig_tints.insertLast(obj.GetTint());
			}
		}
	}

	void Update(){
		if(deleted){return;}

		for(uint i = 0; i < char_ids.size(); i++){
			MovementObject@ char = ReadCharacterID(char_ids[i]);
			Object@ char_obj = ReadObjectFromID(char_ids[i]);
			if(distance(char.position, player_pos) < 75.0f){
				char_obj.SetEnabled(true);
			}else{
				char_obj.SetEnabled(false);
			}
		}
	}

	void SetSpawnPosition(vec3 _position){
		position = _position;

		position.x += (type.block_size_mult * block_size) - (block_size);
		position.y -= (type.block_size_mult * block_size);
		position.z += (type.block_size_mult * block_size) - (block_size);

		SpawnObject new_spawn(type, position, this);
		objects_to_spawn.insertLast(@new_spawn);
	}

	array<SpawnObject@> GetObjectsToSpawn(){
		return objects_to_spawn;
	}

	void Delete(){
		on_grid -= 1;

		if(on_grid == 0){
			AddToGarbage();
			world.RemoveBlock(this);
		}
	}

	void AddToGarbage(){
		deleted = true;
		Garbage garbage();
		array<int> groups;

		for(uint i = 0; i < obj_ids.size(); i++){
			if(!ObjectExists(obj_ids[i])){
				continue;
			}
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(obj_ids[i]);
				MovementObject@ player = ReadCharacterID(player_id);
				if(distance(char.position, player.position) < (world_size * block_size / 2.0f)){
					garbage.movement_objects.insertLast(obj_ids[i]);
					continue;
				}else{
					//MovementObject need to be queued or else the ItemObject they hold is going to reset position in the same update.
					QueueDeleteObjectID(obj_ids[i]);
					ForgetCharacter(obj_ids[i]);
					continue;
				}
			}else if(obj.GetType() == _item_object){
				MovementObject@ player = ReadCharacterID(player_id);
				ItemObject@ item = ReadItemID(obj_ids[i]);
				vec3 color = vec3(RangedRandomFloat(0.0f, 1.0f), RangedRandomFloat(0.0f, 1.0f), RangedRandomFloat(0.0f, 1.0f));
				if(distance(item.GetPhysicsPosition(), player.position) < (world_size * block_size / 2.0f)){
					garbage.item_objects.insertLast(obj_ids[i]);
					continue;
				}
			}else if(obj.GetType() == _group){
				//The first group is the only one to delete, the rest will be inside this group, so ignore those.
				if(garbage.group == -1){
					garbage.group = obj_ids[i];
				}
				continue;
			}
			DeleteObjectID(obj_ids[i]);
		}

		world.garbages.insertLast(garbage);
		obj_ids.resize(0);
	}

	void AddObjectID(int id){
		obj_ids.insertLast(id);
	}

	void MakeConnections(){
		int char_id = -1;
		int item_id = -1;
		array<int> pathpoints;
		array<int> nav_connections;

		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _path_point_object){
				pathpoints.insertLast(obj_ids[i]);
			}else if(obj.GetType() == _navmesh_connection_object){
				nav_connections.insertLast(obj_ids[i]);
			}else if(obj.GetType() == _item_object){
				item_id = obj_ids[i];
			}else if(obj.GetType() == _placeholder_object){
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Path")){
					PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
					placeholder_object.SetPreview("Data/Objects/IGF_Characters/pale_turner.xml");
					placeholder_object.SetSpecialType(kSpawn);

					string path = obj_params.GetString("Path");
					char_id = CreateObject(path);
					obj_ids.insertLast(char_id);
					Object@ char_obj = ReadObjectFromID(char_id);
					char_obj.SetTranslation(obj.GetTranslation());
					char_ids.insertLast(char_id);
					char_obj.SetEnabled(false);
				}
			}
		}

		if(char_id != -1){
			Object@ char = ReadObjectFromID(char_id);
			for(uint i = 0; i < pathpoints.size(); i++){
				//Connect the character to the first pathpoint.
				Object@ pathpoint = ReadObjectFromID(pathpoints[i]);
				if(i == 0){
					pathpoint.ConnectTo(char);
				}

				//Connect all the pathspoints together.
				if(i != (pathpoints.size() - 1)){
					Object@ next_pathpoint = ReadObjectFromID(pathpoints[i + 1]);
					pathpoint.ConnectTo(next_pathpoint);
				}
			}

			//Attach any item/weapon to the grip of the target character.
			if(item_id != -1){
				Object@ item = ReadObjectFromID(item_id);
				char.AttachItem(item, _at_grip, false);
			}
		}

		for(uint i = 0; i < nav_connections.size(); i++){
			Object@ first_nav_connection = ReadObjectFromID(nav_connections[i]);
			for(uint j = 0; j < nav_connections.size(); j++){
				Object@ second_nav_connection = ReadObjectFromID(nav_connections[j]);
				first_nav_connection.ConnectTo(second_nav_connection);
			}
		}
	}

	void DrawDebug(ivec2 location){
		DebugDrawText(vec3(position.x,  floor_height + block_size, position.z), "x" + location.x + ",y" + location.y + "\n" + available_space, 1.0f, true, _delete_on_update);
	}
}

class SpawnObject{
	BlockType@ block_type;
	vec3 position;
	Block@ owner;

	SpawnObject(BlockType @_block_type, vec3 _position, Block@ _owner){
		position = _position;
		@owner = @_owner;
		@block_type = @_block_type;
	}
}

class World{
	array<array<Block@>> blocks;
	array<SpawnObject@> objects_to_spawn;
	array<Garbage> garbages;

	World(){}

	void Reset(){
		for(uint i = 0; i < blocks.size(); i++){
			for(uint j = 0; j < blocks[i].size(); j++){
				if(blocks[i][j] !is null){
					//Delete all the existing blocks and their garbage.
					blocks[i][j].Delete();
				}
			}
		}

		//Delete all the garbage that's already collected.
		for(uint i = 0; i < garbages.size(); i++){
			if(garbages[i].group != -1){
				DeleteObjectID(garbages[i].group);
			}
		}

		blocks.resize(0);
		garbages.resize(0);
		objects_to_spawn.resize(0);
	}

	void RemoveBlock(Block@ block){
		for(uint i = 0; i < blocks.size(); i++){
			for(uint j = 0; j < blocks[i].size(); j++){
				if(blocks[i][j] is block){
					@blocks[i][j] = null;
				}
			}
		}
	}

	bool RemoveEmptyRowTop(){
		bool row_empty = true;

		for(int x = array_offset.x; x < array_offset.x + world_size; x++){
			int y = array_offset.y;
			ivec2 location = ivec2(x, y);
			if(blocks[location.y][location.x] !is null){
				row_empty = false;
				break;
			}
		}

		if(row_empty){
			blocks.removeAt(array_offset.y);

			if(array_offset.y > 0){
				array_offset.y -= 1;
			}

			RemoveEmptyRowTop();
		}

		return row_empty;
	}

	bool RemoveEmptyRowLeft(){
		bool row_empty = true;
		for(int y = array_offset.y; y < array_offset.y + world_size; y++){
			ivec2 location = ivec2(array_offset.x, y);
			if(blocks[location.y][location.x] !is null){
				row_empty = false;
				break;
			}
		}

		if(row_empty){
			for(uint y = 0; y < blocks.size(); y++){
				ivec2 location = ivec2(0, y);
				blocks[location.y].removeAt(location.x);
			}

			if(array_offset.x > 0){
				array_offset.x -= 1;
			}

			RemoveEmptyRowLeft();
		}

		return row_empty;
	}

	void MoveRight(){
		for(int y = array_offset.y; y < array_offset.y + world_size; y++){
			ivec2 location = ivec2(array_offset.x, y);
			if(blocks[location.y][location.x] !is null){
				blocks[location.y][location.x].Delete();
			}
		}

		if(!RemoveEmptyRowLeft()){
			array_offset.x += 1;
		}

		for(int y = array_offset.y; y < array_offset.y + world_size; y++){
			ivec2 location = ivec2(array_offset.x + world_size - 1, y);
			InsertBlock(location.x, location.y, 1, 1);
		}
	}

	void MoveLeft(){
		for(int y = array_offset.y; y < array_offset.y + world_size; y++){
			int x = array_offset.x + world_size - 1;
			ivec2 location = ivec2(x, y);
			if(blocks[location.y][location.x] !is null){
				blocks[location.y][location.x].Delete();
			}
		}

		//Make sure ALL the blocks are shifted to the right, not just on-grid ones.
		for(uint y = 0; y < blocks.size(); y++){
			blocks[y].insertAt(0, null);
		}

		for(int y = array_offset.y; y < array_offset.y + world_size; y++){
			ivec2 location = ivec2(array_offset.x, y);
			InsertBlock(location.x, location.y, -1, 1);
		}
	}

	void MoveUp(){
		//Remove the bottom row.
		for(int x = array_offset.x; x < array_offset.x + world_size; x++){
			int y = array_offset.y + world_size - 1;
			ivec2 location = ivec2(x, y);
			if(blocks[location.y][location.x] !is null){
				blocks[location.y][location.x].Delete();
			}
		}

		int row_size = world_size;
		if(blocks.size() > 0){
			row_size = blocks[0].size();
		}
		array<Block@> new_row(row_size);
		blocks.insertAt(0, new_row);

		for(int x = array_offset.x; x < array_offset.x + world_size; x++){
			ivec2 location = ivec2(x, array_offset.y);
			InsertBlock(location.x, location.y, 1, -1);
		}
	}

	void MoveDown(){
		//Remove the top row.
		for(int x = array_offset.x; x < array_offset.x + world_size; x++){
			int y = array_offset.y;
			ivec2 location = ivec2(x, y);
			if(blocks[location.y][location.x] !is null){
				blocks[location.y][location.x].Delete();
			}
		}

		if(!RemoveEmptyRowTop()){
			array_offset.y += 1;
		}

		for(int x = array_offset.x; x < array_offset.x + world_size; x++){
			ivec2 location = ivec2(x, array_offset.y + world_size - 1);
			InsertBlock(location.x, location.y, 1, 1);
		}
	}

	int GetAvailableSpace(int start_x, int start_y, int direction_x, int direction_y){
		int available_space_y = 1;
		int available_space_x = 1;

		while(true){
			//Check how many blocks of space we have available in the row.
			if(	int(blocks.size()) > start_y &&
				int(blocks[start_y].size()) > start_x + (available_space_x * direction_x) && start_x + (available_space_x * direction_x) > 0){
				if(blocks[start_y][start_x + (available_space_x * direction_x)] is null){
					available_space_x += 1;
				}else{
					break;
				}
			}else{
				if(available_space_x > 2 * world_size){
					break;
				}else{
					available_space_x += 1;
				}
			}
		}

		while(true){
			//Check how many rows we have available in the whole blocks array.
			if(int(blocks.size()) > start_y + (available_space_y * direction_y) && start_y + (available_space_y * direction_y) > 0 &&
				int(blocks[start_y + (available_space_y * direction_y)].size()) > start_x){

				if(blocks[start_y + (available_space_y * direction_y)][start_x] is null){
					available_space_y += 1;
				}else{
					break;
				}
			}else{
				if(available_space_y > 2 * world_size){
					break;
				}else{
					available_space_y += 1;
				}
			}
		}

		if(available_space_x < available_space_y){
			return available_space_x;
		}else{
			return available_space_y;
		}
	}

	void InsertBlock(int x, int y, int direction_x, int direction_y){
		//If the currect block is already occupied, then increment the on_grid value.
		if(int(blocks.size()) > y && int(blocks[y].size()) > x && blocks[y][x] !is null){
			blocks[y][x].on_grid += 1;
			return;
		}

		int available_space = GetAvailableSpace(x, y, direction_x, direction_y);

		Block new_block(available_space);

		ivec2 adjusted_grid_location  = ivec2(grid_position.x - array_offset.x - (world_size / 2) + x, grid_position.y - array_offset.y - (world_size / 2) + y);

		if(direction_x == -1){
			adjusted_grid_location.x -= new_block.type.block_size_mult - 1;
		}

		if(direction_y == -1){
			adjusted_grid_location.y -= new_block.type.block_size_mult - 1;
		}

		vec3 adjusted_grid_position = vec3(adjusted_grid_location.x, 0.0f, adjusted_grid_location.y) * (block_size * 2.0f);
		vec3 spawn_pos = starting_pos + adjusted_grid_position;
		new_block.SetSpawnPosition(spawn_pos);

		objects_to_spawn.insertAt((objects_to_spawn.size()), new_block.GetObjectsToSpawn());

		//Set the same block at all the positions it occupies.
		for(uint k = 0; k < uint(pow(new_block.type.block_size_mult, 2.0f)); k++){
			int x_offset = int(floor(k / new_block.type.block_size_mult));
			int y_offset = int(floor(k % new_block.type.block_size_mult));

			//Add a new row at the bottom if needed.
			while(int(blocks.size()) <= (y + y_offset)){
				//Use use world size as the standard size, but the whole block size after that.
				int row_size = world_size;
				if(blocks.size() > 0){
					row_size = blocks[blocks.size() - 1].size();
				}
				array<Block@> new_row(row_size);
				blocks.insertLast(new_row);
			}

			//Add a new row at the top if needed.
			while(y + (direction_y * y_offset) < 0){
				//Use use world size as the standard size, but the whole block size after that.
				int row_size = world_size;
				if(blocks.size() > 0){
					row_size = blocks[0].size();
				}
				array<Block@> new_row(row_size);
				blocks.insertAt(0, new_row);

				array_offset.y += 1;
				y += 1;
			}

			//Expand row to the right if needed.
			while(int(blocks[y + y_offset].size()) <= (x + x_offset)){
				for(uint j = 0; j < blocks.size(); j++){
					blocks[j].insertLast(null);
				}
			}

			//Expand the row to the left if needed.
			while(x + (direction_x * x_offset) < 0){
				for(uint j = 0; j < blocks.size(); j++){
					blocks[j].insertAt(0, null);
				}
				array_offset.x += 1;
				x += 1;
			}

			@blocks[y + (direction_y * y_offset)][x + (direction_x * x_offset)] = new_block;
		}
		new_block.on_grid += 1;
	}

	void CreateFloor(){
		Object@ player_obj = ReadObjectFromID(player_id);
		player_pos = vec3(floor(player_obj.GetTranslation().x),floor(player_obj.GetTranslation().y),floor(player_obj.GetTranslation().z));
		floor_height = player_pos.y - (block_size) - 1.0f;

		starting_pos = player_pos;
		starting_pos.x += block_size;
		starting_pos.z += block_size;
		starting_pos.y = floor_height;

		for(uint i = 0; i < uint(world_size); i++){
			for(uint j = 0; j < uint(world_size); j++){
				InsertBlock(j, i, 1, 1);
			}
		}
	}

	void BlockUpdate(){
		if(blocks.size() == 0 || resetting || !released_player){return;}

		if(int(blocks.size()) <= update_block_index){
			update_block_index = 0;
			return;
		}

		for(uint j = 0; j < blocks[update_block_index].size(); j++){
			if(blocks[update_block_index][j] !is null){
				blocks[update_block_index][j].Update();
			}
		}

		update_block_index += 1;
		if(update_block_index >= int(blocks.size())){
			update_block_index = 0;
		}
	}

	void CreateWall(){
		if(wall_created || game_mode == dynamic_world){return;}
		for(int j = 0; j < 4; j++){
			for(int i = 0; i < world_size; i++){
				int id = CreateObject(wall_path);
				Object@ wall_obj = ReadObjectFromID(id);
				wall_obj.SetSelectable(true);
				wall_obj.SetTranslatable(true);
				wall_obj.SetRotatable(true);

				wall_obj.SetScale(vec3(3.34f));
				vec3 spawn_position = starting_pos;
				spawn_position.x += (i * block_size * 2.0f) - ((world_size / 2) * block_size * 2.0f);
				spawn_position.z -= ((world_size / 2) * block_size * 2.0f) + block_size + 2.0f;
				if(j == 0 || j == 3){
					spawn_position.z *= -1;
				}

				if(j == 2 || j == 3){
					quaternion rotation(vec4(0, 1, 0, 90.0f * deg2rad));
					wall_obj.SetRotation(rotation);

					float old_x = spawn_position.x;
					spawn_position.x = spawn_position.z;
					spawn_position.z = old_x;
				}
				spawn_position.y = floor_height + (block_size * 2.0f);
				wall_obj.SetTranslation(spawn_position);
			}
		}
		wall_created = true;
	}

	block_creation_states block_creation_state = duplicate_block;
	int skip_counter = 0;

	void UpdateSpawning(){
		if(!preload_done){return;}

		if(objects_to_spawn.size() > 0){

			ShowBuildProgress();

			if(!released_player){
				MovementObject@ player = ReadCharacterID(player_id);
				Object@ spawn = ReadObjectFromID(player_id);
				player.velocity = vec3(0.0f);
				player.position = spawn.GetTranslation();
			}

			SpawnObject@ spawn_obj = objects_to_spawn[0];
			if(!spawn_obj.owner.deleted){
				//In the first update we create the object.
				if(block_creation_state == duplicate_block){
					// int id = DuplicateObject(spawn_obj.block_type.original);
					int id = CreateObject(spawn_obj.block_type.path);
					Object@ obj = ReadObjectFromID(id);
					obj.SetEnabled(true);
					obj.SetSelectable(true);
					obj.SetDeletable(true);
					obj.SetTranslatable(true);
					obj.SetName(spawn_obj.block_type.path);
					spawn_obj.owner.AddObjectID(id);
					AddNewBlockObjects(spawn_obj.owner, obj);

					block_creation_state = skip_state;
				}if(block_creation_state == skip_state){
					//Because prefabs take a while to load, we need to pause a couple of updates before translating.
					skip_counter += 1;
					if(skip_counter == 1){
						skip_counter = 0;
						block_creation_state = translate_block;
					}
				}if(block_creation_state == translate_block){
					//In the second update we translate the object to the correct spot.
					int id = spawn_obj.owner.obj_ids[0];
					Object@ obj = ReadObjectFromID(id);
					RotateBlock(id);
					if(IsGroupDerived(id)){
						TransposeNewBlock(spawn_obj.owner, spawn_obj.block_type.path);
					}else{
						obj.SetTranslation(spawn_obj.position + vec3(0.0f, obj.GetBoundingBox().y / 2.0f, 0.0f));
					}
					block_creation_state = make_connections;
				}if(block_creation_state == make_connections){
					spawn_obj.owner.MakeConnections();
					objects_to_spawn.removeAt(0);
					block_creation_state = duplicate_block;
				}
			}else{
				objects_to_spawn.removeAt(0);
				block_creation_state = duplicate_block;
			}
		}else if(!released_player){
			if(distance_cull){
				DisableAllBLocks();
				EnableCloseBlocks();
			}
			MovementObject@ player = ReadCharacterID(player_id);
			player.static_char = false;

			col.GetSweptSphereCollision(player.position + vec3(0.0, 25.0, 0.0), player.position - vec3(0.0, 25.0, 0.0), 1.0);
			vec3 ground_position = player.position;

			for(int i = 0; i < sphere_col.NumContacts(); i++){
				vec3 new_ground_position = sphere_col.GetContact(i).position;

				if(new_ground_position.y > ground_position.y){
					ground_position = new_ground_position;
				}
			}

			// DebugDrawLine(player.position + vec3(0.0, 25.0, 0.0), player.position - vec3(0.0, 25.0, 0.0), vec3(1.0), vec3(1.0, 0.0, 0.0), _persistent);
			// DebugDrawWireSphere(ground_position, 0.5, vec3(1.0), _persistent);
			player.position = ground_position + vec3(0.0, 0.5, 0.0);
			
			released_player = true;
			text_container.clear();
			blackout_amount = 1.0f;

			if(postKnocked == 1){
				MovementObject@ mo = ReadCharacterID(player_id);
				//level.SendMessage("displaytext \""+"debug: going limp");
				mo.Execute("Ragdoll(_RGDL_LIMP);");
				SetHDRWhitePoint(0.0f);
			}
		}
	}

	void DisableAllBLocks(){
		for(uint i = 0; i < blocks.size(); i++){
			for(uint j = 0; j < blocks[i].size(); j++){
				if(blocks[i][j] !is null){
					blocks[i][j].Disable();
				}
			}
		}
	}

	void EnableCloseBlocks(){
		for(int i = 0; i < cull_distance; i++){
			for(int j = 0; j < cull_distance; j++){
				ivec2 position = ivec2(i, j);
				ivec2 adjusted_grid_location  = ivec2((world_size / 2) - (cull_distance / 2) + position.x, (world_size / 2) - (cull_distance / 2) + position.y);
				adjusted_grid_location += array_offset;
				blocks[adjusted_grid_location.x][adjusted_grid_location.y].Enable();
			}
		}
	}

	void CullMoveUp(){
		for(int i = 0; i < 2; i++){
			int direction = (i == 0)?1:-1;
			for(int j = 0; j < cull_distance; j++){

				ivec2 position = ivec2(cull_grid_position.x - (cull_distance / 2) + j, cull_grid_position.y - ((cull_distance / 2) * direction));
				ivec2 adjusted_grid_location  = ivec2((world_size / 2) + position.x + array_offset.x, (world_size / 2) + position.y + array_offset.y);

				if(adjusted_grid_location.y >= int(blocks.size()) || adjusted_grid_location.y < 0 ||
					adjusted_grid_location.x >= int(blocks[adjusted_grid_location.y].size()) || adjusted_grid_location.x < 0){
						continue;
				}

				if(blocks[adjusted_grid_location.y][adjusted_grid_location.x] is null){return;}

				if(direction == 1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Enable();
				}else if(direction == -1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Disable();
				}
			}
		}
	}

	void CullMoveDown(){
		for(int i = 0; i < 2; i++){
			int direction = (i == 0)?1:-1;
			for(int j = 0; j < cull_distance; j++){

				ivec2 position = ivec2(cull_grid_position.x - (cull_distance / 2) + j, cull_grid_position.y - ((cull_distance / 2) * direction) - 1);
				ivec2 adjusted_grid_location  = ivec2((world_size / 2) + position.x + array_offset.x, (world_size / 2) + position.y + array_offset.y);

				if(adjusted_grid_location.y >= int(blocks.size()) || adjusted_grid_location.y < 0 ||
					adjusted_grid_location.x >= int(blocks[adjusted_grid_location.y].size()) || adjusted_grid_location.x < 0){
						continue;
				}

				if(blocks[adjusted_grid_location.y][adjusted_grid_location.x] is null){return;}

				if(direction == 1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Disable();
				}else if(direction == -1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Enable();
				}
			}
		}
	}

	void CullMoveLeft(){
		for(int i = 0; i < 2; i++){
			int direction = (i == 0)?1:-1;
			for(int j = 0; j < cull_distance; j++){

				ivec2 position = ivec2(cull_grid_position.x - ((cull_distance / 2) * direction), cull_grid_position.y - (cull_distance / 2) + j);
				ivec2 adjusted_grid_location  = ivec2((world_size / 2) + position.x + array_offset.x, (world_size / 2) + position.y + array_offset.y);

				if(adjusted_grid_location.y >= int(blocks.size()) || adjusted_grid_location.y < 0 ||
					adjusted_grid_location.x >= int(blocks[adjusted_grid_location.y].size()) || adjusted_grid_location.x < 0){
						continue;
				}

				if(blocks[adjusted_grid_location.y][adjusted_grid_location.x] is null){return;}

				if(direction == 1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Enable();
				}else if(direction == -1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Disable();
				}
			}
		}
	}

	void CullMoveRight(){
		for(int i = 0; i < 2; i++){
			int direction = (i == 0)?1:-1;
			for(int j = 0; j < cull_distance; j++){

				ivec2 position = ivec2(cull_grid_position.x - ((cull_distance / 2) * direction) - 1, cull_grid_position.y - (cull_distance / 2) + j);
				ivec2 adjusted_grid_location  = ivec2((world_size / 2) + position.x + array_offset.x, (world_size / 2) + position.y + array_offset.y);

				if(adjusted_grid_location.y >= int(blocks.size()) || adjusted_grid_location.y < 0 ||
					adjusted_grid_location.x >= int(blocks[adjusted_grid_location.y].size()) || adjusted_grid_location.x < 0){
						continue;
				}

				if(blocks[adjusted_grid_location.y][adjusted_grid_location.x] is null){return;}

				if(direction == 1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Disable();
				}else if(direction == -1){
					blocks[adjusted_grid_location.y][adjusted_grid_location.x].Enable();
				}
			}
		}
	}

	void AddNewBlockObjects(Block@ owner, Object@ obj){
		array<int> ids = obj.GetChildren();

		for(uint i = 0; i < ids.size(); i++){
			owner.AddObjectID(ids[i]);
			Object@ child_obj = ReadObjectFromID(ids[i]);
			if(child_obj.GetType() == _group){
				AddNewBlockObjects(owner, child_obj);
			}else if(child_obj.GetType() == _movement_object){
				MovementObject@ char = ReadCharacterID(ids[i]);
			}
		}
	}

	void RotateBlock(int id){
		Object@ obj = ReadObjectFromID(id);
		ScriptParams@ params = obj.GetScriptParams();
		if(obj.GetType() == _group){
			float x;
			float z;
			switch(rand() % 4){
				case 0:
					x = 1.0f;
					z = 0.0f;
					break;
				case 1:
					x = 0.0f;
					z = 1.0f;
					break;
				case 2:
					x = -1.0f;
					z = 0.0f;
					break;
				default:
					x = 0.0f;
					z = -1.0f;
					break;
			}
			float cur_rotation = atan2(x, z);
			quaternion rotation(vec4(0,1,0,cur_rotation));
			obj.SetTranslationRotationFast(obj.GetTranslation(), rotation);

		}else{
			DisplayError("Ohno!", "First block is not a group!");
		}
	}

	void TransposeNewBlock(Block@ owner, string path){
		vec3 offset = vec3(0.0f);
		vec3 position = owner.position;
		vec3 base_pos = vec3(0.0f);
		bool block_base_found = false;
		array<int> obj_ids = owner.obj_ids;

		//Find the main base.
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			ScriptParams@ params = obj.GetScriptParams();
			if(params.HasParam("BlockBase")){
				offset = offset - obj.GetTranslation();
				float over_limit = (obj.GetBoundingBox().y - 20.0f);
				base_pos = position + vec3(0.0f, ((over_limit / 2.0f) * owner.type.block_size_mult) + 10.0f, 0.0f);
				params.Remove("BlockBase");
				block_base_found = true;
				if(!released_player){
					/* obj.SetTint(vec3(RangedRandomFloat(0.0f, 5.0f))); */
				}

				break;
			}
		}

		if(!block_base_found){
			DisplayError("Ohno", "No blockbase found in " + path);
		}

		//Now set all children with the offset.
		array<EntityType> transpose_types = {_env_object, _movement_object, _item_object, _hotspot_object, _decal_object, _dynamic_light_object, _path_point_object, _placeholder_object, _navmesh_connection_object, _navmesh_hint_object};
		for(uint i = 0; i < obj_ids.size(); i++){
			Object@ obj = ReadObjectFromID(obj_ids[i]);
			if(obj.GetType() == _prefab){
				DisplayError("Error", "Block contains a prefab! " + path);
			}
			if(obj_ids[i] != player_id && transpose_types.find(obj.GetType()) != -1){
				vec3 start_pos = obj.GetTranslation();
				quaternion start_rot = obj.GetRotation();
				obj.SetTranslation(start_pos + base_pos + offset);
			}
			if(!add_detail_objects && obj.GetType() == _env_object){
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("DetailObjects")){
					QueueDeleteObjectID(obj_ids[i]);
				}
			}
		}
	}

	float garbage_timer = 1.0f;
	void RemoveGarbage(){
		garbage_timer -= time_step;
		if(garbage_timer < 0.0f){
			garbage_timer = 1.0f;
			for(uint i = 0; i < garbages.size(); i++){
				MovementObject@ player = ReadCharacterID(player_id);
				Garbage@ current_garbage = garbages[i];

				for(uint j = 0; j < current_garbage.item_objects.size(); j++){
					ItemObject@ item = ReadItemID(current_garbage.item_objects[j]);
					if(distance(item.GetPhysicsPosition(), player.position) > (world_size * block_size)){
						if(ObjectExists(current_garbage.item_objects[j])){
							DeleteObjectID(current_garbage.item_objects[j]);
							current_garbage.item_objects.removeAt(j);
						}
						j--;
					}
				}

				for(uint j = 0; j < current_garbage.movement_objects.size(); j++){
					MovementObject@ char = ReadCharacterID(current_garbage.movement_objects[j]);
					if(distance(char.position, player.position) > (world_size * block_size)){
						//MovementObject need to be queued or else the ItemObject they hold is going to reset position in the same update.
						if(ObjectExists(current_garbage.movement_objects[j])){
							QueueDeleteObjectID(current_garbage.movement_objects[j]);
							ForgetCharacter(current_garbage.movement_objects[j]);
						}
						current_garbage.movement_objects.removeAt(j);
						j--;
					}
				}

				if (current_garbage.movement_objects.size() == 0 && current_garbage.item_objects.size() == 0) {
					if(current_garbage.group != -1 && ObjectExists(current_garbage.group)){
						QueueDeleteObjectID(current_garbage.group);
					}
					garbages.removeAt(i);
					i--;
				}
			}
		}
	}

	void DrawDebug(){
		for(uint i = 0; i < blocks.size(); i++){
			for(uint j = 0; j < blocks[i].size(); j++){
				Block@ target_block = blocks[i][j];
				if(target_block !is null){
					target_block.DrawDebug(ivec2(j, i));
				}
			}
		}
	}
}

void Init(string p_level_name){
	LoadSettings();
	SetWeather();
	CreateUI();
	level_name = p_level_name;
	SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
	string jailed = saved_level.GetValue("jailed");
	if(jailed == "yes"){
		PlaySoundLoop("Data/Sounds/jail_bg.wav", 1.0f);
	}else{
		PlaySoundLoop("Data/Sounds/ambient.wav", 1.0f);
	}
}

void CreateIMGUIContainers(){
	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	imGUI.getMain().setZOrdering(-1);
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));
}

void SetWindowDimensions(int width, int height){
	imGUI.doScreenResize();
}

void ShowPreloadProgress(){
	IMText @load_progress = cast<IMText>(text_container.getContents());
	/* IMText @load_progress = cast<IMText>(text_container.findElement("Progress")); */
	load_progress.setText("           " + floor(preload_progress) + "%\nPreloading assets.");
}

void ShowBuildProgress(){
	IMText @load_progress = cast<IMText>(text_container.getContents());
	if(load_progress !is null){
		load_progress.setText(world.objects_to_spawn.size() + " blocks left.\nCreating world.");
	}
}

void SetWeather(){
	if(rain_sound_id != -1){
		StopSound(rain_sound_id);
		rain_sound_id = -1;
	}

	switch(weather_state){
		case foggy:
			SetWeatherFoggy();
			break;
		case rainy:
			SetWeatherRainy();
			break;
		case snowy:
			SetWeatherSnowy();
			break;
		case sunny:
			SetWeatherSunny();
			break;
		case evening:
			SetWeatherEvening();
			break;
		case creepy:
			SetWeatherCreepy();
			break;
		default:
			DisplayError("Error", "Unknown weather type : " + weather_state);
			break;
	}
}

void SetWeatherSnowy(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "#SNOW #MED");
	level_params.SetString("Custom Shader", "#SNOW_EVERYWHERE");
	PlaySoundLoop("Data/Sounds/ambient/amb_ice_wind_2.wav", 1.0f);
}

void SetWeatherRainy(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "#RAIN");
	level_params.SetString("Custom Shader", "#RAINY #ADD_MOON #TEST_CLOUDS_2");
	if(rand() % 2 == 0){
		PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
	}
	rain_sound_id = PlaySoundLoop("Data/Sounds/weather/rain.wav", 1.0f);
	PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
}

void SetWeatherFoggy(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "#BUGS");
	level_params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
	PlaySoundLoop("Data/Sounds/ambient/night_woods.wav", 1.0f);
}

void SetWeatherEvening(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "#FIREFLY");
	level_params.SetString("Custom Shader", "#MISTY");
	PlaySoundLoop("Data/Sounds/ambient/amb_forestquiet_1.wav", 1.0f);
}

void SetWeatherSunny(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "");
	level_params.SetString("Custom Shader", "#MISTY");
	PlaySoundLoop("Data/Sounds/ambient/meadow_morning_birds.wav", 0.025f);
}

void SetWeatherCreepy(){
	ScriptParams@ level_params = level.GetScriptParams();
	level_params.SetString("GPU Particle Field", "");
	level_params.SetString("Custom Shader", "#MISTY2 #SCROLL_VERY_SLOW");
	PlaySoundLoop("Data/Sounds/ambient/whisper.wav", 0.03f);
}

bool HasFocus(){
	return false;
}

void Reset(){
	ResetLevel();

	noSave = 0;
	Object @objz = ReadObjectFromID(player_id);
	ScriptParams@ params = objz.GetScriptParams();
	ReadPersistentInfo();
	//level.SendMessage("displaytext \""+"debug: search skill is at "+params.GetInt("Search")+"\"");
	if(params.GetInt("Winter") <= 0 ){
		if(summer_sound_id == -1){
			MovementObject@ mo = ReadCharacterID(player_id);
			mo.ReceiveMessage("summerBreath");
			//StopSound(winter_sound_id);
			winter_sound_id = -1;
			summer_sound_id = 0;
		}
		rogueUI("Sunny");
		spam = 3;
	}
	objz.UpdateScriptParams();

	resetting = true;
	array_offset = ivec2(0, 0);
	grid_position = ivec2(0, 0);
	cull_grid_position = ivec2(0, 0);
	update_block_index = 0;
	MovementObject@ player = ReadCharacterID(player_id);
	player.static_char = true;
}

bool created_world = false;

void BuildWorld(){
	if((post_init_done && preload_done && final_translation_done && !created_world)){
		CreateUI();
		world.Reset();
		world.CreateFloor();
		world.CreateWall();
		created_world = true;
		rebuild_world = false;
	}
}

void CreateUI(){
	@imGUI = CreateIMGUI();
	@text_container = IMContainer(2560, 1440);
	CreateIMGUIContainers();
	text_container.setAlignment(CACenter, CACenter);
	IMText@ load_progress = IMText("Progress");
	load_progress.setFont(default_font);
	load_progress.setText("Preloading assets.");
	IMImage@ background = IMImage("Textures/error.tga");
	background.setSize(vec2(2560, 1440));
	background.setColor(vec4(0.0f, 0.0f, 0.0f, 1.0f));
	/* text_container.addFloatingElement(background, "background", vec2(0.0f, 0.0f)); */
	text_container.setElement(load_progress);
}

void UpdateGlobalReflection(){
	if(updated_global_reflection || !released_player || resetting){
		return;
	}

	array<int> gl_ids = GetObjectIDsType(_reflection_capture_object);
	for(uint i = 0; i < gl_ids.size(); i++){
		Object@ gl_obj = ReadObjectFromID(gl_ids[i]);
		gl_obj.SetTranslation(gl_obj.GetTranslation() + vec3(RangedRandomFloat(-0.1f, 0.1f)));
		/* DebugDrawText(gl_obj.GetTranslation(), "GlobalReflection", 1.0f, true, _persistent); */
	}

	updated_global_reflection_counter += 1;
	if(weather_state == rainy){
		if(updated_global_reflection_counter > 0){
			updated_global_reflection = true;
		}
	}else{
		if(updated_global_reflection_counter > 100){
			updated_global_reflection = true;
		}
	}
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();

	if(player_id == -1){return;}

	MovementObject@ mo = ReadCharacterID(player_id);
	if(!token_iter.FindNextToken(msg)){
		return;
  	}

	string token = token_iter.GetToken(msg);
   	//level.SendMessage("displaytext \""+"msg is "+msg+" token is "+token);
	// bypass the token to get the cheevos
 	if(msg == "achievement_event player_blocked"){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(rand()% 100 < (params.GetInt("KungfuMastery")*5)){
			attacker_set_ko = mo.GetIntVar("attacked_by_id");
			if(attacker_set_ko != -1){
				PlaySound("Data/Sounds/proc.wav", mo.position);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/kungProc.png");
			}
		}
		//achievement_event player_threw_knife
		//ai_attacked
	}else if(msg == "achievement_event player_threw_knife"){
		rogueThrow();
	}else if(msg == "achievement_event player_attacked"){
		//level.SendMessage("displaytext \""+"player has attacked");
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(GetCharPrimaryWeapon(mo) == -1){
			if(rand()% 100 < (params.GetInt("KungfuMastery")*3)){
				//level.SendMessage("displaytext \""+"no weapon attack");
				attacker_set_on_fire = mo.GetIntVar("target_id");
				PlaySound("Data/Sounds/proc.wav", mo.position);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/kungProc2.png");
			}
		}else{
				  //
			if(rand()% 100 < (params.GetInt("KenjutsuMastery")*5)){
				//level.SendMessage("displaytext \""+"weapon attack");
				attacker_set_bleeding = mo.GetIntVar("target_id");
				PlaySound("Data/Sounds/proc.wav", mo.position);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("displayhud /Data/UI/Icons/kenjuProc.png");
			}
				  //if attacking with a relic check if its a banshee
				  if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "banshee"){
						Object @enemyObj = ReadObjectFromID(mo.GetIntVar("target_id"));
						MovementObject@ enemy_mo = ReadCharacterID(mo.GetIntVar("target_id"));
						if(rand()% 100 < 10){
							  //tell the enemy to gtfo
							  PlaySound("Data/Sounds/bansheeProc.wav", mo.position);
							  enemyObj.QueueScriptMessage("gtfo"); 
							  level.SendMessage("clearhud");
							  level.SendMessage("uicue");
							  level.SendMessage("displayhud /Data/UI/Icons/bansheeProc.png");
							  mat4 head_transform = enemy_mo.rigged_object().GetAvgIKChainTransform("head");
							  uint32 idz = MakeParticle("Data/Particles/Undergrowth/relic_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+enemy_mo.velocity),vec3(1.0));           
						}
				  }     
		}
	}else if(msg == "achievement_event ai_attacked"){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		//check if it is an assassin
			int foo =  mo.GetIntVar("attacked_by_id");
			//
			//level.SendMessage("displaytext \""+"attacker id is "+foo);
		MovementObject@ enemy_mo = ReadCharacterID(foo);
			Object @enemyObj = ReadObjectFromID(enemy_mo.GetID());
			ScriptParams@ enemy_params = enemyObj.GetScriptParams();
		if(rand()% 100 < 25){
			if(enemy_params.HasParam("Poison")){
				if(enemy_params.GetInt("Poison") == 1){
					if(params.GetString("trinketType") == "Venom" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						level.SendMessage("displaytext \""+"Your trinket protected you against the assassin's poison");
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
								createTrinketSparks();
					}else{
									if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "purity"){
										  PlaySound("Data/Sounds/purityProc.wav", mo.position);
										  level.SendMessage("clearhud");
										  level.SendMessage("uicue");
										  level.SendMessage("displayhud /Data/UI/Icons/purityProc.png");
										  createTrinketSparks();
									}else{
							 level.SendMessage("displaytext \""+"The assassin has poisoned you!!");
							 mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
								 uint32 idz = MakeParticle("Data/Particles/Undergrowth/poison_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
								 PlaySound("Data/Sounds/poisonStrike.wav", mo.position);
										 if(params.GetInt("Poison")<= 0){
								 params.SetInt("Poison", 5);
										 }else{
								 params.SetInt("Poison", (params.GetInt("Poison")+5));
							 }
									}
					}	
				}
			}
			if(enemy_params.HasParam("Thief")){
				if(enemy_params.GetInt("Thief") == 1){
							//level.SendMessage("displaytext \""+"active thief");
					if(params.GetInt("Gold") > 0 && (rand()% 100 < 50)){
						params.SetInt("Gold", params.GetInt("Gold") -1);
						PlaySound("Data/Sounds/stealing.wav", mo.position);
						level.SendMessage("displaytext \""+"The Cut Purse has stolen GOLD from you!!!");
						PlaySound("Data/Sounds/singleCoin.wav", mo.position);
						enemy_params.SetInt("Gold", enemy_params.GetInt("Gold")+1);
						mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
							uint32 idz = MakeParticle("Data/Particles/Undergrowth/steal_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
								enemyObj.QueueScriptMessage("gtfo"); 
							}else if(params.GetInt("xp") > 0 && (rand()% 100 < 50)){
						params.SetInt("xp", params.GetInt("xp") -1);
						PlaySound("Data/Sounds/stealing.wav", mo.position);
						level.SendMessage("displaytext \""+"The Cut Purse has stolen SCROLLS from you!!!");
						PlaySound("Data/Sounds/scroll.wav", mo.position);
						enemy_params.SetInt("Scroll", enemy_params.GetInt("Scroll")+1);
						mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
							uint32 idz = MakeParticle("Data/Particles/Undergrowth/steal_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
					   	enemyObj.QueueScriptMessage("gtfo"); 
							}else if(params.GetInt("lockPick") > 0 && (rand()% 100 < 50)){
						params.SetInt("lockPick", params.GetInt("lockPick") -1);
						PlaySound("Data/Sounds/stealing.wav", mo.position);
						level.SendMessage("displaytext \""+"The Cut Purse has stolen LOCKPICKS from you!!!");
						PlaySound("Data/Sounds/lockPickPicked.wav", mo.position);
						enemy_params.SetInt("PickLocks", enemy_params.GetInt("PickLocks")+1);
						mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
							uint32 idz = MakeParticle("Data/Particles/Undergrowth/steal_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
								enemyObj.QueueScriptMessage("gtfo"); 
							} 
				}
			}
		}
	}else if(msg == "achievement_event choke_hold_kill"){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		params.SetInt("Assassination", (params.GetInt("Assassination")+1));
		// chances to add the sweet oooh sweet sounds of someone choking on their own blood!!
		if(rand()% 100 < 30){
			PlaySound("Data/Sounds/neckSlash"+((rand()% 4)+1)+".wav", mo.position);
		}
		//NinjitsuMastery
		attacker_set_bleeding = mo.GetIntVar("target_id");
		if(rand()% 100 < (params.GetInt("NinjitsuMastery")*20)){
			PlaySound("Data/Sounds/proc.wav", mo.position);
			PlaySound("Data/Sounds/cashish.wav", mo.position);
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("displayhud /Data/UI/Icons/ninjaProc.png");
			if(params.GetString("trinketType") == "Fortune" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						params.SetInt("Gold", (params.GetInt("Gold")+1));
				PlaySound("Data/Sounds/trinketProc.wav", mo.position);
						createTrinketSparks();
			}else{
				params.SetInt("Gold", (params.GetInt("Gold")+2));	
			}
		}
		obj.UpdateScriptParams();
		assBelt();
	}else if(msg.findFirst("character_died")== 0 || msg.findFirst("character_knocked_out")== 0){
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		//detected a npc who died
		if(msg.findFirst("character_died")== 0 ){
			msg.erase(0, 15);
		}else{
			msg.erase(0, 22);
		}
		MovementObject@ dead_mo = ReadCharacterID(parseInt(msg));
		Object @enemyObj = ReadObjectFromID(dead_mo.GetID());
		ScriptParams@ paramzx = enemyObj.GetScriptParams();
		//21 is the gettype of creature object
		//level.SendMessage("displaytext \""+" debug: type of object creature is "+enemyObj.GetType());
		if(params.GetInt("throwFlag") > 0){
			//level.SendMessage("displaytext \""+"debug: death by thorwen object detected"+"\"");
	   		//shuriken jutsu
			params.SetInt("throwKills", params.GetInt("throwKills")+1);
				  if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) != "assassin"){
			   params.SetInt("huntFactor", params.GetInt("huntFactor")+1);
				  }
			obj.UpdateScriptParams();
			shuriBelt();
		}else{
			if(dead_mo.GetIntVar("attacked_by_id") == player_id){
					if(GetCharPrimaryWeapon(mo) != -1){
					//level.SendMessage("displaytext \""+"debug: death by  weapon "+"\"");
					params.SetInt("weaponKills", params.GetInt("weaponKills")+1);
							  if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) != "assassin"){
						   params.SetInt("huntFactor", params.GetInt("huntFactor")+1);
							  }
					obj.UpdateScriptParams();
					kenjuBelt();
							  //check if you have a relic
							  if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "bloodThirst"){
									//tell the enemy to gtfo
									PlaySound("Data/Sounds/bloodThristProc.wav");
									level.SendMessage("clearhud");
									level.SendMessage("uicue");
									level.SendMessage("displayhud /Data/UI/Icons/bloodThirstProc.png");
									mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
									uint32 idz = MakeParticle("Data/Particles/Undergrowth/relic_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));           
									params.SetInt("Food", params.GetInt("Food")+5);
									params.SetInt("Water", params.GetInt("Water")+5);
									if(params.GetInt("Water")> 100){
										  params.SetInt("Water", 100);
									}
									if(params.GetInt("Food") > 100){
										  params.SetInt("Food", 100);
									}
									obj.UpdateScriptParams();
							  }else if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "holyAvenger"){
									createBuffSparks();
									params.SetInt("Bless", params.GetInt("Bless")+5);
									if(params.GetInt("Bless") > 100){
										  params.SetInt("Bless", 100);
									}
									rogueUI("Blessed");
									PlaySound("Data/Sounds/Gong.wav", mo.position);
							  }
				}else{
					//level.SendMessage("displaytext \""+"debug: death by kung fu"+"\"");
					params.SetInt("handKills", params.GetInt("handKills")+1);
					obj.UpdateScriptParams();
					kungBelt();
				}
		
			}
		}
		// check the kill count for quests
		if(dead_mo.GetIntVar("attacked_by_id") == player_id || dead_mo.GetIntVar("attacked_by_id") == GetBuddyID()){
			// check for quests
			if(paramzx.HasParam("Name")){
				//level.SendMessage("displaytext \""+"debug: name of npc is "+paramzx.GetString("Name")+"\"");
				if(paramzx.GetString("Name") == "general" && params.GetInt("questType") == 10 && params.GetInt("questStatus") == 0){
					params.SetInt("questStatus", 1);
					PlaySound("Data/Sounds/quest2riff.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("questReset");
					level.SendMessage("displayhud /Data/UI/Icons/quest10completed.png");
				}
			}
			//check for kill nbr
			if(dead_mo.GetIntVar("species") == 3){
				//level.SendMessage("displaytext \""+"debug: rat killed"+"\"");
				if(params.GetInt("questType") == 4){
					if(params.GetInt("questKills")>= 4 && params.GetInt("questStatus") == 0){
						//at 5 kills the quest is gtg
						params.SetInt("questStatus", 1);
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("questReset");
						level.SendMessage("displayhud /Data/UI/Icons/killQuestCompleted.png");
					}else{
						params.SetInt("questKills", params.GetInt("questKills")+1);
					}
				}
			}else if(dead_mo.GetIntVar("species") == 4){
				//level.SendMessage("displaytext \""+"debug: cat killed"+"\"");
				if(params.GetInt("questType") == 5){
					if(params.GetInt("questKills")>= 4 && params.GetInt("questStatus") == 0){
						//at 5 kills the quest is gtg
						params.SetInt("questStatus", 1);
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("questReset");
						level.SendMessage("displayhud /Data/UI/Icons/killQuestCompleted.png");
					}else{
						params.SetInt("questKills", params.GetInt("questKills")+1);
					}
				}
			}else if(dead_mo.GetIntVar("species") == 1){
				//level.SendMessage("displaytext \""+"debug: wolf killed"+"\"");
				if(params.GetInt("questType") == 7 && params.GetInt("questStatus") == 0){
					params.SetInt("questStatus", 1);
					PlaySound("Data/Sounds/quest2riff.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("questReset");
					level.SendMessage("displayhud /Data/UI/Icons/killQuestCompleted.png");
				}
			}else if(dead_mo.GetIntVar("species") == 2){
				//level.SendMessage("displaytext \""+"debug: dog killed"+"\"");
				if(params.GetInt("questType") == 6){
					if(params.GetInt("questKills")>= 4 && params.GetInt("questStatus") == 0){
						//at 5 kills the quest is gtg
						params.SetInt("questStatus", 1);
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("questReset");
						level.SendMessage("displayhud /Data/UI/Icons/killQuestCompleted.png");
					}else{
						params.SetInt("questKills", params.GetInt("questKills")+1);
					}
				}
			}else if(dead_mo.GetIntVar("species") == 0){
				//level.SendMessage("displaytext \""+"debug: bunny killed"+"\"");
			}
			if(paramzx.HasParam("Thief")){
					int stuffBack = 0;
					if(dead_mo.GetIntVar("attacked_by_id") == player_id){
						if(distance(dead_mo.position, mo.position) < 10.0){
							if(paramzx.GetInt("Gold") > 0 ){
									params.SetInt("Gold", params.GetInt("Gold")+paramzx.GetInt("Gold"));  
									stuffBack = 1;
							}
							if(paramzx.GetInt("Scroll") > 0 ){
									params.SetInt("xp", params.GetInt("xp")+paramzx.GetInt("Scroll"));  
									stuffBack = 1;
							}
							if(paramzx.GetInt("PickLocks") > 0 ){
									params.SetInt("lockPick", params.GetInt("lockPick")+paramzx.GetInt("PickLocks"));  
									stuffBack = 1;
							}
							if(stuffBack > 0){
									level.SendMessage("displaytext \""+"You got your stuff back from that scoundrel.");
									PlaySound("Data/Sounds/cueSound.wav", mo.position);
							}
						}
					}
			}
			obj.UpdateScriptParams();
	}
	// check for the trench mission and doesnt care if killed by player or not
	if(paramzx.HasParam("Name")){
		if(paramzx.GetString("Name") == "trenchBuddy" && params.GetInt("questType") == 11 && params.GetInt("questStatus") == 0){
			if(distance(dead_mo.position, mo.position) < 5.0){
				params.SetInt("questStatus", -1);
				PlaySound("Data/Sounds/researchFail.wav", mo.position);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				level.SendMessage("questReset");
				level.SendMessage("displayhud /Data/UI/Icons/quest11failed.png");
			}
		}else if(paramzx.GetString("Name") == "diplomat" && params.GetInt("questType") == 12 && params.GetInt("questStatus") == 0){
			params.SetInt("questStatus", -1);
			PlaySound("Data/Sounds/researchFail.wav", mo.position);
			level.SendMessage("clearhud");
			level.SendMessage("uicue");
			level.SendMessage("questReset");
			level.SendMessage("displayhud /Data/UI/Icons/quest12failed.png");
		}else if(paramzx.GetString("Name") == "runnerBuddy" && params.GetInt("Buddy") > 0){
				params.SetInt("Buddy", 0);
				level.SendMessage("displaytext \""+"You have lost your companion!!");
				PlaySound("Data/Sounds/researchFail.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					obj.UpdateScriptParams();
			}else if(paramzx.GetString("Name") == "Ronin"){
				if(GetCharPrimaryWeapon(mo) == -1){
					params.SetInt("roninKill", params.GetInt("roninKill")+1);
					// if not chasing a relic will reset the sub quest
					if(params.GetInt("graveDistance") < 0){
						params.SetInt("roninGrave", 1);
						//params.SetInt("graveDistance", -1);
					}
					obj.UpdateScriptParams();
					level.SendMessage("displaytext \""+"You defeated a Ronin in single combat. His legacy has ended. "+(13-params.GetInt("roninKill"))+" remain.");
				}else{
					level.SendMessage("displaytext \""+"You must defeat the Ronin honorably (not armed) or his legacy will continue.");
					PlaySound("Data/Sounds/meh.wav", mo.position);
				}
			}else if(paramzx.GetString("Name") == "Attacker" && params.GetInt("questType") == 11 && params.GetInt("questStatus") == 0){
			//check for the other attackers
			int dudeKilled = 0;
			int num = GetNumCharacters();
				for(int i=0; i<num; ++i){
					MovementObject@ char = ReadCharacter(i);
				Object @trenchObj = ReadObjectFromID(char.GetID());
				ScriptParams@ paramzzz = trenchObj.GetScriptParams();
				if(paramzzz.HasParam("Name")){
						if(char.GetIntVar("knocked_out") != _awake && paramzzz.GetString("Name") == "Attacker" ){
							dudeKilled ++;
						}
				}
				}
			if(dudeKilled >= 4){
					//quest successful
					params.SetInt("questStatus", 1);
					PlaySound("Data/Sounds/quest2riff.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("questReset");
					level.SendMessage("displayhud /Data/UI/Icons/quest11completed.png");
				}
			}
		}
		// check for player deaths in order to stats and quests adjust
		if(parseInt(msg) == player_id){
			noSave = 1;
			params.SetInt("trinketChances", 0);
			params.SetInt("fortChances", 0);
			params.SetInt("knockedOut", 1);
			// if on the salvage quest reset the containers
			if(params.GetInt("questType") == 13){
				params.SetInt("questKills", 0);
			}
			//
			if(dead_mo.GetIntVar("attacked_by_id") != -1){
				Object @killerObj = ReadObjectFromID(dead_mo.GetIntVar("attacked_by_id"));
				ScriptParams@ killerParams = killerObj.GetScriptParams();
				if(params.GetInt("questType") == 8 && params.GetInt("questStatus") == 0){
					params.SetInt("questStatus", -1);
				}else if(params.GetInt("questType") == 10){
					//paramzx
					if(killerParams.HasParam("Name")){
						if(params.GetInt("questKills") == 99 || killerParams.GetString("Name") == "general" || killerParams.GetString("Name") == "bodyguard" ){
							params.SetInt("questStatus", -1);
							//params.SetInt("questStatus", 1);
							PlaySound("Data/Sounds/researchFail.wav", mo.position);
							level.SendMessage("clearhud");
							level.SendMessage("uicue");
							level.SendMessage("questReset");
							level.SendMessage("displayhud /Data/UI/Icons/quest10Failed.png");
						}
					}
				}
						//regarldess of quests if knocked by hunters you got o jail
						if(killerParams.HasParam("Hunter")){
							if(killerParams.GetInt("Hunter") == 1){
								SavedLevel @saved_level = save_file.GetSavedLevel("undergrowth_redux");
								saved_level.SetValue("jailed", "yes");
								save_file.WriteInPlace();
								PlaySound("Data/Sounds/researchFail.wav", mo.position);
					   			level.SendMessage("clearhud");
								level.SendMessage("uicue");
								level.SendMessage("questReset");
								level.SendMessage("displayhud /Data/UI/Icons/captured.png");
							}
						}
					if(params.GetInt("questType") == 13){
						params.SetInt("questKills", 0);
			   		}
			}
			obj.UpdateScriptParams();
			crashSave();
			WritePersistentInfo();
			SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
			saved_level.SetValue("knockedOut", "knocked");
				save_file.WriteInPlace();
		}
		obj.UpdateScriptParams();
	}		
		// non combat tokens
		if(token == "reset"){
			Reset();
		}else if(token == "nom"){
			PlaySound("Data/Sounds/eating.wav", mo.position);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			if(params.GetString("trinketType") == "Plenty" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
				params.SetInt("Food", (params.GetInt("Food")+35));
				PlaySound("Data/Sounds/trinketProc.wav", mo.position);
					createTrinketSparks();
			}else{
				params.SetInt("Food", (params.GetInt("Food")+25));
			}
			// prevent excessive fatness 
			if(params.GetInt("Food") > 150){
				params.SetInt("Food", 150);
			}
			obj.UpdateScriptParams();
			spam = 0;
			rogueUI("Food");
			//
		}else if(token == "slurp"){
			PlaySound("Data/Sounds/drinking.wav", mo.position);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			// augment food level
			if(params.GetInt("Water")< 100){
				if(params.GetString("trinketType") == "Plenty" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
					params.SetInt("water", (params.GetInt("Water")+35));
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
							createTrinketSparks();
				}else{
					params.SetInt("Water", (params.GetInt("Water")+25));
				}
					if(params.GetInt("Water")> 100){
							params.SetInt("Water", 100);
					}
			}else{
				//level.SendMessage("displaytext \""+"You are not thristy anymore."+"\"");
				if(spam <= 0){
					//DisplayError("wtf", "token has worked");
					PlaySound("Data/Sounds/burp.wav", mo.position);
					spam = 3;
				}
			}
			obj.UpdateScriptParams();
			spam = 0;
			rogueUI("Water");
		}else if(token == "badslurp"){
			//mo.SetAnimation("Data/Animations/r_wallpress.anm",20.0f);
			//DisplayError("wtf", "token has worked");
			PlaySound("Data/Sounds/drinking.wav", mo.position);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			// augment food level
			if(params.GetInt("Water")< 100){
				if(params.GetString("trinketType") == "Plenty" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
					params.SetInt("Water", (params.GetInt("Water")+35));
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
							createTrinketSparks();
				}else{
					params.SetInt("Water", (params.GetInt("Water")+25));
				}
				if(rand() % 4 == 1){
					if(params.GetString("trinketType") == "Purity" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						level.SendMessage("displaytext \""+"Your trinket protected you against the disease!!");
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
								createTrinketSparks();
					}else{
									if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "purity"){
										  PlaySound("Data/Sounds/purityProc.wav", mo.position);
										  level.SendMessage("clearhud");
										  level.SendMessage("uicue");
										  level.SendMessage("displayhud /Data/UI/Icons/purityProc.png");
										  createTrinketSparks();
									}else{
							  params.SetInt("Sick", (params.GetInt("Sick")+25));
							  PlaySound("Data/Sounds/nay.wav", mo.position);
							  rogueUI("Ill");
									}
					}
				}else{
					spam = 0;
					rogueUI("Water");
				}
				if(params.GetInt("Water")> 100){
							params.SetInt("Water", 100);
					}
			}else{
				PlaySound("Data/Sounds/burp.wav", mo.position);
				spam = 0;
				rogueUI("Water");
			}
			obj.UpdateScriptParams();
		}else if(token == "saveGame"){
			WritePersistentInfo();
		}else if(token == "rackle"){
				  PlaySound("Data/Sounds/searching.wav", mo.position);
				  createGear();
				  level.SendMessage("clearhud");
				  level.SendMessage("uicue");
				  level.SendMessage("displayhud /Data/UI/Icons/weaponLoot.png");
			}else if(token == "rumble"){
			PlaySound("Data/Sounds/searching.wav", mo.position);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			//mo.ReceiveMessage("woot");
			int dicez = rand() % 100;
			//level.SendMessage("displaytext \""+" debug: searching skill is at "+params.GetInt("Search")+" and dice roll is at "+dicez);
			//dicez < params.GetInt("Search")
			if(params.GetInt("questType") == 13){
				if(params.GetInt("questStatus") == 0){
					params.SetInt("questKills", params.GetInt("questKills")+1);
					if(params.GetInt("questKills") >= 10){
						PlaySound("Data/Sounds/quest2riff.wav", mo.position);
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/quest13Completed.png");
						params.SetInt("questStatus", 1);
					}
				}
			}
			if(params.GetInt("questType") == 14){
				if(params.GetInt("questStatus") == 0){
					PlaySound("Data/Sounds/quest2riff.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displayhud /Data/UI/Icons/quest14Completed.png");
					params.SetInt("questStatus", 1);	
					bombTimer = (rand() % 100)+20;
				}
			}
			if(skillCheck("Search", 0)){
				//check for the supply quests
				if(params.GetInt("Sick") > 0 && (rand() % 100 < 25)){
					params.SetInt("Sick", 1);
					PlaySound("Data/Sounds/yay.wav", mo.position);
					level.SendMessage("displaytext \""+"You found medicine and your illness is cured.");
				}else if(params.GetInt("Poison") > 0 && (rand() % 100 < 25)){
					params.SetInt("Poison", 0);
					rogueUI("Poison");
			   	 		PlaySound("Data/Sounds/yay.wav", mo.position);
			   	 		level.SendMessage("displaytext \""+"You found an antidote and you are not poisoned anymore.");
				}else if(params.GetInt("Fatigue") > 50 && (rand() % 100 < 25)){
					rogueUI("ZZZ");
					params.SetInt("Fatigue", 0);
							PlaySound("Data/Sounds/yay.wav", mo.position);
				}else if(params.GetInt("Food") < 75 && (rand() % 100 < 25)){	
					if(params.GetString("trinketType") == "Plenty" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						params.SetInt("Food", (params.GetInt("Food")+35));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
								createTrinketSparks();
					}else{
						rogueUI("Food");
						params.SetInt("Food", params.GetInt("Food")+25);
								PlaySound("Data/Sounds/eating.wav", mo.position);
						level.SendMessage("displayhud /Data/UI/Icons/foodLoot.png");
					}
				}else if(params.GetInt("Water") < 75 && (rand() % 100 < 25)){
					if(params.GetString("trinketType") == "Plenty" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						params.SetInt("Food", (params.GetInt("Food")+25));
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
								createTrinketSparks();
					}else{
						params.SetInt("Water", params.GetInt("Water")+35);
						rogueUI("Water");
								PlaySound("Data/Sounds/burp.wav", mo.position);
						level.SendMessage("displayhud /Data/UI/Icons/waterLoot.png");
					}
				}else{
							int dice = rand() % 5;
					if(dice == 0){
						PlaySound("Data/Sounds/cashish.wav", mo.position);
						if(params.GetString("trinketType") == "Fortune" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
							params.SetInt("Gold", (params.GetInt("Gold")+2));
							PlaySound("Data/Sounds/trinketProc.wav", mo.position);
										createTrinketSparks();
						}else{
							params.SetInt("Gold", (params.GetInt("Gold")+1));
						}
						rogueUI("Gold");
					}else if(dice == 1){
						//skill cap (sorta, the task master can still issue scrolls)
						if((params.GetInt("Search")+params.GetInt("Faith")+params.GetInt("Tracking")+params.GetInt("Steal") < 200)&& (params.GetInt("xp") < 10)){
							if(params.GetString("trinketType") == "Wisdom" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
								params.SetInt("xp", (params.GetInt("xp")+2));
								PlaySound("Data/Sounds/trinketProc.wav", mo.position);
							   			createTrinketSparks();
							}else{
								params.SetInt("xp", (params.GetInt("xp")+1));
							}
										  if(params.GetInt("xp") > 10){
												params.SetInt("xp", 10);
										  }
							rogueUI("Scroll");
							PlaySound("Data/Sounds/scroll.wav", mo.position);
						}else{
							PlaySound("Data/Sounds/cashish.wav", mo.position);
							if(params.GetString("trinketType") == "Fortune" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
								params.SetInt("Gold", (params.GetInt("Gold")+2));
								PlaySound("Data/Sounds/trinketProc.wav", mo.position);
											createTrinketSparks();
							}else{
								params.SetInt("Gold", (params.GetInt("Gold")+1));
							}
							rogueUI("Gold");
						}
					}else if(dice == 2){
						if(params.GetInt("lockPick") < 10){
							params.SetInt("lockPick", (params.GetInt("lockPick")+1));
						}
						rogueUI("lockPick");
						PlaySound("Data/Sounds/lockPickPicked.wav", mo.position);
					}else if(dice == 3){
								params.SetInt("map", (params.GetInt("map")+((rand() % 5)+1)));
								PlaySound("Data/Sounds/mapPicked.wav", mo.position);
								level.SendMessage("clearhud");
								level.SendMessage("uicue");
								level.SendMessage("displayhud /Data/UI/Icons/mapHUD.png");
							}else if(dice == 4){
						level.SendMessage("displayhud /Data/UI/Icons/weaponLoot.png");
						createGear();
						level.SendMessage("clearhud");
						level.SendMessage("uicue");
						level.SendMessage("displayhud /Data/UI/Icons/weaponLoot.png");
					}
				} 
				obj.UpdateScriptParams();
			}else{
				rogueUI("noLoot");
				PlaySound("Data/Sounds/noLoot.wav", mo.position);
			}
		}else if(token == "mumble"){
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			if(skillCheck("Faith", 0)){
				createBuffSparks();
				params.SetInt("Bless", 100);
				rogueUI("Blessed");
				PlaySound("Data/Sounds/Gong.wav", mo.position);
				obj.UpdateScriptParams();
			}else{
				rogueUI("noPray");
				PlaySound("Data/Sounds/meh.wav", mo.position);
			}
		}else if(token == "uicue"){
			rogueUI_timer = 15.0f;
			spam = 5;
		}else if(token == "throwFlagSet"){
			throwFlag_timer = 2.0f;
		}else if(token == "questLoot"){
			questLoot_timer = 2.0f;
		}else if(token == "quest"){
			rogueUI_timer = 4.0f;
			//rogueUI("questReceived");
			//Find the enemy spawn placeholder and put the new enemy at that point.
				array<int> @object_ids = GetObjectIDs();
				int num_objects = object_ids.length();
			int questAssigned = -1;
				for(int i=0; i<num_objects; ++i){
					Object @obj = ReadObjectFromID(object_ids[i]);
					ScriptParams@ params = obj.GetScriptParams();
					if(params.HasParam("Name")){
						string name_str = params.GetString("Name");
						if("taskMasterSpot" == name_str){
							//params.SetInt("Quested", 1);
						questAssigned = params.GetInt("questID");
						//level.SendMessage("displaytext \""+"debug: quest assigned is "+questAssigned);
						//obj.UpdateScriptParams();
								break;
						}
					}
				}
			//then set the quest param for the player too
			Object @obj2 = ReadObjectFromID(player_id);
			ScriptParams@ paramzz = obj2.GetScriptParams();
			if(questAssigned  != -1){
				if(questAssigned == 1 || questAssigned == 3){
					//messagesd quest are successful from the get  go all you need to do is find a non used taskmaster						  
					paramzz.SetInt("questStatus", 1);
				}else if(questAssigned == 2){
					BlockTypeUpdate("Data/Objects/block_quest_2.xml", 5.0f);
					paramzz.SetInt("questStatus", 0);
				}else if(questAssigned == 8){
					BlockTypeUpdate("Data/Objects/block_quest_8.xml", 5.0f);
					paramzz.SetInt("questStatus", 0);
				}else if(questAssigned == 9){
					BlockTypeUpdate("Data/Objects/block_quest_9.xml", 5.0f);
					paramzz.SetInt("questStatus", 0);
				}else if(questAssigned == 10){
					BlockTypeUpdate("Data/Objects/block_quest_10.xml", 5.0f);
					paramzz.SetInt("questStatus", 0);
				}else if(questAssigned == 11){
					BlockTypeUpdate("Data/Objects/block_quest_11.xml", 5.0f);
					paramzz.SetInt("questStatus", 0);
				}else if(questAssigned == 12){
					spawnDiplomat();
					paramzz.SetInt("questStatus", 0);
				}else{
					paramzz.SetInt("questStatus", 0);
				}
				//
				paramzz.SetInt("questKills", 0);
				//
				paramzz.SetInt("questType", questAssigned);
			}else{
				DisplayError("wtf", "no quest assigned by npc?");
			}
			PlaySound("Data/Sounds/questing.wav", mo.position);
			obj2.UpdateScriptParams();
			//level.SendMessage("displaytext \""+"debug: questType on the player is "+paramzz.GetInt("questType"));
			spam = 0;
			rogueUI("questReceived");
		}else if(token == "nearfire"){
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			params.SetInt("FireNear", 1);
			obj.UpdateScriptParams();
			//level.SendMessage("displaytext \""+"ENTER WARMTH KICKED IN winter is "+params.GetInt("Winter")+" and NearFire is "+params.GetInt("NearFire")+""+"\"");
			if(params.GetInt("Winter") > 0){
				rogueUI("FireNear");
			}
			//obj.UpdateScriptParams();
		}else if(token == "quest2Init"){
			BlockTypeUpdate("Data/Objects/block_quest_2.xml", 15.0);
		}else if(token == "farfire"){
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			params.SetInt("FireNear", 0);
			if(params.GetInt("Winter") > 0){
				rogueUI("FireFar");
			}
			obj.UpdateScriptParams();
		}else if(token == "searchable"){
			level.SendMessage("displayhud /Data/UI/Icons/lootage.png");
			//level.SendMessage("displayhud /Data/UI/Icons/lootage.png");
		}else if(token == "questReset"){
			//DisplayError("wtf", "quest reset triggered");
			BlockTypeUpdate("Data/Objects/block_quest_2.xml", 0.0001f);
			BlockTypeUpdate("Data/Objects/block_quest_8.xml", 0.0001f);
			BlockTypeUpdate("Data/Objects/block_quest_9.xml", 0.0001f);
			BlockTypeUpdate("Data/Objects/block_quest_10.xml", 0.0001f);
			BlockTypeUpdate("Data/Objects/block_quest_11.xml", 0.0001f);
		}else if(token == "shuffle"){
			//mo.ReceiveMessage("woot");
			//MovementObject@ mo = ReadCharacterID(player_id);
			//DisplayError("wtf", "token has worked");
			PlaySound("Data/Sounds/searching.wav", mo.position);
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			// augment food level
		if(skillCheck("Steal", 0)){
			int amount = (rand() % 4)+1;
			if(params.GetString("trinketType") == "Fortune" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
				params.SetInt("Gold", (params.GetInt("Gold")+amount+1));
				PlaySound("Data/Sounds/trinketProc.wav", mo.position);
						createTrinketSparks();
			}else{
				params.SetInt("Gold", (params.GetInt("Gold")+amount));	
			}
			rogueUI("Gold");
			PlaySound("Data/Sounds/cashish.wav", mo.position);
			obj.UpdateScriptParams();
		}else{
			int dice = (rand() % 4);
			if(params.GetInt("lockPick") <= 0){
				if(dice == 0){
					level.SendMessage("displaytext \""+"You triggered a fire trap!!!");
					mo.ReceiveMessage("ignite");
					PlaySound("Data/Sounds/trapSound.wav", mo.position);
					rogueUI("noSteal");
				}else if(dice == 1){
					//nothing happens (lucky)
					level.SendMessage("displaytext \""+"You failed to unlock this container.");
					PlaySound("Data/Sounds/meh.wav", mo.position);
					rogueUI("noSteal");
				}else if(dice == 2){
					level.SendMessage("displaytext \""+"Someone saw you!!");
					PlaySound("Data/Sounds/meh.wav", mo.position);
					rogueUI("noSteal");
					SendInEnemyChar();
					if(rand()%2==0){
						SendInEnemyChar();
					}
					if(rand()%2==0){
						SendInEnemyChar();
					}
				}else if(dice == 3){
					PlaySound("Data/Sounds/poison.wav", mo.position);
					level.SendMessage("displayhud /Data/UI/Icons/poisoned.png");
					if(params.GetString("trinketType") == "Venom" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
						level.SendMessage("displaytext \""+"Your trinket protected you against the poison trap!!");
						PlaySound("Data/Sounds/trinketProc.wav", mo.position);
								createTrinketSparks();
					}else{
									if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "purity"){
										  PlaySound("Data/Sounds/purityProc.wav", mo.position);
										  level.SendMessage("clearhud");
										  level.SendMessage("uicue");
										  level.SendMessage("displayhud /Data/UI/Icons/purityProc.png");
										  createTrinketSparks();
									}else{
							  level.SendMessage("displaytext \""+"You triggered a poison trap!!!");
							  mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
							  	uint32 idz = MakeParticle("Data/Particles/Undergrowth/poison_cloud.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
							  	PlaySound("Data/Sounds/trapSound.wav", mo.position);
							  	if(params.GetInt("Poison")<= 0){
						   		params.SetInt("Poison", 5);
						   	}else{
						   		params.SetInt("Poison", (params.GetInt("Poison")+5));
						   	}
									}	
					}
				}
			}else{
				level.SendMessage("displaytext \""+"You failed to unlock this container.");
				PlaySound("Data/Sounds/pickFailed.wav", mo.position);
				params.SetInt("lockPick", (params.GetInt("lockPick")-1));
				rogueUI("lockPick");
			}
			obj.UpdateScriptParams();
		}
	}
}

void DrawGUI() {
	imGUI.render();
	HUDImage @blackout_image = hud.AddImage();
	blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
	blackout_image.position.y = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.x = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.z = -2.0f;
	blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight()) * 2.0f;
	blackout_image.color = vec4(0.0f, 0.0f, 0.0f, blackout_amount);
}

int update_counter = 0;
void PostInit(){
	if(!post_init_done){
		if(update_counter > 100){
			post_init_done = true;
		}
		update_counter += 1;
	}
}

bool preload_done = false;
bool resetting = false;

void Update() {

	PostInit();
	PreloadBlocks();
	SetBlockFinalTranslation();
	GetPlayerIDAndSetStatic();
	BuildWorld();
	UpdateGlobalReflection();

	if(game_mode == dynamic_world){
		UpdateMovement();
	}

	if(distance_cull){
		UpdateCullMovement();
	}

	world.UpdateSpawning();
	world.RemoveGarbage();
	MovementObject@ player_char = ReadCharacterID(player_id);
	player_pos = player_char.position;
	world.BlockUpdate();

	UpdateMusic();
	UpdateSounds();
	UpdateReviving();
	UpdateFading();

	UpdateUndergrowth();

	imGUI.update();

	if(!released_player && !EditorModeActive()){
		camera.SetPos(starting_pos + vec3(world_size * 7.0f));
		camera.LookAt(starting_pos);
	}

	if(resetting){
		created_world = false;
		released_player = false;
		player_id = -1;
		resetting = false;
		/* blackout_amount = 1.0f; */
	}

	if(attacker_set_ko != -1){
		MovementObject@ enemy_mo = ReadCharacterID(attacker_set_ko);
			enemy_mo.Execute("GoLimp();");
			attacker_set_ko = -1;
	}
	if(attacker_set_on_fire != -1){
		MovementObject@ enemy_mo = ReadCharacterID(attacker_set_on_fire);
			enemy_mo.Execute("SetOnFire(true);");
			attacker_set_on_fire = -1;
	}
	if(attacker_set_bleeding != -1){
		MovementObject@ enemy_mo = ReadCharacterID(attacker_set_bleeding);
			enemy_mo.Execute("CutThroat();");
			attacker_set_bleeding = -1;
	}

	UpdateInput(player_char);
}

void UpdateUndergrowth(){
	if(!post_init_done || !preload_done || !final_translation_done || !created_world || rebuild_world || !released_player || resetting || GetMenuPaused()){
		return;
	}
	
	UpdateHunger();
	UpdateThirst();
	UpdateBlessing();
	UpdateSickness();
	UpdateRogueUi();
	WinterUpdate();
	UpdateQuestLoot();
	ThrowFlagUpdate();
	dayNightCycle();
	UpdateCaravan();
	UpdateHunting();
	UpdatePoison();
}

void UpdateInput(MovementObject @player){
	if(GetInputPressed(player.controller_id, "i")){
		if(uiIsOn == false){
			AddProgressUI();
			PlaySound("Data/Sounds/openui.wav", player.position);
			uiIsOn = true;
		}else{
			RemoveUI();
			PlaySound("Data/Sounds/closeui.wav", player.position);
			uiIsOn = false;
		}
	}

	if(GetInputPressed(player.controller_id, "m")){
		missionTell();
	}
}

void UpdateFading(){
	if(world.objects_to_spawn.size() == 0 && updated_global_reflection && blackout_amount > 0.0f){
		blackout_amount -= time_step * 0.5f;;
	}
}

void GetPlayerIDAndSetStatic(){
	if(player_id == -1){
		uint num_chars = GetNumCharacters();
		for(uint a=0; a<num_chars; ++a){
			MovementObject@ char = ReadCharacter(a);
			if(char.controlled){
				player_id = char.GetID();
				break;
			}
		}
		if(player_id == -1){
			player_id = ReadCharacter(0).GetID();
		}
		MovementObject@ player = ReadCharacterID(player_id);
		player.static_char = true;
		/* player.Execute("run_speed = 1000.0f; true_max_speed = 1000.0f"); */
	}
}

void UpdateCullMovement(){
	if(!post_init_done || !preload_done || !final_translation_done || !created_world || rebuild_world || !released_player || resetting){
		return;
	}

	MovementObject@ player = ReadCharacterID(player_id);
	vec3 target_position;
	if(EditorModeActive()){
		target_position = camera.GetPos();
	}else{
		target_position = player.position;
	}

	if(GetInputPressed(0, "g")){
		cull_grid_position += ivec2(1, 0);
		world.CullMoveRight();
		Log(warning, "grid_position : " + cull_grid_position.x + "," + cull_grid_position.y);
	}

	ivec2 new_cull_grid_position = ivec2(int(floor(target_position.x / (block_size * 2.0f))), int(floor(target_position.z / (block_size * 2.0f))));
	if(cull_grid_position.x != new_cull_grid_position.x || cull_grid_position.y != new_cull_grid_position.y){
		if(new_cull_grid_position.y > cull_grid_position.y){
			cull_grid_position += ivec2(0, 1);
			world.CullMoveDown();
		}
		if(new_cull_grid_position.y < cull_grid_position.y){
			cull_grid_position += ivec2(0, -1);
			world.CullMoveUp();
		}
		if(new_cull_grid_position.x > cull_grid_position.x){
			cull_grid_position += ivec2(1, 0);
			world.CullMoveRight();
		}
		if(new_cull_grid_position.x < cull_grid_position.x){
			cull_grid_position += ivec2(-1, 0);
			world.CullMoveLeft();
		}
	}
}

void UpdateMovement(){
	if(!post_init_done || !preload_done || !final_translation_done || !created_world || rebuild_world || !released_player || resetting){
		return;
	}

	MovementObject@ player = ReadCharacterID(player_id);
	vec3 target_position;
	if(EditorModeActive()){
		target_position = camera.GetPos();
	}else{
		target_position = player.position;
	}

	ivec2 new_grid_position = ivec2(int(floor(target_position.x / (block_size * 2.0f))), int(floor(target_position.z / (block_size * 2.0f))));
	if(grid_position.x != new_grid_position.x || grid_position.y != new_grid_position.y){
		CheckWendigo(player);
		if(new_grid_position.y > grid_position.y){
			grid_position += ivec2(0, 1);
			world.MoveDown();
		}
		if(new_grid_position.y < grid_position.y){
			grid_position += ivec2(0, -1);
			world.MoveUp();
		}
		if(new_grid_position.x > grid_position.x){
			grid_position += ivec2(1, 0);
			world.MoveRight();
		}
		if(new_grid_position.x < grid_position.x){
			grid_position += ivec2(-1, 0);
			world.MoveLeft();
		}
		Log(warning, "grid_position : " + grid_position.x + "," + grid_position.y);
	}
}

void CheckWendigo(MovementObject@ player_mo){
	if(wendigoTimer > 0){
		if(!skillCheck("Tracking", 0)){
			level.SendMessage("displaytext \""+"You should have not move!! The Wendigo has spotted you. (Bushcraft skill failed)"+"\"");
			//spawn wendigo
			string enemyPath = "Data/Characters/Undergrowth/Wendigo.xml";
			int enemyID = CreateObject(enemyPath);
			Object@ charObj = ReadObjectFromID(enemyID);
			MovementObject@ enemy = ReadCharacterID(enemyID);
			int dice = rand()% 4;
			if(dice == 0){
				vec3 enemy_pos = vec3(player_mo.position.x-20.0, player_mo.position.y, player_mo.position.z-20.0);
				charObj.SetTranslation(enemy_pos);
			}else if(dice == 1){
				vec3 enemy_pos = vec3(player_mo.position.x+20.0, player_mo.position.y, player_mo.position.z-20.0);
				charObj.SetTranslation(enemy_pos);
			}else if(dice == 2){
				vec3 enemy_pos = vec3(player_mo.position.x-20.0, player_mo.position.y, player_mo.position.z+20.0);
				charObj.SetTranslation(enemy_pos);
			}else if(dice == 3){
				vec3 enemy_pos = vec3(player_mo.position.x+20.0, player_mo.position.y, player_mo.position.z+20.0);
				charObj.SetTranslation(enemy_pos);				 
			}
			charObj.QueueScriptMessage("escort_me "+player_id); 
		}else{
			level.SendMessage("displaytext \""+"Although you moved the Wendigo can't seem to find you. (Bushcraft skill success)"+"\"");
			PlaySound("Data/Sounds/wendigoCurious.wav", player_mo.position);
		}
		wendigoTimer  = -1;
	}
}

bool DialogueCameraControl(){
	if(!released_player){
		return true;
	}
	return false;
}

void AdjustMalus(){
	  totalMalus = 0.01;
	  Object @obj = ReadObjectFromID(GetPlayerID());
	  ScriptParams@ params = obj.GetScriptParams();
	  MovementObject@ player = ReadCharacterID(GetPlayerID());
	  if(params.GetInt("Water") < 25){
	  	totalMalus += 0.25;
	  }else if(params.GetInt("Water") < 50){
	  	totalMalus += 0.15;
	  }
	  //
	  if(params.GetInt("Food") > 100){
	  	totalMalus += 0.10;
	  }else if(params.GetInt("Food") < 25){
	  	totalMalus += 0.25;
	 	}else if(params.GetInt("Food") < 50){
	  	totalMalus += 0.15;
	  }
	  //
	  if(params.GetInt("Fatigue") > 100){
	  	totalMalus += 0.25;
	  }else if(params.GetInt("Fatigue") > 50){
	  	totalMalus += 0.15;
	  }
	  //
	  if(params.GetInt("Sick") > 0){
	  	totalMalus += 0.25;
	  }
	  //
	  if(params.GetInt("Bless") > 0){
	  	totalMalus -= 0.25;
	  }
	  //shadow run relic
	  if(GetCharWeaponTag(GetCharPrimaryWeapon(player)) == "shadowRun"){
			if(params.GetInt("hour")>20){
				 totalMalus -= 0.10; 
			}
	  }
	  //adjust the maluses
	  params.SetFloat("Attack Damage", (1.0-totalMalus));
	  params.SetFloat("Attack Knockback", (1.0-totalMalus));
	  params.SetFloat("Attack Speed", 1.0-(totalMalus));
	  params.SetFloat("Movement Speed", 1.0-(totalMalus));
	  params.SetFloat("Fat", (params.GetFloat("Food")/200));

	  //block updates
	  BlockTypeUpdate("Data/Objects/block_trees_27.xml", 0.5+params.GetFloat("Forts"));
	  BlockTypeUpdate("Data/Objects/block_trinket.xml", 0.0001+params.GetFloat("trinketChances"));
	  if(params.GetInt("special1") == 1){
	  	BlockTypeUpdate("Data/Objects/special_1.xml", 0.5);
	  }
	  if(params.GetInt("special2") == 1){
	  	BlockTypeUpdate("Data/Objects/special_2.xml", 0.5);
	  }
	  if(params.GetInt("special3") == 1){
	  	BlockTypeUpdate("Data/Objects/special_3.xml", 0.5);
	  }
	  if(params.GetInt("special4") == 1){
	  	BlockTypeUpdate("Data/Objects/special_4.xml", 0.5);
	  }
	  if(params.GetInt("special5") == 1){
	  	BlockTypeUpdate("Data/Objects/special_5.xml", 0.5);
	  }
	  if(params.HasParam("wanted")){
	  	cityBlockTypeUpdate("Data/Objects/city_block_17.xml", 0.0001+(params.GetFloat("wanted")));
	  }else{
	  	// level.SendMessage("displaytext \""+"debug: no wanted param found setting up the float during block update.");
			params.AddFloat("wanted", 0.0f); 
			obj.UpdateScriptParams();    
	  }
	  // if there is still Ronins in the game
	  if(params.GetInt("roninKill") < 13){
	  	// spawns ronin towers
	  	BlockTypeUpdate("Data/Objects/block_trees_24.xml", 0.25);
	  }else{
	  	// if not ronins stop spawning
	  	BlockTypeUpdate("Data/Objects/block_trees_24.xml", 0.0001);
	  }
	  //ronin side quest
	  if(params.GetInt("roninGrave") > 0){
	  	BlockTypeUpdate("Data/Objects/block_trees_57.xml", 0.0001);
	  	BlockTypeUpdate("Data/Objects/block_trees_58.xml", 0.1);
	  	BlockTypeUpdate("Data/Objects/block_trees_59.xml", 0.0001);
	  	params.SetInt("relicDistance", -1);
	  }
	  if(params.GetInt("relicDistance") == 0){
	  	params.SetInt("roninGrave", 0);
	  	BlockTypeUpdate("Data/Objects/block_trees_57.xml", 0.0001);
	  	BlockTypeUpdate("Data/Objects/block_trees_58.xml", 0.0001);
	  	BlockTypeUpdate("Data/Objects/block_trees_59.xml", 0.1);
	  }else if(params.GetInt("relicDistance") > 0){
	  	params.SetInt("roninGrave", 0);
	  	BlockTypeUpdate("Data/Objects/block_trees_57.xml", 0.1);
	  	BlockTypeUpdate("Data/Objects/block_trees_58.xml", 0.0001);
	  	BlockTypeUpdate("Data/Objects/block_trees_59.xml", 0.0001);
	  }
	  // samurai mid game difficulty adjusters
	  if(params.GetInt("KungfuBelt") + params.GetInt("KenjutsuBelt") + params.GetInt("ShurikenBelt") + params.GetInt("NinjitsuBelt") > 7){
	  	BlockTypeUpdate("Data/Objects/block_guard_patrol4.xml", 1.0);
	  }
	  if(params.GetInt("KungfuBelt") + params.GetInt("KenjutsuBelt") + params.GetInt("ShurikenBelt") + params.GetInt("NinjitsuBelt") > 7){
	  	BlockTypeUpdate("Data/Objects/Data/Objects/block_camp_7.xml", 1.0);
	  }
	  //thieves
	  if(params.GetInt("hour")>20){
	  	BlockTypeUpdate("Data/Objects/block_trees_55.xml", 0.25); 
			BlockTypeUpdate("Data/Objects/block_trees_56.xml", 0.25);  
	  }else{
			BlockTypeUpdate("Data/Objects/block_trees_55.xml", 0.001); 
			BlockTypeUpdate("Data/Objects/block_trees_56.xml", 0.001); 
	  }
	  if(once == 1){
	  	once = 0;
		player.Execute("invincible = false;");
	}


	  
		   int weapID = player.GetArrayIntVar("weapon_slots",1);
		   //weaponTell
			if(weapID != -1){
				  if(weaponTell == 0){
						string weapLabel;
						ItemObject@ weap = ReadItemID(weapID);
						weapLabel = weap.GetLabel();
						if(weapLabel == "banshee"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped a Banshee blade. 10% per strike to scare your opponent.");
							  weaponTell = 1;
						}else if(weapLabel == "bloodThirst"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped a Blood Thirst Katana. Every kill will nourish your body and soul.");
							  weaponTell = 1;
						}else if(weapLabel == "holyAvenger"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped a Holy Avenger. Every kill will give you a small bless. You cannot steal while having this blade.");
							  weaponTell = 1;
						}else if(weapLabel == "shadowRun"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped the Shadow Run. You will move and attack 10% faster at night.");
							  weaponTell = 1;
						}else if(weapLabel == "purity"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped a Blade of Purity. If you hold the blade you are immune to poison and diseases. ");
							  weaponTell = 1;
						}else if(weapLabel == "north"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped a Blade of the North. If you hold the blade you are immune to Frost. ");
							  weaponTell = 1;
						}else if(weapLabel == "assassin"){
							  PlaySound("Data/Sounds/relicEquip.wav");
							  level.SendMessage("displaytext \""+"You have equipped an Assassin blade. Weapon kills will not spool up hunting parties.");
							  weaponTell = 1;
						}else{
						  //level.SendMessage("displaytext \""+"debug: level name is "+level_name);
							  weaponTell = 0;
						}  
				  }                
			}else{
				  weaponTell = 0;
			}
	  obj.UpdateScriptParams();
}

//used as a cope out for the throwing kills until merlyn give me a cheevos for that
void rogueThrow(){
		//ReadCharacterID(player_ids[0])
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		//throwFlag is set
		params.SetInt("throwFlag", 1);
		obj.UpdateScriptParams();
		// set a timer to put it back to 0
		level.SendMessage("throwFlagSet");
		obj.UpdateScriptParams();
}