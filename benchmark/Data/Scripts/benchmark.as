string level_name = "";
uint64 last_time;
IMGUI@ imGUI;

FontSetup small_font("arial", 25, HexColor("#ffffff"), true);
FontSetup black_small_font("arial", 25, HexColor("#000000"), false);
FontSetup normal_font("arial", 55, HexColor("#ffffff"), true);
FontSetup big_font("arial", 75, HexColor("#ffffff"), true);

array<uint16> fps_collection;
uint64 fps;

string connected_icon = "Images/connected.png";
string disconnected_icon = "Images/disconnected.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string custom_address_icon = "Textures/ui/menus/main/icon-lock.png";
IMMouseOverPulseColor mouseover_fontcolor(vec4(1), vec4(1), 5.0f);

uint16 highest_fps = 60;
float update_speed = 0.05f;
int bar_graph_height = 300;
int bar_graph_width = 700;
float bar_width = 5.0f;
vec4 bar_color = vec4(1.0f, 0.0f, 0.0f, 1.0f);
IMText@ highest_fps_label;
const float MPI = 3.14159265359;

array<IMImage@> bars;
array<int> bars_fps;
uint score = 0;

array<BenchmarkResult@> benchmark_results = {	BenchmarkResult("Intel i5 6600k", "NVidia GTX1060", "Linux", 5000)};

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

	bars.resize(0);
	bars_fps.resize(0);
	fps_collection.resize(0);
	duration_timer = 0.0f;
	recording = true;
	highest_fps = 60.0f;
	score = 0;
	last_time = GetPerformanceCounter();

	imGUI.clear();
	imGUI.setHeaderHeight(bar_graph_height + 25.0f);
	imGUI.setup();
	AddBarGraph();

	Print("reset\n");
}

void Init(string p_level_name) {
	ReadHardwareReport();
	@imGUI = CreateIMGUI();
    level_name = p_level_name;
	imGUI.setHeaderHeight(bar_graph_height + 25.0f);
	imGUI.setup();
	AddBarGraph();
	last_time = GetPerformanceCounter();
}

void AddBarGraph(){
	IMDivider bar_graph_holder("bar_graph", DOHorizontal);
	bar_graph_holder.setAlignment( CACenter, CABottom );

	//The labels on the left.
	IMDivider label_holder("label_holder", DOVertical);
	@highest_fps_label = IMText(highest_fps + " fps", black_small_font);
	IMText lowest(0 + " fps", black_small_font);
	label_holder.append(highest_fps_label);
	label_holder.appendSpacer(bar_graph_height - (2.0f * black_small_font.size));
	label_holder.append(lowest);
	bar_graph_holder.append(label_holder);

	imGUI.getHeader().setAlignment(CACenter, CABottom);
	imGUI.getHeader().setElement( bar_graph_holder );

	IMDivider bar_holder("bar_holder", DOHorizontal);
	bar_holder.setAlignment( CACenter, CABottom );
	for(int i = 0; i < int(bar_graph_width / bar_width); i++){
		IMImage new_bar( white_background );
		new_bar.setSize(vec2(bar_width, 1.0f));
		new_bar.setColor(bar_color);
		new_bar.setClip(false);
		/*new_bar.showBorder();*/
		new_bar.setBorderColor(vec4(0.5f, 0.0f, 0.0f, 1.0f));
		bars.insertLast(new_bar);
		bars_fps.insertLast(0);
		bar_holder.append(new_bar);
	}
	bar_graph_holder.append(bar_holder);
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
	fps = GetPerformanceFrequency() / (GetPerformanceCounter() - last_time);
	last_time = GetPerformanceCounter();
	imGUI.render();
}

void Update(int paused) {
	Update();
}

bool post_init_done = false;
int player_id = -1;

void PostInit(){
	if(post_init_done){
		return;
	}
	array<int> characters = GetObjectIDsType(_movement_object);
	for(uint i = 0; i < characters.size(); i++){
		MovementObject@ char = ReadCharacterID(characters[i]);
		if(char.controlled){
			player_id = characters[i];
			break;
		}
	}
	/*camera.SetFlags(kEditorCamera);*/
	Print("postinit done\n");
	post_init_done = true;
}

