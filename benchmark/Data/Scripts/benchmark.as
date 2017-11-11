string level_name = "";
uint64 last_time;
IMGUI@ imGUI;

FontSetup small_font("arial", 25, HexColor("#ffffff"), true);
FontSetup normal_font("arial", 35, HexColor("#ffffff"), true);
FontSetup black_small_font("arial", 25, HexColor("#000000"), false);
FontSetup big_font("arial", 55, HexColor("#ffffff"), true);
FontSetup huge_font("arial", 75, HexColor("#ffffff"), true);

array<uint16> fps_collection;
uint64 fps = 0;

string connected_icon = "Images/connected.png";
string disconnected_icon = "Images/disconnected.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string custom_address_icon = "Textures/ui/menus/main/icon-lock.png";
IMMouseOverPulseColor mouseover_fontcolor(vec4(1), vec4(1), 5.0f);

uint16 highest_fps = 60;
float update_speed = 1.00f;
int bar_graph_height = 300;
int bar_graph_width = 700;
float bar_width = 15.0f;
vec4 bar_color = vec4(1.0f, 0.0f, 0.0f, 1.0f);
IMText@ highest_fps_label;
const float MPI = 3.14159265359;
IMText@ count_down;

array<IMImage@> bars;
array<int> bars_fps;
array<int> ai;
int water_hotspot_id = -1;
uint score = 0;

string benchmark_list_address = "gyrthmcmulin.me";
string benchmark_list_request = "GET /benchmark_results.json HTTP/1.1\r\nHost: gyrthmcmulin.me\r\n\r\n";

uint16 benchmark_list_port = 80;
uint main_socket = SOCKET_ID_INVALID;

array<BenchmarkResult@> benchmark_results = {};

class BenchmarkResult{
	string cpu;
	string gpu;
	string os;
	string settings;
	int score;
	BenchmarkResult(string _cpu, string _gpu, string _os, string _settings, int _score){
		cpu = _cpu;
		gpu = _gpu;
		os = _os;
		settings = _settings;
		score = _score;
	}
}

void RequestBenchmarkList(){
	if( main_socket == SOCKET_ID_INVALID ) {
		main_socket = CreateSocketTCP(benchmark_list_address, benchmark_list_port);
        if( main_socket != SOCKET_ID_INVALID ) {
            Log( info, "Connected " + main_socket );
			array<uint8> message = toByteArray(benchmark_list_request);
			if( IsValidSocketTCP(main_socket) ){
		        SocketTCPSend(main_socket,message);
			}
        } else {
            Log( warning, "Unable to connect" );
        }
    }
}

void ReadBenchmarkList(string whole_message){
	array<string> split_message = whole_message.split("\n");
	split_message.removeRange(0, 12);
	string json = join(split_message, "");

    JSON file;
    file.parseString(json);
    JSONValue root = file.getRoot();
    array<string> list_animations = root.getMemberNames();
    for(uint i = 0; i < list_animations.size(); i++){
		JSONValue result = root[list_animations[i]];
		benchmark_results.insertLast(BenchmarkResult(result["cpu"].asString(), result["gpu"].asString(), result["os"].asString(), result["settings"].asString(), result["score"].asInt()));
    }
}

void addToByteArray(string message, array<uint8> @data){
	uint8 message_length = message.length();
	data.insertLast(message_length);
	for(uint i = 0; i < message_length; i++){
		data.insertLast(message.substr(i, 1)[0]);
	}
}

array<uint8> toByteArray(string message){
	array<uint8> data;
	for(uint i = 0; i < message.length(); i++){
		data.insertLast(message.substr(i, 1)[0]);
	}
	return data;
}

uint counter = 0;
string whole_message = "";

void IncomingTCPData(uint socket, array<uint8>@ data) {
	counter += data.size();
	string incoming = GetString(data);
	whole_message += incoming;
}

