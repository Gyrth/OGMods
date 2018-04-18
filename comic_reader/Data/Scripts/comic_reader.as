#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

string level_name = "";
IMGUI@ imGUI;

string arrow = "Textures/ui/menus/main/icon-navigation.png";
vec4 mouseover_color = vec4(0.75, 0.75, 0.75, 0.85);
IMMouseOverPulseColor mouseover(mouseover_color, mouseover_color, 5.0f);

int comic_move_duration = 500;
vec2 image_size = vec2(1920, 1200);

int image_index = 0;
int direction = 1;
float arrow_size = 200.0;

JSON file;
int nr_paths = 0;
array<BackgroundObject@> bgobjects;

void Initialize(){
	Init("this_level");
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
			new_image.addUpdateBehavior(IMMoveIn ( comic_move_duration, vec2(image_size.x * direction, 0), inOutQuartTween ), "");
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

bool CanGoBack(){
	return true;
}

void Init(string p_level_name) {
	@imGUI = CreateIMGUI();
	PlaySong("menu-lugaru");

	imGUI.setup();
	setBackGround();

	if(GetInterlevelData("comic_progress") != ""){
		image_index = atoi(GetInterlevelData("comic_progress"));
	}

	file.parseFile("Data/Scripts/comic_paths.json");
	nr_paths = file.getRoot().size();
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
	AddUI();
}

void Update(int paused) {
	Update();
}

void Update() {
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "Close" ) {
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
		SetInterlevelData("comic_progress", "" + image_index);
		ReloadUI();
	}
}

void PreviousPage(){
	image_index -= 1;
	if(image_index < 0){
		image_index += 1;
	}else{
		direction = -1;
		SetInterlevelData("comic_progress", "" + image_index);
		ReloadUI();
	}
}

void SetWindowDimensions(int w, int h){
	Print("SetWindowDimensions\n");
}

void Resize() {
	imGUI.doScreenResize();
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

// keep track of the math for our backgrounds
class BackgroundObject {
	int z;          // z ordering
	vec2 startPos; // where does it start rendering?
	float sizeX;     // how big is this in the x direction?
	vec2 shiftSize; // how much to shift it by for parallax
	string filename;// what file to load for this
	string GUIname; // name used to find this in the GUI
	float alpha;    // alpha value
	bool fadeIn;    // should we fade in

	BackgroundObject( string _fileName, string _GUIname, int _z,
					  vec2 _startPos, float _sizeX, vec2 _shiftSize, float _alpha,
					  bool _fadeIn ) {
		z = _z;
		startPos = _startPos;
		sizeX = _sizeX;
		shiftSize = _shiftSize;
		filename = _fileName;
		GUIname = _GUIname;
		alpha = _alpha;
		fadeIn = _fadeIn;
	}

	void addToGUI( IMGUI@ theGUI ) {
		// Set it to our background image
		IMImage backgroundImage( filename );

		backgroundImage.setSkipAspectFitting(true);
		backgroundImage.setCenter(true);

		if((backgroundImage.getSizeX() / backgroundImage.getSizeY()) > (screenMetrics.getScreenWidth() / screenMetrics.getScreenHeight())) {
			backgroundImage.scaleToSizeY(screenMetrics.getScreenHeight());
		} else {
			backgroundImage.scaleToSizeX(screenMetrics.getScreenWidth());
		}

		backgroundImage.setAlpha(alpha);

		if(fadeIn) {
			backgroundImage.addUpdateBehavior( IMFadeIn( 2000, inSineTween ), filename + "-fadeIn" );
		}

		// Now set this as the element in the background container, this will center it
		theGUI.getBackgroundLayer().addFloatingElement( backgroundImage,
														   GUIname,
														   startPos,
														   z );
	}

	void adjustPositionByMouse( IMGUI@ theGUI ) {
		vec2 mouseRatio = vec2( theGUI.guistate.mousePosition.x/screenMetrics.GUISpace.x,
								theGUI.guistate.mousePosition.y/screenMetrics.GUISpace.y );

		vec2 shiftPosition = vec2( shiftSize.x * mouseRatio.x,
								   0 );//int( float(shiftSize.y) * mouseRatio.y ) );

		theGUI.getBackgroundLayer().moveElement( GUIname, startPos + shiftPosition );
	}

}

// Draw the picture for the background
void setBackGround(float alpha = 1.0) {
	// Clear the current background
	bgobjects.resize(0);
	imGUI.getBackgroundLayer( 0 ).clear();

	bgobjects.insertLast(BackgroundObject( GetInterlevelData("background"),
											"Background",
											1,
											vec2(0,0),
											screenMetrics.GUISpace.x,
											vec2(0,0),
											alpha,
											false ));
	for( uint i = 0; i < bgobjects.length(); ++i ) {
		bgobjects[i].addToGUI( imGUI );
	}
}
