string level_name = "";
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
string arrow = "Textures/ui/menus/main/icon-navigation.png";
vec4 mouseover_color = vec4(0.75, 0.75, 0.75, 0.85);
IMMouseOverPulseColor mouseover(mouseover_color, mouseover_color, 5.0f);

int move_in_time = 500;
vec2 image_size = vec2(1920, 1200);

int image_index = 0;
int direction = 1;
float arrow_size = 200.0;

JSON file;
int nr_paths = 0;

bool post_init = false;

void Initialize(){
	Init("this_level");
}

bool PostInit(){
	Log(info, "ok");
	level.Execute("has_gui = true;");
	return true;
}

void AddUI(){
	IMDivider mainDiv( "mainDiv", DOHorizontal );

	IMContainer menu_container(image_size.x, image_size.y);
	/*menu_container.showBorder();*/
	menu_container.setAlignment(CACenter, CACenter);

	IMImage left_arrow(arrow);
	left_arrow.addMouseOverBehavior(mouseover, "");
	left_arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("previous"), "" );
	left_arrow.scaleToSizeX(arrow_size);
	mainDiv.append(left_arrow);

	mainDiv.append(menu_container);

	IMImage right_arrow(arrow);
	right_arrow.scaleToSizeX(arrow_size);
	right_arrow.addMouseOverBehavior(mouseover, "");
	right_arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("next"), "" );
	right_arrow.setRotation(180);
	mainDiv.append(right_arrow);

	float image_x_position = -image_size.x * 2.0;

	JSONValue images = file.getRoot();

	for(int i = (image_index - 2); i < (image_index + 3); i++){
		if(i < 0 || i > int(images.size() - 1)){
			image_x_position += image_size.x;
		}else{
			IMImage new_image(images[i]["path"].asString());
			new_image.setClip(false);
			new_image.setZOrdering(-1);
			new_image.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(image_size.x * direction, 0), inOutQuartTween ), "");
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
	file.parseFile("Data/Scripts/comic_paths.json");
	nr_paths = file.getRoot().size();
	@imGUI = CreateIMGUI();
	level_name = p_level_name;
	ReloadUI();
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
}

void Update(int paused) {
	Update();
}

void Update() {
	if(!post_init){
		post_init = PostInit();
	}
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "Back to Main Menu" ) {
			level.SendMessage("go_to_main_menu");
		}else if( message.name == "Run Benchmark Again" ) {
			level.SendMessage("reset");
		}else if( message.name == "Close" ) {
			imGUI.getMain().clear();
		}else if( message.name == "next" ) {
			NextPage();
		}else if( message.name == "previous" ) {
			PreviousPage();
		}
	}
	if(GetInputPressed(0, "l")){
		Reset();
	}
	else if(GetInputPressed(0, "move_right") || GetInputPressed(0, "right")){
		NextPage();
	}
	else if(GetInputPressed(0, "move_left") || GetInputPressed(0, "left")){
		PreviousPage();
	}

	imGUI.update();
}

void NextPage(){
	image_index += 1;
	if(image_index > (nr_paths - 1)){
		image_index -= 1;
	}else{
		direction = 1;
		ReloadUI();
		level.Execute("has_gui = true;");
	}
}

void PreviousPage(){
	image_index -= 1;
	if(image_index < 0){
		image_index += 1;
	}else{
		direction = -1;
		ReloadUI();
		level.Execute("has_gui = true;");
	}
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
	return false;
}
