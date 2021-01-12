#include "save/general.as"
#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

// Coloring options
vec4 background_color(0.2f, 0.2f, 0.2f, 0.7f);
vec4 titlebar_color(0.0f);
vec4 item_background(0.4f, 0.4f, 0.4f, 1.0f);
vec4 item_hovered(0.3f, 0.3f, 0.3f, 1.0f);
vec4 item_clicked(0.3f, 0.3f, 0.3f, 1.0f);
vec4 text_color(0.9f, 0.9f, 0.9f, 1.0f);
int padding = 10;
bool open = true;

array<string> train_levels = {	"desert_outpost_train_track.xml",
								"forgotten_plains_train_track.xml",
								"patchy_highlands_train_track.xml",
								"red_desert_train_track.xml",
								"red_shards_train_track.xml",
								"scrubby_hills_train_track.xml"};

int chosen_level_index = 0;
int num_intersections = 50;
int env_objects_mult = 1;

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
}

void BuildUI(){
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Train Track Editor", header_divider);
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
	ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_Text, text_color);
	ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_clicked);
	ImGui_PushStyleColor(ImGuiCol_CloseButton, background_color);
	ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);

	ImGui_Begin("Train Editor", open, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize);
	float target_height = screenMetrics.getScreenHeight() * 0.66f;
	float target_width = screenMetrics.getScreenWidth() * 0.66f;
	ImGui_SetWindowPos(vec2((screenMetrics.getScreenWidth() / 2.0f) - (target_width / 2.0f), (screenMetrics.getScreenHeight() / 2.0f) - (target_height / 2.0f)));
	ImGui_SetWindowSize(vec2(target_width, target_height));

	ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
	if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth(), ImGui_GetWindowHeight() - (padding * 3.0)))){

		if(ImGui_BeginCombo("Train Level ", train_levels[chosen_level_index], 0)){
			for(uint i = 0; i < train_levels.size(); i++){
				if(ImGui_Selectable(train_levels[i], int(i) == chosen_level_index, 0)){
					chosen_level_index = i;
				}
			}
			ImGui_EndCombo();
		}

		ImGui_DragInt("Number of intersections", num_intersections, 1.0f, 2, 100);
		ImGui_DragInt("Environmental Objects Mult ", env_objects_mult, 1.0f, 1, 10);

		if(ImGui_Button("Load Level")){
			LoadLevel(train_levels[chosen_level_index]);
		}
		ImGui_EndChildFrame();
	}
	ImGui_End();
	ImGui_PopStyleColor(19);
}

void Draw() {

}

void Init(string str) {

}
