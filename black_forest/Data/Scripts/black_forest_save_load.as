#include "black_forest_shared.as"

void SaveSettings(){
	JSON data;
	JSONValue root;

	JSONValue settings;

	settings["world_size"] = JSONValue(world_size);
	settings["game_mode"] = JSONValue(game_mode);
	settings["enemy_spawn_mult"] = JSONValue(enemy_spawn_mult);
	root["settings"] = settings;

	data.getRoot() = root;
	SavedLevel@ saved_level = save_file.GetSavedLevel("black_forest_data");
	saved_level.SetValue("settings", data.writeString(false));
	save_file.WriteInPlace();
}

void LoadSettings(){
	SavedLevel@ saved_level = save_file.GetSavedLevel("black_forest_data");
	string settings_json = saved_level.GetValue("settings");
	JSON data;

	if(settings_json != "" && data.parseString(settings_json)){
		JSONValue root;

		root = data.getRoot();
		JSONValue settings = root["settings"];
		world_size = settings["world_size"].asInt();
		game_mode = game_modes(settings["game_mode"].asInt());
		enemy_spawn_mult = settings["enemy_spawn_mult"].asFloat();
	}
}

void DeleteSettings(){
	SavedLevel@ saved_level = save_file.GetSavedLevel("black_forest_data");
	saved_level.SetValue("settings", "");
	save_file.WriteInPlace();
}
