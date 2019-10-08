#include "comic_element.as"
#include "comic_fade_in.as"
#include "comic_font.as"
#include "comic_grabber.as"
#include "comic_image.as"
#include "comic_move_in.as"
#include "comic_page.as"
#include "comic_sound.as"
#include "comic_text.as"
#include "comic_wait_click.as"
#include "comic_crawl_in.as"
#include "comic_music.as"
#include "comic_song.as"
#include "music_load.as"

string level_name = "";
IMGUI@ imGUI;

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef duplicate_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Copy.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef delete_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Delete.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

string grid_background = "Textures/grid.png";
string black_background = "Textures/black.tga";
string default_image = "Textures/ui/menus/credits/overgrowth.png";
array<ComicElement@> comic_elements;
array<int> comic_indexes;
int grabber_size = 50;

enum environment_states { in_game, in_menu };
enum creator_states { editing, playing };
enum editing_states { edit_image };

environment_states environment_state;
creator_states creator_state = editing;
bool editor_open = creator_state == editing;

vec2 drag_position;
ComicGrabber@ current_grabber = null;
ComicFont@ current_font = null;
FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);
string comic_path;
uint image_layer = 0;
uint text_layer = 0;
uint grabber_layer = 2;

bool dragging = false;
bool unsaved = false;
bool at_correct_line = false;
int snap_scale = 20;
int target_line = 0;

int current_line = 0;
int element_counter = 0;
bool post_init_done = false;

IMContainer@ image_container;
IMContainer@ text_container;
IMContainer@ grabber_container;

// Coloring options
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

array<string> tween_types = {
								"linearTween",
							    "inQuadTween",
							    "outQuadTween",
							    "inOutQuadTween",
							    "outInQuadTween",
							    "inCubicTween",
							    "outCubicTween",
							    "inOutCubicTween",
							    "outInCubicTween",
							    "inQuartTween",
							    "outQuartTween",
							    "inOutQuartTween",
							    "outInQuartTween",
							    "inQuintTween",
							    "outQuintTween",
							    "inOutQuintTween",
							    "outInQuintTween",
							    "inSineTween",
							    "outSineTween",
							    "inOutSineTween",
							    "outInSineTween",
							    "inExpoTween",
							    "outExpoTween",
							    "inOutExpoTween",
							    "outInExpoTween",
							    "inCircTween",
							    "outCircTween",
							    "inOutCircTween",
							    "outInCircTween",
							    "outBounceTween",
							    "inBounceTween",
							    "inOutBounceTween",
    							"outInBounceTween"
							};

// This init is used when loaded from the main menu.
void Initialize(){
	environment_state = in_menu;
	ConvertDisplayColors();
	SortFunctionsAlphabetical();
	PlaySong("menu-lugaru");
	CreateComicUI();

	/* comic_path = "Data/Comics/example_in_menu.txt";
	LoadComic(comic_path); */

	string new_comic_path = GetInterlevelData("load_comic");
	if(new_comic_path != ""){
		creator_state = playing;
		editor_open = false;
		LoadComic(new_comic_path);
		SetInterlevelData("load_comic", "");
	}else{
		comic_path = "New Comic";
	}
	AddBackground();
}

// This init is used when loaded in-game.
void Init(string level_name){
	environment_state = in_game;
	editor_open = false;
	CreateComicUI();
}

void ConvertDisplayColors(){
	for(uint i = 0; i < display_colors.size(); i++){
		display_colors[i].x /= 255;
		display_colors[i].y /= 255;
		display_colors[i].z /= 255;
	}
}

void SortFunctionsAlphabetical(){
	//Remove empty function names.
	for(uint i = 0; i < comic_element_names.size(); i++){
		if(comic_element_names[i] == ""){
			comic_element_names.removeAt(i);
			i--;
		}
	}
	sorted_element_names = comic_element_names;
	sorted_element_names.sortAsc();
}

void Menu(){
	ImGui_Checkbox("Comic Creator", editor_open);
}

void CreateComicUI(){
	@imGUI = CreateIMGUI();
	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	imGUI.getMain().setZOrdering(-1);

	@image_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(image_container, "image_container", vec2(0));

	@text_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));

	@grabber_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(grabber_container, "grabber_container", vec2(0));
}