string GetString(array<uint8>@ data){
	array<string> seperated;
	int string_size = data.size();
    for( uint i = 0; i < data.size(); i++ ) {
		//Skip if the char is not an actual number/letter/etc
		/*if(data[i] < 32){
			continue;
		}*/
        string s('0');
        s[0] = data[i];
        seperated.insertLast(s);
    }
    return join(seperated, "");
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
	reset_timer_started = false;
	reset_timer = 0.0f;
	fps = 0;

	imGUI.clear();
	imGUI.setHeaderHeight(bar_graph_height + 25.0f);
	imGUI.setup();
	AddBarGraph();
	AddCountDown();
}

void AddCountDown(){
	@count_down = IMText("Getting benchmark list...", huge_font);
	imGUI.getMain().setElement(count_down);
}

void Init(string p_level_name) {
	RequestBenchmarkList();
	ReadHardwareReport();
	@imGUI = CreateIMGUI();
    level_name = p_level_name;
	imGUI.setHeaderHeight(bar_graph_height + 25.0f);
	imGUI.setup();
	AddBarGraph();
	AddCountDown();

	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);
		if(!char.controlled){
			ai.insertLast(char.GetID());
		}
	}
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
		new_bar.showBorder();
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
	if(recording){
		fps += 1;
	}
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
	post_init_done = true;
}

int camera_id = -1;
float duration = 60.0f;
float duration_timer = 0.0f;
bool recording = false;
float fps_timer = 0.0f;
float list_timer = 0.0f;
bool got_list = false;

void Update() {
	PostInit();
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

	KeepAIAlive();

	if(!got_list){
		list_timer += time_step;
		if(list_timer > 3.0f){
			got_list = true;
			recording = true;
			DestroySocketTCP(main_socket);
			ReadBenchmarkList(whole_message);
 		}
		imGUI.update();
		return;
	}

	duration_timer += time_step;
	fps_timer += time_step;

	if(duration_timer > duration && recording){
		ShowResults();
		recording = false;
		imGUI.update();
		return;
	}

	if(fps_timer > update_speed){
		fps_timer = 0.0f;
		if(recording){
			count_down.setText("Seconds left: " + int(duration - duration_timer));
			fps_collection.insertLast(uint16(fps));
		}
		score += uint(fps);
		if(fps > highest_fps){
			highest_fps = fps;
			highest_fps_label.setText(highest_fps + "fps");
		}
		ScootchBarsLeft();
		bars[bars.size() - 1].setSizeY(fps * bar_graph_height / highest_fps);
		bars_fps[bars.size() - 1] = fps;
		fps = 0;
	}

	imGUI.update();
}

float reset_timer = 0.0f;
bool reset_timer_started = false;

void KeepAIAlive(){
	if(reset_timer_started){
		reset_timer += time_step;
		if(reset_timer > 10.0f){
			for(uint j = 0; j < ai.size(); j++){
				MovementObject@ char_reset = ReadCharacterID(ai[j]);
				Object@ char_obj = ReadObjectFromID(ai[j]);

				/*char_reset.Execute("water_id = -1;water_depth = 0.0;");
				char_reset.Execute("Recover();");
				char_reset.Execute("Reset();PostReset;");
				char_reset.Execute("ResetSecondaryAnimation();");*/
				char_reset.Execute("SwitchCharacter(\"Data/Characters/rabbot.xml\");");
				char_reset.velocity = vec3(0);
				char_reset.position = char_obj.GetTranslation();
				char_reset.velocity = vec3(0);
			}
			reset_timer_started = false;
			reset_timer = 0.0f;
		}
	}else{
		for(uint i = 0; i < ai.size(); i++){
			MovementObject@ char = ReadCharacterID(ai[i]);
	        if(char.GetIntVar("knocked_out") != _awake){
				reset_timer_started = true;
				return;
			}
		}
	}
}

