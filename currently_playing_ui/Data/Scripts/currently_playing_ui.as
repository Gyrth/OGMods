IMGUI@ imGUI;
IMDivider@ vertical_divider;
IMDivider@ horizontal_divider;
float healthbar_width;
bool post_init_done = false;
level_types level_type;
string campaign_id;
string author_name;
string campaign_name;
string campaign_progress;
string level_name;
string mod_source_id;
string level_thumbnail_path;
string campaign_thumbnail_path;
ModID mod_id;
string level_title;
int font_size = 90;
bool font_shadowed = true;
string font_name = "arialbd";
int vertical_alignment = CATop;
int horizontal_alignment = CACenter;
float padding = 30.0;
string level_description;
vec4 font_color = HexColor("#CCCCCC");
FontSetup title_font(font_name, font_size - 20, font_color, font_shadowed);
FontSetup main_font(font_name, font_size , font_color, font_shadowed);
FontSetup description_font(font_name, font_size - 40, font_color, font_shadowed);
float ui_update_timer = 0.0;
bool no_fade = false;

vec2 ui_size(800.0, 300.0);
vec2 screen_size(2560, 1440);

enum ui_states{
					show_level = 0,
					show_author = 1,
					show_thumbnail = 2,
					show_description = 3
				};

int current_ui_state = show_level;

enum level_types{
					campaign_level = 0,
					single_level = 1
				};

void Initialize() {
	@imGUI = CreateIMGUI();
	LoadSettings();
}

void LoadSettings(){
	JSON data;
	JSONValue root;

	SavedLevel@ saved_level = save_file.GetSavedLevel("currently_playing_ui_settings");
	string palette_data = saved_level.GetValue("settings_json");

	if(palette_data == "" || !data.parseString(palette_data)){
		if(!data.parseString(palette_data)){
			Log(warning, "Unable to parse the saved JSON in the saved data!");
		}
		return;
	}

	root = data.getRoot();

	JSONValue font_color_json = root["font_color"];
	font_color = vec4(font_color_json[0].asFloat(), font_color_json[1].asFloat(), font_color_json[2].asFloat(), font_color_json[3].asFloat());

	font_name = root["font_name"].asString();
	font_shadowed = root["font_shadowed"].asBool();
	font_size = root["font_size"].asInt();
	padding = root["padding"].asInt();
	horizontal_alignment = root["horizontal_alignment"].asInt();
	vertical_alignment = root["vertical_alignment"].asInt();

	main_font.fontName = font_name;
	title_font.fontName = font_name;
	description_font.fontName = font_name;

	main_font.size = font_size;
	title_font.size = max(10, font_size - 20);
	description_font.size = max(10, font_size - 40);

	main_font.shadowed = font_shadowed;
	title_font.shadowed = font_shadowed;
	description_font.shadowed = font_shadowed;

	main_font.color = font_color;
	title_font.color = font_color;
	description_font.color = font_color;
}

void FindLevelInfo(){
	campaign_id = GetCurrCampaignID();
	array<ModID> mod_sids = GetActiveModSids();

	//If the campaign id is empty then it must be a single custom level.
	if(campaign_id == ""){
		level_type = single_level;

		mod_source_id = GetCurrentLevelModsourceID();
		for(uint i = 0; i < mod_sids.size(); i++){
			//Get the actual ModID object based on the string id to get more information.
			if(ModGetID(mod_sids[i]) == mod_source_id){
				mod_id = mod_sids[i];
				author_name = ModGetAuthor(mod_id);
				level_name = GetCurrLevelName();
				level_description = ModGetDescription(mod_id);

				array<ModLevel> single_levels = ModGetSingleLevels(mod_id);
				for(uint j = 0; j < single_levels.size(); j++){
					Log(warning, single_levels[j].GetDetails().GetName() + " - " + level_name);
					if(single_levels[j].GetDetails().GetName() == level_name){
						level_thumbnail_path = single_levels[j].GetThumbnail();
						level_title = single_levels[j].GetTitle();
						break;
					}
				}

				break;
			}
		}
	}else{
		level_type = campaign_level;

		for(uint i = 0; i < mod_sids.size(); i++){
			//Get the actual ModID object based on the string id to get more information.
			if(ModGetID(mod_sids[i]) == campaign_id){
				mod_id = mod_sids[i];
				author_name = ModGetAuthor(mod_id);
				string level_id = GetCurrLevelID();

				Campaign current_campaign = GetCampaign(GetCurrCampaignID());
				array<ModLevel>campaign_levels = current_campaign.GetLevels();
				ModLevel current_level = current_campaign.GetLevel(level_id);

				campaign_name = current_campaign.GetTitle();
				campaign_thumbnail_path = current_campaign.GetThumbnail();
				//Get the thumbnail path for future features.
				level_thumbnail_path = current_level.GetThumbnail();

				level_title = current_level.GetTitle();

				for(uint j = 0; j < campaign_levels.size(); j++){
					Log(warning, campaign_levels[j].GetID() + " " + level_id);
					if(campaign_levels[j].GetID() == level_id){
						//Create a string to show which level this in the whole campaign. example: 5/15
						campaign_progress = j + "/" + campaign_levels.size();
						Log(warning, campaign_progress);
						break;
					}
				}
				level_description = ModGetDescription(mod_id);

				break;
			}
		}
	}
}