bool DialogueCameraControl(){
	return (editor_open || creator_state == playing);
}

string comic_content;
void LoadComic(string path){
	comic_content = "";
	comic_path = path;
	image_container.clear();
	text_container.clear();
	grabber_container.clear();
	@current_font = null;
	@current_grabber = null;
	comic_elements.resize(0);
	comic_indexes.resize(0);
	unsaved = false;
	current_line = 0;

	if(StorageHasInt32("progress_" + comic_path)){
		target_line = StorageGetInt32("progress_" + path);
	}

	if(LoadFile(path)){
		string new_line;
		while(true){
			new_line = GetFileLine();
			if(new_line == "end"){
				break;
			}
			comic_content += new_line + "\n";
		}
	}
	InterpComic();
}

void InterpComic(){
	JSON data;

	if(!data.parseString(comic_content)){
		Log(warning, "Unable to parse the JSON in the Script Data!");
	}else{
		for(uint i = 0; i < data.getRoot()["functions"].size(); ++i ){
			comic_elements.insertLast(InterpElement(data.getRoot()["functions"][i]));
			comic_indexes.insertLast(comic_elements.size() - 1);
		}
	}

	Log(info, "Interp of comic script done.");
	ReorderElements();
}

ComicElement@ InterpElement(JSONValue &in function_json){
	if(function_json["function_name"].asString() == "add_image"){
		return ComicImage(function_json);
	}else if(function_json["function_name"].asString() == "new_page"){
		return ComicPage(function_json);
	}else if(function_json["function_name"].asString() == "set_font"){
		return ComicFont(function_json);
	}else if(function_json["function_name"].asString() == "add_text"){
		return ComicText(function_json);
	}else if(function_json["function_name"].asString() == "wait_click"){
		return ComicWaitClick(function_json);
	}else if(function_json["function_name"].asString() == "play_sound"){
		return ComicSound(function_json);
	}else if(function_json["function_name"].asString() == "add_music"){
		return ComicMusic(function_json);
	}else if(function_json["function_name"].asString() == "play_song"){
		return ComicSong(function_json);
	}else if(function_json["function_name"].asString() == "crawl_in"){
		return ComicCrawlIn(function_json);
	}else if(function_json["function_name"].asString() == "fade_in"){
		return ComicFadeIn(function_json);
	}else if(function_json["function_name"].asString() == "move_in"){
		return ComicMoveIn(function_json);
	}else{
		//Either an empty line or an unknown command is in the comic.
		Log(warning, "Unknown command found: " + function_json["function_name"].asString());
		return ComicElement();
	}
}

void ReorderElements(){
	for(uint index = 0; index < comic_indexes.size(); index++){
		ComicElement@ current_element = comic_elements[comic_indexes[index]];
		current_element.SetIndex(index);
		current_element.ClearTarget();
		current_element.SetVisible(false);
		current_element.SetEdit(false);
		if(current_element.comic_element_type == comic_page){
			// A page needs to get all the comic elements untill it finds different page.
			for(uint j = index + 1; j < comic_indexes.size(); j++){
				if(comic_elements[comic_indexes[j]].comic_element_type == comic_page){
					// Found a new page so adding no more elements to this page.
					break;
				}else{
					current_element.SetTarget(comic_elements[comic_indexes[j]]);
				}
			}
		}else if(current_element.comic_element_type == comic_crawl_in){
			// A crawl-in just needs the previous text element.
			for(int j = index - 1; j > -1; j--){
				if(comic_elements[comic_indexes[j]].comic_element_type == comic_text){
					current_element.SetTarget(comic_elements[comic_indexes[j]]);
					break;
				}
			}
		}else if(current_element.comic_element_type == comic_fade_in){
			// A fade-in works both on the text element and the image element.
			for(int j = index - 1; j > -1; j--){
				if(comic_elements[comic_indexes[j]].comic_element_type == comic_text || comic_elements[comic_indexes[j]].comic_element_type == comic_image){
					current_element.SetTarget(comic_elements[comic_indexes[j]]);
					break;
				}
			}
		}else if(current_element.comic_element_type == comic_font){
			// The font applies to all the next text element untill a new font is found.
			for(uint j = index + 1; j < comic_indexes.size(); j++){
				if(comic_elements[comic_indexes[j]].comic_element_type == comic_text){
					current_element.SetTarget(comic_elements[comic_indexes[j]]);
				}else if(comic_elements[comic_indexes[j]].comic_element_type == comic_font){
					break;
				}
			}
		}else if(current_element.comic_element_type == comic_move_in){
			// A move-in works both on the text element and the image element.
			for(int j = index - 1; j > -1; j--){
				if(comic_elements[comic_indexes[j]].comic_element_type == comic_text || comic_elements[comic_indexes[j]].comic_element_type == comic_image){
					current_element.SetTarget(comic_elements[comic_indexes[j]]);
					break;
				}
			}
		}
	}
	// Run the whole script again from the beginning to fix any ordering problems.
	current_line = 0;
}

