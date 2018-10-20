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
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

string level_name = "";
IMGUI@ imGUI;

bool textbox_active = false;
int current_line = -1;

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

string grid_background = "Textures/grid.png";
string black_background = "Textures/black.tga";
array<ComicElement@> comic_elements;
int grabber_size = 50;

enum grabber_types { scaler, mover };
enum creator_states { editing, playing };
enum editing_states { edit_image };
enum comic_element_types { none, grabber, comic_image, comic_page, comic_text, wait_click };

creator_states creator_state = playing;
bool editor_open = creator_state == editing;

vec2 drag_position;
ComicGrabber@ current_grabber = null;
ComicElement@ current_page = null;
ComicFont@ current_font = null;
FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);
string comic_path = "Data/Comics/example.txt";
int update_behavior_counter = 0;
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
uint image_layer = 0;
uint text_layer = 0;
uint grabber_layer = 2;

IMContainer@ image_container;
IMContainer@ text_container;
IMContainer@ grabber_container;

void Initialize(){
	@imGUI = CreateIMGUI();
	PlaySong("menu-lugaru");

	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	imGUI.getMain().setZOrdering(-1);

	@image_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(image_container, "image_container", vec2(0));

	@text_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));

	@grabber_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(grabber_container, "grabber_container", vec2(0));

	AddBackground();
	LoadComic(comic_path);
}

string comic_content;
void LoadComic(string path){
	comic_content = "";
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
	ImGui_SetTextBuf(comic_content);
	InterpComic();
}

void InterpComic(){
	array<string> lines = comic_content.split("\n");

	for(uint i = 0; i < lines.size(); i++){
		array<string> line_elements = lines[i].split(" ");
		if(line_elements[0] == "add_image"){
			Log(info, "addimage");
			vec2 position = vec2(atoi(line_elements[2]), atoi(line_elements[3]));
			vec2 size = vec2(atoi(line_elements[4]), atoi(line_elements[5]));
			comic_elements.insertLast(ComicImage(line_elements[1], position, size, i));
		}else if(line_elements[0] == "fade_in"){
			Log(info, "addfadein");
			comic_elements.insertLast(ComicFadeIn(GetLastElement(), atoi(line_elements[1])));
		}else if(line_elements[0] == "move_in"){
			Log(info, "addmovein");
			comic_elements.insertLast(ComicMoveIn(GetLastElement(), atoi(line_elements[1]), vec2(atoi(line_elements[2]), atoi(line_elements[3]))));
		}else if(line_elements[0] == "new_page"){
			Log(info, "add page");
			ComicPage new_page = ComicPage();
			@current_page = new_page;
			comic_elements.insertLast(@new_page);
		}else if(line_elements[0] == "set_font"){
			ComicFont new_font(line_elements[1], atoi(line_elements[2]), line_elements[3], line_elements[4] == "true");
			Log(info, "addfont");
			comic_elements.insertLast(@new_font);
			@current_font = new_font;
		}else if(line_elements[0] == "add_text"){
			Log(info, "addtext");
			string complete_text = "";
			for(uint j = 3; j < line_elements.size(); j++){
				complete_text += line_elements[j] + (j==line_elements.size()-1? "" : " ");
			}
			ComicText new_text(complete_text, current_font, vec2(atoi(line_elements[1]), atoi(line_elements[2])), i);
			comic_elements.insertLast(@new_text);
		}else if(line_elements[0] == "wait_click"){
			Log(info, "addwait");
			comic_elements.insertLast(ComicWaitClick());
		}else if(line_elements[0] == "play_sound"){
			comic_elements.insertLast(ComicSound(line_elements[1]));
		}else{
			Log(info, "addelement");
			comic_elements.insertLast(ComicElement());
		}
		@comic_elements[comic_elements.size() - 1].on_page = current_page;
		if(@current_page != null){
			Log(info, "addtopage");
			current_page.AddElement(comic_elements[comic_elements.size() - 1]);
		}
	}
	@current_page = null;
}

ComicElement@ GetLastElement(){
	for(int i = comic_elements.size() -1; i > -1; i--){
		if(comic_elements[i].comic_element_type == comic_image || comic_elements[i].comic_element_type == comic_text){
			return comic_elements[i];
		}
	}
	return null;
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
	if(GetInputPressed(0, "f1")){
		editor_open = !editor_open;
		if(!editor_open){
			creator_state = playing;
		}else if(editor_open){
			creator_state = editing;
		}
	}else if(GetInputDown(0, "lctrl") && GetInputPressed(0, "s")){
		SaveComic();
	}
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		/* Log(info, "message " + message.name); */
		if( message.name == "Close" ) {
			imGUI.getMain().clear();
		}else if( message.name == "grabber_activate" ) {
			if(!dragging){
				@current_grabber = comic_elements[current_line].GetGrabber(message.getString(0));
				Log(info, "message " + message.getString(0));
			}
		}else if( message.name == "grabber_deactivate" ) {

		}else if( message.name == "grabber_move_check" ) {
		}
	}
	UpdateGrabber();
	UpdateProgress();
	imGUI.update();
}

int play_direction = 1.0;

bool CanPlayForward(){
	if(current_line + 1 < int(comic_elements.size())){
		return true;
	}else{
		return false;
	}
}

