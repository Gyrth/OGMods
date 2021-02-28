#include "save/general.as"
#include "menu_common.as"
#include "music_load.as"
#include "black_forest_save_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

// Coloring options
vec4 background_color(0.2f, 0.2f, 0.2f, 0.8f);
vec4 titlebar_color(0.4f, 0.4f, 0.4f, 1.0f);
vec4 item_background(0.4f, 0.4f, 0.4f, 1.0f);
vec4 item_hovered(0.3f, 0.3f, 0.3f, 1.0f);
vec4 item_clicked(0.3f, 0.3f, 0.3f, 1.0f);
vec4 text_color(0.9f, 0.9f, 0.9f, 1.0f);
vec4 black_color(0.0f, 0.0f, 0.0f, 1.0f);
int padding = 10;
bool open = true;
string level_path = "Data/Levels/black_forest.xml";
string sunny_level_path = "Data/Levels/black_forest_sunny.xml";
string evening_level_path = "Data/Levels/black_forest_evening.xml";
int weather_state = foggy;

array<string> game_mode_names = {	"Dynamic World",
									"Fixed World"};

array<string> weather_state_names = {	"Foggy",
										"Rainy",
										"Sunny",
										"Snowy",
										"Evening",
										"Creepy"};

int game_mode = dynamic_world;
int world_size = 8;
float enemy_spawn_mult = 1.0f;
bool distance_cull = false;
bool add_detail_objects = true;

bool HasFocus() {
	return false;
}

void Initialize() {
	@imGUI = CreateIMGUI();
	// Start playing some music
	PlaySong("overgrowth_main");

	// We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
	imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
	// Actually setup the GUI -- must do this before we do anything
	imGUI.setup();
	BuildUI();
	setBackGround();
	AddVerticalBar();
	LoadSettings();
}

void BuildUI(){
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Black Forest Editor", header_divider);
	imGUI.getHeader().setElement(header_divider);

	// Add it to the main panel of the GUI
	imGUI.getMain().setElement( @mainDiv );

	float button_trailing_space = 100.0f;
	float button_width = 400.0f;
	bool animated = true;

	IMDivider right_panel("right_panel", DOHorizontal);
	right_panel.setBorderColor(vec4(0,1,0,1));
	right_panel.setAlignment(CALeft, CABottom);
	right_panel.append(IMSpacer(DOHorizontal, button_trailing_space));
	AddButton("Back", right_panel, arrow_icon, button_back, animated, button_width);

	imGUI.getFooter().setAlignment(CALeft, CACenter);
	imGUI.getFooter().setElement(right_panel);
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
	return true;
}

void Update() {
	UpdateKeyboardMouse();
	// process any messages produced from the update
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();

		if( message.name == "run_file" ){

		}else if( message.name == "Back" ){
			SaveSettings();
			this_ui.SendCallback( "back" );
		}
	}

	// Do the general GUI updating
	imGUI.update();
	UpdateController();
}

void Resize() {
	imGUI.doScreenResize(); // This must be called first
	setBackGround();
	AddVerticalBar();
}

void ScriptReloaded() {
	// Clear the old GUI
	imGUI.clear();
	// Rebuild it
	Initialize();
}

void DrawGUI() {
	imGUI.render();

	ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_Text, text_color);
	ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_CloseButton, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);

	ImGui_Begin("Black Forest Editor", open, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize);
	float target_height = screenMetrics.getScreenHeight() * 0.33f;
	float target_width = screenMetrics.getScreenWidth() * 0.50f;
	ImGui_SetWindowPos(vec2((screenMetrics.getScreenWidth() / 2.0f) - (target_width / 2.0f), (screenMetrics.getScreenHeight() / 2.0f) - (target_height / 2.0f)));
	ImGui_SetWindowSize(vec2(target_width, target_height));

	ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f));
	if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth()  - (padding * 3.0), ImGui_GetWindowHeight() - (padding * 3.0)))){
		ImGui_PushStyleColor(ImGuiCol_FrameBg, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_MenuBarBg, item_clicked);

		float option_name_width = 240.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Game Mode");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);

		if(ImGui_BeginCombo("##Game Mode ", game_mode_names[game_mode], ImGuiComboFlags_HeightLarge)){
			for(uint i = 0; i < game_mode_names.size(); i++){
				if(ImGui_Selectable(game_mode_names[i], int(i) != game_mode, 0)){
					game_mode = i;
				}
			}
			ImGui_EndCombo();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("World Size");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderInt("##World Size", world_size, 4, 64);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Enemy Spawn Multiplier");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderFloat("##Enemy Spawn Multiplier", enemy_spawn_mult, 0.0f, 5.0f, "%.1f");
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Weather");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);

		if(ImGui_BeginCombo("##Weather", weather_state_names[weather_state], ImGuiComboFlags_HeightLarge)){
			for(uint i = 0; i < weather_state_names.size(); i++){
				if(ImGui_Selectable(weather_state_names[i], int(i) != weather_state, 0)){
					weather_state = i;
				}
			}
			ImGui_EndCombo();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Add Detail Objects");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_Checkbox("##Add Detail Objects", add_detail_objects);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		/* ImGui_AlignTextToFramePadding();
		ImGui_Text("Distance Culling");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_Checkbox("##Distance Culling", distance_cull);
		ImGui_PopItemWidth();
		ImGui_NextColumn(); */

		ImGui_NextColumn();
		if(ImGui_Button("Load")){
			SaveSettings();
			string load_level = level_path;

			if(weather_state == sunny){
				load_level = sunny_level_path;
			}else if(weather_state == evening){
				load_level = evening_level_path;
			}

			LoadLevel(load_level);
		}

		ImGui_SameLine();

		if(ImGui_Button("Reset Settings")){
			DeleteSettings();
			this_ui.SendCallback("back");
			this_ui.SendCallback("Data/Scripts/black_forest_editor.as");
		}

		ImGui_EndChildFrame();
	}
	ImGui_End();
	ImGui_PopStyleColor(21);
}

void Draw() {

}

void Init(string str) {

}
