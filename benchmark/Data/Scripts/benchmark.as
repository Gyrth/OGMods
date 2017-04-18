uint socket = SOCKET_ID_INVALID;
uint connect_try_countdown = 60;
string level_name = "";
uint64 last_time;
float counter = 0.0f;
IMDivider@ main_div;
vec4 color(1,0,0,1);
IMGUI imGUI;
array<PerformanceBar@> bars;
float screen_height = 1.0f;
uint64 highest_value = 100;
FontSetup font("edosz", 75, HexColor("#CCCCCC"), true);
IMText@ onscreen_fps;
IMText@ onscreen_highest_fps;
float update_speed = 0.05f;
float bar_width = 5.0f;
array<uint64> all_fps;
uint64 fps;

class PerformanceBar{
	vec2 position;
	vec2 dimensions;
	PerformanceBar(vec2 _position, vec2 _dimensions){
		dimensions = _dimensions;
		position = _position;
	}
	void Render(){
		imGUI.drawBox(position, vec2(dimensions.x, dimensions.y * screen_height / highest_value ), color, 5);
	}
	void UpdatePosition(){
		position.x -= time_step * dimensions.x / update_speed;
	}
}

void Initialize(){
	Init("this_level");
}

void Init(string p_level_name) {
    level_name = p_level_name;
	screen_height = GetScreenHeight();
	IMDivider mainDiv( "mainDiv", DOVertical );
	
	IMDivider fps_divider("fps_divider", DOHorizontal);
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
	imGUI.setup();
	@main_div = @mainDiv;
	imGUI.getMain().setElement( @mainDiv );
}

void ReceiveMessage(string msg) {
}

void DrawGUI() {
	fps = GetPerformanceFrequency() / (GetPerformanceCounter() - last_time);
	last_time = GetPerformanceCounter();
	for(uint i = 0; i < bars.size(); i++){
		bars[i].Render();
	}
	imGUI.render();
}

void Update(int paused) {
	Update();
}

void Update() {
	counter += time_step;
	
	if(GetInputPressed(0, "p")){
		PrintResults();
	}
	
	for(uint i = 0; i < bars.size(); i++){
		bars[i].UpdatePosition();
		if(bars[i].position.x < 0.0f){
			bars.removeAt(i);
			i--;
		}
	}
	if(counter > update_speed){
		counter = 0.0f;
		
		onscreen_fps.setText(fps + "");
		onscreen_highest_fps.setText(highest_value + "");
		
		all_fps.insertLast(fps);
		
		if(fps > highest_value){
			highest_value = fps;
		}
		bars.insertLast( PerformanceBar(vec2(GetScreenWidth(), 0.0f), vec2(bar_width, fps)) );
	}
	imGUI.update();
}

void SetWindowDimensions(int w, int h)
{
}

void PrintResults(){
	float average = all_fps[0];
	for(uint i = 1; i < all_fps.size(); i++){
		average = (average + all_fps[i]) / 2.0f;
	}
	Print("Average FPS: " + average + "\n");
	uint64 highest_fps = 0;
	for(uint i = 0; i < all_fps.size(); i++){
		if(all_fps[i] > highest_fps){
			highest_fps = all_fps[i];
		}
	}
	Print("Highest FPS: " + highest_fps + "\n");
	uint64 lowest_fps = 99999.0f;
	for(uint i = 0; i < all_fps.size(); i++){
		if(all_fps[i] < lowest_fps && all_fps[i] != 0){
			lowest_fps = all_fps[i];
		}
	}
	Print("Lowest FPS: " + lowest_fps + "\n");
}

bool HasFocus(){
	return false;
}