void ScootchBarsLeft(){
	for(uint i = 0; i < (bars.size() - 1); i++){
		bars_fps[i] = bars_fps[i + 1];
		bars[i].setSizeY(bars_fps[i + 1] * bar_graph_height / highest_fps);
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

vec2 menu_size(2400, 1100);
vec4 background_color(0,0,0,0.5);
vec4 light_background_color(0,0,0,0.25);
vec2 button_size(1000, 60);
vec2 option_size(900, 60);
vec2 connect_button_size(1000, 60);
float button_size_offset = 10.0f;
float description_width = 200.0f;
int player_name_width = 500;
int player_character_width = 200;
int max_shown_scores = 10;

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
	IMText title("Results", big_font);
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

		IMContainer gpu_label_container(menu_size.x / 5);
		IMText gpu_label("GPU", normal_font);
		gpu_label.setZOrdering(3);
		gpu_label_container.setElement(gpu_label);
		titlebar_divider.append(gpu_label_container);

		IMContainer cpu_label_container(menu_size.x / 5);
		IMText cpu_label("CPU", normal_font);
		cpu_label.setZOrdering(3);
		cpu_label_container.setElement(cpu_label);
		titlebar_divider.append(cpu_label_container);

		IMContainer os_label_container(menu_size.x / 5);
		IMText os_label("OS", normal_font);
		os_label.setZOrdering(3);
		os_label_container.setElement(os_label);
		titlebar_divider.append(os_label_container);

		IMContainer settings_label_container(menu_size.x / 5);
		IMText settings_label("Settings", normal_font);
		settings_label.setZOrdering(3);
		settings_label_container.setElement(settings_label);
		titlebar_divider.append(settings_label_container);

		IMContainer score_label_container(menu_size.x / 5);
		IMText score_label("Score", normal_font);
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
	int result_index = 0;
	for(uint i = 0; i < results_sorted.size(); i++){
		for(uint j = 0; j < benchmark_results.size(); j++){
			if(results_sorted[i] == benchmark_results[j].score){
				results_sorted[i] = j;
				if(int(score) < benchmark_results[j].score){
					result_index++;
				}
				break;
			}
		}
	}
	bool new_results_added = false;
	int num_score_counter = 0;
	//Where to add the new score. Making sure it's in the middle of a few scores if available.
	int start_at = max(0, result_index - int(max_shown_scores / 2));
	//If the score is way below on the list then add a few on top to show the same amount.
	//Add 1 because of the difference between index and size.
	if((result_index + int(max_shown_scores / 2) + 1 > int(results_sorted.size()))){
		start_at = max(0, start_at - (result_index + (int(max_shown_scores / 2) + 1 - results_sorted.size())));
	}
	for(uint i = start_at; i < results_sorted.size(); i++){
		num_score_counter++;
		BenchmarkResult@ result = benchmark_results[results_sorted[i]];
		if(result.score < int(score) && !new_results_added){
			AddNewResults(menu_divider);
			new_results_added = true;
		}
		AddSingleResult(menu_divider, result);
		if(num_score_counter == max_shown_scores){
			break;
		}
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

	array<string> buttons = {"Back to Main Menu", "Run Benchmark Again", "Close"};
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
	imGUI.getMain().setElement(menu_container);
}

void AddSingleResult(IMDivider@ menu_divider, BenchmarkResult@ result){
	//Single result
	IMContainer titlebar_container(menu_size.x, connect_button_size.y);
	menu_divider.append(titlebar_container);
	IMDivider titlebar_divider("result ", DOHorizontal);
	titlebar_divider.setZOrdering(3);
	titlebar_container.setElement(titlebar_divider);

	IMImage background(white_background);
	background.setColor(light_background_color);
	background.setZOrdering(0);
	background.setSize(vec2(menu_size.x, 60));
	titlebar_container.addFloatingElement(background, "background", vec2(0,0));

	IMContainer gpu_label_container(menu_size.x / 5);
	IMText gpu_label(result.gpu, small_font);
	gpu_label.setZOrdering(3);
	gpu_label_container.setElement(gpu_label);
	titlebar_divider.append(gpu_label_container);

	IMContainer cpu_label_container(menu_size.x / 5);
	IMText cpu_label(result.cpu, small_font);
	cpu_label.setZOrdering(3);
	cpu_label_container.setElement(cpu_label);
	titlebar_divider.append(cpu_label_container);

	IMContainer os_label_container(menu_size.x / 5);
	IMText os_label(result.os, small_font);
	os_label.setZOrdering(3);
	os_label_container.setElement(os_label);
	titlebar_divider.append(os_label_container);

	IMContainer settings_label_container(menu_size.x / 5);
	IMText settings_label(result.settings, normal_font);
	settings_label.setZOrdering(3);
	settings_label_container.setElement(settings_label);
	titlebar_divider.append(settings_label_container);

	IMContainer score_label_container(menu_size.x / 5);
	IMText score_label("" + result.score, small_font);
	score_label.setZOrdering(3);
	score_label_container.setElement(score_label);
	titlebar_divider.append(score_label_container);

	menu_divider.appendSpacer(5);
}

void AddNewResults(IMDivider@ menu_divider){
	//Your results.
	BenchmarkResult result("NA", gpu, "NA", GetConfigValueString("overall"), score);

	IMContainer results_container(menu_size.x);
	IMDivider results_divider("results_divider", DOVertical);
	results_container.setElement(results_divider);
	AddSingleResult(results_divider, result);

	IMDivider horiz_divider("main_horiz_div", DOHorizontal);
	horiz_divider.setAlignment(CACenter, CATop);
	results_divider.append(horiz_divider);

	AddStat(results_divider, "Your Score", "" + score, normal_font);

	{
		IMDivider column_one("column_one", DOVertical);
		horiz_divider.append(column_one);
		AddStat(column_one, "Highest FPS", "" + highest_fps, small_font);
		AddStat(column_one, "Lowest FPS", "" + GetLowestFPS(), small_font);
		AddStat(column_one, "Average FPS", "" + GetAverageFPS(), small_font);
	}

	{
		IMDivider column_two("column_two", DOVertical);
		horiz_divider.append(column_two);
		AddStat(column_two, "VSync", VsyncOn(), small_font);
		AddStat(column_two, "Resolution", GetConfigValueInt("screenwidth") + "x" + GetConfigValueInt("screenheight"), small_font);
		AddStat(column_two, "Driver version", driver_version, small_font);

	}

	/*{
		IMDivider column_three("column_three", DOVertical);
		horiz_divider.append(column_three);
		AddStat(column_three, "Highest FPS", "" + highest_fps, small_font);
	}*/

	menu_divider.append(results_container);
	IMImage background(white_background);
	background.setZOrdering(0);
	background.setColor(background_color);
	background.setSize(menu_size);
	results_container.addFloatingElement(background, "background", vec2(0));
}

void AddStat(IMDivider@ parent, string name, string value, FontSetup font){
	int result_width = 250;
	int result_height = 40;
	IMDivider horiz_divider("horiz_div", DOHorizontal);
	parent.append(horiz_divider);
	IMContainer label_container(result_width, result_height);
	label_container.setAlignment(CALeft, CACenter);
	horiz_divider.append(label_container);
	IMContainer value_container(result_width, result_height);
	value_container.setAlignment(CALeft, CACenter);
	horiz_divider.append(value_container);

	IMText label_text(name + ": ", font);
	label_text.setZOrdering(3);
	label_container.setElement(label_text);
	IMText value_text(value, font);
	value_text.setZOrdering(3);
	value_container.setElement(value_text);
}

string gpu = "";
string driver_version;

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
				gpu += join(new_str.split("GL_Renderer: "), " ").substr(0, 20);
			}else if(new_str.findFirst("Driver version: ") != -1){
				driver_version = join(new_str.split("Driver version: "), " ");
			}
        }
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
