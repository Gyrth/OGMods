bool resetting = false;
bool animating_camera = false;
bool has_camera_control = false;
bool showing_interactive_ui = false;
bool show_dialogue = false;
array<string> hotspot_ids;
IMGUI@ imGUI;
FontSetup name_font_arial("arial", 70 , HexColor("#CCCCCC"), true);
FontSetup name_font("edosz", 70 , HexColor("#CCCCCC"), true);
FontSetup dialogue_font("Kenney Mini Square", 80 , HexColor("#000000"), false);
FontSetup controls_font("arial", 45 , HexColor("#616161"), true);
FontSetup red_dialogue_font("arial", 50 , HexColor("#990000"), true);
FontSetup green_dialogue_font("arial", 50 , HexColor("#009900"), true);
FontSetup blue_dialogue_font("arial", 50 , HexColor("#000099"), true);
FontSetup death_font_arial("Lato-Regular", 70 , HexColor("#CCCCCC"), true);
vec3 camera_position;
vec3 camera_rotation;
float camera_zoom = 90.0f;
bool fading = false;
float blackout_amount = 0.0;
float starting_fade_amount = 0.0;
float fade_direction = 1.0;
float fade_duration = 0.25;
float fade_timer = 0.0;
float target_fade_to_black = 1.0;
float fade_to_black_duration = 1.0;
bool fade_to_black = false;
array<int> waiting_hotspot_ids;
int dialogue_layout = 0;
bool use_voice_sounds = true;
bool show_names = true;
int ui_hotspot_id = -1;
float camera_near_blur = 0.0;
float camera_near_dist = 0.0;
float camera_near_transition = 0.0;
float camera_far_blur = 0.0;
float camera_far_dist = 0.0;
float camera_far_transition = 0.0;
bool update_dof = false;
bool enable_look_at_target = false;
bool enable_move_with_target = false;
int look_at_target_id = -1;
int move_with_target_id = -1;
vec3 target_positional_difference = vec3();
vec3 current_camera_position = vec3();
bool camera_settings_changed = false;
vec2 dialogue_size = vec2(2560, 450);
IMText@ lmb_continue;
IMText@ rtn_skip;
vec3 old_camera_translation;
vec3 old_camera_rotation;
bool show_avatar;
bool add_camera_shake = false;
float position_shake_max_distance;
float position_shake_slerp_speed;
float position_shake_interval;
float rotation_shake_max_distance;
float rotation_shake_slerp_speed;
float rotation_shake_interval;

vec3 camera_shake_position;
vec3 camera_shake_rotation;
float rotation_shake_timer;
vec3 new_camera_shake_rotation;
float position_shake_timer;
vec3 new_camera_shake_position;

FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);
IMContainer@ dialogue_container;
IMContainer@ dialogue_ui_container;
IMContainer@ image_container;
IMContainer@ text_container;
IMContainer@ grabber_container;
IMContainer@ death_container;
IMContainer@ death_ui_container;
array<IMText@> dialogue_texts;
array<string> split_dialogue;
IMImage@ continue_icon;
/* string dialogue_string = "I have to get out of here. As soon as possible. \n I have to get out of here. As soon as possible. \n I have to get out of here. As soon as possible."; */
string dialogue_string = "I have to get out of here. \n I have to get out of here. \n I have to get out of here.";
float dialogue_progress = 0.0f;
float last_sound_time = 0.0f;
int dialogue_array_index = 0;
bool dialogue_done = true;
bool editing_ui = false;
array<IMText@> text_elements;
bool grabber_dragging = false;
vec2 click_position;
bool show_grid = false;
bool post_init_done = false;
bool read_animation_list = false;
bool added_death_screen = false;
string defeat_sting = "Data/Music/slaver_loop/the_slavers_defeat.wav";
float ko_time;
bool checkpoint_fading = false;
float checkpoint_blackout_amount = 0.0f;
float checkpoint_fade_timer = 0.0f;
float checkpoint_fade_duration = 0.25f;
float checkpoint_fade_direction = 1.0f;

string in_combat_song = "";
bool in_combat_from_beginning_no_fade = false;
string player_died_song = "";
bool player_died_from_beginning_no_fade = false;
string enemies_defeated_song = "";
bool enemies_defeated_from_beginning_no_fade = false;
string ambient_song = "";
bool ambient_from_beginning_no_fade = false;
string current_song = "None";
bool take_player_controls = false;
float PI = 3.14159265359f;

bool ui_created = false;
string current_actor_name = "Default";
bool show_editor = true;
TextureAssetRef imgui_image = LoadTexture("Data/Textures/HEROS/spritesheets/adventurer_idle_down.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |
TextureLoadFlags_NoReduce);