bool CanPlayBackward(){
	for(int i = (current_line - 1); i >= 0; i--){
		if(comic_elements[i].comic_element_type == wait_click){
			return true;
		}
	}
	return false;
}

void UpdateProgress(){
	int new_line = current_line;
	if(creator_state == playing){
		if(current_line != -1 && comic_elements[current_line].comic_element_type == wait_click || current_line == int(comic_elements.size() - 1)){
			if(GetInputPressed(0, "mouse0")){
				if(CanPlayForward()){
					new_line = current_line + 1;
					play_direction = 1;
				}
			}else if(GetInputPressed(0, "grab")){
				if(CanPlayBackward()){
					new_line = current_line - 1;
					play_direction = -1;
				}
			}
		}else if(current_line < int(comic_elements.size() - 1)){
			if(play_direction == 1){
				new_line = current_line + 1;
			}else if(play_direction == -1){
				new_line = current_line - 1;
			}
		}
	}else{
		new_line = GetLineNumber(ImGui_GetTextBuf());
	}
	if(new_line != current_line){
		if(current_line != -1){
			comic_elements[current_line].SetEdit(false);
		}
		while(true){
			if(new_line < current_line){
				if(comic_elements[current_line].comic_element_type == comic_page){
					comic_elements[current_line - 1].on_page.ShowPage();
					@current_page = comic_elements[current_line - 1].on_page;
				}
				comic_elements[current_line].SetVisible(false);
				current_line -= 1;
				comic_elements[current_line].SetVisible(true);

			}else if(new_line > current_line){
				if(comic_elements[current_line + 1].comic_element_type == comic_page){
					if(@current_page != null){
						current_page.HidePage();
					}else{
						Log(info, "current_page null");
					}
					@current_page = comic_elements[current_line + 1];
				}
				current_line += 1;
				/* Log(info, "current line" + current_line); */
				comic_elements[current_line].SetVisible(true);
			// At the correct line.
			}else{
				/* comic_elements[current_line].SetVisible(true); */
				break;
			}
		}
		if(creator_state == editing){
			comic_elements[current_line].SetEdit(true);
		}
	}
}

int GetLineNumber(string input){
	array<string> split_input = input.split("\n");
	int counter = 0;

	if(!textbox_active){
		return current_line;
	}else{
		for(uint i = 0; i < split_input.size(); i++){
			counter += split_input[i].length() + 1;
			if(imgui_text_input_CursorPos < counter){
				return i;
			}
		}
		return 0;
	}
}

bool dragging = false;
int snap_scale = 20;

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
						comic_elements[current_line].AddSize(vec2(snap_scale * direction_x * steps_x, 0.0), current_grabber.direction_x, current_grabber.direction_y);
						drag_position.x += snap_scale * direction_x * steps_x;
						SetCurrentLineContent();
					}
					if(abs(difference.y) >= snap_scale){
						comic_elements[current_line].AddSize(vec2(0.0, snap_scale * direction_y * steps_y), current_grabber.direction_x, current_grabber.direction_y);
						drag_position.y += snap_scale * direction_y * steps_y;
						SetCurrentLineContent();
					}
				}else if(current_grabber.grabber_type == mover){
					if(abs(difference.x) >= snap_scale){
						comic_elements[current_line].AddPosition(vec2(snap_scale * direction_x * steps_x, 0.0));
						drag_position.x += snap_scale * direction_x * steps_x;
						SetCurrentLineContent();
					}
					if(abs(difference.y) >= snap_scale){
						comic_elements[current_line].AddPosition(vec2(0.0, snap_scale * direction_y * steps_y));
						drag_position.y += snap_scale * direction_y * steps_y;
						SetCurrentLineContent();
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

void SetCurrentLineContent(){
	array<string> lines = comic_content.split("\n");
	lines[current_line] = comic_elements[current_line].GetSaveString();
	comic_content = join(lines, "\n");
	ImGui_SetTextBuf(comic_content);
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "notify_deleted"){

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

void DrawGUI(){
	if(editor_open){
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));
		ImGui_Begin("Comic Creator", editor_open, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoScrollbar);
		if(ImGui_BeginMenuBar()){
			if(ImGui_BeginMenu("File")){
				if(ImGui_MenuItem("Save")){
					SaveComic();
				}
				if(ImGui_MenuItem("Save to file")){

				}
				ImGui_EndMenu();
			}
			ImGui_EndMenuBar();
		}
		if(ImGui_InputTextMultiline("##TEST", vec2(-1,-1))){
	        /* SetCurrentAction(ImGui_GetTextBuf()); */
			Log(info, "" + GetLineNumber(ImGui_GetTextBuf()));
		}
		textbox_active = ImGui_IsItemActive();

		ImGui_End();
	}
	imGUI.render();
}

void SaveComic(){
	Log(info, FindFilePath(comic_path));
	StartWriteFile();

	for(uint i = 0; i < comic_elements.size(); i++){
		AddFileString(comic_elements[i].GetSaveString());
		if(i != comic_elements.size() - 1){
			AddFileString("\n");
		}
	}
	WriteFileKeepBackup(FindFilePath(comic_path));
}

void SetCurrentAction(string strings){
	/* int new_cursor_pos = imgui_text_input_CursorPos;
	if(new_cursor_pos != old_cursor_pos){ */
}
