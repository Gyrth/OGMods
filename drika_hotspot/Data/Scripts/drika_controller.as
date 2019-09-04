bool animating_camera = false;
bool show_dialogue = false;
array<string> hotspot_ids;
IMGUI@ imGUI;
FontSetup name_font("edosz", 70 , HexColor("#CCCCCC"), true);
FontSetup dialogue_font("arial", 50 , HexColor("#CCCCCC"), true);
FontSetup controls_font("arial", 45 , HexColor("#616161"), true);

class ActorSettings{
	string name = "Default";
	vec4 color = vec4(1.0);
	int voice = 0;

	ActorSettings(){

	}
}

array<string> dialogue_cache;
IMDivider @dialogue_lines_holder_vert;
IMDivider @dialogue_line_holder;
int line_counter = 0;
bool ui_created = false;
string current_actor_name = "Default";
array<ActorSettings@> actor_settings;
ActorSettings@ current_actor_settings = ActorSettings();

void Init(string str){
	@imGUI = CreateIMGUI();
}

void SetWindowDimensions(int width, int height){
	if(show_dialogue){
		BuildUI();
	}
}

void BuildUI(){
	ui_created = false;
	line_counter = 0;
	DisposeTextAtlases();
	imGUI.clear();
	imGUI.setHeaderHeight(225);
	imGUI.setFooterHeight(450);
	imGUI.setFooterPanels(500.0f, 500.0f);
	imGUI.setup();

	CreateNameTag(imGUI.getFooter());
	CreateBackground(imGUI.getFooter());

	imGUI.getFooter().setAlignment(CALeft, CACenter);

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_lines_holder_horiz.appendSpacer(100.0);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(1);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(1);
	}

	IMContainer controls_container(2400.0, 375.0);
	controls_container.setAlignment(CABottom, CARight);
	IMDivider controls_divider("controls_divider", DOVertical);
	controls_divider.setAlignment(CATop, CALeft);
	controls_divider.setZOrdering(2);
	controls_container.setElement(controls_divider);
	IMText lmb_continue("Left mouse button to continue", controls_font);
	IMText rtn_skip("return to skip", controls_font);
	controls_divider.append(lmb_continue);
	controls_divider.append(rtn_skip);

	imGUI.getFooter().addFloatingElement(controls_container, "controls_container", vec2(0.0, 0.0), -1);
	imGUI.getFooter().setElement(dialogue_lines_holder_horiz);

	ui_created = true;
}

void CreateBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 0.5;
	float bg_height = 350.0;
	float dialogue_height = 450.0;

	IMImage left_fade("Textures/ui/dialogue/dialogue_bg-fade.png");
	left_fade.setColor(current_actor_settings.color);
	left_fade.setSizeX(500.0);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/ui/dialogue/dialogue_bg.png");
	middle_fade.setColor(current_actor_settings.color);
	middle_fade.setSizeX(1560.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/ui/dialogue/dialogue_bg-fade_reverse.png");
	right_fade.setColor(current_actor_settings.color);
	right_fade.setSizeX(500.0);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	parent.addFloatingElement(bg_container, "bg_container", vec2(0.0, 50.0), -1);
}

void CreateNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(0.0, 100.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(2);
	/* name_divider.showBorder(); */
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);
	IMText name(current_actor_settings.name, name_font);
	name_divider.appendSpacer(30.0);
	name_divider.append(name);
	name_divider.appendSpacer(30.0);
	name.setColor(current_actor_settings.color);

	IMImage name_background("Textures/ui/menus/main/brushStroke.png");
	name_background.setClip(false);
	/* name_background.showBorder(); */

	name_background.setSize(vec2(CalculateTextWidth(name.getText(), name_font.size), 100.0));
	name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);

	parent.addFloatingElement(name_container, "name_container", vec2(0, 0), 3);
}

float CalculateTextWidth(string text, int font_size){
	uint8 text_length = text.length();
	int lower_case = 0;
	int upper_case = 0;
	for(uint i = 0; i < text_length; i++){
		if(text.substr(i, 1)[0] >= 65 && text.substr(i, 1)[0] <= 90){
			upper_case += 1;
		}else{
			lower_case += 1;
		}
	}
	return (lower_case * font_size * 0.30) + (upper_case * font_size * 1.40);
}

void PostScriptReload(){
	BuildUI();
}

void WriteMusicXML(string music_path, string song_name, string song_path){
	StartWriteFile();
	AddFileString("<?xml version=\"2.0\" ?>\n");
	AddFileString("<Music version=\"1\">\n");

	AddFileString("<Song name=\"" + song_name + "\" type=\"single\" file_path=\"" + song_path + "\" />\n");

	AddFileString("</Music>\n");
	WriteFileToWriteDir(music_path);
}