void PostInit(){
	FindLevelInfo();
	BuildUI();
}

void Update(int paused){
	if(!post_init_done){
		PostInit();
		post_init_done = true;
	}

	ui_update_timer -= time_step;

	if(ui_update_timer <= 0.0){
		NextUIState();
		ui_update_timer = 10.0;
		current_ui_state += 1;
		if(current_ui_state > show_author){
			current_ui_state = 0;
		}
	}

	imGUI.update();
}

void NextUIState(){
	vertical_divider.clear();
	horizontal_divider.clear();

	horizontal_divider.appendSpacer(padding);
	horizontal_divider.append(vertical_divider);
	vertical_divider.appendSpacer(padding);
	int fadein_time = 250;

	if(current_ui_state == show_author){
		IMText by_label("By:", title_font);
		IMText author_label(author_name, main_font);

		if(!no_fade){
			by_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
			author_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
		}

		vertical_divider.append(by_label);
		vertical_divider.append(author_label);
	}else if(current_ui_state == show_level){
		IMText currently_playing_label("Currently Playing " + ((level_type == single_level)?"Level":"Campaign") + ":", title_font);
		IMText campaign_title_label(((level_type == campaign_level)?campaign_name:""), main_font);
		IMText level_title_label(((level_type == campaign_level)?campaign_progress + " ":"") + level_title, main_font);

		/* currently_playing_label.addUpdateBehavior(IMMoveIn(15000.0f, vec2(0, 800.0), outExpoTween), ""); */
		currently_playing_label.setClip(true);
		if(!no_fade){
			currently_playing_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
			level_title_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
			campaign_title_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
		}

		vertical_divider.append(currently_playing_label);
		vertical_divider.append(campaign_title_label);
		vertical_divider.append(level_title_label);
	}else if(current_ui_state == show_thumbnail){
		IMImage thumbnail(level_thumbnail_path);
		thumbnail.scaleToSizeY(300.0f);
		vertical_divider.append(thumbnail);

		if(!no_fade){
			thumbnail.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
		}
	}else if(current_ui_state == show_description){
		IMText description_label(level_description, description_font);

		vertical_divider.append(description_label);
		if(!no_fade){
			description_label.addUpdateBehavior(IMFadeIn(fadein_time, inSineTween), "");
		}
	}
	vertical_divider.appendSpacer(padding);
	horizontal_divider.appendSpacer(padding);
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "dispose_level"){
			SaveSettings();
		}
	}
}

void Update() {
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "run_file" )
        {

        }
	}
}

void Dispose() {
    imGUI.clear();
}

void SetWindowDimensions(int width, int height){
    imGUI.doScreenResize(); // This must be called first
}

void PostScriptReload() {
    imGUI.clear();
    BuildUI();
}