ComicElement@ GetNextElementOfType(comic_element_types type){
	for(uint i = current_line + 1; i < comic_indexes.size(); i++){
		if(comic_elements[comic_indexes[i]].comic_element_type == type){
			return comic_elements[comic_indexes[i]];
		}
	}
	return null;
}

ComicElement@ GetPreviousElementOfType(comic_element_types type){
	for(int i = current_line - 1; i > -1; i--){
		if(comic_elements[comic_indexes[i]].comic_element_type == type){
			return comic_elements[comic_indexes[i]];
		}
	}
	return null;
}

ComicElement@ GetCurrentElement(){
	return comic_elements[comic_indexes[current_line]];
}

void AddBackground(){
	int vertical_amount = 5;
	int horizontal_amount = 8;
	IMDivider vertical("vertical", DOVertical);
	for(int i = 0; i < vertical_amount; i++){
		IMDivider horizontal("horizontal" + i, DOHorizontal);
		vertical.append(horizontal);
		for(int j = 0; j < horizontal_amount; j++){
			string background_path;
			if(creator_state == editing){
				background_path = grid_background;
			}else{
				background_path = black_background;
			}
			IMImage background(background_path);
			background.scaleToSizeX(320);
			horizontal.append(background);
		}
	}
	imGUI.getBackgroundLayer(0).setClip(true);
	imGUI.getBackgroundLayer(0).setElement(vertical);
}

bool CanGoBack(){
	if(unsaved){
		if(!editor_open){
			editor_open = true;
		}
		show_confirm = true;
		return false;
	}else{
		return true;
	}
}

void Dispose(){

}

void Resize() {
	imGUI.doScreenResize();
}

void Update(){
	Update(0);
}

void PostInit(){
	post_init_done = true;
	for(uint i = 0; i < comic_elements.size(); i++){
		comic_elements[i].PostInit();
	}
}

void Update(int is_paused){
	if(!post_init_done){
		PostInit();
		return;
	}

	if(GetInputPressed(0, "f1") && environment_state == in_menu){
		editor_open = !editor_open;
		if(!editor_open){
			creator_state = playing;
		}else if(editor_open){
			target_line = current_line;
			creator_state = editing;
		}
	}else if(GetInputDown(0, "lctrl") && GetInputPressed(0, "s")){
		SaveComic();
	}else if(GetInputDown(0, "l") && environment_state == in_game){
		CloseComic();
		SetPaused(false);
	}

	while(imGUI.getMessageQueueSize() > 0){
		IMMessage@ message = imGUI.getNextMessage();
		/* Log(info, "message " + message.name); */
		if( message.name == "Close" ) {
			imGUI.getMain().clear();
		}else if( message.name == "grabber_activate" ) {
			if(!dragging){
				@current_grabber = GetCurrentElement().GetGrabber(message.getString(0));
			}
		}else if( message.name == "grabber_deactivate" ) {

		}else if( message.name == "grabber_move_check" ) {
		}
	}

	UpdateGrabber();
	UpdateProgress();
	imGUI.update();
}