void DrawGUI(){
	imGUI.render();
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "animating_camera"){
		token_iter.FindNextToken(msg);
		string enable = token_iter.GetToken(msg);
		token_iter.FindNextToken(msg);
		string hotspot_id = token_iter.GetToken(msg);
		if(enable == "true"){
			hotspot_ids.insertLast(hotspot_id);
			animating_camera = true;
		}else{
			for(uint i = 0; i < hotspot_ids.size(); i++){
				if(hotspot_ids[i] == hotspot_id){
					hotspot_ids.removeAt(i);
					i--;
				}
			}
			if(hotspot_ids.size() == 0){
				animating_camera = false;
			}
		}
	}else if(token == "write_music_xml"){
		array<string> lines;
		string xml_content;

		token_iter.FindNextToken(msg);
		string music_path = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string song_name = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string song_path = token_iter.GetToken(msg);

		WriteMusicXML(music_path, song_name, song_path);
	}else if(token == "drika_dialogue_hide"){
		show_dialogue = false;
		imGUI.clear();
	}else if(token == "drika_dialogue_add_say"){
		token_iter.FindNextToken(msg);
		string actor_name = token_iter.GetToken(msg);

		if(!show_dialogue){
			BuildUI();
			show_dialogue = true;
		}

		if(current_actor_settings.name != actor_name){
			bool settings_found = false;

			for(uint i = 0; i < actor_settings.size(); i++){
				if(actor_settings[i].name == actor_name){
					settings_found = true;
					@current_actor_settings = actor_settings[i];
					break;
				}
			}

			if(!settings_found){
				ActorSettings new_settings();
				actor_settings.insertLast(@new_settings);
				current_actor_settings = new_settings;
			}

			CreateNameTag(imGUI.getFooter());
			CreateBackground(imGUI.getFooter());
		}

		PlayLineContinueSound();

		token_iter.FindNextToken(msg);
		string text = token_iter.GetToken(msg);

		if(text != "\n"){
			IMText dialogue_text(text + " ", dialogue_font);
			if(dialogue_cache.size() == 0){
				dialogue_cache.insertLast("");
			}
			dialogue_cache[dialogue_cache.size() - 1] += text + " ";
			dialogue_text.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");

			dialogue_line_holder.append(dialogue_text);
		}

		if(dialogue_line_holder.getSizeX() > 1500.0 || text == "\n"){
			line_counter += 1;
			dialogue_cache.insertLast("");
			@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
			dialogue_lines_holder_vert.append(dialogue_line_holder);
			dialogue_line_holder.setZOrdering(1);
		}
	}else if(token == "drika_dialogue_clear_say"){
		dialogue_cache.resize(0);
		dialogue_lines_holder_vert.clear();
		line_counter = 0;
		dialogue_cache.insertLast("");

		if(show_dialogue){
			@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
			dialogue_lines_holder_vert.append(dialogue_line_holder);
			dialogue_line_holder.setZOrdering(1);
		}
	}else if(token == "drika_dialogue_set_color"){
		token_iter.FindNextToken(msg);
		string actor_name = token_iter.GetToken(msg);

		vec4 color;
		token_iter.FindNextToken(msg);
		color.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.z = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.a = atof(token_iter.GetToken(msg));

		bool settings_found = false;

		for(uint i = 0; i < actor_settings.size(); i++){
			if(actor_settings[i].name == actor_name){
				settings_found = true;
				actor_settings[i].color = color;
				break;
			}
		}

		if(!settings_found){
			ActorSettings new_settings();
			new_settings.name = actor_name;
			new_settings.color = color;
			actor_settings.insertLast(@new_settings);
		}

		CreateNameTag(imGUI.getFooter());
		CreateBackground(imGUI.getFooter());
	}else if(token == "drika_dialogue_set_voice"){
		token_iter.FindNextToken(msg);
		string actor_name = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int voice = atoi(token_iter.GetToken(msg));
		bool settings_found = false;

		for(uint i = 0; i < actor_settings.size(); i++){
			if(actor_settings[i].name == actor_name){
				settings_found = true;
				actor_settings[i].voice = voice;
				break;
			}
		}

		if(!settings_found){
			ActorSettings new_settings();
			new_settings.name = actor_name;
			new_settings.voice = voice;
			actor_settings.insertLast(@new_settings);
		}
	}else if(token == "drika_dialogue_test_voice"){
		token_iter.FindNextToken(msg);
		int test_voice = atoi(token_iter.GetToken(msg));
		PlayLineContinueSound(test_voice);
	}else if(token == "drika_dialogue_skip"){
		PlayLineStartSound();
	}
}

