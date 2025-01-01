enum campaign_control_options {	finished_current_next_level = 0,
								finished_current_main_menu = 1,
								finished_current = 2
								};

class DrikaCampaignControl : DrikaElement{

	array<string> campaign_control_names = {	"Finished current level and load next level",
												"Finished current level and load main menu",
												"Finished current level"
											};

	string campaign_id;
	string level_id;
	int current_campaign_control_option;
	campaign_control_options campaign_control_option;

	int current_campaign = 0;
	int current_level = 0;
	array<string> campaign_titles = {};
	array<string> campaign_ids = {};
	array<string> level_titles = {};
	array<string> level_ids = {};

	string campaign_thumbnail_path;
	TextureAssetRef campaign_thumbnail;
	string campaign_main_script;
	string campaign_menu_script;

	string level_thumbnail_path;
	TextureAssetRef level_thumbnail;
	string level_path;
	bool level_completion_optional;

	DrikaCampaignControl(JSONValue params = JSONValue()){
		campaign_id = GetJSONString(params, "campaign_id", "com-wolfire-overgrowth-campaign");
		level_id = GetJSONString(params, "level_id", "river_village_intro");
		campaign_control_option = campaign_control_options(GetJSONInt(params, "campaign_control_option", 0));
		current_campaign_control_option = campaign_control_option;
		drika_element_type = drika_campaign_control;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;

		data["campaign_id"] = JSONValue(campaign_id);
		data["level_id"] = JSONValue(level_id);
		data["campaign_control_option"] = JSONValue(campaign_control_option);

		return data;
	}

	string GetDisplayString(){
		return "CampaignControl " + campaign_id + " " + level_id;
	}

	void StartSettings(){
		GetCampaignDropdown();
		GetLevelDropdown();
		GetCampaignInfo();
		GetLevelInfo();
	}

	void GetCampaignDropdown(){
		array<Campaign> @campaigns = GetCampaigns();
		campaign_titles.resize(0);
		campaign_ids.resize(0);

		for(uint i = 0; i < campaigns.size(); i++){
			Log(warning, "Campaign : " + campaigns[i].GetID());
			campaign_titles.insertLast(campaigns[i].GetTitle());
			campaign_ids.insertLast(campaigns[i].GetID());

			if(campaigns[i].GetID() == campaign_id){
				current_campaign = i;
			}
		}
	}

	void GetLevelDropdown(){
		Campaign campaign = GetCampaign(campaign_id);
	    array<ModLevel> levels = campaign.GetLevels();
		level_titles.resize(0);
		level_ids.resize(0);

		for(uint i = 0; i < levels.size(); i++){
			Log(warning, "Level : " + levels[i].GetID());
			level_titles.insertLast(levels[i].GetTitle());
			level_ids.insertLast(levels[i].GetID());

			if(levels[i].GetID() == level_id){
				current_level = i;
			}
		}
	}

	void GetCampaignInfo(){
		Campaign campaign = GetCampaign(campaign_id);

		campaign_thumbnail_path = campaign.GetThumbnail();

		Log(warning, "Path : "+ campaign_thumbnail_path);

		if(FileExists(campaign_thumbnail_path)){
			campaign_thumbnail = LoadTexture(campaign_thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}else if(FileExists("Data/" + campaign_thumbnail_path)){
			campaign_thumbnail = LoadTexture("Data/" + campaign_thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}else{
			campaign_thumbnail = LoadTexture("Data/Textures/ui/main_menu/overgrowth.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}
		
		campaign_main_script = campaign.GetMainScript();
		campaign_menu_script = campaign.GetMenuScript();
	}

	void GetLevelInfo(){
		Campaign campaign = GetCampaign(campaign_id);
		ModLevel level = campaign.GetLevel(level_id);

		level_thumbnail_path = level.GetThumbnail();
		Log(warning, "Path : "+ level_thumbnail_path);

		if(FileExists(level_thumbnail_path)){
			level_thumbnail = LoadTexture(level_thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}else if(FileExists("Data/" + level_thumbnail_path)){
			level_thumbnail = LoadTexture("Data/" + level_thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}else{
			level_thumbnail = LoadTexture("Data/Textures/ui/main_menu/overgrowth.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}

		level_path = level.GetPath();
		level_completion_optional = level.CompletionOptional();
	}

	void DrawSettings(){
		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Option");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Option", current_campaign_control_option, campaign_control_names, 15)){
			campaign_control_option = campaign_control_options(current_campaign_control_option);
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Campaign");
		ImGui_NextColumn();

		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Campaign", current_campaign, campaign_titles, campaign_titles.size())){
			campaign_id = campaign_ids[current_campaign];
			GetCampaignInfo();
			GetLevelDropdown();
			level_id = level_ids[0];
			current_level = 0;
			GetLevelInfo();
		}

		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Campaign info");
		ImGui_NextColumn();

		//------------------------

		ImGui_BeginChild("Campaign info", vec2(0.0, 110.0), false);

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0.0, second_column_width / 2.0);

		ImGui_Text("ID : " + campaign_id);
		ImGui_Text("Main script : " + campaign_main_script);
		ImGui_Text("Menu script : " + campaign_menu_script);
		ImGui_NextColumn();
		ImGui_Image(campaign_thumbnail, vec2(180.0, 101.0));

		ImGui_EndChild();

		//----------------------------

		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Level");
		ImGui_NextColumn();

		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Level", current_level, level_titles, level_titles.size())){
			level_id = level_ids[current_level];
			GetLevelInfo();
		}

		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Level info");
		ImGui_NextColumn();

		//------------------------

		ImGui_BeginChild("Level info", vec2(0.0, 110.0), false);

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0.0, second_column_width / 2.0);

		ImGui_Text("ID : " + level_id);
		ImGui_Text("Path : " + level_path);
		ImGui_Text("Completion optional : " + level_completion_optional);
		ImGui_NextColumn();
		ImGui_Image(level_thumbnail, vec2(180.0, 101.0));

		ImGui_EndChild();

		//----------------------------

		ImGui_NextColumn();
	}
	bool Trigger(){
		return true;
	}
}
