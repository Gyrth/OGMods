uint socket = SOCKET_ID_INVALID;
uint connect_try_countdown = 60;
string level_name = "";
uint64 last_time;
float counter = 0.0f;
IMDivider@ main_div;
vec4 color(1,0,0,1);
IMGUI@ imGUI;
float screen_height = 1.0f;
FontSetup small_font("arial", 35, HexColor("#ffffff"), true);
FontSetup font("arial", 75, HexColor("#ffffff"), true);
IMText@ onscreen_fps;
IMText@ onscreen_highest_fps;
array<uint64> all_fps;
uint64 fps;

FontSetup main_font("arial", 25 , vec4(0,0,0,0.75), false);
FontSetup error_font("arial", 25 , vec4(0.85,0,0,0.75), true);
FontSetup client_connect_font("arial", 25 , vec4(1,1,1,0.75), true);
FontSetup client_connect_font_small("arial", 20 , vec4(1,1,1,0.75), true);
IMMouseOverPulseColor mouseover_fontcolor(vec4(1), vec4(1), 5.0f);
IMPulseAlpha pulse(1.0f, 0.0f, 2.0f);
string connected_icon = "Images/connected.png";
string disconnected_icon = "Images/disconnected.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string custom_address_icon = "Textures/ui/menus/main/icon-lock.png";

uint64 highest_value = 60;
float update_speed = 0.05f;
int bar_graph_height = 300;
int bar_graph_width = 700;
float bar_width = 5.0f;
vec4 bar_color = vec4(1.0f, 0.0f, 0.0f, 1.0f);
IMText@ highest;

array<IMImage@> bars;
array<int> bars_fps;

array<BenchmarkResult@> benchmark_results = {BenchmarkResult("Intel 6600k", "NVidia GTX1060", "Linux", 1337)};

class BenchmarkResult{
	string cpu;
	string gpu;
	string os;
	int score;
	BenchmarkResult(string _cpu, string _gpu, string _os, int _score){
		cpu = _cpu;
		gpu = _gpu;
		os = _os;
		score = _score;
	}
}

void Initialize(){
	Init("this_level");
}

void Reset(){
	Init("go!");
	Print("reset\n");
}

void Init(string p_level_name) {
	@imGUI = CreateIMGUI();
    level_name = p_level_name;
	bars.resize(0);
	bars_fps.resize(0);
	screen_height = GetScreenHeight();
	imGUI.setHeaderHeight(bar_graph_height + 25.0f);
	imGUI.setup();
	imGUI.getHeader().setAlignment(CACenter, CABottom);

	IMDivider bar_graph_holder("bar_graph", DOHorizontal);
	bar_graph_holder.setAlignment( CACenter, CABottom );

	//The labels on the left.
	IMDivider label_holder("label_holder", DOVertical);
	@highest = IMText(int(highest_value) + " fps", small_font);
	IMText lowest(0 + " fps", small_font);
	label_holder.append(highest);
	label_holder.appendSpacer(bar_graph_height - (2.0f * small_font.size));
	label_holder.append(lowest);
	bar_graph_holder.append(label_holder);

	/*imGUI.getHeader().showBorder();*/
	imGUI.getHeader().setElement( bar_graph_holder );

	IMDivider bar_holder("bar_holder", DOHorizontal);
	bar_holder.setAlignment( CACenter, CABottom );
	for(int i = 0; i < int(bar_graph_width / bar_width); i++){
		IMImage new_bar( white_background );
		new_bar.setSize(vec2(bar_width, 0.0f));
		new_bar.setColor(bar_color);
		new_bar.setClip(false);
		new_bar.showBorder();
		new_bar.setBorderColor(vec4(0.5f, 0.0f, 0.0f, 1.0f));
		bars.insertLast(new_bar);
		bars_fps.insertLast(0);
		bar_holder.append(new_bar);
	}
	bar_graph_holder.append(bar_holder);

	ShowResults();


	/*IMDivider fps_divider("fps_divider", DOHorizontal);
	IMText fps_label("FPS: ", font);
	fps_divider.append(fps_label);
	IMText fps_counter("fps", font);
	@onscreen_fps = @fps_counter;
	fps_divider.append(fps_counter);
	mainDiv.append(fps_divider);

	IMDivider fps_highest_divider("fps_highest_divider", DOHorizontal);
	IMText fps_highest_label("Highest FPS: ", font);
	fps_highest_divider.append(fps_highest_label);
	IMText fps_highest("fps", font);
	@onscreen_highest_fps = @fps_highest;
	fps_highest_divider.append(fps_highest);
	mainDiv.append(fps_highest_divider);
	//mainDiv.showBorder();
	@main_div = @mainDiv;
	imGUI.getMain().setElement( @mainDiv );*/
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
    }
}