void CloseComic(){
	comic_content = "";
	comic_path = "";
	image_container.clear();
	text_container.clear();
	grabber_container.clear();
	current_line = 0;
	target_line = 0;
	@current_font = null;
	@current_grabber = null;
	comic_elements.resize(0);
	comic_indexes.resize(0);
	creator_state = editing;
}

int play_direction = 1.0;

bool CanPlayForward(){
	if(current_line + 1 < int(comic_indexes.size())){
		return true;
	}else{
		return false;
	}
}

bool CanPlayBackward(){
	if(@GetPreviousElementOfType(comic_wait_click) != null || @GetPreviousElementOfType(comic_wait_click) != null){
		return true;
	}
	return false;
}

void UpdateProgress(){
	if(comic_elements.size() == 0){
		return;
	}
	GetCurrentElement().Update();
	if(creator_state == playing){
		GoToLine(GetPlayingProgress());
	}else{
		GoToLine(target_line);
	}
}

void GoToLine(int new_line){
	// Don't do anything if already at target line.
	if(new_line == current_line){
		return;
	}

	GetCurrentElement().SetEdit(false);
	GetCurrentElement().SetCurrent(false);
	at_correct_line = false;
	while(true){
		// Going to a previous line in the script.
		if(new_line < current_line){
			// Show the previous page.
			if(GetCurrentElement().comic_element_type == comic_page){
				ComicElement@ previous_page = GetPreviousElementOfType(comic_page);
				if(@previous_page != null){
					previous_page.ShowPage();
				}
			}
			GetCurrentElement().SetVisible(false);
			current_line -= 1;
			GetCurrentElement().SetVisible(true);
		// Going to the next line in the script.
		}else if(new_line > current_line){
			// Hide the current page to go to the next page.
			if(comic_elements[comic_indexes[current_line + 1]].comic_element_type == comic_page){
				ComicElement@ previous_page = GetPreviousElementOfType(comic_page);
				if(@previous_page != null){
					previous_page.HidePage();
				}
			}
			current_line += 1;
			GetCurrentElement().SetVisible(true);
		// At the correct line.
		}else{
			break;
		}
	}
	at_correct_line = true;
	StorageSetInt32("progress_" + comic_path, current_line);
	GetCurrentElement().SetCurrent(true);
	if(creator_state == editing){
		GetCurrentElement().SetEdit(true);
	}
}

int GetPlayingProgress(){
	int new_line = current_line;
	while(true){
		if(new_line == int(comic_elements.size() -1) || comic_elements[comic_indexes[new_line]].comic_element_type == comic_wait_click || comic_elements[comic_indexes[new_line]].comic_element_type == comic_crawl_in){
			break;
		}else{
			new_line += play_direction;
		}
	}
	if(target_line != -1){
		new_line = target_line;
		target_line = -1;
	}
	if(new_line == current_line){
		// Waiting for input to progress.
		if(GetInputPressed(0, "mouse0")){
			if(environment_state == in_game && current_line == int(comic_indexes.size() - 1)){
				StorageSetInt32("progress_" + comic_path, 0);
				CloseComic();
				SetPaused(false);
				return 0;
			}else{
				if(CanPlayForward()){
					new_line = current_line + 1;
					play_direction = 1;
				}else if(current_line == int(comic_indexes.size() - 1)){
					StorageSetInt32("progress_" + comic_path, 0);
					imGUI.receiveMessage(IMMessage("Back"));
				}
			}
		}else if(GetInputPressed(0, "grab")){
			if(CanPlayBackward()){
				new_line = current_line - 1;
				play_direction = -1;
			}
		}
	}
	return new_line;
}