int camera_id = -1;
float duration = 30.0f;
float duration_timer = 0.0f;
bool recording = true;
float fps_timer = 0.0f;

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

	if(!EditorModeActive()){
		if(camera_id != -1){
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
		}else{
			array<int> cams = GetObjectIDsType(_placeholder_object);
			for(uint i = 0; i < cams.size(); i++){
				Object@ cam_obj = ReadObjectFromID(cams[i]);
				ScriptParams@ cam_params = cam_obj.GetScriptParams();
				if(cam_params.HasParam("Name")){
					if(cam_params.GetString("Name") == "animation_main"){
						camera_id = cams[i];
						Print("found cam id  " + camera_id + "\n");
					}
				}
			}
		}
		if(player_id != -1){
			if(!ReadCharacterID(player_id).GetBoolVar("dialogue_control")){
				MovementObject@ player = ReadCharacterID(player_id);
				player.ReceiveMessage("set_dialogue_control true");
			}
		}
	}

	if(recording){
		duration_timer += time_step;
		fps_timer += time_step;

		if(duration_timer > duration){
			ShowResults();
			recording = false;
			return;
		}

		if(fps_timer > update_speed){
			fps_timer = 0.0f;
			fps_collection.insertLast(uint16(fps));
			score += uint(fps);
			if(fps > highest_fps){
				highest_fps = fps;
				highest_fps_label.setText(highest_fps + "fps");
			}
			ScootchBarsLeft();
			bars[bars.size() - 1].setSizeY(fps * bar_graph_height / highest_fps);
			bars_fps[bars.size() - 1] = fps;
		}
	}

	imGUI.update();
}

void ScootchBarsLeft(){
	/*Print("highest " + highest_fps + "\n");*/
	for(uint i = 0; i < (bars.size() - 1); i++){
		bars_fps[i] = bars_fps[i + 1];
		bars[i].setSizeY(bars_fps[i + 1] * bar_graph_height / highest_fps);
	}
}

void SetWindowDimensions(int w, int h){
}
vec2 menu_size(1400, 1200);
vec4 background_color(0,0,0,0.5);
vec4 light_background_color(0,0,0,0.25);
vec2 button_size(1000, 60);
vec2 option_size(900, 60);
vec2 connect_button_size(1000, 60);
float button_size_offset = 10.0f;
float description_width = 200.0f;
int player_name_width = 500;
int player_character_width = 200;

