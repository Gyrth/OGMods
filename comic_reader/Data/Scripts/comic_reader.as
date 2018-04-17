string level_name = "";
uint64 last_time;
IMGUI@ imGUI;

FontSetup small_font("arial", 25, HexColor("#ffffff"), true);
FontSetup normal_font("arial", 35, HexColor("#ffffff"), true);
FontSetup black_small_font("arial", 25, HexColor("#000000"), false);
FontSetup big_font("arial", 55, HexColor("#ffffff"), true);
FontSetup huge_font("arial", 75, HexColor("#ffffff"), true);

string connected_icon = "Images/connected.png";
string disconnected_icon = "Images/disconnected.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string custom_address_icon = "Textures/ui/menus/main/icon-lock.png";
IMMouseOverPulseColor mouseover_fontcolor(vec4(1), vec4(1), 5.0f);

vec2 menu_size = vec2(800, 800);
int move_in_time = 500;
int move_in_distance = 500;
vec2 image_size = vec2(1920, 1200);

array<string> images = {"Comic/monk_comic_0.jpg", "Comic/monk_comic_1.jpg", "Comic/monk_comic_2.jpg", "Comic/monk_comic_3.jpg", "Comic/monk_comic_4.jpg", "Comic/monk_comic_5.jpg", "Comic/monk_comic_6.jpg"};
int image_index = 0;
int direction = 1;

void Initialize(){
	Init("this_level");
}

void AddUI(){
	IMDivider mainDiv( "mainDiv", DOVertical );

	IMContainer menu_container(image_size.x, image_size.y);
	/*menu_container.showBorder();*/
	menu_container.setAlignment(CACenter, CACenter);

	mainDiv.append(menu_container);

	float image_x_position = -image_size.x * 2.0;

	for(int i = (image_index - 2); i < (image_index + 3); i++){
		if(i < 0 || i > int(images.size() - 1)){
			image_x_position += image_size.x;
		}else{
			IMImage new_image(images[i]);
			new_image.setClip(false);
			new_image.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(image_size.x * direction, 0), inQuartTween ), "");
			new_image.scaleToSizeY(1200);
			menu_container.addFloatingElement(new_image, "image " + i, vec2(image_x_position, 0));
			image_x_position += image_size.x;
		}
	}

	imGUI.getMain().setElement(mainDiv);
}

void Reset(){
	ReloadUI();
}

void Init(string p_level_name) {
	@imGUI = CreateIMGUI();
	level_name = p_level_name;
	imGUI.setup();
	AddUI();
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "reset"){
		Reset();
	}else if(token == "Back"){

	}
}

void DrawGUI() {
	imGUI.render();
}

void ReloadUI(){
	imGUI.clear();
	imGUI.setup();
	AddUI();
	level.Execute("has_gui = true;");
}

void Update(int paused) {
	Update();
}

void Update() {
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "Back to Main Menu" ) {
			level.SendMessage("go_to_main_menu");
		}else if( message.name == "Run Benchmark Again" ) {
			level.SendMessage("reset");
		}else if( message.name == "Close" ) {
			imGUI.getMain().clear();
		}
	}
	if(GetInputPressed(0, "l")){
		Reset();
	}
	else if(GetInputPressed(0, "d")){
		image_index += 1;
		if(image_index > int(images.size() - 1)){
			image_index -= 1;
		}else{
			direction = 1;
			ReloadUI();
		}
	}
	else if(GetInputPressed(0, "a")){
		image_index -= 1;
		if(image_index < 0){
			image_index += 1;
		}else{
			direction = -1;
			ReloadUI();
		}
	}

	imGUI.update();
}

void SetWindowDimensions(int w, int h){
	Print("SetWindowDimensions\n");
}

void Resize() {
	Print("Resize\n");
}

void ScriptReloaded() {
	Print("ScriptReloaded\n");
}

bool DialogueCameraControl() {
    return true;
}

void Dispose() {
	imGUI.clear();
}

bool HasFocus(){
	return true;
}