void UpdateGrabber(){
	if(dragging){
		if(!GetInputDown(0, "mouse0")){
			dragging = false;
			@current_grabber = null;
		}else{
			vec2 new_position = imGUI.guistate.mousePosition;
			if(new_position != drag_position){
				vec2 difference = (new_position - drag_position);
				int direction_x = (difference.x > 0.0) ? 1 : -1;
				int direction_y = (difference.y > 0.0) ? 1 : -1;
				int steps_x = int(abs(difference.x) / snap_scale);
				int steps_y = int(abs(difference.y) / snap_scale);
				if(current_grabber.grabber_type == scaler){
					if(abs(difference.x) >= snap_scale){
						GetCurrentElement().AddSize(vec2(snap_scale * direction_x * steps_x, 0.0), current_grabber.direction_x, current_grabber.direction_y);
						drag_position.x += snap_scale * direction_x * steps_x;
					}
					if(abs(difference.y) >= snap_scale){
						GetCurrentElement().AddSize(vec2(0.0, snap_scale * direction_y * steps_y), current_grabber.direction_x, current_grabber.direction_y);
						drag_position.y += snap_scale * direction_y * steps_y;
					}
				}else if(current_grabber.grabber_type == mover){
					if(abs(difference.x) >= snap_scale){
						GetCurrentElement().AddPosition(vec2(snap_scale * direction_x * steps_x, 0.0));
						drag_position.x += snap_scale * direction_x * steps_x;
					}
					if(abs(difference.y) >= snap_scale){
						GetCurrentElement().AddPosition(vec2(0.0, snap_scale * direction_y * steps_y));
						drag_position.y += snap_scale * direction_y * steps_y;
					}
				}
			}
		}
	}else{
		if(GetInputDown(0, "mouse0") && @current_grabber != null){
			drag_position = imGUI.guistate.mousePosition;
			dragging = true;
		}
	}
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "show_comic"){
			current_line = 0;
			token_iter.FindNextToken(msg);
			LoadComic(token_iter.GetToken(msg));
			creator_state = playing;
			SetPaused(true);
		}
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

bool reorded = false;
int display_index = 0;
int drag_target_line = 0;
bool update_scroll = false;
bool show_confirm = false;