// Coloring options
vec4 background_color();
vec4 titlebar_color();
vec4 item_background();
vec4 item_hovered();
vec4 item_clicked();
vec4 text_color();
vec4 transparent(0.0f);

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef loading_texture = LoadTexture("Data/Images/spawner_loading.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
array<GUISpawnerItem@> all_items;
array<GUISpawnerCategory@> categories;
array<string> thumbnail_object_paths;
array<string> thumbnail_image_paths;
bool show = true;
int voice_preview = 1;
bool select = false;
int icon_size = 100;
int new_icon_size = 100;
int title_height = 23;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
bool spawn = false;
bool retrieved_item_list = false;
vec3 spawn_position;
int currently_selected = -1;
string load_item_path = "";
int placeholder_id = -1;
float spawn_height_offset = 0.0;
bool steal_focus = false;
string input_query;
int set_position = -1;
int spawn_id = -1;
int load_wait_counter = 0;
bool allow_animated_thumbnail = true;
int thumbnailed_counter = 0;
int max_thumbnailed_per_draw = 5;
array<string> dialogue_queue = {};


enum dialogue_states{
	DIALOGUE_NONE,
	DIALOGUE_ADDING,
	DIALOGUE_WAIT_INPUT
}

dialogue_states dialogue_state = DIALOGUE_NONE;

class GUISpawnerCategory{
	string category_name;
	array<GUISpawnerItem@> spawner_items;
	GUISpawnerCategory(string _category_name){
		category_name = _category_name;
	}
	void AddItem(GUISpawnerItem@ item){
		spawner_items.insertLast(item);
	}
}

class GUISpawnerItem{
	string title;
	string category;
	string path;
	int id;
	TextureAssetRef icon;
	SpawnerItem spawner_item;
	bool has_thumbnail = false;
	bool animated_thumbnail = false;
	array<TextureAssetRef> anims;
	int thumbnail_index = 0;
	float thumbnail_update_timer;
	string thumbnail_path = "";
	vec2 thumbnail_size = vec2(32.0f, 32.0f);

	GUISpawnerItem(string _category, string _path, int _id, TextureAssetRef _icon){
		category = _category;
		icon = _icon;
		path = _path;
		id = _id;

		array<string> split_path = path.split("/");
		title = split_path[split_path.size() - 1];
	}

	void SetThumbnail(){
		string data;
		bool two_letter_orientation = false;
		bool one_letter_orientation = false;

		if(LoadFile(path)){
			while(true){
				string line = GetFileLine();
				if(line == "end"){
					break;
				}else{
					data += line + "\n";
				}
			}

			//Remove all spaces to eliminate style differences.
			string xml_content = join(data.split(" "), "");
			//The target is an env_object, so just use that as the placeholder object.
			string color_map = GetStringBetween(xml_content, "<ColorMap>", "</ColorMap>");
			if(color_map != ""){
				thumbnail_path = color_map;
			}
		}else{
			Log(error, "Error loading file: " + path);
		}

		if(one_letter_orientation){
			//First check for two letter orientation thumbnails.
			string anim_path = thumbnail_path.substr(0, thumbnail_path.length() - 6);

			array<string> extentions = {"_N.png", "_E.png", "_S.png", "_W.png"};
			for(uint i = 0; i < extentions.size(); i++){
				if(!FileExists(anim_path + extentions[i])){
					/* Log(warning, "Does not exist " + anim_path + extentions[i]); */
					break;
				}

				TextureAssetRef image = LoadTexture(anim_path + extentions[i], TextureLoadFlags_NoLiveUpdate);
				if(!image.IsValid()){
					continue;
				}
				anims.insertLast(image);
			}

			if(anims.size() > 0){
				icon = anims[0];
				animated_thumbnail = true;
				has_thumbnail = true;
				return;
			}
		}else if(two_letter_orientation){
			string anim_path = thumbnail_path.substr(0, thumbnail_path.length() - 7);

			array<string> extentions = {"_SE.png", "_SW.png", "_NW.png", "_NE.png"};
			for(uint i = 0; i < extentions.size(); i++){
				if(!FileExists(anim_path + extentions[i])){
					/* Log(warning, "Does not exist " + anim_path + extentions[i]); */
					break;
				}

				TextureAssetRef image = LoadTexture(anim_path + extentions[i], TextureLoadFlags_NoLiveUpdate);
				if(!image.IsValid()){
					continue;
				}
				anims.insertLast(image);
			}

			if(anims.size() > 0){
				icon = anims[0];
				animated_thumbnail = true;
				has_thumbnail = true;
				return;
			}
		}

		//If no thumbnail was set, use the default one.
		if(!DatabaseThumbnailSearch()){
			if(thumbnail_path != "" && FileExists(thumbnail_path)){
				icon = LoadTexture(thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
				HUDImage @image = hud.AddImage();
				image.SetImageFromPath(thumbnail_path);
				thumbnail_size = vec2(image.GetWidth(), image.GetHeight());
				/* Log(warning, "thumbnail_size " + thumbnail_size.x + " " + thumbnail_size.y); */
			}
		}
		has_thumbnail = true;
	}

	void ClearThumbnail(){
		for(uint i = 0; i < anims.size(); i++){
			anims[i].Clear();
		}
		anims.resize(0);
		icon = default_texture;
		has_thumbnail = false;
	}

	void UpdateThumbnailAnimation(){
		if(ui_time - thumbnail_update_timer > 0.5f){
			thumbnail_update_timer = ui_time;

			if(thumbnail_index >= int(anims.size())){
				thumbnail_index = 0;
			}

			if(int(anims.size()) > thumbnail_index){
				icon = anims[thumbnail_index];
				thumbnail_index++;
			}else{
				thumbnail_index = 0;
			}
		}
	}

	bool DatabaseThumbnailSearch(){
		for(uint i = 0; i < thumbnail_object_paths.size(); i++){
			if(thumbnail_object_paths[i] == path && FileExists(thumbnail_image_paths[i])){
				icon = LoadTexture(thumbnail_image_paths[i], TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
				return true;
			}
		}
		return false;
	}

	void SetSpawnerItem(SpawnerItem _spawner_item){
		spawner_item = _spawner_item;
	}

	void DrawItem(){
		if(currently_selected == id){
			ImGui_PushStyleColor(ImGuiCol_ChildBg, item_clicked);
		}else{
			ImGui_PushStyleColor(ImGuiCol_ChildBg, item_background);
		}

		ImGui_BeginChild(id + "button", vec2(icon_size + 15.0f, icon_size + title_height + 20.0f), true, ImGuiWindowFlags_NoScrollWithMouse);
		ImGui_Indent((title_height / 2.0f) - (padding / 2.0f));
		ImGui_AlignTextToFramePadding();
		ImGui_Text(title);
		ImGui_Unindent((title_height / 2.0f) - (padding / 2.0f));
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
		/* bool ImGui_ImageButton(const TextureAssetRef &in texture, const vec2 &in size, const vec2 &in uv0 = vec2(0,0), const vec2 &in uv1 = vec2(1,1), int frame_padding = -1, const vec4 &in background_color = vec4(0,0,0,0), const vec4 &in tint_color = vec4(1,1,1,1)); */

		if(ImGui_ImageButton(icon, vec2(icon_size, icon_size), vec2(0,0), vec2(1.0 / (thumbnail_size.x / 32.0f),1), 0, vec4(0,0,0,0), vec4(1,1,1,1))){
			if(currently_selected == id){
				ClearSpawnSettings();
			}else{
				currently_selected = id;
				SetSpawnSettings(path);
			}
		}
		ImGui_PopStyleColor(2);

		ImGui_EndChild();

		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip(title);
			ImGui_PopStyleColor();
		}

		if(thumbnailed_counter < max_thumbnailed_per_draw && !has_thumbnail && ImGui_IsItemVisible()){
			SetThumbnail();
			thumbnailed_counter++;
		}else if(has_thumbnail && !ImGui_IsItemVisible()){
			ClearThumbnail();
		}
	}
}

void Init(string str){
	@imGUI = CreateIMGUI();
	@dialogue_container = IMContainer(2560, 1440);
	@image_container = IMContainer(2560, 1440);
	@text_container = IMContainer(2560, 1440);
	@grabber_container = IMContainer(2560, 1440);
	@death_container = IMContainer(2560, 1440);
	CreateIMGUIContainers();
	LoadPalette();
	AddMusic("Data/Music/therium_advance_music.xml");
	SetSong("Adventure");
}

void AddDialogueUI(){
	dialogue_progress = 0.0f;
	dialogue_array_index = 0;
	dialogue_done = false;
	dialogue_texts.resize(0);

	bool use_keyboard = (max(last_mouse_event_time, last_keyboard_event_time) > last_controller_event_time);
	dialogue_container.clear();
	@dialogue_ui_container = IMContainer(2560, 400);
	/* dialogue_ui_container.showBorder(); */
	dialogue_container.setAlignment(CACenter, CABottom);
	dialogue_container.setElement(dialogue_ui_container);
	dialogue_container.setSize(vec2(2560, 1440));

	IMContainer text_container(0.0, 250.0);

	IMDivider text_divider("text_divider", DOHorizontal);
	/* text_divider.showBorder(); */
	text_divider.setZOrdering(2);
	text_divider.setAlignment(CALeft, CACenter);
	text_container.setElement(text_divider);

	IMDivider text_vert("text_vert", DOVertical);
	text_vert.setZOrdering(2);
	text_vert.setAlignment(CALeft, CACenter);

	text_divider.appendSpacer(300.0);
	text_divider.append(text_vert);
	text_divider.appendSpacer(300.0);

	IMImage text_background("Textures/UI/buttonLong_grey.png");
	text_background.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");
	text_background.setClip(false);
	text_background.setColor(vec4(1.0, 0.65, 1.0, 0.97));
	dialogue_ui_container.setElement(text_container);
	text_background.setVisible(false);

	split_dialogue = dialogue_string.split("\\n");

	for(uint i = 0; i < split_dialogue.size(); i++){
		IMText @dialogue_text = IMText(split_dialogue[i], dialogue_font);
		dialogue_text.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");
		/* dialogue_text.showBorder(); */
		text_vert.append(dialogue_text);
		dialogue_text.setVisible(false);
		dialogue_texts.insertLast(dialogue_text);
	}

	imGUI.update();

	float added_height = 100.0f;
	text_background.setSize(text_container.getSize() + vec2(0.0, added_height));
	text_container.addFloatingElement(text_background, "text_background", vec2(0, -(added_height / 2.0)), 1);
	text_background.setZOrdering(1);

	IMImage avatar("Textures/ghost_avatar.png");
	avatar.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");
	avatar.setClip(false);
	avatar.setColor(vec4(1.0, 1.0, 1.0, 0.97));
	avatar.scaleToSizeX(350.0f);
	avatar.setZOrdering(2);
	text_container.addFloatingElement(avatar, "avatar", vec2(0.0f, 0.0f -(added_height / 2.0)), 1);

	imGUI.update();

	@continue_icon = IMImage("Textures/UI/arrowBlack_down.png");
	continue_icon.setColor(vec4(1.0, 1.0, 1.0, 0.97));
	continue_icon.scaleToSizeX(50.0f);
	continue_icon.setZOrdering(2);
	text_container.addFloatingElement(continue_icon, "continue_icon", vec2(text_container.getSize().x - 175.0f, 150.0f -(added_height / 2.0)), 1);
	continue_icon.addUpdateBehavior(IMPulseAlpha(0.0, 1.0, 1.0), "pulse");
	continue_icon.setVisible(false);

	text_background.setVisible(true);

	for(uint i = 0; i < dialogue_texts.size(); i++){
		dialogue_texts[i].setText("");
		dialogue_texts[i].setVisible(true);
	}
}

void LoadPalette(bool use_defaults = false){
	JSON data;
	JSONValue root;

	if(!data.parseFile("Data/Scripts/therium_advance_default_palette.json")){
		Log(warning, "Error loading the default palette.");
		return;
	}

	root = data.getRoot();
	JSONValue ui_palette = root["UI Palette"];

	JSONValue bg_color = ui_palette["Background Color"];
	background_color = vec4(bg_color[0].asFloat(), bg_color[1].asFloat(), bg_color[2].asFloat(), bg_color[3].asFloat());

	JSONValue tb_color = ui_palette["Titlebar Color"];
	titlebar_color = vec4(tb_color[0].asFloat(), tb_color[1].asFloat(), tb_color[2].asFloat(), tb_color[3].asFloat());

	JSONValue ib_color = ui_palette["Item Background"];
	item_background = vec4(ib_color[0].asFloat(), ib_color[1].asFloat(), ib_color[2].asFloat(), ib_color[3].asFloat());

	JSONValue ih_color = ui_palette["Item Hovered"];
	item_hovered = vec4(ih_color[0].asFloat(), ih_color[1].asFloat(), ih_color[2].asFloat(), ih_color[3].asFloat());

	JSONValue ic_color = ui_palette["Item Clicked"];
	item_clicked = vec4(ic_color[0].asFloat(), ic_color[1].asFloat(), ic_color[2].asFloat(), ic_color[3].asFloat());

	JSONValue t_color = ui_palette["Text Color"];
	text_color = vec4(t_color[0].asFloat(), t_color[1].asFloat(), t_color[2].asFloat(), t_color[3].asFloat());
}

void CreateIMGUIContainers(){
	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	/* imGUI.getMain().showBorder(); */
	imGUI.getMain().setZOrdering(-1);

	imGUI.getMain().addFloatingElement(dialogue_container, "dialogue_container", vec2(0));
	imGUI.getMain().addFloatingElement(image_container, "image_container", vec2(0));
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));
	imGUI.getMain().addFloatingElement(grabber_container, "grabber_container", vec2(0));
	imGUI.getMain().addFloatingElement(death_container, "death_container", vec2(0));
}

