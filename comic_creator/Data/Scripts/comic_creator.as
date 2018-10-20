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
Grabber@ current_grabber = null;
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

class ComicElement{
	comic_element_types comic_element_type = none;
	ComicElement@ on_page = null;
	bool edit_mode = false;
	bool visible;
	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	Grabber@ GetGrabber(string grabber_name){return null;}
	string GetSaveString(){return "";}
	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){};
	void RemoveUpdateBehavior(string behavior_name){};
	void AddElement(ComicElement@ element){}
	void ShowPage(){}
	void HidePage(){}
	void Update(){}
	void SetVisible(bool _visible){
		visible = _visible;
	}
	void SetEdit(bool editing){
		edit_mode = editing;
		Update();
	}
}

class ComicWaitClick : ComicElement{
	ComicWaitClick(){
		comic_element_type = wait_click;
	}
}

class ComicFont : ComicElement{
	FontSetup font("edosz", 75, HexColor("#CCCCCC"), true);
	ComicFont(string _font_name, int _font_size, string _font_color, bool _shadowed){
		font.fontName = _font_name;
		font.size = _font_size;
		font.color = HexColor(_font_color);
		font.shadowed = _shadowed;
	}
}

class ComicText : ComicElement{
	IMDivider@ holder;
	array<IMText@> text_elements;
	string content;
	vec2 location;
	int index;
	Grabber@ grabber_center;
	ComicText(string _content, ComicFont@ _comic_font, vec2 _location, int _index){
		comic_element_type = comic_text;
		content = _content;
		location = _location;
		index = _index;

		IMDivider text_holder("textholder" + index, DOVertical);
		text_holder.showBorder();
		text_holder.setBorderColor(edit_outline_color);
		text_holder.setAlignment(CALeft, CATop);
		text_holder.setClip(false);
		array<string> lines = _content.split("\\n");
		for(uint i = 0; i < lines.size(); i++){
			IMText@ new_text;
			if(_comic_font is null){
				@new_text = IMText(lines[i], default_font);
			}else{
				@new_text = IMText(lines[i], _comic_font.font);
			}
			text_elements.insertLast(@new_text);
			text_holder.append(new_text);
			new_text.setZOrdering(index);
		}
		@grabber_center = Grabber(index, "center", 1, 1, mover);
		@holder = text_holder;
		text_container.addFloatingElement(text_holder, "text" + index, location, index);
		Update();
	}

	void Update(){
		holder.showBorder(edit_mode);
		Log(info, visible + content);
		holder.setVisible(visible);
		for(uint i = 0; i < text_elements.size(); i++){
			text_elements[i].setVisible(visible);
		}
		grabber_center.SetVisible(edit_mode);

		vec2 location = text_container.getElementPosition("text" + index);
		vec2 size = holder.getSize();

		grabber_container.moveElement("grabber" + index + "center", location + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void SetVisible(bool _visible){
		visible = _visible;
		Update();
	}

	Grabber@ GetGrabber(string grabber_name){
		if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	void AddPosition(vec2 added_positon){
		text_container.moveElementRelative("text" + index, added_positon);
		location += added_positon;
		Update();
	}

	string GetSaveString(){
		return "add_text " + location.x + " " + location.y + " " + content;
	}

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		holder.addUpdateBehavior(behavior, name);
	}

	void RemoveUpdateBehavior(string name){
		holder.removeUpdateBehavior(name);
	}
}

class ComicSound : ComicElement{
	string path;
	ComicSound(string _path){
		path = _path;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			PlaySound(path);
		}
	}
}

class ComicPage : ComicElement{
	array<ComicElement@> elements;
	ComicPage(){
		comic_element_type = comic_page;
	}
	void AddElement(ComicElement@ element){
		elements.insertLast(element);
	}
	void ShowPage(){
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(true);
		}
	}
	void HidePage(){
		Log(info, "hidepage");
		for(uint i = 0; i < elements.size(); i++){
			elements[i].SetVisible(false);
		}
	}
}

class ComicFadeIn : ComicElement{
	ComicElement@ target;
	int duration;
	string name;
	ComicFadeIn(ComicElement@ _target, int _duration){
		duration = _duration;
		@target = _target;
		name = "fadein" + update_behavior_counter;
		update_behavior_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			IMFadeIn new_fade(duration, inSineTween);
			target.AddUpdateBehavior(new_fade, name);
		}else{
			target.RemoveUpdateBehavior(name);
		}
	}
}

class ComicMoveIn : ComicElement{
	ComicElement@ target;
	int duration;
	vec2 offset;
	string name;
	ComicMoveIn(ComicElement@ _target, int _duration, vec2 _offset){
		duration = _duration;
		offset = _offset;
		@target = _target;
		name = "movein" + update_behavior_counter;
		update_behavior_counter += 1;
	}
	void SetVisible(bool _visible){
		visible = _visible;
		if(visible){
			IMMoveIn new_move(duration, offset, inSineTween);
			target.AddUpdateBehavior(new_move, name);
		}else{
			target.RemoveUpdateBehavior(name);
		}
	}
}

