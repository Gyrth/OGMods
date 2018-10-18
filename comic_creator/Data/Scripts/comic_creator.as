#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

string level_name = "";
IMGUI@ imGUI;

bool show = true;
bool textbox_active = false;
int current_line = 0;

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

string background_path = "Textures/grid.png";
array<ComicElement@> comic_elements;
int grabber_size = 100;

enum grabber_types { scaler, mover };
enum creator_states { editing, playing };
enum editing_states { edit_image };

creator_states creator_state = editing;

vec2 drag_position;
Grabber@ current_grabber = null;
string comic_path = "Data/Comics/example.txt";

class ComicElement{
	void AddPosition(vec2 added_positon){}
	void AddSize(vec2 added_size, int direction_x, int direction_y){}
	Grabber@ GetGrabber(string grabber_name){return null;}
	void Select(){}
	void UnSelect(){}
	string GetSaveString(){return "";}
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

		direction_x = _direction_x;
		direction_y = _direction_y;

	    IMMessage on_enter("grabber_activate");
		on_enter.addInt(image_index);
		on_enter.addString(name);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");

		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		imGUI.getMain().addFloatingElement(grabber_image, "grabber" + image_index + name, vec2(grabber_size / 2.0), 4);
	}
	void setVisible(bool visible){
		image.setVisible(visible);
		image.setPauseBehaviors(!visible);
	}
}

class ComicImage : ComicElement{
	bool edit_mode = false;
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
		IMImage new_image(path);
		@image = new_image;
		new_image.setBorderColor(vec4(1.0, 0.0, 0.0, 1.0));

		@grabber_top_left = Grabber(index, "top_left", -1, -1, scaler);
		@grabber_top_right = Grabber(index, "top_right", 1, -1, scaler);
		@grabber_bottom_left = Grabber(index, "bottom_left", -1, 1, scaler);
		@grabber_bottom_right = Grabber(index, "bottom_right", 1, 1, scaler);
		@grabber_center = Grabber(index, "center", 1, 1, mover);

		new_image.setSize(size);
		Log(info, " " + path );
		imGUI.getMain().addFloatingElement(new_image, "image" + index, location, 2);
		Update();
	}

	void Update(){
		image.showBorder(edit_mode);
		grabber_top_left.setVisible(edit_mode);
		grabber_top_right.setVisible(edit_mode);
		grabber_bottom_left.setVisible(edit_mode);
		grabber_bottom_right.setVisible(edit_mode);
		grabber_center.setVisible(edit_mode);

		vec2 location = imGUI.getMain().getElementPosition("image" + index);
		vec2 size = image.getSize();

		imGUI.getMain().moveElement("grabber" + index + "top_left", location - vec2(grabber_size / 2.0));
		imGUI.getMain().moveElement("grabber" + index + "top_right", location + vec2(size.x, 0) - vec2(grabber_size / 2.0));
		imGUI.getMain().moveElement("grabber" + index + "bottom_left", location + vec2(0, size.y) - vec2(grabber_size / 2.0));
		imGUI.getMain().moveElement("grabber" + index + "bottom_right", location + vec2(size.x, size.y) - vec2(grabber_size / 2.0));
		imGUI.getMain().moveElement("grabber" + index + "center", location + vec2(size.x / 2.0, size.y / 2.0) - vec2(grabber_size / 2.0));
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
			size.x += added_size.x;
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			size.x -= added_size.x;
			imGUI.getMain().moveElementRelative("image" + index, vec2(added_size.x, 0.0));
			location.x += added_size.x;
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
			size.y += added_size.y;
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			size.y -= added_size.y;
			imGUI.getMain().moveElementRelative("image" + index, vec2(0.0, added_size.y));
			location.y += added_size.y;
		}
		Update();
	}

	void AddPosition(vec2 added_positon){
		imGUI.getMain().moveElementRelative("image" + index, added_positon);
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

	void UnSelect(){
		edit_mode = false;
		Update();
	}
	void Select(){
		edit_mode = true;
		Update();
	}

	string GetSaveString(){
		return "add_image " + path + " " + location.x + " " + location.y + " " + size.x + " " + size.y;
	}
}

void Initialize(){
	@imGUI = CreateIMGUI();
	PlaySong("menu-lugaru");

	imGUI.setup();
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
			vec2 position = vec2(atoi(line_elements[2]), atoi(line_elements[3]));
			vec2 size = vec2(atoi(line_elements[4]), atoi(line_elements[5]));
			comic_elements.insertLast(ComicImage(line_elements[1], position, size, i));
		}else{
			comic_elements.insertLast(ComicElement());
		}
	}
}

void AddBackground(){
	int vertical_amount = 5;
	int horizontal_amount = 8;
	IMDivider vertical("vertical", DOVertical);
	vertical.setZOrdering(-1);
	for(int i = 0; i < vertical_amount; i++){
		IMDivider horizontal("horizontal" + i, DOHorizontal);
		vertical.append(horizontal);
		for(int j = 0; j < horizontal_amount; j++){
			IMImage background(background_path);
			background.scaleToSizeX(320);
			horizontal.append(background);
		}
	}
	imGUI.getMain().addFloatingElement(vertical, "Background", vec2(0,0));
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
	if(GetInputPressed(0, "i")){
		show = !show;
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
	UpdateEditState();
	imGUI.update();
}

void UpdateEditState(){
	int new_line = GetLineNumber(ImGui_GetTextBuf());
	if(new_line != current_line){
		comic_elements[current_line].UnSelect();
		current_line = new_line;
		comic_elements[current_line].Select();
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
		if(GetInputDown(0, "mouse0")){
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
	ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));
	ImGui_Begin("Comic Creator", show, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoScrollbar);
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