void SetWindowDimensions(int width, int height){
	imGUI.doScreenResize();
}

void PostScriptReload(){

}

void DrawMouseBlockContainer(){
	ImGui_PushStyleColor(ImGuiCol_WindowBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
	ImGui_Begin("MouseBlockContainer", editing_ui, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBringToFrontOnFocus);
	ImGui_PopStyleColor(1);
	ImGui_SetWindowPos("MouseBlockContainer", vec2(0,0));
	ImGui_SetWindowSize("MouseBlockContainer", vec2(GetScreenWidth(), GetScreenHeight()));
	ImGui_End();
}

int ui_snap_scale = 20;

void DrawGrid(){
	if(!show_grid){
		return;
	}
	vec2 vertical_position = vec2(0.0, 0.0);
	vec2 horizontal_position = vec2(0.0, 0.0);
	int nr_horizontal_lines = int(ceil(screenMetrics.screenSize.y / (ui_snap_scale * screenMetrics.GUItoScreenYScale)));
	int nr_vertical_lines = int(ceil(screenMetrics.screenSize.x / (ui_snap_scale * screenMetrics.GUItoScreenXScale))) + 1;
	vec4 line_color = vec4(0.25, 0.25, 0.25, 1.0);
	float line_width = 1.0;
	float thick_line_width = 3.0;

	for(int i = 0; i < nr_vertical_lines; i++){
		bool thick_line = i % 10 == 0;

		imGUI.drawBox(vertical_position, vec2(thick_line?thick_line_width:line_width, screenMetrics.screenSize.y), line_color, 0, false);
		vertical_position += vec2((ui_snap_scale * screenMetrics.GUItoScreenXScale), 0.0);
	}

	for(int i = 0; i < nr_horizontal_lines; i++){
		bool thick_line = i % 10 == 0;
		imGUI.drawBox(horizontal_position, vec2(screenMetrics.screenSize.x, thick_line?thick_line_width:line_width), line_color, 0, false);
		horizontal_position += vec2(0.0, (ui_snap_scale * screenMetrics.GUItoScreenYScale));
	}
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);

	/* Log(warning, token); */
	if(token == "reset"){
		dialogue_queue.resize(0);
		dialogue_state = DIALOGUE_NONE;
		resetting = true;
	}else if(token == "ta_take_player_controls"){
		token_iter.FindNextToken(msg);
		take_player_controls = token_iter.GetToken(msg) == "true";
	}else if(token == "ta"){
		token_iter.FindNextToken(msg);
		string command = token_iter.GetToken(msg);

		if(command == "dialogue"){
			string text;
			while(token_iter.FindNextToken(msg)){
				text += " " + token_iter.GetToken(msg);
			}

			dialogue_queue.insertLast(text);

			/* Log(warning, text); */
		}

	}
}