void DrawGUI(){
	if(editor_open){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_Text, text_color);
		ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_CloseButton, background_color);
		ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Comic Creator " + comic_path + (unsaved?" * " : "") + "###Comic Creator", editor_open, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoSavedSettings);
		ImGui_PopStyleVar();

		if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_Delete))){
			DeleteCurrentElement();
		}

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(500.0f, 450.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, ImGui_GetWindowHeight() - 60));
			GetCurrentElement().AddSettings();
			ImGui_EndChild();
			ImGui_BeginChild("Modal Buttons", vec2(-1, 60));
			if(ImGui_Button("Close")){
				unsaved = true;
				GetCurrentElement().EditDone();
				ImGui_CloseCurrentPopup();
			}
			ImGui_EndChild();
			ImGui_EndPopup();
		}
		ImGui_PopStyleVar();

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(380, 75));
		if(ImGui_BeginPopupModal("Confirm", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoResize)){
			ImGui_Text("You unsaved changes. Are you sure you want to quit?");
			ImGui_Separator();
			ImGui_BeginChild("ConfirmButtons");
			ImGui_Dummy(vec2(130.0, 1.0));
			ImGui_SameLine();
			if(ImGui_Button("Yes")){
				unsaved = false;
				this_ui.SendCallback("back");
			}
			ImGui_SameLine(0.0, 25.0);
			if(ImGui_Button("No")){
				ImGui_CloseCurrentPopup();
			}
			ImGui_EndChild();
			ImGui_EndPopup();
		}
		if(show_confirm){
			ImGui_OpenPopup("Confirm");
			show_confirm = false;
		}

		ImGui_PopStyleVar();

		if(ImGui_BeginMenuBar()){
			if(ImGui_BeginMenu("File")){
				if(ImGui_MenuItem("New file")){
					CloseComic();
					unsaved = true;
					comic_path = "New Comic";
				}
				if(ImGui_MenuItem("Load file")){
					string new_path = GetUserPickedReadPath("txt", "Data");
					if(new_path != ""){
						LoadComic(new_path);
					}
				}
				if(ImGui_MenuItem("Save")){
					if(!FileExists(comic_path)){
						SaveComicToFile();
					}else{
						SaveComic();
					}
				}
				if(ImGui_MenuItem("Save to file")){
					SaveComicToFile();
				}
				ImGui_EndMenu();
			}
			if(ImGui_BeginMenu("Settings")){
				ImGui_DragInt("Snap Scale", snap_scale, 0.5f, 1, 50, "%.0f");
				ImGui_EndMenu();
			}
			if(ImGui_BeginMenu("Add")){
				AddFunctionMenuItems();
				ImGui_EndMenu();
			}

			if(ImGui_ImageButton(delete_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				DeleteCurrentElement();
			}

			if(ImGui_ImageButton(duplicate_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(comic_elements.size() > 0){
					ComicElement@ new_element = InterpElement(GetCurrentElement().GetSaveData());
					InsertElement(new_element);
				}
			}

			ImGui_EndMenuBar();
		}

		if(!ImGui_IsPopupOpen("Edit") && !ImGui_IsPopupOpen("Confirm")){
			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(current_line > 0){
					target_line -= 1;
					display_index = comic_indexes[current_line - 1];
					update_scroll = true;
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(current_line < int(comic_elements.size() - 1)){
					target_line += 1;
					display_index = comic_indexes[current_line + 1];
					update_scroll = true;
				}
			}
		}

		int line_counter = 0;
		for(uint i = 0; i < comic_indexes.size(); i++){
			int item_no = comic_indexes[i];
			string line_number = comic_elements[item_no].index + ".";
			int initial_length = max(1, (7 - line_number.length()));
			for(int j = 0; j < initial_length; j++){
				line_number += " ";
			}
			ImGui_PushStyleColor(ImGuiCol_Text, comic_elements[item_no].display_color);
			if(ImGui_Selectable(line_number + comic_elements[item_no].GetDisplayString(), display_index == int(item_no), ImGuiSelectableFlags_AllowDoubleClick)){
				if(ImGui_IsMouseDoubleClicked(0)){
					if(comic_elements[comic_indexes[i]].has_settings){
						ImGui_OpenPopup("Edit");
					}
				}else{
					display_index = int(item_no);
					target_line = int(i);
				}
			}
			if(update_scroll && display_index == int(item_no)){
				update_scroll = false;
				ImGui_SetScrollHere(0.5);
			}
			ImGui_PopStyleColor();
			if(ImGui_IsItemActive() && !ImGui_IsItemHovered()){
				float drag_dy = ImGui_GetMouseDragDelta(0).y;
				if(drag_dy < 0.0 && i > 0){
					// Swap
					comic_indexes[i] = comic_indexes[i-1];
            		comic_indexes[i-1] = item_no;
					drag_target_line = i-1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}else if(drag_dy > 0.0 && i < comic_elements.size() - 1){
					comic_indexes[i] = comic_indexes[i+1];
            		comic_indexes[i+1] = item_no;
					drag_target_line = i+1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}
			}
			line_counter += 1;
		}
		ImGui_End();
		ImGui_PopStyleColor(18);
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
	}
	if(at_correct_line){
	}
	imGUI.render();
}

void DeleteCurrentElement(){
	if(comic_elements.size() > 0){
		GetCurrentElement().Delete();
		int current_index = comic_indexes[current_line];

		comic_elements.removeAt(current_index);
		comic_indexes.removeAt(current_line);

		for(uint i = 0; i < comic_indexes.size(); i++){
			if(comic_indexes[i] > current_index){
				comic_indexes[i] -= 1;
			}
		}
		// If the last element is deleted then the target needs to be the previous element.
		if(current_line > 0 && current_line == int(comic_elements.size())){
			display_index = comic_indexes[current_line - 1];
			current_line -= 1;
		}else if(comic_elements.size() > 0){
			display_index = comic_indexes[current_line];
		}
		unsaved = true;
		ReorderElements();
	}
}

void AddFunctionMenuItems(){
	for(uint i = 0; i < sorted_element_names.size(); i++){
		comic_element_types current_element_type = comic_element_types(comic_element_names.find(sorted_element_names[i]));
		if(current_element_type == none){
			continue;
		}
		ImGui_PushStyleColor(ImGuiCol_Text, display_colors[current_element_type]);
		if(ImGui_MenuItem(sorted_element_names[i])){
			InsertElement(@CreateNewFunction(current_element_type));
		}
		ImGui_PopStyleColor();
	}
}