void BuildUI(){

	@imGUI = CreateIMGUI();
    imGUI.setFooterHeight(200);
    imGUI.setup();

	IMContainer main_container(screen_size.x, screen_size.y);
	main_container.setBorderColor(vec4(1.0, 0.0, 1.0, 1.0));
	main_container.setAlignment(ContainerAlignment(horizontal_alignment), ContainerAlignment(vertical_alignment));

	@horizontal_divider = IMDivider("horizontal_divider", DOHorizontal);
	/* horizontal_divider.showBorder(); */
	horizontal_divider.setAlignment(CACenter, CACenter);
	main_container.setElement(horizontal_divider);

	@vertical_divider = IMDivider("vertical_divider", DOVertical);
	/* vertical_divider.showBorder(); */
	vertical_divider.setAlignment(CACenter, CACenter);
	horizontal_divider.append(vertical_divider);

    // Add it to the main panel of the GUI
    imGUI.getMain().setElement(main_container);
}

void DrawGUI() {
    imGUI.render();
}

void Init(string str){
	Initialize();
}

bool update_font = false;
array<string> vertical_aligment_options = {"Top", "Center", "Bottom"};
array<string> horizontal_aligment_options = {"Left", "Center", "Right"};

void Menu(){
	if(ImGui_BeginMenu("Currently Playing UI Settings")){
		ImGui_AlignTextToFramePadding();
		ImGui_Text(font_name);
		ImGui_SameLine();
		if(ImGui_Button("Pick Font")){
			string new_path = GetUserPickedReadPath("ttf", "Data/Fonts");
			if(new_path != ""){
				new_path = new_path;
				array<string> path_split = new_path.split("/");
				for(uint i = 0; i < path_split.size(); i++){
					if(path_split[i].findFirst(".ttf") != -1){
						string new_font_name = join(path_split[i].split(".ttf"), "");
						font_name = new_font_name;
						main_font.fontName = font_name;
						title_font.fontName = font_name;
						description_font.fontName = font_name;
						update_font = true;
						break;
					}
				}
			}
		}

		if(ImGui_SliderInt("Font size", font_size, 1, 120)){
			main_font.size = font_size;
			title_font.size = max(10, font_size - 20);
			description_font.size = max(10, font_size - 40);
			update_font = true;
		}
		if(ImGui_Checkbox("Font shadowed", font_shadowed)){
			main_font.shadowed = font_shadowed;
			title_font.shadowed = font_shadowed;
			description_font.shadowed = font_shadowed;
			update_font = true;
		}

		if(ImGui_Combo("Vertical Alignment", vertical_alignment, vertical_aligment_options, vertical_aligment_options.size())){
			update_font = true;
		}

		if(ImGui_Combo("Horizontal Alignment", horizontal_alignment, horizontal_aligment_options, horizontal_aligment_options.size())){
			update_font = true;
		}

		if(ImGui_SliderFloat("Padding", padding, 0, 120, "%.0f")){
			update_font = true;
		}

		if(ImGui_ColorEdit4("Font Color", font_color)){
			main_font.color = font_color;
			title_font.color = font_color;
			description_font.color = font_color;
			update_font = true;
		}

		ImGui_EndMenu();
	}

	if(update_font){
		no_fade = true;
		imGUI.clear();
	    BuildUI();
		NextUIState();
		imGUI.update();
		update_font = false;
		no_fade = false;
	}
}

void SaveSettings(){
	JSON data;
	JSONValue root;

	JSONValue font_color_json = JSONValue(JSONarrayValue);
	font_color_json.append(font_color.x);
	font_color_json.append(font_color.y);
	font_color_json.append(font_color.z);
	font_color_json.append(font_color.a);
	root["font_color"] = font_color_json;

	root["font_name"] = JSONValue(font_name);
	root["font_shadowed"] = JSONValue(font_shadowed);
	root["font_size"] = JSONValue(font_size);
	root["padding"] = JSONValue(padding);
	root["horizontal_alignment"] = JSONValue(horizontal_alignment);
	root["vertical_alignment"] = JSONValue(vertical_alignment);

	data.getRoot() = root;

	SavedLevel@ saved_level = save_file.GetSavedLevel("currently_playing_ui_settings");
	saved_level.SetValue("settings_json", data.writeString(false));
	save_file.WriteInPlace();
}