void Update(int paused){
	if(!post_init_done){
		PostInit();
	}

	if(resetting){
		PostReset();
		resetting = false;
	}

	UpdateDialogue();

	if(EditorModeActive()){
		UpdatePlaceholder();
		if(show && spawn){
			if(spawn && GetInputPressed(0, "mouse0")){
				if(GetInputPressed(0, "mouse0")){
					SpawnObject(load_item_path);
					ClearSpawnSettings();
				}
			}

			if(GetInputDown(0, "pageup")){
				spawn_height_offset += time_step;
			}else if(GetInputDown(0, "pagedown")){
				spawn_height_offset -= time_step;
			}else if(GetInputDown(0, "q")){
				ClearSpawnSettings();
			}
		}

		if(show && !retrieved_item_list){
			//To be able to show the Loading... image we need to wait a couple of updates.
			if(load_wait_counter > 5){
				/* LoadThumbnailDatabase(); */
				GetAllSpawnerItems();
				categories = SortIntoCategories(QuerySpawnerItems(""));
				retrieved_item_list = true;
			}
			load_wait_counter++;
		}

		if(GetInputPressed(0, "i")){
			show = !show;
			SetPlaceholderVisible(show);
		}

		//Sometimes OG sets the scale, rot and pos to 0.0f when loading images.
		//So keep setting it to the correct values if it's not. For 50 updates.
		if(set_position > 0){
			set_position -= 1;
			Object@ obj = ReadObjectFromID(spawn_id);
			if(obj.GetScale() == vec3()){
				obj.SetScale(vec3(1.0f));
				obj.SetTranslation(spawn_position + vec3(0, spawn_height_offset, 0));
			}
		}else if(set_position == 0){
			set_position -= 1;
		}

	}else if(show){
		show = false;
	}

	array<int> selected = GetSelected();
	for(uint i = 0; i < selected.size(); i++){
		if(!GetInputDown(0, "attack") && !GetInputDown(0, "grab")){
			Object@ obj = ReadObjectFromID(selected[i]);
			vec3 translation = obj.GetTranslation();

			float flo_x = floor(translation.x);
			float dec_x = translation.x - flo_x;
			translation.x = dec_x > 0.5 ? ceil(translation.x) : floor(translation.x);

			float mult = 5.0f;
			float flo_y = floor(translation.y * mult);
			float dec_y = (translation.y * mult) - flo_y;
			translation.y = (dec_y > 0.5 ? ceil(translation.y * mult) : floor(translation.y * mult)) / mult;

			float flo_z = floor(translation.z);
			float dec_z = translation.z - flo_z;
			translation.z = dec_z > 0.5 ? ceil(translation.z) : floor(translation.z);

			obj.SetTranslation(translation);
		}
	}

	imGUI.update();
}

