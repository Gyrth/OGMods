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
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

string level_name = "";
IMGUI@ imGUI;

int current_line = 0;
int element_counter = 0;

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

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
int snap_scale = 20;
int target_line = 0;

IMContainer@ image_container;
IMContainer@ text_container;
IMContainer@ grabber_container;

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

// This init is used when loaded from the main menu.
void Initialize(){
	environment_state = in_menu;
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
		unsaved = true;
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
	current_line = 0;
	@current_font = null;
	@current_grabber = null;
	comic_elements.resize(0);
	comic_indexes.resize(0);
	unsaved = false;
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
	array<string> lines = comic_content.split("\n");

	for(uint index = 0; index < lines.size(); index++){
		array<string> line_elements = lines[index].split(" ");

		if(line_elements[0] == "add_image"){
			vec2 position = vec2(atoi(line_elements[2]), atoi(line_elements[3]));
			vec2 size = vec2(atoi(line_elements[4]), atoi(line_elements[5]));
			comic_elements.insertLast(ComicImage(line_elements[1], position, size, index));
		}else if(line_elements[0] == "fade_in"){
			comic_elements.insertLast(ComicFadeIn(atoi(line_elements[1]), index));
		}else if(line_elements[0] == "move_in"){
			comic_elements.insertLast(ComicMoveIn(atoi(line_elements[1]), vec2(atoi(line_elements[2]), atoi(line_elements[3])), index));
		}else if(line_elements[0] == "new_page"){
			comic_elements.insertLast(ComicPage(index));
		}else if(line_elements[0] == "set_font"){
			comic_elements.insertLast(ComicFont(line_elements[1], atoi(line_elements[2]), vec3(atoi(line_elements[3]), atoi(line_elements[4]), atoi(line_elements[5])), line_elements[6] == "true", index));
		}else if(line_elements[0] == "add_text"){
			string complete_text = "";
			for(uint j = 3; j < line_elements.size(); j++){
				complete_text += line_elements[j] + (j==line_elements.size()-1? "" : " ");
			}
			comic_elements.insertLast(ComicText(complete_text, vec2(atoi(line_elements[1]), atoi(line_elements[2])), index));
		}else if(line_elements[0] == "wait_click"){
			comic_elements.insertLast(ComicWaitClick(index));
		}else if(line_elements[0] == "play_sound"){
			comic_elements.insertLast(ComicSound(line_elements[1], index));
		}else if(line_elements[0] == "crawl_in"){
			comic_elements.insertLast(ComicCrawlIn(atoi(line_elements[1]), index));
		}else{
			//Either an empty line or an unknown command is in the comic.
			continue;
		}
		comic_indexes.insertLast(index);
	}
	ReorderElements();
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
	return true;
}

void Dispose(){

}

void Resize() {
	imGUI.doScreenResize();
}

void Update(){
	Update(0);
}

void Update(int is_paused){
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
	while( imGUI.getMessageQueueSize() > 0 ) {
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
	if(new_line == current_line){
		// Waiting for input to progress.
		if(GetInputPressed(0, "mouse0")){
			if(CanPlayForward()){
				new_line = current_line + 1;
				play_direction = 1;
			}else if(environment_state == in_game){
				CloseComic();
				SetPaused(false);
				return 0;
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

void DrawGUI(){
	if(editor_open){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
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
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Comic Creator " + comic_path + (unsaved?" * " : "") + "###Comic Creator", editor_open, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoSavedSettings);
		ImGui_PopStyleVar();

		if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_Delete))){
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
					target_line -= 1;
					display_index = comic_indexes[current_line - 1];
				}else{
					display_index = comic_indexes[current_line];
				}
				unsaved = true;
				ReorderElements();
			}
		}

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(300.0f, 150.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, ImGui_GetWindowHeight() - 60));
			GetCurrentElement().AddSettings();
			ImGui_EndChild();
			ImGui_BeginChild("Modal Buttons", vec2(-1, 60));
			if(ImGui_Button("Close")){
				GetCurrentElement().EditDone();
				ImGui_CloseCurrentPopup();
			}
			ImGui_EndChild();
			ImGui_EndPopup();
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
				if(ImGui_MenuItem("New Page")){
					ComicPage new_page(current_line);
					InsertElement(@new_page);
				}
				if(ImGui_MenuItem("Image")){
					ComicImage new_image(default_image, vec2(500, 500), vec2(720, 255), current_line);
					InsertElement(@new_image);
				}
				if(ImGui_MenuItem("Text")){
					ComicText new_text("Example text", vec2(200, 200), current_line);
					InsertElement(@new_text);
				}
				if(ImGui_MenuItem("Crawl In")){
					ComicCrawlIn new_crawl_in(1000, current_line);
					InsertElement(@new_crawl_in);
				}
				if(ImGui_MenuItem("Fade In")){
					ComicFadeIn new_fade_in(1000, current_line);
					InsertElement(@new_fade_in);
				}
				if(ImGui_MenuItem("Move In")){
					ComicMoveIn new_move_in(1000, vec2(0, 200), current_line);
					InsertElement(@new_move_in);
				}
				if(ImGui_MenuItem("Font")){
					ComicFont new_font("Underdog-Regular", 35, vec3(1.0), false, current_line);
					InsertElement(@new_font);
				}
				if(ImGui_MenuItem("Wait Click")){
					ComicWaitClick new_wait_click(current_line);
					InsertElement(@new_wait_click);
				}
				ImGui_EndMenu();
			}
			ImGui_EndMenuBar();
		}

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
					if(comic_elements[i].has_settings){
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
		ImGui_PopStyleColor(14);
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
	}
	imGUI.render();
}

void InsertElement(ComicElement@ new_element){
	comic_elements.insertLast(new_element);
	if(comic_indexes.size() < 1){
		comic_indexes.insertAt(current_line, comic_elements.size() - 1);
		target_line = 0;
		display_index = comic_indexes[current_line];
	}else{
		comic_indexes.insertAt(current_line + 1, comic_elements.size() - 1);
		target_line += 1;
		display_index = comic_indexes[current_line + 1];
	}
	unsaved = true;
	ReorderElements();
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