ComicElement@ CreateNewFunction(comic_element_types element_type) {
	switch(element_type){
		case comic_crawl_in:
			return ComicCrawlIn();
		case comic_fade_in:
			return ComicFadeIn();
		case comic_font:
			return ComicFont();
		case comic_image:
			return ComicImage();
		case comic_move_in:
			return ComicMoveIn();
		case comic_music:
			return ComicMusic();
		case comic_page:
			return ComicPage();
		case comic_song:
			return ComicSong();
		case comic_text:
			return ComicText();
		case comic_wait_click:
			return ComicWaitClick();
	}
	return ComicElement();
}

void InsertElement(ComicElement@ new_element){
	if(comic_elements.size() > 0){
		GetCurrentElement().SetVisible(false);
		GetCurrentElement().EditDone();
	}
	new_element.PostInit();
	comic_elements.insertLast(new_element);
	//There are no functions in the list yet.
	if(comic_indexes.size() < 1){
		comic_indexes.insertLast(comic_elements.size() - 1);
		display_index = comic_indexes[0];
	//Add a the new function to the next line and make that line the current one.
	}else{
		comic_indexes.insertAt(current_line + 1, comic_elements.size() - 1);
		display_index = comic_indexes[current_line + 1];
		current_line += 1;
	}
	ReorderElements();
	if(post_init_done && comic_elements.size() > 0){
		GetCurrentElement().StartEdit();
		GetCurrentElement().SetVisible(true);
	}
	unsaved = true;
}

void SaveComicToFile(){
	string new_path = GetUserPickedWritePath("txt", "Data");
	if(new_path != ""){
		SaveComic(new_path);
	}
}

void SaveComic(string path = ""){
	if(path != ""){
		comic_path = path;
	}
	unsaved = false;
	StartWriteFile();

	for(uint i = 0; i < comic_indexes.size(); i++){
		AddFileString(comic_elements[comic_indexes[i]].GetSaveString());
		if(i != comic_elements.size() - 1){
			AddFileString("\n");
		}
	}
	WriteFileKeepBackup(FindFilePath(comic_path));
}

int GetJSONInt(JSONValue data, string var_name, int default_value){
	if(data.isMember(var_name) && data[var_name].isInt()){
		return data[var_name].asInt();
	}else{
		return default_value;
	}
}

string GetJSONString(JSONValue data, string var_name, string default_value){
	if(data.isMember(var_name) && data[var_name].isString()){
		return data[var_name].asString();
	}else{
		return default_value;
	}
}

vec2 GetJSONVec2(JSONValue data, string var_name, vec2 default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		return vec2(data[var_name][0].asFloat(), data[var_name][1].asFloat());
	}else{
		return default_value;
	}
}

vec3 GetJSONVec3(JSONValue data, string var_name, vec3 default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		return vec3(data[var_name][0].asFloat(), data[var_name][1].asFloat(), data[var_name][2].asFloat());
	}else{
		return default_value;
	}
}

vec4 GetJSONVec4(JSONValue data, string var_name, vec4 default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		return vec4(data[var_name][0].asFloat(), data[var_name][1].asFloat(), data[var_name][2].asFloat(), data[var_name][3].asFloat());
	}else{
		return default_value;
	}
}

bool GetJSONBool(JSONValue data, string var_name, bool default_value){
	if(data.isMember(var_name) && data[var_name].isBool()){
		return data[var_name].asBool();
	}else{
		return default_value;
	}
}

float GetJSONFloat(JSONValue data, string var_name, float default_value){
	if(data.isMember(var_name) && data[var_name].isNumeric()){
		return data[var_name].asFloat();
	}else{
		return default_value;
	}
}

array<float> GetJSONFloatArray(JSONValue data, string var_name, array<float> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<float> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asFloat());
		}
		return values;
	}else{
		return default_value;
	}
}

array<int> GetJSONIntArray(JSONValue data, string var_name, array<int> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<int> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asInt());
		}
		return values;
	}else{
		return default_value;
	}
}

array<string> GetJSONStringArray(JSONValue data, string var_name, array<string> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<string> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asString());
		}
		return values;
	}else{
		return default_value;
	}
}

array<JSONValue> GetJSONValueArray(JSONValue data, string var_name, array<JSONValue> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<JSONValue> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i]);
		}
		return values;
	}else{
		return default_value;
	}
}