void UpdateDialogue(){

	switch(dialogue_state) {
		case DIALOGUE_NONE:
			if(dialogue_queue.size() > 0){
				dialogue_string = dialogue_queue[dialogue_queue.size() - 1];
				AddDialogueUI();
				dialogue_state = DIALOGUE_ADDING;
				dialogue_queue.removeAt(dialogue_queue.size() - 1);
				TakePlayerControl();
			}
			break;
		case DIALOGUE_ADDING:{
			float dialogue_string_length = split_dialogue[dialogue_array_index].length();
			dialogue_progress = min(1.0, dialogue_progress + (time_step / dialogue_string_length * 20.0f));

			if(dialogue_progress <= 1.0){
				string dialogue_substring = split_dialogue[dialogue_array_index].substr(0, int(dialogue_progress * dialogue_string_length));
				dialogue_texts[dialogue_array_index].setText(dialogue_substring);

				if(last_sound_time < the_time){
					string path;

					switch(rand() % 2) {
						case 0:
						path = "Data/Sounds/tick_002.wav"; break;
						default:
						path = "Data/Sounds/tick_001.wav"; break;
					}

					int sound_id = PlaySound(path);
					SetSoundPitch(sound_id, RangedRandomFloat(0.5f, 2.0f));
					last_sound_time = the_time + 0.1f;
				}

				if(dialogue_progress == 1.0){
					if(dialogue_array_index < int(dialogue_texts.size() - 1)){
						dialogue_array_index += 1;
						dialogue_progress = 0.0f;
					}else if(dialogue_done == false){
						continue_icon.setVisible(true);
						dialogue_done = true;
						dialogue_state = DIALOGUE_WAIT_INPUT;
					}
				}
			}

			break;}
		case DIALOGUE_WAIT_INPUT:
			if(GetInputPressed(0, "attack")){
				dialogue_container.clear();
				dialogue_state = DIALOGUE_NONE;
				ReleasePlayerControl();
			}
			break;
		default:
			Log(error, "Dialogue Error");
			break;
	}
}