void ShowResults(){
	IMDivider mainDiv( "mainDiv", DOVertical );
	level.Execute("has_gui = true;");

	IMContainer menu_container(menu_size.x, menu_size.y);
	menu_container.setAlignment(CACenter, CATop);
	IMDivider menu_divider("menu_divider", DOVertical);
	menu_container.setElement(menu_divider);

	menu_divider.appendSpacer(5);

	//Header
	IMContainer container(button_size.x, button_size.y);
	menu_divider.append(container);
	IMDivider divider("title_divider", DOHorizontal);
	divider.setZOrdering(4);
	container.setElement(divider);
	IMText title("Results", normal_font);
	divider.append(title);

	menu_divider.appendSpacer(5);

	{
		//Background
		IMImage background(white_background);
		background.setColor(background_color);
		background.setZOrdering(2);
		background.setSize(vec2(300, 60));
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
		IMText gpu_label("GPU", small_font);
		gpu_label.setZOrdering(3);
		gpu_label_container.setElement(gpu_label);
		titlebar_divider.append(gpu_label_container);

		IMContainer cpu_label_container(menu_size.x / 4);
		IMText cpu_label("CPU", small_font);
		cpu_label.setZOrdering(3);
		cpu_label_container.setElement(cpu_label);
		titlebar_divider.append(cpu_label_container);

		IMContainer os_label_container(menu_size.x / 4);
		IMText os_label("OS", small_font);
		os_label.setZOrdering(3);
		os_label_container.setElement(os_label);
		titlebar_divider.append(os_label_container);

		IMContainer score_label_container(menu_size.x / 4);
		IMText score_label("Score", small_font);
		score_label.setZOrdering(3);
		score_label_container.setElement(score_label);
		titlebar_divider.append(score_label_container);

		menu_divider.appendSpacer(5);
	}

	menu_divider.appendSpacer(5);

	array<int> results_sorted;
	for(uint i = 0; i < benchmark_results.size(); i++){
		results_sorted.insertLast(benchmark_results[i].score);
	}
	results_sorted.sortDesc();
	for(uint i = 0; i < results_sorted.size(); i++){
		for(uint j = 0; j < benchmark_results.size(); j++){
			if(results_sorted[i] == benchmark_results[j].score){
				results_sorted[i] = j;
				break;
			}
		}
	}
	bool new_results_added = false;

	for(uint i = 0; i < results_sorted.size(); i++){
		if(benchmark_results[results_sorted[i]].score < int(score) && !new_results_added){
			AddNewResults(menu_divider);
			new_results_added = true;
		}
		//Single result
		IMContainer titlebar_container(menu_size.x, connect_button_size.y);
		menu_divider.append(titlebar_container);
		IMDivider titlebar_divider("result " + i, DOHorizontal);
		titlebar_divider.setZOrdering(3);
		titlebar_container.setElement(titlebar_divider);

		IMImage background(white_background);
		background.setColor(light_background_color);
		background.setZOrdering(0);
		background.setSize(vec2(menu_size.x, 60));
		titlebar_container.addFloatingElement(background, "background", vec2(0,0));

		IMContainer gpu_label_container(menu_size.x / 4);
		IMText gpu_label(benchmark_results[results_sorted[i]].gpu, small_font);
		gpu_label.setZOrdering(3);
		gpu_label_container.setElement(gpu_label);
		titlebar_divider.append(gpu_label_container);

		IMContainer cpu_label_container(menu_size.x / 4);
		IMText cpu_label(benchmark_results[results_sorted[i]].cpu, small_font);
		cpu_label.setZOrdering(3);
		cpu_label_container.setElement(cpu_label);
		titlebar_divider.append(cpu_label_container);

		IMContainer os_label_container(menu_size.x / 4);
		IMText os_label(benchmark_results[i].os, small_font);
		os_label.setZOrdering(3);
		os_label_container.setElement(os_label);
		titlebar_divider.append(os_label_container);

		IMContainer score_label_container(menu_size.x / 4);
		IMText score_label("" + benchmark_results[results_sorted[i]].score, small_font);
		score_label.setZOrdering(3);
		score_label_container.setElement(score_label);
		titlebar_divider.append(score_label_container);

		menu_divider.appendSpacer(5);
	}

	if(!new_results_added){
		AddNewResults(menu_divider);
	}

	menu_divider.appendSpacer(10);

	//The button container at the bottom of the UI.
	IMContainer main_button_container(connect_button_size.x, connect_button_size.y);
	IMDivider main_button_divider("button_divider", DOHorizontal);
	main_button_container.setElement(main_button_divider);
	menu_divider.append(main_button_container);

	array<string> buttons = {"Back to Main Menu", "Run Benchmark Again"};
	for(uint i = 0; i < buttons.size(); i++){
		int button_width = 400;
		int button_height = 60;
		//The next button
		IMContainer button_container(button_width, connect_button_size.y);
		button_container.sendMouseOverToChildren(true);
		button_container.sendMouseDownToChildren(true);
		button_container.setAlignment(CACenter, CACenter);
		IMDivider button_divider("button_divider", DOHorizontal);
		button_divider.setZOrdering(4);
		button_container.setElement(button_divider);
		IMText button(buttons[i], small_font);
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

void AddNewResults(IMDivider@ menu_divider){
	//Your results.
	array<string> var_names = {"Highest FPS", "Lowest FPS", "Average FPS", "VSync", "Score"};
	array<string> var_values = {"" + highest_fps, "" + GetLowestFPS(), "" + GetAverageFPS(), VsyncOn(), "" + score};

	IMContainer results_container(menu_size.x);
	IMDivider results_divider("results_divider", DOVertical);
	results_container.setElement(results_divider);
	int result_width = 250;
	int result_height = 40;
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
	menu_divider.append(results_container);
	IMImage background(white_background);
	background.setZOrdering(0);
	background.setColor(background_color);
	background.setSize(menu_size);
	results_container.addFloatingElement(background, "background", vec2(0));
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

int GetLowestFPS(){
	uint16 lowest = highest_fps;
	for(uint i = 0 ; i < fps_collection.size(); i++){
		if(fps_collection[i] < lowest){
			lowest = fps_collection[i];
		}
	}
	return lowest;
}

int GetAverageFPS(){
	uint total = 0;
	for(uint i = 0 ; i < fps_collection.size(); i++){
		total += fps_collection[i];
	}
	return total / fps_collection.size();
}

void ScriptReloaded() {
	Print("reloaded\n");
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