void Update(){
	imGUI.update();
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	if(animating_camera){
		return true;
	}else{
		return false;
	}
}

void PlayLineContinueSound(int test_voice = -1) {
    switch(test_voice == -1?current_actor_settings.voice:test_voice){
        case 0: PlaySoundGroup("Data/Sounds/concrete_foley/fs_light_concrete_edgecrawl.xml"); break;
        case 1: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_light_drygrass_crouchwalk.xml"); break;
        case 2: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_fabric_crouchwalk.xml"); break;
        case 3: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_light_dirtyrock_crouchwalk.xml"); break;
        case 4: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_leather_crouchwalk.xml"); break;
        case 5: PlaySoundGroup("Data/Sounds/grass_foley/fs_light_grass_run.xml", 0.5); break;
        case 6: PlaySoundGroup("Data/Sounds/gravel_foley/fs_light_gravel_crouchwalk.xml"); break;
        case 7: PlaySoundGroup("Data/Sounds/sand_foley/fs_light_sand_crouchwalk.xml", 0.7); break;
        case 8: PlaySoundGroup("Data/Sounds/snow_foley/fs_light_snow_run.xml", 0.5); break;
        case 9: PlaySoundGroup("Data/Sounds/wood_foley/fs_light_wood_crouchwalk.xml", 0.4); break;
        case 10: PlaySoundGroup("Data/Sounds/water_foley/mud_fs_walk.xml", 0.4); break;
        case 11: PlaySoundGroup("Data/Sounds/concrete_foley/fs_heavy_concrete_walk.xml", 0.5); break;
        case 12: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_heavy_drygrass_walk.xml", 0.4); break;
        case 13: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_heavy_dirtyrock_walk.xml", 0.5); break;
        case 14: PlaySoundGroup("Data/Sounds/grass_foley/fs_heavy_grass_walk.xml", 0.3); break;
        case 15: PlaySoundGroup("Data/Sounds/gravel_foley/fs_heavy_gravel_walk.xml", 0.3); break;
        case 16: PlaySoundGroup("Data/Sounds/sand_foley/fs_heavy_sand_run.xml", 0.3); break;
        case 17: PlaySoundGroup("Data/Sounds/snow_foley/fs_heavy_snow_crouchwalk.xml", 0.3); break;
        case 18: PlaySoundGroup("Data/Sounds/wood_foley/fs_heavy_wood_walk.xml", 0.3); break;
    }
}

void PlayLineStartSound() {
	switch(current_actor_settings.voice){
		case 0: PlaySoundGroup("Data/Sounds/concrete_foley/fs_light_concrete_run.xml"); break;
		case 1: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_light_drygrass_walk.xml"); break;
		case 2: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_fabric_choke_move.xml"); break;
		case 3: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_light_dirtyrock_run.xml"); break;
		case 4: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_leather_choke_move.xml"); break;
		case 5: PlaySoundGroup("Data/Sounds/grass_foley/bf_grass_medium.xml", 0.5); break;
		case 6: PlaySoundGroup("Data/Sounds/gravel_foley/fs_light_gravel_run.xml"); break;
		case 7: PlaySoundGroup("Data/Sounds/sand_foley/fs_light_sand_run.xml", 0.7); break;
		case 8: PlaySoundGroup("Data/Sounds/snow_foley/bf_snow_light.xml", 0.5); break;
		case 9: PlaySoundGroup("Data/Sounds/wood_foley/fs_light_wood_run.xml", 0.4); break;
		case 10: PlaySoundGroup("Data/Sounds/water_foley/mud_fs_run.xml", 0.4); break;
		case 11: PlaySoundGroup("Data/Sounds/concrete_foley/fs_heavy_concrete_run.xml", 0.5); break;
		case 12: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_heavy_drygrass_run.xml", 0.4); break;
		case 13: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_heavy_dirtyrock_run.xml", 0.5); break;
		case 14: PlaySoundGroup("Data/Sounds/grass_foley/fs_heavy_grass_run.xml", 0.3); break;
		case 15: PlaySoundGroup("Data/Sounds/gravel_foley/fs_heavy_gravel_run.xml", 0.3); break;
		case 16: PlaySoundGroup("Data/Sounds/sand_foley/fs_heavy_sand_jump.xml", 0.3); break;
		case 17: PlaySoundGroup("Data/Sounds/snow_foley/fs_heavy_snow_jump.xml", 0.3); break;
		case 18: PlaySoundGroup("Data/Sounds/wood_foley/fs_heavy_wood_run.xml", 0.3); break;
	}
}