void DrawGUI(){
	imGUI.render();

	if(show){
		thumbnailed_counter = 0;

		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_Text, text_color);
		ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, transparent);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_CloseButton, background_color);
		ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(550,450));
		ImGui_Begin("Top Down 2D Editor", show, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar(1);

		if(steal_focus){
			steal_focus = false;
			ImGui_SetNextWindowFocus();
		}

		if(ImGui_BeginMenuBar()){
			if(ImGui_Button("Load File")){
				string path = GetUserPickedReadPath("xml", "Data/Objects");
				if(path != ""){
					SetSpawnSettings(path);
				}
			}

			if(ImGui_BeginMenu("Settings")){
				if(ImGui_DragInt("Icon Size", new_icon_size, 1.0, 75, 500, "%.0f")){
					icon_size = min(500, max(75, new_icon_size));
				}

				ImGui_EndMenu();
			}

			ImGui_EndMenuBar();
		}

		ImGui_BeginChild("FirstBar", vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar);

		ImGui_SameLine();
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Search : ");
		ImGui_SameLine();
		ImGui_PushItemWidth(ImGui_GetWindowWidth() - 225);
		ImGui_SetTextBuf(input_query);
		if(ImGui_InputText("##Search", ImGuiInputTextFlags_AutoSelectAll)){
			input_query = ImGui_GetTextBuf();
			categories = SortIntoCategories(QuerySpawnerItems(input_query));
		}
		ImGui_SameLine();
		if(ImGui_Button("Clear")){
			input_query = "";
			categories = SortIntoCategories(QuerySpawnerItems(input_query));
		}

		ImGui_EndChild();

		ImGui_PushStyleColor(ImGuiCol_FrameBg, transparent);
		if(!retrieved_item_list){
			float image_width = ImGui_GetContentRegionAvailWidth();
			ImGui_Image(loading_texture, vec2(image_width, image_width / 2.0f), vec2(0,0), vec2(1,1), vec4(1.0f, 1.0f, 1.0f, 0.15f));
		}else{
			if(!ImGui_IsWindowCollapsed()){
				if(ImGui_BeginChildFrame(55, vec2(-1, -1), ImGuiWindowFlags_AlwaysAutoResize)){
					for(uint i = 0; i < categories.size(); i++){
						AddCategory(categories[i]);
					}
					ImGui_EndChildFrame();
				}
			}
		}

		ImGui_End();
		ImGui_PopStyleColor(19);
	}
}


