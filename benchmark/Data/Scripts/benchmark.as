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
FontSetup normal_font("arial", 55, HexColor("#ffffff"), true);
FontSetup big_font("arial", 75, HexColor("#ffffff"), true);
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
const float MPI = 3.14159265359;

array<IMImage@> bars;
array<int> bars_fps;

array<BenchmarkResult@> benchmark_results = {BenchmarkResult("Intel i5 6600k", "NVidia GTX1060", "Linux", 1337)};

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




	ReadHardwareReport();
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

	/*ShowResults();*/


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
	Print(token + "!\n");
    if(token == "reset"){
        Reset();
    }else if(token == "Back"){
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

bool post_init_done = false;

void PostInit(){
	if(post_init_done){
		return;
	}
	/*camera.SetFlags(kEditorCamera);*/
	Print("postinit done\n");
	post_init_done = true;
}

int camera_id = -1;

void Update() {

	PostInit();

	while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
		Print(message.name + "\n");
        if( message.name == "Back to Main Menu" ) {
			level.SendMessage("go_to_main_menu");
		}else if( message.name == "Run Benchmark Again" ) {
			level.SendMessage("reset");
		}
	}

	if(camera_id != -1 && !EditorModeActive()){
		Object@ cam_obj = ReadObjectFromID(camera_id);
		/*PlaceholderObject@ placeholder_cam = cast<PlaceholderObject@>(cam_obj);*/
		camera.SetPos(cam_obj.GetTranslation());
		camera.SetDistance(0.0f);
		quaternion rot  = cam_obj.GetRotation();
		vec3 front = Mult(rot, vec3(0,0,1));
		float y_rot = atan2(front.x, front.z)*180.0f/MPI;
		camera.SetYRotation(y_rot);
		float x_rot = asin(front[1])*-180.0f/MPI;
		camera.SetXRotation(x_rot);
		vec3 up = Mult(rot, vec3(0,1,0));
		vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
		vec3 expected_up = normalize(cross(expected_right, front));
		float z_rot = atan2(dot(up,expected_right), dot(up, expected_up))*180.0f/MPI;
		camera.SetZRotation(z_rot);

		UpdateListener(cam_obj.GetTranslation(),vec3(0.0f),camera.GetFacing(),camera.GetUpVector());
	}
	if(camera_id == -1){
		array<int> cams = GetObjectIDsType(_placeholder_object);
		for(uint i = 0; i < cams.size(); i++){
			Object@ cam_obj = ReadObjectFromID(cams[i]);
			ScriptParams@ cam_params = cam_obj.GetScriptParams();
			if(cam_params.HasParam("Name")){
				if(cam_params.GetString("Name") == "animation_main"){
					camera_id = cams[i];
					ReadCharacter(0).ReceiveMessage("set_dialogue_control true");
					Print("found cam id  " + camera_id + "\n");
				}
			}
		}
	}

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
	/*Print("highest " + highest_value + "\n");*/
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
	vec2 menu_size(1200, 1000);
	vec4 background_color(0,0,0,0.5);
	vec4 light_background_color(0,0,0,0.25);
	vec2 button_size(1000, 60);
	vec2 option_size(900, 60);
	vec2 connect_button_size(1000, 60);
	float button_size_offset = 10.0f;
	float description_width = 200.0f;
	int player_name_width = 500;
	int player_character_width = 200;

	IMContainer menu_container(menu_size.x, menu_size.y);
	menu_container.setAlignment(CACenter, CATop);
	IMDivider menu_divider("menu_divider", DOVertical);
	menu_container.setElement(menu_divider);

	menu_divider.appendSpacer(10);

	//Header
	IMContainer container(button_size.x, button_size.y);
	menu_divider.append(container);
	IMDivider divider("title_divider", DOHorizontal);
	divider.setZOrdering(4);
	container.setElement(divider);
	IMText title("Results", normal_font);
	divider.append(title);

	menu_divider.appendSpacer(10);

	{
		//Background
		IMImage background(white_background);
		background.setColor(background_color);
		background.setZOrdering(2);
		background.setClip(false);
		background.setSize(vec2(menu_size.x / 2, 60));
		container.addFloatingElement(background, "background", vec2(container.getSizeX() / 2.0f - background.getSizeX() / 2.0f,0));
	}

	{
		//Table header
		IMContainer titlebar_container(menu_size.x, connect_button_size.y);
		menu_divider.append(titlebar_container);
		IMDivider titlebar_divider("titlebar_divider", DOHorizontal);
		titlebar_divider.setZOrdering(3);
		titlebar_container.setElement(titlebar_divider);

		IMImage background(white_background);
		background.setColor(background_color);
		background.setZOrdering(0);
		background.setSize(vec2(menu_size.x, 60));
		titlebar_container.addFloatingElement(background, "background", vec2(0,0));

		IMContainer gpu_label_container(menu_size.x / 4);
		IMText gpu_label("GPU", client_connect_font);
		gpu_label.setZOrdering(3);
		gpu_label_container.setElement(gpu_label);
		titlebar_divider.append(gpu_label_container);

		IMContainer cpu_label_container(menu_size.x / 4);
		IMText cpu_label("CPU", client_connect_font);
		cpu_label.setZOrdering(3);
		cpu_label_container.setElement(cpu_label);
		titlebar_divider.append(cpu_label_container);

		IMContainer os_label_container(menu_size.x / 4);
		IMText os_label("OS", client_connect_font);
		os_label.setZOrdering(3);
		os_label_container.setElement(os_label);
		titlebar_divider.append(os_label_container);

		IMContainer score_label_container(menu_size.x / 4);
		IMText score_label("Score", client_connect_font);
		score_label.setZOrdering(3);
		score_label_container.setElement(score_label);
		titlebar_divider.append(score_label_container);

		menu_divider.appendSpacer(10);
	}

	menu_divider.appendSpacer(10);

	for(uint i = 0; i < benchmark_results.size(); i++){
		//Single result
		IMContainer titlebar_container(menu_size.x, connect_button_size.y);
		menu_divider.append(titlebar_container);
		IMDivider titlebar_divider("titlebar_divider", DOHorizontal);
		titlebar_divider.setZOrdering(3);
		titlebar_container.setElement(titlebar_divider);

		IMImage background(white_background);
		background.setColor(light_background_color);
		background.setZOrdering(0);
		background.setSize(vec2(menu_size.x, 60));
		titlebar_container.addFloatingElement(background, "background", vec2(0,0));

		IMContainer gpu_label_container(menu_size.x / 4);
		IMText gpu_label(benchmark_results[i].gpu, client_connect_font);
		gpu_label.setZOrdering(3);
		gpu_label_container.setElement(gpu_label);
		titlebar_divider.append(gpu_label_container);

		IMContainer cpu_label_container(menu_size.x / 4);
		IMText cpu_label(benchmark_results[i].cpu, client_connect_font);
		cpu_label.setZOrdering(3);
		cpu_label_container.setElement(cpu_label);
		titlebar_divider.append(cpu_label_container);

		IMContainer os_label_container(menu_size.x / 4);
		IMText os_label(benchmark_results[i].os, client_connect_font);
		os_label.setZOrdering(3);
		os_label_container.setElement(os_label);
		titlebar_divider.append(os_label_container);

		IMContainer score_label_container(menu_size.x / 4);
		IMText score_label("" + benchmark_results[i].score, client_connect_font);
		score_label.setZOrdering(3);
		score_label_container.setElement(score_label);
		titlebar_divider.append(score_label_container);

		menu_divider.appendSpacer(10);
	}

	{
		//Your results.
		array<string> var_names = {"Highest FPS", "Lowest FPS", "Average FPS", "VSync"};
		array<string> var_values = {"1", "2", "3", VsyncOn()};

		IMDivider results_divider("results_divider", DOVertical);
		int result_width = 250;
		int result_height = 60;
		for(uint i = 0; i < var_names.size() && i < var_values.size(); i++){
			IMDivider horiz_divider("horiz_div", DOHorizontal);
			results_divider.append(horiz_divider);
			IMContainer label_container(result_width, result_height);
			label_container.setAlignment(CALeft, CACenter);
			horiz_divider.append(label_container);
			IMContainer value_container(result_width, result_height);
			value_container.setAlignment(CALeft, CACenter);
			horiz_divider.append(value_container);

			IMText label_text(var_names[i] + ": ", small_font);
			label_text.setZOrdering(3);
			label_container.setElement(label_text);
			IMText value_text(var_values[i], small_font);
			value_text.setZOrdering(3);
			value_container.setElement(value_text);
		}
		menu_divider.append(results_divider);

	}

	menu_divider.appendSpacer(20);

	//The button container at the bottom of the UI.
	IMContainer main_button_container(connect_button_size.x, connect_button_size.y);
	IMDivider main_button_divider("button_divider", DOHorizontal);
	main_button_container.setElement(main_button_divider);
	menu_divider.append(main_button_container);

	array<string> buttons = {"Back to Main Menu", "Run Benchmark Again"};
	for(uint i = 0; i < buttons.size(); i++){
		int button_width = 300;
		int button_height = 60;
		//The next button
		IMContainer button_container(button_width, connect_button_size.y);
		button_container.sendMouseOverToChildren(true);
		button_container.sendMouseDownToChildren(true);
		button_container.setAlignment(CACenter, CACenter);
		IMDivider button_divider("button_divider", DOHorizontal);
		button_divider.setZOrdering(4);
		button_container.setElement(button_divider);
		IMText button(buttons[i], client_connect_font);
		button.addMouseOverBehavior(mouseover_fontcolor, "");
		button_divider.append(button);

		IMImage button_background(white_background);
		button_background.setZOrdering(0);
		button_background.setSize(vec2(button_width - button_size_offset, button_height - button_size_offset));
		button_background.setColor(vec4(0,0,0,0.75));
		button_container.addFloatingElement(button_background, "button_background", vec2(button_size_offset / 2.0f));

		button_container.addLeftMouseClickBehavior(IMFixedMessageOnClick(buttons[i]), "");
		main_button_divider.append(button_container);
	}

	//The main background
	IMImage background(white_background);
	background.setColor(background_color);
	background.setSize(menu_size);
	menu_container.addFloatingElement(background, "background", vec2(0));
	/*menu_container.showBorder();*/
	imGUI.getMain().setElement(menu_container);
}

string gpu = "";

void ReadHardwareReport() {
	string path = "Data/hwreport.txt";
    if(!LoadFile(path)){
        Print("Couldn't load " + path + "\n");
    } else {
        string new_str;
        while(true){
            new_str = GetFileLine();
            if(new_str == "end"){
                break;
            }
			if(new_str.findFirst("Vendor: ") != -1){
				gpu += join(new_str.split("Vendor: "), " ");
			}else if(new_str.findFirst("GL_Renderer: ") != -1){
				gpu += join(new_str.split("GL_Renderer: "), " ");
			}
        }
		Print("GPU info " + gpu + "\n");
    }
}

void Dispose() {
	imGUI.clear();
}

string VsyncOn(){
	if(GetConfigValueBool("vsync")){
		return "On";
	}else{
		return "Off";
	}
}


bool HasFocus(){
	return false;
}