void DrawGUI() {
	fps = GetPerformanceFrequency() / (GetPerformanceCounter() - last_time);
	last_time = GetPerformanceCounter();
	imGUI.render();
}

void Update(int paused) {
	Update();
}

void Update() {
	counter += time_step;

	if(counter > update_speed){
		counter = 0.0f;

		/*onscreen_fps.setText(fps + "");
		onscreen_highest_fps.setText(highest_value + "");*/

		all_fps.insertLast(fps);

		if(fps > highest_value){
			highest_value = fps;
			highest.setText(highest_value + "fps");
		}
		ScootchBarsLeft();
		bars[bars.size() - 1].setSizeY(fps * bar_graph_height / highest_value);
		bars_fps[bars.size() - 1] = fps;
	}
	imGUI.update();
}

void ScootchBarsLeft(){
	Print("highest " + highest_value + "\n");
	for(uint i = 0; i < (bars.size() - 1); i++){
		bars_fps[i] = bars_fps[i + 1];
		bars[i].setSizeY(bars_fps[i + 1] * bar_graph_height / highest_value);
	}
}

void SetWindowDimensions(int w, int h){
}

void ShowResults(){
	IMDivider mainDiv( "mainDiv", DOVertical );
	level.Execute("has_gui = true;");
	vec2 menu_size(1000, 500);
	vec4 background_color(0,0,0,0.5);
	vec2 button_size(1000, 60);
	vec2 option_size(900, 60);
	vec2 connect_button_size(1000, 60);
	float button_size_offset = 10.0f;
	float description_width = 200.0f;

	IMContainer menu_container(menu_size.x, menu_size.y);
	menu_container.setAlignment(CACenter, CATop);
	IMDivider menu_divider("menu_divider", DOVertical);
	menu_container.setElement(menu_divider);

	menu_divider.appendSpacer(10);

	{
		//Choose a username and character
		IMContainer container(button_size.x, button_size.y);
		menu_divider.append(container);
		IMDivider divider("title_divider", DOHorizontal);
		divider.setZOrdering(4);
		container.setElement(divider);
		IMText title("Choose a username and character.", client_connect_font);
		divider.append(title);
		//Background
		IMImage background(brushstroke_background);
		background.setZOrdering(2);
		background.setClip(false);
		background.setSize(vec2(600, 60));
		background.setAlpha(0.85f);
		container.addFloatingElement(background, "background", vec2(container.getSizeX() / 2.0f - background.getSizeX() / 2.0f,0));
	}

	menu_divider.appendSpacer(10);

	{
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Username: ", client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);

		username_divider.appendSpacer(25);

		IMText username_label("test", client_connect_font);
		username_label.addMouseOverBehavior(mouseover_fontcolor, "");
		username_label.setZOrdering(3);
		username_parent.append(username_label);
		username_divider.append(username_parent_container);

		IMImage username_background(white_background);
		username_background.setZOrdering(0);
		username_background.setSize(500 - button_size_offset);
		username_background.setColor(vec4(0,0,0,0.75));
		username_parent_container.addFloatingElement(username_background, "username_background", vec2(button_size_offset / 2.0f));

		menu_divider.append(username_container);
	}

	menu_divider.appendSpacer(20);

	//The button container at the bottom of the UI.
	IMContainer button_container(connect_button_size.x, connect_button_size.y);
	button_container.setAlignment(CARight, CACenter);
	IMDivider button_divider("button_divider", DOHorizontal);
	button_container.setElement(button_divider);
	menu_divider.append(button_container);

	{
		//The next button
		IMContainer next_button_container(200, connect_button_size.y);
		next_button_container.sendMouseOverToChildren(true);
		next_button_container.sendMouseDownToChildren(true);
		next_button_container.setAlignment(CACenter, CACenter);
		IMDivider next_button_divider("next_button_divider", DOHorizontal);
		next_button_divider.setZOrdering(4);
		next_button_container.setElement(next_button_divider);
		IMText next_button("Next", client_connect_font);
		next_button.addMouseOverBehavior(mouseover_fontcolor, "");
		next_button_divider.append(next_button);

		IMImage next_button_background(white_background);
		next_button_background.setZOrdering(0);
		next_button_background.setSize(vec2(200 - button_size_offset, connect_button_size.y - button_size_offset));
		next_button_background.setColor(vec4(0,0,0,0.75));
		next_button_container.addFloatingElement(next_button_background, "next_button_background", vec2(button_size_offset / 2.0f));

		next_button_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("next_ui"), "");
		button_divider.append(next_button_container);
	}

	//The main background
	IMImage background(white_background);
	background.setColor(background_color);
	background.setSize(menu_size);
	menu_container.addFloatingElement(background, "background", vec2(0));
	/*menu_container.showBorder();*/
	imGUI.getMain().setElement(menu_container);
}

void Dispose() {
	imGUI.clear();
}


bool HasFocus(){
	return false;
}