array<GUISpawnerCategory@> SortIntoCategories(array<GUISpawnerItem@> unsorted){
	array<GUISpawnerCategory@> sorted;
	for(uint i = 0; i < unsorted.size(); i++){
		int category_index = -1;
		for(uint j = 0; j < sorted.size(); j++){
			if (sorted[j].category_name == unsorted[i].category){
				category_index = j;
			}
		}

		if(category_index == -1){
			GUISpawnerCategory new_category(unsorted[i].category);
			new_category.AddItem(unsorted[i]);
			sorted.insertLast(new_category);
		}else{
			sorted[category_index].AddItem(unsorted[i]);
		}
	}
	return sorted;
}

void ClearSpawnSettings(){
	load_item_path = "";
	currently_selected = -1;
	spawn = false;
	SetPlaceholderVisible(false);
}

void SetSpawnSettings(string path){
	load_item_path = path;
	SetPlaceholderModel();
	spawn = true;
	SetPlaceholderVisible(true);
}


array<GUISpawnerItem@> QuerySpawnerItems(string query){
	array<GUISpawnerItem@> new_list;
	//If the query is empty then just return the whole database.
	if(query == ""){
		new_list = all_items;
	}else{
		//The query can be multiple words separated by spaces.
		array<string> split_query = query.split(" ");
		for(uint i = 0; i < all_items.size(); i++){
			string item_name = ToLowerCase(all_items[i].title);
			string category_name = ToLowerCase(all_items[i].category);
			bool found_result = true;

			for(uint j = 0; j < split_query.size(); j++){
				//Could not find part of query in the database.
				string query_part = ToLowerCase(split_query[j]);
				if(item_name.findFirst(query_part) == -1 && category_name.findFirst(query_part) == -1){
					found_result = false;
					break;
				}
			}
			//Only if all parts of the query are found then add the result.
			if(found_result){
				new_list.insertLast(all_items[i]);
			}
		}
	}
	return new_list;
}

void AddCategory(GUISpawnerCategory@ category){
	if(category.spawner_items.size() < 1){
		return;
	}

	if(ImGui_TreeNodeEx(category.category_name + "(" + category.spawner_items.size() + ")", ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
		/* ImGui_Unindent(30.0f); */
		ImGui_BeginChild(category.category_name, vec2(ImGui_GetWindowWidth(), icon_size + title_height + 20.0f), false, ImGuiWindowFlags_NoScrollWithMouse);
		float row_size = 0.0f;
		for(uint i = 0; i < category.spawner_items.size(); i++){
			row_size += icon_size + padding + 15.0f;
			if(row_size > ImGui_GetWindowWidth()){
				row_size = icon_size + padding;
				ImGui_EndChild();
				ImGui_BeginChild("child " + i, vec2(ImGui_GetWindowWidth(), icon_size + title_height + 20.0f), false, ImGuiWindowFlags_NoScrollWithMouse);
			}
			ImGui_SameLine();
			category.spawner_items[i].DrawItem();
		}
		ImGui_EndChild();
		/* ImGui_Indent(30.0f); */
		/* ImGui_TreePop(); */
	}
}

string ToLowerCase(string input){
	string output;
	for(uint i = 0; i < input.length(); i++){
		if(input[i] >= 65 &&  input[i] <= 90){
			string lower_case('0');
			lower_case[0] = input[i] + 32;
			output += lower_case;
		}else{
			string new_character('0');
			new_character[0] = input[i];
			output += new_character;
		}
	}
	return output;
}

void PostInit(){
	post_init_done = true;
}

void PostReset(){
	dialogue_container.clear();
	added_death_screen = false;
}

bool HasFocus(){
	return ((showing_interactive_ui) && !EditorModeActive())?true:false;
}

bool DialogueCameraControl() {
	if((animating_camera || has_camera_control) && !EditorModeActive()){
		return true;
	}else{
		return false;
	}
}


void SetPlaceholderModel(){
	if(!FileExists(load_item_path)){
		Object@ placeholder_box = ReadObjectFromID(placeholder_id);
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder_box);
		placeholder_object.SetPreview("");
		return;
	}

	string placeholder_path = GetObjectPath(load_item_path);
	Log(warning, "placeholder_path " + placeholder_path);
	Object@ placeholder_box = ReadObjectFromID(placeholder_id);
	PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder_box);
	placeholder_object.SetPreview(placeholder_path);
}



void SetPlaceholderVisible(bool visible){
	Object@ placeholder_object = ReadObjectFromID(placeholder_id);
	placeholder_object.SetTranslation(vec3(0,-1000,0));
	placeholder_object.SetEnabled(visible);
}