class Grabber : ComicElement{
	IMImage@ image;
	int direction_x;
	int direction_y;
	grabber_types grabber_type;
	Grabber(int image_index, string name, int _direction_x, int _direction_y, grabber_types _grabber_type){
		IMImage grabber_image("Textures/ui/eclipse.tga");
		@image = grabber_image;
		grabber_type = _grabber_type;

		comic_element_type = grabber;

		direction_x = _direction_x;
		direction_y = _direction_y;

	    IMMessage on_enter("grabber_activate");
		on_enter.addInt(image_index);
		on_enter.addString(name);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");

		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		grabber_container.addFloatingElement(grabber_image, "grabber" + image_index + name, vec2(grabber_size / 2.0), image_index);
	}
	void SetVisible(bool _visible){
		visible = _visible;
		image.setVisible(visible);
		image.setPauseBehaviors(!visible);
	}
}

class ComicImage : ComicElement{
	IMImage@ image;
	Grabber@ grabber_top_left;
	Grabber@ grabber_top_right;
	Grabber@ grabber_bottom_left;
	Grabber@ grabber_bottom_right;
	Grabber@ grabber_center;
	int index;
	string path;
	vec2 location;
	vec2 size;

	ComicImage(string _path, vec2 _location, vec2 _size, int _index){
		path = _path;
		index = _index;
		location = _location;
		size = _size;
		comic_element_type = comic_image;
		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(edit_outline_color);

		@grabber_top_left = Grabber(index, "top_left", -1, -1, scaler);
		@grabber_top_right = Grabber(index, "top_right", 1, -1, scaler);
		@grabber_bottom_left = Grabber(index, "bottom_left", -1, 1, scaler);
		@grabber_bottom_right = Grabber(index, "bottom_right", 1, 1, scaler);
		@grabber_center = Grabber(index, "center", 1, 1, mover);

		new_image.setSize(size);
		Log(info, "adding image " + index);
		image_container.addFloatingElement(new_image, "image" + index, location, index);
		Update();
	}

	void Update(){
		image.showBorder(edit_mode);
		grabber_top_left.SetVisible(edit_mode);
		grabber_top_right.SetVisible(edit_mode);
		grabber_bottom_left.SetVisible(edit_mode);
		grabber_bottom_right.SetVisible(edit_mode);
		grabber_center.SetVisible(edit_mode);

		image.setVisible(visible);

		vec2 location = image_container.getElementPosition("image" + index);
		vec2 size = image.getSize();

		grabber_container.moveElement("grabber" + index + "top_left", location - vec2(grabber_size / 2.0));
		grabber_container.moveElement("grabber" + index + "top_right", location + vec2(size.x, 0) - vec2(grabber_size / 2.0));
		grabber_container.moveElement("grabber" + index + "bottom_left", location + vec2(0, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement("grabber" + index + "bottom_right", location + vec2(size.x, size.y) - vec2(grabber_size / 2.0));
		grabber_container.moveElement("grabber" + index + "center", location + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
			size.x += added_size.x;
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			size.x -= added_size.x;
			image_container.moveElementRelative("image" + index, vec2(added_size.x, 0.0));
			location.x += added_size.x;
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
			size.y += added_size.y;
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			size.y -= added_size.y;
			image_container.moveElementRelative("image" + index, vec2(0.0, added_size.y));
			location.y += added_size.y;
		}
		Update();
	}

	void AddPosition(vec2 added_positon){
		image_container.moveElementRelative("image" + index, added_positon);
		location += added_positon;
		Update();
	}

	Grabber@ GetGrabber(string grabber_name){
		if(grabber_name == "top_left"){
			return grabber_top_left;
		}else if(grabber_name == "top_right"){
			return grabber_top_right;
		}else if(grabber_name == "bottom_left"){
			return grabber_bottom_left;
		}else if(grabber_name == "bottom_right"){
			return grabber_bottom_right;
		}else if(grabber_name == "center"){
			return grabber_center;
		}else{
			return null;
		}
	}

	string GetSaveString(){
		return "add_image " + path + " " + location.x + " " + location.y + " " + size.x + " " + size.y;
	}

	void AddUpdateBehavior(IMUpdateBehavior@ behavior, string name){
		image.addUpdateBehavior(behavior, name);
	}

	void RemoveUpdateBehavior(string name){
		/* image.removeUpdateBehavior(name); */
		/* image.clearUpdateBehaviors(); */
	}

	void SetVisible(bool _visible){
		visible = _visible;
		Update();
	}
}

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
				complete_text += line_elements[j] + " ";
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
		if(ImGui_InputTextMultiline("##TEST", vec2(-1.0, -1.0))){
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
	array<string> lines = comic_content.split("\n");

	for(uint i = 0; i < lines.size(); i++){
		AddFileString(lines[i]);
		if(i != lines.size() - 1){
			AddFileString("\n");
		}
	}
	WriteFileKeepBackup(FindFilePath(comic_path));
}

void SetCurrentAction(string strings){
	/* int new_cursor_pos = imgui_text_input_CursorPos;
	if(new_cursor_pos != old_cursor_pos){ */
}
