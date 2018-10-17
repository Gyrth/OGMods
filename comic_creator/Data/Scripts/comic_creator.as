#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

string level_name = "";
IMGUI@ imGUI;

bool show = true;

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

string background_path = "Textures/Terrain/default_c.png";
int nr_background_tiles = 5;
array<ComicImage@> images;

class ComicElement{
	int grabber_size = 100;

	IMImage@ AddGrabber(int image_index, string name, int direction_x, int direction_y){
		IMImage grabber_image("Textures/ui/eclipse.tga");
	    IMMessage on_enter("grabber_activate");
		on_enter.addInt(image_index);
		on_enter.addInt(direction_x);
		on_enter.addInt(direction_y);
	    IMMessage on_over("grabber_move_check");
		IMMessage on_exit("grabber_deactivate");
		grabber_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
		grabber_image.setSize(vec2(grabber_size));
		imGUI.getMain().addFloatingElement(grabber_image, "grabber" + image_index + name, vec2(grabber_size / 2.0), 2);
		return @grabber_image;
	}
}

class ComicImage : ComicElement{
	bool edit_mode = false;
	IMImage@ image;
	IMImage@ grabber_top_left;
	IMImage@ grabber_top_right;
	IMImage@ grabber_bottom_left;
	IMImage@ grabber_bottom_right;
	int index;

	ComicImage(string path, vec2 size, vec2 location, bool _edit_mode, int _index){
		IMImage new_image(path);
		@image = new_image;
		edit_mode = _edit_mode;
		index = _index;
		new_image.setBorderColor(vec4(1.0, 0.0, 0.0, 1.0));

		@grabber_top_left = AddGrabber(index, "top_left", -1, -1);
		@grabber_top_right = AddGrabber(index, "top_right", -1, 1);
		@grabber_bottom_left = AddGrabber(index, "bottom_left", 1, -1);
		@grabber_bottom_right = AddGrabber(index, "bottom_right", 1, 1);

		new_image.setSize(size);
		imGUI.getMain().addFloatingElement(new_image, "image" + index, location, 2);
		Update();
	}

	void Update(){
		image.showBorder(edit_mode);
		grabber_top_left.setVisible(edit_mode);
		grabber_top_right.setVisible(edit_mode);
		grabber_bottom_left.setVisible(edit_mode);
		grabber_bottom_right.setVisible(edit_mode);

		vec2 location = imGUI.getMain().getElementPosition("image" + index);
		vec2 size = image.getSize();

		imGUI.getMain().moveElement("grabber" + index + "top_left", location - vec2(50.0));
		imGUI.getMain().moveElement("grabber" + index + "top_right", location + vec2(0, size.y) - vec2(50.0));
		imGUI.getMain().moveElement("grabber" + index + "bottom_left", location + vec2(size.x, 0) - vec2(50.0));
		imGUI.getMain().moveElement("grabber" + index + "bottom_right", location + vec2(size.x, size.y) - vec2(50.0));
	}

	void AddSize(vec2 added_size, int direction_x, int direction_y){
		if(direction_x == 1){
			image.setSizeX(image.getSizeX() + added_size.x);
		}else{
			image.setSizeX(image.getSizeX() - added_size.x);
			imGUI.getMain().moveElementRelative("image" + index, vec2(added_size.x, 0.0));
		}
		if(direction_y == 1){
			image.setSizeY(image.getSizeY() + added_size.y);
		}else{
			image.setSizeY(image.getSizeY() - added_size.y);
			imGUI.getMain().moveElementRelative("image" + index, vec2(0.0, added_size.y));
		}
		Update();
	}
	void SetSizeX(float size){
	}
	void SetSizeY(float size){
	}
}

void Initialize(){
	@imGUI = CreateIMGUI();
	PlaySong("menu-lugaru");

	imGUI.setup();
	AddBackground();

	string collection;
	if(LoadFile("Data/Comics/example.txt")){
		string new_line;
	    while(true){
	        new_line = GetFileLine();
			if(new_line == "end"){
				break;
			}
			collection += new_line + "\n";
		}
	}
	ImGui_SetTextBuf(collection);
	images.insertLast(ComicImage("Textures/fire.png", vec2(500, 500), vec2(500, 500), true, 0));
}

void AddBackground(){
	IMDivider vertical("vertical", DOVertical);
	for(int i = 0; i < nr_background_tiles; i++){
		IMDivider horizontal("horizontal" + i, DOHorizontal);
		vertical.append(horizontal);
		for(int j = 0; j < nr_background_tiles; j++){
			IMImage background(background_path);
			background.scaleToSizeX(500);
			horizontal.append(background);
		}
	}
	imGUI.getMain().addFloatingElement(vertical, "Background", vec2(0,0), -1);
}

bool CanGoBack(){
	return true;
}

void Dispose(){

}

void Resize() {
	imGUI.doScreenResize();
}

vec2 drag_position;
ComicImage@ current_image = null;
int scale_direction_x = 1.0;
int scale_direction_y = 1.0;

void Update(){
	if(GetInputPressed(0, "mouse0")){
	}
	if(GetInputPressed(0, "i")){
		show = !show;
	}
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		Log(info, "message " + message.name);
		if( message.name == "Close" ) {
			imGUI.getMain().clear();
		}else if( message.name == "grabber_activate" ) {
			@current_image = images[message.getInt(0)];
			scale_direction_x = message.getInt(1);
			scale_direction_y = message.getInt(2);
		}else if( message.name == "grabber_deactivate" ) {
			if(!GetInputDown(0, "mouse0")){
				@current_image = null;
			}
		}else if( message.name == "grabber_move_check" ) {
		}
	}

	if(@current_image != null){
		if(GetInputDown(0, "mouse0")){
			vec2 new_position = imGUI.guistate.mousePosition;
			if(new_position != drag_position){
				vec2 difference = (new_position - drag_position);
				if(abs(difference.x) > 20.0){
					current_image.AddSize(vec2(difference.x, 0.0), scale_direction_x, scale_direction_y);
					drag_position.x = new_position.x;
				}
				if(abs(difference.y) > 20.0){
					current_image.AddSize(vec2(0.0, difference.y), scale_direction_x, scale_direction_y);
					drag_position.y = new_position.y;
				}
			}
		}else{
			drag_position = imGUI.guistate.mousePosition;
		}
	}
	imGUI.update();
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
	ImGui_Begin("Comic Creator", show, ImGuiWindowFlags_NoScrollbar);

	if(ImGui_InputTextMultiline("##TEST", vec2(-1.0, -1.0))){
        /* SetCurrentAction(ImGui_GetTextBuf()); */
		Log(info, "" + GetLineNumber(ImGui_GetTextBuf()));
	}
	ImGui_End();
	imGUI.render();
}

int old_cursor_pos = -1;

int GetLineNumber(string input){
	array<string> split_input = input.split("\n");
	int counter = 0;

	for(uint i = 0; i < split_input.size(); i++){
		counter += split_input[i].length() + 1;
		if(imgui_text_input_CursorPos < counter){
			return i;
		}
	}
	return 0;
}

void SetCurrentAction(string strings){
	/* int new_cursor_pos = imgui_text_input_CursorPos;
	if(new_cursor_pos != old_cursor_pos){ */
}
