void SaveData(){
	JSON data;
	JSONValue root;

	JSONValue settings;

	settings["env_objects_mult"] = JSONValue(env_objects_mult);
	settings["num_intersections"] = JSONValue(num_intersections);
	settings["chosen_level_index"] = JSONValue(chosen_level_index);
	settings["num_barrels"] = JSONValue(num_barrels);
	settings["max_connections"] = JSONValue(max_connections);
	root["settings"] = settings;

	data.getRoot() = root;
	SavedLevel@ saved_level = save_file.GetSavedLevel("train_track_data");
	saved_level.SetValue("settings", data.writeString(false));
	save_file.WriteInPlace();
}

void LoadData(){
	SavedLevel@ saved_level = save_file.GetSavedLevel("train_track_data");
	string settings_json = saved_level.GetValue("settings");
	JSON data;

	if(settings_json != "" && data.parseString(settings_json)){
		JSONValue root;

		root = data.getRoot();
		JSONValue settings = root["settings"];
		env_objects_mult = settings["env_objects_mult"].asFloat();
		num_intersections = settings["num_intersections"].asInt();
		chosen_level_index = settings["chosen_level_index"].asInt();
		num_barrels = settings["num_barrels"].asInt();
		max_connections = settings["max_connections"].asInt();
	}
}

void DeleteData(){
	SavedLevel@ saved_level = save_file.GetSavedLevel("train_track_data");
	saved_level.SetValue("settings", "");
	save_file.WriteInPlace();
}