string GetObjectPath(string target_path){
	string object_path = "";
	string data;

	if(LoadFile(target_path)){
		while(true){
			string line = GetFileLine();
			if(line == "end"){
				break;
			}else{
				data += line + "\n";
			}
		}

		//Remove all spaces to eliminate style differences.
		string xml_content = join(data.split(" "), "");
		//The target is an env_object, so just use that as the placeholder object.
		if(GetStringBetween(xml_content, "<Model>", "</Model>") != ""){
			return target_path;
		}else{
			//Check if the target xml is an ItemObject or a Character.
			string obj_path = GetStringBetween(xml_content, "obj_path=\"", "\"");
			if(obj_path != ""){
				//Target is an ItemObject.
				return GetObjectPath(obj_path);
			}else{
				//Check if the target xml is an Actor.
				string actor_model = GetStringBetween(xml_content, "<Character>", "</Character>");
				if(actor_model != ""){
					return GetObjectPath(actor_model);
				}else{
					Log(warning, "Could not find model in " + target_path);
				}
			}
		}
	}else{
		Log(error, "Error loading file: " + target_path);
	}

	return object_path;
}



string GetStringBetween(string source, string first, string second){
	array<string> first_cut = source.split(first);
	if(first_cut.size() <= 1){
		return "";
	}
	array<string> second_cut = first_cut[1].split(second);

	if(second_cut.size() <= 1){
		return "";
	}
	return second_cut[0];
}


void UpdatePlaceholder(){
	if(placeholder_id == -1 || !ObjectExists(placeholder_id)){
		placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", true);
		Object@ obj = ReadObjectFromID(placeholder_id);
		obj.SetTint(vec3(1.0, 1.0, 1.0));
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
		placeholder_object.SetEditorDisplayName("SpawnPlaceholder");
		return;
	}else if(show && spawn){
		spawn_position = col.GetRayCollision(camera.GetPos(), camera.GetPos() + (camera.GetMouseRay() * 500.0f));
		Object@ placeholder_object = ReadObjectFromID(placeholder_id);
		placeholder_object.SetTranslation(spawn_position + vec3(0, spawn_height_offset, 0));
	}
}



void SpawnObject(string load_item_path){
	if(FileExists(load_item_path)){
		Log(warning, "Creating object " + load_item_path);
		spawn_id = CreateObject(load_item_path, false);
		Object@ obj = ReadObjectFromID(spawn_id);

		obj.SetCopyable(true);
		obj.SetSelectable(true);
		obj.SetTranslatable(true);
		obj.SetScalable(true);
		obj.SetRotatable(false);
		obj.SetDeletable(true);
		obj.SetTranslation(spawn_position + vec3(0, spawn_height_offset, 0));
		/* obj.SetRotation(quaternion(-0.7071068, 0, 0, 0.7071068)); */
		DeselectAll();
		obj.SetSelected(true);
		set_position = 50;
	}else{
		DisplayError("Error", "This xml file does not exist: " + load_item_path);
	}
}


void LoadThumbnailDatabase(){
	JSON file;
	file.parseFile("Data/Scripts/thumbnail_database.json");
	JSONValue root = file.getRoot();

	JSONValue thumbnail_list = root["item_list"];
	array<string> thumbnail_list_names = thumbnail_list.getMemberNames();

	for(uint i = 0; i < thumbnail_list_names.size(); i++){
		string thumbnail_object_path = thumbnail_list_names[i];
		thumbnail_object_paths.insertLast(thumbnail_object_path);
		thumbnail_image_paths.insertLast(thumbnail_list[thumbnail_object_path].asString());
	}
}

void GetAllSpawnerItems(){
	JSON file;
	file.parseFile("Data/Scripts/therium_advance_assets.json");
	JSONValue root = file.getRoot();

	JSONValue asset_list = root["Assets"];

	for(uint i = 0; i < asset_list.size(); i++){
		string assets_path = asset_list[i].asString();
		/* Log(warning, assets_path); */
		TextureAssetRef icon_texture = default_texture;

		GUISpawnerItem @new_item = GUISpawnerItem("Sprites", assets_path, i, icon_texture);
		all_items.insertLast(new_item);
	}
}

void TakePlayerControl(){
	if(!take_player_controls){return;}

	int character_amount = GetNumCharacters();

	for(int i = 0; i < character_amount; i++){
		MovementObject@ char = ReadCharacter(i);

		if(char.is_player){
			char.Execute("stop_controls = true;");
		}
	}
}

void ReleasePlayerControl(){
	if(!take_player_controls){return;}

	int character_amount = GetNumCharacters();

	for(int i = 0; i < character_amount; i++){
		MovementObject@ char = ReadCharacter(i);

		if(char.is_player){
			char.Execute("stop_controls = false;");
		}
	}
}